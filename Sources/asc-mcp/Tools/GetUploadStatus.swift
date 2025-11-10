import AppStoreAPI
import AppStoreConnect
import Foundation
import Logging
import MCP

enum GetUploadStatusHandler {
  static func handle(
    arguments: [String: Value],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    // Extract required app ID
    guard let appID = arguments["app_id"]?.stringValue else {
      throw MCPError.invalidParams("Missing required parameter: app_id")
    }

    logger.info(
      "Checking upload status",
      metadata: [
        "appID": "\(appID)"
      ])

    // Fetch latest builds to check upload status
    let builds = try await client.listBuilds(appID: appID, versionFilter: nil)

    guard !builds.isEmpty else {
      return CallTool.Result(
        content: [
          .text(
            "No builds found for app ID: \(appID)\n\nIf you just uploaded a build, it may take a few minutes to appear."
          )
        ]
      )
    }

    // Sort builds by upload date (most recent first)
    let sortedBuilds = builds.sorted { build1, build2 in
      guard let date1 = build1.attributes?.uploadedDate,
        let date2 = build2.attributes?.uploadedDate
      else {
        return false
      }
      return date1 > date2
    }

    // Get the latest build
    guard let latestBuild = sortedBuilds.first else {
      return CallTool.Result(
        content: [
          .text("No builds found for app ID: \(appID)")
        ]
      )
    }

    // Format response with latest build information
    var lines: [String] = []
    lines.append("Latest Build Status")
    lines.append("")

    let buildInfo = FormatHelpers.formatBuildInfo(latestBuild)
    lines.append(contentsOf: buildInfo)

    // Add processing state information
    if let processingState = latestBuild.attributes?.processingState {
      lines.append("")
      lines.append("Processing State: \(processingState)")

      // Add helpful context about processing states
      lines.append("")
      switch processingState {
      case .processing:
        lines.append(
          "The build is currently being processed. This typically takes 10-30 minutes.")
      case .valid:
        lines.append("The build has been processed successfully and is ready for testing.")
      case .invalid:
        lines.append(
          "The build processing failed. Check the build details in App Store Connect for errors.")
      default:
        lines.append("Processing state: \(processingState)")
      }
    }

    // Show other recent builds
    if sortedBuilds.count > 1 {
      lines.append("")
      lines.append("Recent Builds: (showing last 5)")
      lines.append("")

      for build in sortedBuilds.prefix(5).dropFirst() {
        let version = build.attributes?.version ?? "Unknown"
        let state = build.attributes?.processingState?.rawValue ?? "Unknown"

        if let uploadDate = build.attributes?.uploadedDate {
          let formatter = DateFormatter()
          formatter.dateStyle = .medium
          formatter.timeStyle = .short
          let dateString = formatter.string(from: uploadDate)
          lines.append("- \(version) - \(state) - Uploaded: \(dateString)")
        } else {
          lines.append("- \(version) - \(state)")
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
