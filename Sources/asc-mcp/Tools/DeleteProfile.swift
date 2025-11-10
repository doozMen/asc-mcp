import AppStoreAPI
import AppStoreConnect
import Foundation
import Logging
import MCP

enum DeleteProfileHandler {
  static func handle(
    arguments: [String: Value],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    // Extract required parameter
    guard let profileID = arguments["profile_id"]?.stringValue else {
      throw MCPError.invalidParams("Missing required parameter: profile_id")
    }

    logger.debug("Deleting profile", metadata: ["profileID": "\(profileID)"])

    // Delete profile
    try await client.deleteProfile(id: profileID)

    // Format response
    var lines: [String] = []
    lines.append("✓ Profile Deleted Successfully")
    lines.append("")
    lines.append("Profile ID: \(profileID)")
    lines.append("")
    lines.append("The provisioning profile has been permanently deleted from App Store Connect.")
    lines.append(
      "Note: This action cannot be undone. You will need to create a new profile if needed.")

    return CallTool.Result(
      content: [
        .text(lines.joined(separator: "\n"))
      ]
    )
  }
}
