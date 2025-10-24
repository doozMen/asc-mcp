import Foundation
import Logging

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
            "/usr/local/bin/firebase",     // Intel Homebrew
            "/usr/bin/firebase"            // System installation
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
            let (output, _) = try await executeCommand(
                "/usr/bin/which",
                arguments: ["firebase"]
            )
            
            let trimmedPath = output.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !trimmedPath.isEmpty, fileManager.isExecutableFile(atPath: trimmedPath) else {
                throw FirebaseCLIError.notInstalled
            }
            
            logger.info("Found Firebase CLI via which", metadata: ["path": "\(trimmedPath)"])
            cachedPath = trimmedPath
            return trimmedPath
            
        } catch {
            logger.error("Firebase CLI not found", metadata: [
                "error": "\(error)",
                "suggestion": "Install with: npm install -g firebase-tools"
            ])
            throw FirebaseCLIError.notInstalled
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
        
        logger.info("Uploading dSYMs to Firebase Crashlytics", metadata: [
            "appID": "\(firebaseAppID)",
            "fileCount": "\(dsymPaths.count)"
        ])
        
        let firebasePath = try await detectFirebaseCLI()
        
        // Build command arguments
        var arguments = [
            "crashlytics:symbols:upload",
            "--app", firebaseAppID
        ]
        arguments.append(contentsOf: dsymPaths)
        
        logger.debug("Executing Firebase command", metadata: [
            "command": "firebase \(arguments.joined(separator: " "))"
        ])
        
        do {
            let (output, error) = try await executeCommand(
                firebasePath,
                arguments: arguments
            )
            
            logger.info("Firebase upload completed successfully", metadata: [
                "outputLength": "\(output.count)",
                "errorLength": "\(error.count)"
            ])
            
            return (output, error)
            
        } catch let FirebaseCLIError.commandFailed(command, status) {
            logger.error("Firebase upload failed", metadata: [
                "command": "\(command)",
                "exitCode": "\(status)"
            ])
            throw FirebaseCLIError.commandFailed(command, status)
            
        } catch {
            logger.error("Firebase upload error", metadata: [
                "error": "\(error)"
            ])
            throw error
        }
    }
    
    /// Executes a command and returns stdout and stderr
    /// - Parameters:
    ///   - executable: Absolute path to executable
    ///   - arguments: Command arguments
    /// - Returns: Tuple containing stdout and stderr
    /// - Throws: FirebaseCLIError.commandFailed if process exits with non-zero status
    private func executeCommand(
        _ executable: String,
        arguments: [String]
    ) async throws -> (output: String, error: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        
        // Wait for process to complete
        process.waitUntilExit()
        
        // Read output and error
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        let output = String(data: outputData, encoding: .utf8) ?? ""
        let error = String(data: errorData, encoding: .utf8) ?? ""
        
        // Check termination status
        guard process.terminationStatus == 0 else {
            let command = ([executable] + arguments).joined(separator: " ")
            throw FirebaseCLIError.commandFailed(command, Int(process.terminationStatus))
        }
        
        return (output, error)
    }
}

/// Firebase CLI error types
enum FirebaseCLIError: Error, LocalizedError, Sendable {
    case notInstalled
    case commandFailed(String, Int)
    
    var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "Firebase CLI not found. Install with: npm install -g firebase-tools"
        case .commandFailed(let command, let status):
            return "Firebase command '\(command)' failed with exit code \(status)"
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
        }
    }
}
