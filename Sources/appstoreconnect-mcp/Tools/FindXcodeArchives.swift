import Foundation
import Logging
import MCP

enum FindXcodeArchivesHandler {
  static func handle(
    arguments: [String: Value],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    // Extract optional filters
    let appNameFilter = arguments["app_name_filter"]?.stringValue
    let bundleIDFilter = arguments["bundle_id_filter"]?.stringValue
    let latestOnly = arguments["latest_only"]?.boolValue ?? false

    logger.debug(
      "Searching for Xcode archives",
      metadata: [
        "appNameFilter": "\(appNameFilter ?? "none")",
        "bundleIDFilter": "\(bundleIDFilter ?? "none")",
        "latestOnly": "\(latestOnly)",
      ])

    // Create ArchiveFinder actor
    let archiveFinder = ArchiveFinder(logger: logger)

    // Find archives with filters
    let archives: [XcodeArchive]

    do {
      if latestOnly {
        let latest = try await archiveFinder.findLatestArchive(
          appNameFilter: appNameFilter,
          bundleIDFilter: bundleIDFilter
        )
        archives = [latest]
      } else {
        archives = try await archiveFinder.findArchives(
          appNameFilter: appNameFilter,
          bundleIDFilter: bundleIDFilter
        )
      }
    } catch {
      logger.error("Failed to find archives", metadata: ["error": "\(error.localizedDescription)"])
      throw MCPError.invalidRequest("Failed to find archives: \(error.localizedDescription)")
    }

    // Format response
    var lines: [String] = []

    if archives.isEmpty {
      lines.append("No Xcode archives found matching the criteria.")
      if let filter = appNameFilter {
        lines.append("  App Name Filter: \(filter)")
      }
      if let filter = bundleIDFilter {
        lines.append("  Bundle ID Filter: \(filter)")
      }
    } else {
      lines.append("Found \(archives.count) Xcode archive(s)")
      lines.append("")

      for archive in archives {
        lines.append("Archive: \(archive.name)")
        lines.append("  Bundle ID: \(archive.bundleID)")
        lines.append("  Version: \(archive.version) (\(archive.buildNumber))")
        lines.append("  Created: \(FormatHelpers.formatDate(archive.creationDate))")
        lines.append("  Path: \(archive.path)")

        // Check if dSYMs exist
        let dsymsPath = archive.path.appendingPathComponent("dSYMs").path
        if FileManager.default.fileExists(atPath: dsymsPath) {
          if let contents = try? FileManager.default.contentsOfDirectory(atPath: dsymsPath) {
            let dsymFiles = contents.filter { $0.hasSuffix(".dSYM") }
            lines.append("  dSYMs: \(dsymFiles.count) file(s)")
          }
        } else {
          lines.append("  dSYMs: Not available")
        }

        lines.append("")
      }
    }

    logger.info(
      "Archive search completed",
      metadata: [
        "count": "\(archives.count)",
        "latestOnly": "\(latestOnly)",
      ])

    return CallTool.Result(
      content: [
        .text(lines.joined(separator: "\n"))
      ]
    )
  }
}
