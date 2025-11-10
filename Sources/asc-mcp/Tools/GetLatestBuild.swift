import AppStoreAPI
import AppStoreConnect
import Foundation
import Logging
import MCP

enum GetLatestBuildHandler {
  static func handle(
    arguments: [String: Value],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    // Extract required app ID
    guard let appID = arguments["app_id"]?.stringValue else {
      throw MCPError.invalidParams("Missing required parameter: app_id")
    }

    logger.debug("Getting latest build", metadata: ["appID": "\(appID)"])

    // Get latest build
    let build = try await client.getLatestBuild(appID: appID)

    // Format response
    var lines: [String] = []
    lines.append("Latest Build")
    lines.append("============")
    lines.append("")

    lines.append(contentsOf: FormatHelpers.formatBuildInfo(build))

    if let minOsVersion = build.attributes?.minOsVersion {
      lines.append("Min OS Version: \(minOsVersion)")
    }

    if let usesNonExemptEncryption = build.attributes?.usesNonExemptEncryption {
      lines.append("Uses Non-Exempt Encryption: \(usesNonExemptEncryption ? "Yes" : "No")")
    }

    return CallTool.Result(
      content: [
        .text(lines.joined(separator: "\n"))
      ]
    )
  }
}
