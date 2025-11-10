import AppStoreAPI
import AppStoreConnect
import Foundation
import Logging
import MCP

enum DownloadProfileHandler {
  static func handle(
    arguments: [String: Value],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    // Extract required parameters
    guard let profileID = arguments["profile_id"]?.stringValue else {
      throw MCPError.invalidParams("Missing required parameter: profile_id")
    }

    guard let outputPath = arguments["output_path"]?.stringValue else {
      throw MCPError.invalidParams("Missing required parameter: output_path")
    }

    logger.debug(
      "Preparing profile download",
      metadata: [
        "profileID": "\(profileID)",
        "outputPath": "\(outputPath)",
      ])

    // Download profile
    let profileURL = try await client.downloadProfile(profileID: profileID, outputPath: outputPath)

    // Get file size
    let fileSize =
      try FileManager.default.attributesOfItem(atPath: profileURL.path)[.size] as? Int ?? 0
    let fileSizeKB = Double(fileSize) / 1024.0

    // Format response
    var lines: [String] = []
    lines.append("✓ Profile Downloaded Successfully")
    lines.append("")
    lines.append("Profile ID: \(profileID)")
    lines.append("File Path: \(profileURL.path)")
    lines.append("File Size: \(String(format: "%.2f KB", fileSizeKB))")
    lines.append("")
    lines.append("Installation Instructions:")
    lines.append("  1. Double-click the .mobileprovision file to install it in Xcode")
    lines.append("  2. Or manually copy it to ~/Library/MobileDevice/Provisioning Profiles/")
    lines.append("  3. The profile will appear in Xcode's signing settings")
    lines.append("")
    lines.append("The provisioning profile is ready to use for code signing.")

    return CallTool.Result(
      content: [
        .text(lines.joined(separator: "\n"))
      ]
    )
  }
}
