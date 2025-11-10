import AppStoreAPI
import AppStoreConnect
import Foundation
import Logging
import MCP

enum ListBundleIdsHandler {
  static func handle(
    arguments: [String: Value],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    // Extract optional filters
    let platformString = arguments["platform"]?.stringValue
    let identifierFilter = arguments["identifier_filter"]?.stringValue

    // Parse platform if provided
    var platform: BundleIDPlatform?
    if let platformString = platformString {
      switch platformString.uppercased() {
      case "IOS":
        platform = .iOS
      case "MAC_OS", "MACOS":
        platform = .macOS
      case "UNIVERSAL":
        platform = .universal
      default:
        throw MCPError.invalidParams(
          "Invalid platform: \(platformString). Valid values: IOS, MAC_OS, UNIVERSAL")
      }
    }

    logger.debug(
      "Listing bundle IDs",
      metadata: [
        "platform": "\(platformString ?? "none")",
        "identifierFilter": "\(identifierFilter ?? "none")",
      ])

    // Fetch bundle IDs
    let bundleIDs = try await client.listBundleIDs(
      platform: platform,
      identifierFilter: identifierFilter
    )

    // Format response as table
    var lines: [String] = []
    lines.append("Found \(bundleIDs.count) bundle ID(s)")
    lines.append("")

    if bundleIDs.isEmpty {
      lines.append("No bundle IDs found matching the criteria.")
    } else {
      // Table header
      lines.append(String(format: "%-40s %-30s %-12s %s", "Identifier", "Name", "Platform", "ID"))
      lines.append(String(repeating: "-", count: 100))

      for bundleID in bundleIDs {
        let identifier = bundleID.attributes?.identifier ?? "Unknown"
        let name = bundleID.attributes?.name ?? "Unknown"
        let platformValue = bundleID.attributes?.platform?.rawValue ?? "Unknown"

        lines.append(
          String(format: "%-40s %-30s %-12s %s", identifier, name, platformValue, bundleID.id))
      }
    }

    return CallTool.Result(
      content: [
        .text(lines.joined(separator: "\n"))
      ]
    )
  }
}
