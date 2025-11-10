import AppStoreAPI
import AppStoreConnect
import Foundation
import Logging
import MCP

enum GetBundleIdHandler {
  static func handle(
    arguments: [String: Value],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    // Extract bundle_id parameter (can be ID or identifier)
    guard let bundleIDParam = arguments["bundle_id"]?.stringValue else {
      throw MCPError.invalidParams("bundle_id is required")
    }

    logger.debug(
      "Getting bundle ID details",
      metadata: ["bundleID": "\(bundleIDParam)"])

    // Try to determine if it's an ID or identifier
    let bundleID: BundleID
    if bundleIDParam.contains(".") {
      // Likely an identifier (e.g., com.example.app)
      bundleID = try await client.findBundleIDByIdentifier(bundleIDParam)
    } else {
      // Likely an ID
      bundleID = try await client.getBundleID(id: bundleIDParam)
    }

    // Get capabilities
    let capabilities = try await client.getBundleIDCapabilities(bundleIDID: bundleID.id)

    // Format response
    var lines: [String] = []
    lines.append("Bundle ID Details")
    lines.append("=================")
    lines.append("")
    lines.append("ID: \(bundleID.id)")
    lines.append("Identifier: \(bundleID.attributes?.identifier ?? "Unknown")")
    lines.append("Name: \(bundleID.attributes?.name ?? "Unknown")")
    lines.append("Platform: \(bundleID.attributes?.platform?.rawValue ?? "Unknown")")

    if let seedID = bundleID.attributes?.seedID {
      lines.append("Seed ID: \(seedID)")
    }

    lines.append("")
    lines.append("Capabilities (\(capabilities.count)):")
    lines.append("-------------")

    if capabilities.isEmpty {
      lines.append("No capabilities enabled")
    } else {
      for capability in capabilities {
        if let capType = capability.attributes?.capabilityType {
          lines.append("  - \(capType.rawValue)")
        }
      }
    }

    return CallTool.Result(
      content: [
        .text(lines.joined(separator: "\n"))
      ]
    )
  }
}
