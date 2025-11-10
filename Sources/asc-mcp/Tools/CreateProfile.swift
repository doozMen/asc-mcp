import AppStoreAPI
import AppStoreConnect
import Foundation
import Logging
import MCP

enum CreateProfileHandler {
  static func handle(
    arguments: [String: Value],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    // Extract required parameters
    guard let name = arguments["name"]?.stringValue else {
      throw MCPError.invalidParams("Missing required parameter: name")
    }

    guard let profileType = arguments["profile_type"]?.stringValue else {
      throw MCPError.invalidParams("Missing required parameter: profile_type")
    }

    guard let bundleID = arguments["bundle_id"]?.stringValue else {
      throw MCPError.invalidParams("Missing required parameter: bundle_id")
    }

    guard let certificateIDsValue = arguments["certificate_ids"] else {
      throw MCPError.invalidParams("Missing required parameter: certificate_ids")
    }

    // Parse certificate IDs array
    let certificateIDs: [String]
    if case .array(let values) = certificateIDsValue {
      certificateIDs = values.compactMap { $0.stringValue }
      if certificateIDs.isEmpty {
        throw MCPError.invalidParams("certificate_ids must be a non-empty array of strings")
      }
    } else {
      throw MCPError.invalidParams("certificate_ids must be an array")
    }

    // Parse optional device IDs
    let deviceIDs: [String]?
    if let deviceIDsValue = arguments["device_ids"] {
      if case .array(let values) = deviceIDsValue {
        deviceIDs = values.compactMap { $0.stringValue }
      } else {
        throw MCPError.invalidParams("device_ids must be an array")
      }
    } else {
      deviceIDs = nil
    }

    logger.debug(
      "Creating profile",
      metadata: [
        "name": "\(name)",
        "profileType": "\(profileType)",
        "bundleID": "\(bundleID)",
        "certificateCount": "\(certificateIDs.count)",
        "deviceCount": "\(deviceIDs?.count ?? 0)",
      ])

    // Validate profile type requirements
    let requiresDevices = [
      "IOS_APP_DEVELOPMENT",
      "IOS_APP_ADHOC",
      "MAC_APP_DEVELOPMENT",
      "TVOS_APP_DEVELOPMENT",
    ].contains(profileType.uppercased())

    if requiresDevices && (deviceIDs == nil || deviceIDs?.isEmpty == true) {
      throw MCPError.invalidParams(
        "Profile type \(profileType) requires device_ids to be specified")
    }

    // Create profile
    let profile = try await client.createProfile(
      name: name,
      profileType: profileType,
      bundleID: bundleID,
      certificateIDs: certificateIDs,
      deviceIDs: deviceIDs
    )

    // Format response
    var lines: [String] = []
    lines.append("✓ Profile Created Successfully")
    lines.append("")
    lines.append("Profile Details:")
    lines.append("  Name: \(profile.attributes?.name ?? "Unknown")")
    lines.append("  ID: \(profile.id)")
    lines.append("  Type: \(profile.attributes?.profileType?.rawValue ?? "Unknown")")
    lines.append("  Status: \(profile.attributes?.profileState?.rawValue ?? "Unknown")")

    if let expirationDate = profile.attributes?.expirationDate {
      let formatter = DateFormatter()
      formatter.dateStyle = .medium
      formatter.timeStyle = .none
      lines.append("  Expiration: \(formatter.string(from: expirationDate))")
    }

    if let uuid = profile.attributes?.uuid {
      lines.append("  UUID: \(uuid)")
    }

    lines.append("")
    lines.append(
      "The profile has been created and is ready to use. Download it using the download_profile tool."
    )

    return CallTool.Result(
      content: [
        .text(lines.joined(separator: "\n"))
      ]
    )
  }
}
