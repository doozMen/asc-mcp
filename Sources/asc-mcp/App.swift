import ArgumentParser
import Foundation
import Logging
import MCP

enum LogLevel: String, ExpressibleByArgument {
  case debug, info, warn, error

  var loggerLevel: Logger.Level {
    switch self {
    case .debug: return .debug
    case .info: return .info
    case .warn: return .warning
    case .error: return .error
    }
  }
}

@main
struct AppStoreConnectCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "appstoreconnect-mcp",
    abstract: "MCP server for App Store Connect API integration",
    version: "0.0.1-alpha.0"
  )

  @Option(name: .long, help: "Log level: 'debug', 'info', 'warn', or 'error'")
  var logLevel: LogLevel = .info

  func run() async throws {
    // Setup logging to stderr
    LoggingSystem.bootstrap { label in
      var handler = StreamLogHandler.standardError(label: label)
      handler.logLevel = logLevel.loggerLevel
      return handler
    }

    let logger = Logger(label: "appstoreconnect-mcp")

    // Validate environment variables
    guard let keyID = ProcessInfo.processInfo.environment["ASC_KEY_ID"],
      let issuerID = ProcessInfo.processInfo.environment["ASC_ISSUER_ID"],
      let privateKeyPath = ProcessInfo.processInfo.environment["ASC_PRIVATE_KEY_PATH"]
    else {
      logger.error(
        "Missing required environment variables: ASC_KEY_ID, ASC_ISSUER_ID, ASC_PRIVATE_KEY_PATH")
      throw ExitCode.failure
    }

    let keyExpiry =
      ProcessInfo.processInfo.environment["ASC_KEY_EXPIRY"]
      .flatMap(Int.init) ?? 1200

    logger.info(
      "Starting App Store Connect MCP server",
      metadata: [
        "keyIDPrefix": "\(String(keyID.prefix(4)))***",
        "keyExpiry": "\(keyExpiry)",
      ])

    let server = try await MCPServer(
      keyID: keyID,
      issuerID: issuerID,
      privateKeyPath: privateKeyPath,
      keyExpiry: keyExpiry
    )

    try await server.run()
  }
}
