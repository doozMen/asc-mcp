import AppStoreAPI
import AppStoreConnect
import Foundation
import Logging
import MCP

enum ListAppsHandler {
  static func handle(
    arguments: [String: Value],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    // Extract optional bundle ID filter
    let bundleIDFilter = arguments["bundle_id_filter"]?.stringValue

    logger.debug("Listing apps", metadata: ["bundleIDFilter": "\(bundleIDFilter ?? "none")"])

    // Fetch apps
    let apps = try await client.listApps(bundleIDFilter: bundleIDFilter)

    // Format response
    var lines: [String] = []
    lines.append("Found \(apps.count) app(s)")
    lines.append("")

    for app in apps {
      let name = app.attributes?.name ?? "Unknown"
      let bundleID = app.attributes?.bundleID ?? "Unknown"
      let sku = app.attributes?.sku ?? "Unknown"

      lines.append("App: \(name)")
      lines.append("  ID: \(app.id)")
      lines.append("  Bundle ID: \(bundleID)")
      lines.append("  SKU: \(sku)")
      lines.append("")
    }

    return CallTool.Result(
      content: [
        .text(lines.joined(separator: "\n"))
      ]
    )
  }
}
