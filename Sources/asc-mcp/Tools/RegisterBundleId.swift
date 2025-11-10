import AppStoreAPI
import AppStoreConnect
import Foundation
import Logging
import MCP

enum RegisterBundleIdHandler {
  static func handle(
    arguments: [String: Value],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    // Extract required parameters
    guard let identifier = arguments["identifier"]?.stringValue else {
      throw MCPError.invalidParams("identifier is required")
    }

    guard let name = arguments["name"]?.stringValue else {
      throw MCPError.invalidParams("name is required")
    }

    guard let platformString = arguments["platform"]?.stringValue else {
      throw MCPError.invalidParams("platform is required")
    }

    // Parse platform
    let platform: BundleIDPlatform
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

    logger.debug(
      "Registering bundle ID",
      metadata: [
        "identifier": "\(identifier)",
        "name": "\(name)",
        "platform": "\(platformString)",
      ])

    // Register bundle ID
    let bundleID = try await client.registerBundleID(
      identifier: identifier,
      name: name,
      platform: platform
    )

    // Format response
    var lines: [String] = []
    lines.append("Successfully Registered Bundle ID")
    lines.append("================================")
    lines.append("")
    lines.append("ID: \(bundleID.id)")
    lines.append("Identifier: \(bundleID.attributes?.identifier ?? "Unknown")")
    lines.append("Name: \(bundleID.attributes?.name ?? "Unknown")")
    lines.append("Platform: \(bundleID.attributes?.platform?.rawValue ?? "Unknown")")

    if let seedID = bundleID.attributes?.seedID {
      lines.append("Seed ID: \(seedID)")
    }

    return CallTool.Result(
      content: [
        .text(lines.joined(separator: "\n"))
      ]
    )
  }
}
