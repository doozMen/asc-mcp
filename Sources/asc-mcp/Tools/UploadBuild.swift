import AppStoreConnect
import Foundation
import Logging
import MCP

enum UploadBuildHandler {
  static func handle(
    arguments: [String: Value],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    // Extract required IPA path
    guard let ipaPath = arguments["ipa_path"]?.stringValue else {
      throw MCPError.invalidParams("Missing required parameter: ipa_path")
    }

    // Extract optional platform (default: ios)
    let platform = arguments["platform"]?.stringValue ?? "ios"

    // Validate platform
    let validPlatforms = ["ios", "appletvos", "osx"]
    guard validPlatforms.contains(platform) else {
      throw MCPError.invalidParams(
        "Invalid platform: \(platform). Must be one of: \(validPlatforms.joined(separator: ", "))")
    }

    // Get credentials from environment
    guard let keyID = ProcessInfo.processInfo.environment["ASC_KEY_ID"] else {
      throw MCPError.invalidParams(
        "Missing ASC_KEY_ID environment variable. Set your App Store Connect API Key ID.")
    }

    guard let issuerID = ProcessInfo.processInfo.environment["ASC_ISSUER_ID"] else {
      throw MCPError.invalidParams(
        "Missing ASC_ISSUER_ID environment variable. Set your App Store Connect Issuer ID.")
    }

    logger.info(
      "Starting build upload",
      metadata: [
        "ipaPath": "\(ipaPath)",
        "platform": "\(platform)",
      ])

    // Create TransporterCLI instance
    let transporter = TransporterCLI(logger: logger)

    do {
      // Upload the IPA
      let output = try await transporter.upload(
        ipaPath: ipaPath,
        platform: platform,
        username: keyID,
        password: issuerID
      )

      var lines: [String] = []
      lines.append("Build upload initiated successfully")
      lines.append("")
      lines.append("IPA: \(ipaPath)")
      lines.append("Platform: \(platform)")
      lines.append("")
      lines.append("Upload Output:")
      lines.append(output)
      lines.append("")
      lines.append("Note: The build will now be processed by App Store Connect.")
      lines.append("This may take several minutes. Use 'get_upload_status' to check progress.")

      return CallTool.Result(
        content: [
          .text(lines.joined(separator: "\n"))
        ]
      )

    } catch let error as TransporterCLIError {
      logger.error("Upload failed", metadata: ["error": "\(error)"])
      throw MCPError.internalError(error.localizedDescription)
    } catch {
      logger.error("Unexpected upload error", metadata: ["error": "\(error)"])
      throw error
    }
  }
}
