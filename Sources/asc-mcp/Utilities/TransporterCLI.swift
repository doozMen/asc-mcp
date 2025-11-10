import Foundation
import Logging
import Subprocess

#if canImport(System)
  @preconcurrency import System
#else
  @preconcurrency import SystemPackage
#endif

/// Thread-safe actor for executing xcrun iTMSTransporter commands
actor TransporterCLI {
  private let logger: Logger
  private var cachedPath: String?

  init(logger: Logger) {
    self.logger = logger
  }

  /// Detects iTMSTransporter installation path
  /// - Returns: Absolute path to iTMSTransporter executable
  /// - Throws: TransporterCLIError.notInstalled if iTMSTransporter is not found
  func detectTransporter() async throws -> String {
    // Return cached path if available
    if let cached = cachedPath {
      logger.debug("Using cached iTMSTransporter path", metadata: ["path": "\(cached)"])
      return cached
    }

    logger.info("Detecting iTMSTransporter installation...")

    // Use xcrun to locate iTMSTransporter
    do {
      let result = try await Subprocess.run(
        .path("/usr/bin/xcrun"),
        arguments: ["--find", "iTMSTransporter"],
        output: .string(limit: 1024)
      )

      guard result.terminationStatus.isSuccess else {
        throw TransporterCLIError.notInstalled
      }

      guard let output = result.standardOutput else {
        throw TransporterCLIError.notInstalled
      }

      let trimmedPath = output.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

      guard !trimmedPath.isEmpty else {
        throw TransporterCLIError.notInstalled
      }

      logger.info("Found iTMSTransporter via xcrun", metadata: ["path": "\(trimmedPath)"])
      cachedPath = trimmedPath
      return trimmedPath

    } catch {
      logger.error(
        "iTMSTransporter not found",
        metadata: [
          "error": "\(error)",
          "suggestion": "Install Xcode command line tools",
        ])
      throw TransporterCLIError.notInstalled
    }
  }

  /// Uploads an IPA file to App Store Connect
  /// - Parameters:
  ///   - ipaPath: Absolute path to the .ipa file
  ///   - platform: Platform type (ios, appletvos, osx)
  ///   - username: App Store Connect username or API Key ID
  ///   - password: App Store Connect password or API Key Issuer ID
  /// - Returns: Output from the upload command
  /// - Throws: TransporterCLIError if upload fails
  func upload(
    ipaPath: String,
    platform: String,
    username: String,
    password: String
  ) async throws -> String {
    guard FileManager.default.fileExists(atPath: ipaPath) else {
      throw TransporterCLIError.fileNotFound(ipaPath)
    }

    guard ipaPath.hasSuffix(".ipa") else {
      throw TransporterCLIError.invalidFile("File must be a .ipa file")
    }

    logger.info(
      "Uploading IPA to App Store Connect",
      metadata: [
        "ipaPath": "\(ipaPath)",
        "platform": "\(platform)",
      ])

    let transporterPath = try await detectTransporter()

    let arguments = [
      "-m", "upload",
      "-assetFile", ipaPath,
      "-type", platform,
      "-u", username,
      "-p", password,
    ]

    do {
      let result = try await Subprocess.run(
        .path(FilePath(transporterPath)),
        arguments: Subprocess.Arguments(arguments),
        output: .string(limit: .max),
        error: .string(limit: .max)
      )

      let output = result.standardOutput ?? ""
      let error = result.standardError ?? ""

      // Log output for debugging
      if !output.isEmpty {
        logger.debug("iTMSTransporter stdout", metadata: ["output": "\(output.prefix(500))..."])
      }

      if !error.isEmpty {
        logger.debug("iTMSTransporter stderr", metadata: ["error": "\(error.prefix(500))..."])
      }

      guard result.terminationStatus.isSuccess else {
        let exitCode: Int
        if case .exited(let code) = result.terminationStatus {
          exitCode = Int(code)
        } else {
          exitCode = -1
        }
        logger.error(
          "Upload failed",
          metadata: [
            "exitCode": "\(exitCode)",
            "error": "\(error)",
          ])
        throw TransporterCLIError.uploadFailed(exitCode, error)
      }

      logger.info("Upload completed successfully")
      return output

    } catch let error as TransporterCLIError {
      throw error
    } catch {
      logger.error(
        "Upload command execution error",
        metadata: [
          "error": "\(error)"
        ])
      throw error
    }
  }

  /// Validates an IPA file before upload
  /// - Parameters:
  ///   - ipaPath: Absolute path to the .ipa file
  /// - Returns: Validation output
  /// - Throws: TransporterCLIError if validation fails
  func validate(ipaPath: String) async throws -> String {
    guard FileManager.default.fileExists(atPath: ipaPath) else {
      throw TransporterCLIError.fileNotFound(ipaPath)
    }

    guard ipaPath.hasSuffix(".ipa") else {
      throw TransporterCLIError.invalidFile("File must be a .ipa file")
    }

    logger.info(
      "Validating IPA",
      metadata: [
        "ipaPath": "\(ipaPath)"
      ])

    let transporterPath = try await detectTransporter()

    let arguments = [
      "-m", "verify",
      "-assetFile", ipaPath,
      "-type", "ios",
    ]

    do {
      let result = try await Subprocess.run(
        .path(FilePath(transporterPath)),
        arguments: Subprocess.Arguments(arguments),
        output: .string(limit: .max),
        error: .string(limit: .max)
      )

      let output = result.standardOutput ?? ""
      let error = result.standardError ?? ""

      // Log output for debugging
      if !output.isEmpty {
        logger.debug("iTMSTransporter stdout", metadata: ["output": "\(output.prefix(500))..."])
      }

      if !error.isEmpty {
        logger.debug("iTMSTransporter stderr", metadata: ["error": "\(error.prefix(500))..."])
      }

      guard result.terminationStatus.isSuccess else {
        let exitCode: Int
        if case .exited(let code) = result.terminationStatus {
          exitCode = Int(code)
        } else {
          exitCode = -1
        }
        logger.error(
          "Validation failed",
          metadata: [
            "exitCode": "\(exitCode)",
            "error": "\(error)",
          ])
        throw TransporterCLIError.validationFailed(exitCode, error)
      }

      logger.info("Validation completed successfully")
      return output

    } catch let error as TransporterCLIError {
      throw error
    } catch {
      logger.error(
        "Validation command execution error",
        metadata: [
          "error": "\(error)"
        ])
      throw error
    }
  }
}

/// iTMSTransporter CLI error types
enum TransporterCLIError: Error, LocalizedError, Sendable {
  case notInstalled
  case fileNotFound(String)
  case invalidFile(String)
  case uploadFailed(Int, String)
  case validationFailed(Int, String)
  case authenticationFailed

  var errorDescription: String? {
    switch self {
    case .notInstalled:
      return "iTMSTransporter not found. Install Xcode command line tools."
    case .fileNotFound(let path):
      return "IPA file not found at path: \(path)"
    case .invalidFile(let message):
      return "Invalid file: \(message)"
    case .uploadFailed(let exitCode, let message):
      return "Upload failed with exit code \(exitCode): \(message)"
    case .validationFailed(let exitCode, let message):
      return "Validation failed with exit code \(exitCode): \(message)"
    case .authenticationFailed:
      return "Authentication failed. Check ASC_KEY_ID and ASC_ISSUER_ID environment variables."
    }
  }

  var recoverySuggestion: String? {
    switch self {
    case .notInstalled:
      return """
        Install Xcode command line tools:
        - xcode-select --install
        - Or install full Xcode from App Store
        """
    case .fileNotFound:
      return "Verify the file path exists and is accessible"
    case .invalidFile:
      return "Ensure the file is a valid .ipa file"
    case .uploadFailed, .validationFailed:
      return
        "Check the error message for details. Ensure the IPA is properly signed and configured."
    case .authenticationFailed:
      return
        "Set ASC_KEY_ID and ASC_ISSUER_ID environment variables with your App Store Connect API credentials"
    }
  }
}
