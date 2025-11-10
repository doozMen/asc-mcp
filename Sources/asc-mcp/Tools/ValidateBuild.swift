import AppStoreConnect
import Foundation
import Logging
import MCP

enum ValidateBuildHandler {
  static func handle(
    arguments: [String: Value],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    // Extract required IPA path
    guard let ipaPath = arguments["ipa_path"]?.stringValue else {
      throw MCPError.invalidParams("Missing required parameter: ipa_path")
    }

    logger.info(
      "Starting build validation",
      metadata: [
        "ipaPath": "\(ipaPath)"
      ])

    // Create TransporterCLI instance
    let transporter = TransporterCLI(logger: logger)

    do {
      // Validate the IPA
      let output = try await transporter.validate(ipaPath: ipaPath)

      var lines: [String] = []
      lines.append("Build validation completed successfully")
      lines.append("")
      lines.append("IPA: \(ipaPath)")
      lines.append("")
      lines.append("Validation Output:")
      lines.append(output)
      lines.append("")
      lines.append("The IPA is ready for upload to App Store Connect.")

      return CallTool.Result(
        content: [
          .text(lines.joined(separator: "\n"))
        ]
      )

    } catch let error as TransporterCLIError {
      logger.error("Validation failed", metadata: ["error": "\(error)"])

      var lines: [String] = []
      lines.append("Build validation failed")
      lines.append("")
      lines.append("IPA: \(ipaPath)")
      lines.append("")
      lines.append("Error: \(error.localizedDescription)")
      if let suggestion = error.recoverySuggestion {
        lines.append("")
        lines.append("Suggestion:")
        lines.append(suggestion)
      }

      return CallTool.Result(
        content: [
          .text(lines.joined(separator: "\n"))
        ],
        isError: true
      )

    } catch {
      logger.error("Unexpected validation error", metadata: ["error": "\(error)"])
      throw error
    }
  }
}
