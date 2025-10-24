import AppStoreAPI
import AppStoreConnect
import Foundation
import Logging
import MCP

enum GetAppStatusHandler {
  static func handle(
    arguments: [String: Value],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    let appID = arguments["app_id"]?.stringValue
    let bundleID = arguments["bundle_id"]?.stringValue

    // Validate that at least one identifier is provided
    guard appID != nil || bundleID != nil else {
      throw MCPError.invalidParams("Either app_id or bundle_id must be provided")
    }

    logger.debug(
      "Getting app status",
      metadata: [
        "appID": "\(appID ?? "none")",
        "bundleID": "\(bundleID ?? "none")",
      ])

    // Get app either by ID or bundle ID
    let app: App
    if let appID = appID {
      app = try await client.getApp(id: appID)
    } else if let bundleID = bundleID {
      app = try await client.findAppByBundleID(bundleID)
    } else {
      throw MCPError.invalidParams("Either app_id or bundle_id must be provided")
    }

    // Format detailed app status
    var lines: [String] = []
    lines.append("App Status")
    lines.append("==========")
    lines.append("")
    lines.append("Name: \(app.attributes?.name ?? "Unknown")")
    lines.append("ID: \(app.id)")
    lines.append("Bundle ID: \(app.attributes?.bundleID ?? "Unknown")")
    lines.append("SKU: \(app.attributes?.sku ?? "Unknown")")
    lines.append("Primary Locale: \(app.attributes?.primaryLocale ?? "Unknown")")

    if let contentRightsDeclaration = app.attributes?.contentRightsDeclaration {
      lines.append("Content Rights: \(contentRightsDeclaration)")
    }

    return CallTool.Result(
      content: [
        .text(lines.joined(separator: "\n"))
      ]
    )
  }
}
