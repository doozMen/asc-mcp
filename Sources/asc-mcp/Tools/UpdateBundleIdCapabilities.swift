import AppStoreAPI
import AppStoreConnect
import Foundation
import Logging
import MCP

enum UpdateBundleIdCapabilitiesHandler {
  static func handle(
    arguments: [String: Value],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    // Extract parameters
    guard let bundleIDParam = arguments["bundle_id"]?.stringValue else {
      throw MCPError.invalidParams("bundle_id is required")
    }

    guard let capabilitiesArray = arguments["capabilities"]?.arrayValue else {
      throw MCPError.invalidParams("capabilities is required and must be an array")
    }

    // Parse capabilities
    var capabilityTypes: [CapabilityType] = []
    for capValue in capabilitiesArray {
      guard let capString = capValue.stringValue else {
        throw MCPError.invalidParams("Each capability must be a string")
      }

      // Try to match capability type
      guard
        let capType = CapabilityType(
          rawValue: capString.uppercased().replacingOccurrences(of: "-", with: "_"))
      else {
        throw MCPError.invalidParams(
          "Invalid capability: \(capString). See documentation for valid capability types.")
      }

      capabilityTypes.append(capType)
    }

    logger.debug(
      "Updating bundle ID capabilities",
      metadata: [
        "bundleID": "\(bundleIDParam)",
        "capabilities": "\(capabilityTypes.map { $0.rawValue }.joined(separator: ", "))",
      ])

    // Get bundle ID (either by ID or identifier)
    let bundleID: BundleID
    if bundleIDParam.contains(".") {
      bundleID = try await client.findBundleIDByIdentifier(bundleIDParam)
    } else {
      bundleID = try await client.getBundleID(id: bundleIDParam)
    }

    // Get existing capabilities
    let existingCapabilities = try await client.getBundleIDCapabilities(bundleIDID: bundleID.id)
    let existingTypes = Set(existingCapabilities.compactMap { $0.attributes?.capabilityType })

    // Enable new capabilities
    var enabledCapabilities: [BundleIDCapability] = []
    var skippedCapabilities: [String] = []

    for capType in capabilityTypes {
      if existingTypes.contains(capType) {
        skippedCapabilities.append(capType.rawValue)
        logger.debug("Capability already enabled", metadata: ["capability": "\(capType.rawValue)"])
      } else {
        let capability = try await client.enableBundleIDCapability(
          bundleIDID: bundleID.id,
          capabilityType: capType
        )
        enabledCapabilities.append(capability)
      }
    }

    // Format response
    var lines: [String] = []
    lines.append("Bundle ID Capabilities Updated")
    lines.append("==============================")
    lines.append("")
    lines.append("Bundle ID: \(bundleID.attributes?.identifier ?? "Unknown")")
    lines.append("Name: \(bundleID.attributes?.name ?? "Unknown")")
    lines.append("")

    if !enabledCapabilities.isEmpty {
      lines.append("Newly Enabled Capabilities (\(enabledCapabilities.count)):")
      for capability in enabledCapabilities {
        if let capType = capability.attributes?.capabilityType {
          lines.append("  ✓ \(capType.rawValue)")
        }
      }
      lines.append("")
    }

    if !skippedCapabilities.isEmpty {
      lines.append("Already Enabled (skipped \(skippedCapabilities.count)):")
      for capType in skippedCapabilities {
        lines.append("  - \(capType)")
      }
      lines.append("")
    }

    // Show all current capabilities
    let allCapabilities = try await client.getBundleIDCapabilities(bundleIDID: bundleID.id)
    lines.append("Total Capabilities Enabled: \(allCapabilities.count)")
    for capability in allCapabilities {
      if let capType = capability.attributes?.capabilityType {
        lines.append("  • \(capType.rawValue)")
      }
    }

    return CallTool.Result(
      content: [
        .text(lines.joined(separator: "\n"))
      ]
    )
  }
}
