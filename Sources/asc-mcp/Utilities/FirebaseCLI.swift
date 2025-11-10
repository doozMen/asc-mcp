import Foundation
import Logging
import Subprocess

#if canImport(System)
  @preconcurrency import System
#else
  @preconcurrency import SystemPackage
#endif

/// Thread-safe actor for executing Firebase CLI commands
actor FirebaseCLI {
  private let logger: Logger
  private var cachedPath: String?

  init(logger: Logger) {
    self.logger = logger
  }

  /// Detects Firebase CLI installation path
  /// - Returns: Absolute path to firebase CLI executable
  /// - Throws: FirebaseCLIError.notInstalled if Firebase CLI is not found
  func detectFirebaseCLI() async throws -> String {
    // Return cached path if available
    if let cached = cachedPath {
      logger.debug("Using cached Firebase CLI path", metadata: ["path": "\(cached)"])
      return cached
    }

    logger.info("Detecting Firebase CLI installation...")

    // Common Homebrew installation paths (check these first for performance)
    let commonPaths = [
      "/opt/homebrew/bin/firebase",  // Apple Silicon Homebrew
      "/usr/local/bin/firebase",  // Intel Homebrew
      "/usr/bin/firebase",  // System installation
    ]

    let fileManager = FileManager.default

    for path in commonPaths {
      if fileManager.isExecutableFile(atPath: path) {
        logger.info("Found Firebase CLI at common path", metadata: ["path": "\(path)"])
        cachedPath = path
        return path
      }
    }

    // Fallback to which command
    logger.debug("Common paths failed, trying 'which firebase'")

    do {
      let result = try await Subprocess.run(
        .path("/usr/bin/which"),
        arguments: ["firebase"],
        output: .string(limit: 1024)
      )

      guard result.terminationStatus.isSuccess else {
        throw FirebaseCLIError.notInstalled
      }

      guard let output = result.standardOutput else {
        throw FirebaseCLIError.notInstalled
      }

      let trimmedPath = output.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

      guard !trimmedPath.isEmpty, fileManager.isExecutableFile(atPath: trimmedPath) else {
        throw FirebaseCLIError.notInstalled
      }

      logger.info("Found Firebase CLI via which", metadata: ["path": "\(trimmedPath)"])
      cachedPath = trimmedPath
      return trimmedPath

    } catch {
      logger.error(
        "Firebase CLI not found",
        metadata: [
          "error": "\(error)",
          "suggestion": "Install with: npm install -g firebase-tools",
        ])
      throw FirebaseCLIError.notInstalled
    }
  }

  /// Generic method to execute any Firebase CLI command
  /// - Parameters:
  ///   - arguments: Command arguments (e.g., ["projects:list", "--json"])
  /// - Returns: Tuple containing stdout and stderr output
  /// - Throws: FirebaseCLIError if command fails
  public func executeCommand(arguments: [String]) async throws -> (output: String, error: String) {
    guard !arguments.isEmpty else {
      throw FirebaseCLIError.invalidCommand("No command arguments provided")
    }

    logger.info(
      "Executing Firebase CLI command",
      metadata: [
        "command": "firebase \(arguments.joined(separator: " "))"
      ])

    let firebasePath = try await detectFirebaseCLI()

    logger.debug("Using Firebase CLI", metadata: ["path": "\(firebasePath)"])

    do {
      let result = try await Subprocess.run(
        .path(FilePath(firebasePath)),
        arguments: Subprocess.Arguments(arguments),
        output: .string(limit: .max),
        error: .string(limit: .max)
      )

      let output = result.standardOutput ?? ""
      let error = result.standardError ?? ""

      // Log output for debugging
      if !output.isEmpty {
        logger.debug("Firebase stdout", metadata: ["output": "\(output.prefix(500))..."])
      }

      if !error.isEmpty {
        logger.debug("Firebase stderr", metadata: ["error": "\(error.prefix(500))..."])
      }

      guard result.terminationStatus.isSuccess else {
        let command = "firebase \(arguments.joined(separator: " "))"
        let exitCode: Int
        if case .exited(let code) = result.terminationStatus {
          exitCode = Int(code)
        } else {
          exitCode = -1
        }
        logger.error(
          "Firebase command failed",
          metadata: [
            "command": "\(command)",
            "exitCode": "\(exitCode)",
            "error": "\(error)",
          ])
        throw FirebaseCLIError.commandFailed(command, exitCode)
      }

      logger.info("Firebase command completed successfully")
      return (output, error)

    } catch let error as FirebaseCLIError {
      throw error
    } catch {
      logger.error(
        "Firebase command execution error",
        metadata: [
          "error": "\(error)"
        ])
      throw error
    }
  }

  /// Uploads dSYM files to Firebase Crashlytics
  /// - Parameters:
  ///   - firebaseAppID: Firebase App ID (e.g., "1:123456789:ios:abc123")
  ///   - dsymPaths: Array of absolute paths to dSYM files or directories
  /// - Returns: Tuple containing stdout and stderr output
  /// - Throws: FirebaseCLIError if upload fails
  func uploadDSYMs(
    firebaseAppID: String,
    dsymPaths: [String]
  ) async throws -> (output: String, error: String) {
    guard !dsymPaths.isEmpty else {
      logger.warning("No dSYM paths provided for upload")
      return ("", "No dSYM paths provided")
    }

    logger.info(
      "Uploading dSYMs to Firebase Crashlytics",
      metadata: [
        "appID": "\(firebaseAppID)",
        "fileCount": "\(dsymPaths.count)",
      ])

    // Build command arguments
    var arguments = [
      "crashlytics:symbols:upload",
      "--app", firebaseAppID,
    ]
    arguments.append(contentsOf: dsymPaths)

    return try await executeCommand(arguments: arguments)
  }
}

/// Firebase CLI error types
enum FirebaseCLIError: Error, LocalizedError, Sendable {
  case notInstalled
  case commandFailed(String, Int)
  case invalidCommand(String)
  case notLoggedIn
  case permissionDenied(String)
  case invalidProjectID(String)
  case jsonParsingFailed(String)

  var errorDescription: String? {
    switch self {
    case .notInstalled:
      return "Firebase CLI not found. Install with: npm install -g firebase-tools"
    case .commandFailed(let command, let status):
      return "Firebase command '\(command)' failed with exit code \(status)"
    case .invalidCommand(let message):
      return "Invalid Firebase command: \(message)"
    case .notLoggedIn:
      return "Not logged into Firebase. Run: firebase login"
    case .permissionDenied(let resource):
      return "Permission denied for Firebase resource: \(resource)"
    case .invalidProjectID(let projectID):
      return "Invalid Firebase project ID: \(projectID)"
    case .jsonParsingFailed(let message):
      return "Failed to parse Firebase CLI JSON output: \(message)"
    }
  }

  var recoverySuggestion: String? {
    switch self {
    case .notInstalled:
      return """
        Install Firebase CLI using one of these methods:
        - npm: npm install -g firebase-tools
        - Homebrew: brew install firebase-cli
        - Direct download: https://firebase.google.com/docs/cli
        """
    case .commandFailed(_, let status):
      return "Check the Firebase CLI output for details. Exit code: \(status)"
    case .invalidCommand:
      return "Verify the command arguments are correct"
    case .notLoggedIn:
      return "Run 'firebase login' to authenticate with Firebase"
    case .permissionDenied:
      return "Verify you have access to this Firebase project"
    case .invalidProjectID:
      return "Verify the project ID exists and you have access to it"
    case .jsonParsingFailed:
      return "Check that Firebase CLI is up to date"
    }
  }
}
