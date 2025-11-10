import AppStoreAPI
import AppStoreConnect
import Foundation
import Logging
import MCP

enum ListBuildsHandler {
  static func handle(
    arguments: [String: Value],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    // Extract required app ID
    guard let appID = arguments["app_id"]?.stringValue else {
      throw MCPError.invalidParams("Missing required parameter: app_id")
    }

    // Extract optional version filter
    let versionFilter = arguments["version_filter"]?.stringValue

    logger.debug(
      "Listing builds",
      metadata: [
        "appID": "\(appID)",
        "versionFilter": "\(versionFilter ?? "none")",
      ])

    // Fetch builds
    let builds = try await client.listBuilds(appID: appID, versionFilter: versionFilter)

    // Format response
    var lines: [String] = []
    lines.append("Found \(builds.count) build(s)")
    lines.append("")

    for build in builds {
      let version = build.attributes?.version ?? "Unknown"
      lines.append("Build: \(version)")

      let buildInfo = FormatHelpers.formatBuildInfo(build)
      // Skip first line (Version) since we already show it as "Build: X"
      for info in buildInfo.dropFirst() {
        lines.append("  \(info)")
      }

      lines.append("")
    }

    return CallTool.Result(
      content: [
        .text(lines.joined(separator: "\n"))
      ]
    )
  }
}
