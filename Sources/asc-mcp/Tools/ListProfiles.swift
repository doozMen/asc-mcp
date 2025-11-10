import AppStoreAPI
import AppStoreConnect
import Foundation
import Logging
import MCP

enum ListProfilesHandler {
  static func handle(
    arguments: [String: Value],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    // Extract optional parameters
    let profileType = arguments["profile_type"]?.stringValue
    let bundleIDFilter = arguments["bundle_id_filter"]?.stringValue

    logger.debug(
      "Listing profiles",
      metadata: [
        "profileType": "\(profileType ?? "none")",
        "bundleIDFilter": "\(bundleIDFilter ?? "none")",
      ])

    // Fetch profiles
    let response = try await client.listProfiles(
      profileType: profileType,
      bundleIDFilter: bundleIDFilter
    )

    // Filter by bundle ID if needed (client-side filtering)
    var profiles = response.data
    if let bundleFilter = bundleIDFilter, !bundleFilter.isEmpty {
      profiles = profiles.filter { profile in
        guard let bundleIDRel = profile.relationships?.bundleID?.data?.id else {
          return false
        }

        // Look up bundle ID in included data
        if let included = response.included {
          for item in included {
            if case .bundleID(let bundleID) = item {
              if bundleID.id == bundleIDRel,
                let identifier = bundleID.attributes?.identifier,
                identifier.localizedCaseInsensitiveContains(bundleFilter)
              {
                return true
              }
            }
          }
        }
        return false
      }
    }

    // Format response
    var lines: [String] = []
    lines.append("Found \(profiles.count) provisioning profile(s)")
    lines.append("")

    if profiles.isEmpty {
      lines.append("No profiles found matching the criteria.")
    } else {
      // Table header
      lines.append(
        String(
          format: "%-40s %-25s %-10s %-30s",
          "Name", "Type", "Status", "Bundle ID"))
      lines.append(String(repeating: "-", count: 110))

      for profile in profiles {
        let name = profile.attributes?.name ?? "Unknown"
        let type = profile.attributes?.profileType?.rawValue ?? "Unknown"
        let state = profile.attributes?.profileState?.rawValue ?? "Unknown"

        // Get bundle ID from included data
        var bundleIDStr = "Unknown"
        if let bundleIDRel = profile.relationships?.bundleID?.data?.id,
          let included = response.included
        {
          for item in included {
            if case .bundleID(let bundleID) = item, bundleID.id == bundleIDRel {
              bundleIDStr = bundleID.attributes?.identifier ?? "Unknown"
              break
            }
          }
        }

        // Truncate long names
        let truncatedName = name.count > 38 ? String(name.prefix(35)) + "..." : name
        let truncatedType =
          type.count > 23 ? String(type.prefix(20)) + "..." : type
        let truncatedBundleID =
          bundleIDStr.count > 28 ? String(bundleIDStr.prefix(25)) + "..." : bundleIDStr

        lines.append(
          String(
            format: "%-40s %-25s %-10s %-30s",
            truncatedName, truncatedType, state, truncatedBundleID))

        // Add expiration date
        if let expirationDate = profile.attributes?.expirationDate {
          let formatter = DateFormatter()
          formatter.dateStyle = .medium
          formatter.timeStyle = .none
          lines.append("  Expiration: \(formatter.string(from: expirationDate))")
        }

        lines.append("  ID: \(profile.id)")
        lines.append("")
      }
    }

    return CallTool.Result(
      content: [
        .text(lines.joined(separator: "\n"))
      ]
    )
  }
}
