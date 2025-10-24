import Foundation
import Logging
import MCP

enum ListFirebaseAppsHandler {
  static func handle(
    arguments: [String: Value],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    // Extract required project_id parameter
    guard let projectID = arguments["project_id"]?.stringValue else {
      throw MCPError.invalidParams("Missing required parameter: project_id")
    }

    // Extract optional platform filter
    let platform = arguments["platform"]?.stringValue

    logger.debug(
      "Listing Firebase apps",
      metadata: [
        "projectID": "\(projectID)",
        "platform": "\(platform ?? "all")",
      ])

    let firebaseCLI = FirebaseCLI(logger: logger)

    do {
      // Build command arguments
      var commandArgs = ["apps:list", "--project", projectID, "--json"]

      // Add platform filter if specified
      if let platform = platform {
        guard ["ios", "android", "web"].contains(platform.lowercased()) else {
          throw MCPError.invalidParams("Invalid platform. Must be one of: ios, android, web")
        }
        commandArgs.append(contentsOf: ["--platform", platform.lowercased()])
      }

      // Execute command
      let (output, error) = try await firebaseCLI.executeCommand(arguments: commandArgs)

      // Check for authentication errors
      if error.contains("not logged in") || error.contains("authentication") {
        throw FirebaseCLIError.notLoggedIn
      }

      // Check for permission or not found errors
      if error.contains("Permission denied") || error.contains("403") {
        throw FirebaseCLIError.permissionDenied(projectID)
      }

      if error.contains("not found") || error.contains("404") {
        throw FirebaseCLIError.invalidProjectID(projectID)
      }

      // Parse JSON response
      guard let jsonData = output.data(using: .utf8) else {
        throw FirebaseCLIError.jsonParsingFailed("Unable to convert output to data")
      }

      let decoder = JSONDecoder()
      let response = try decoder.decode(FirebaseAppsResponse.self, from: jsonData)

      // Format response
      var lines: [String] = []
      lines.append("Firebase Apps in Project: \(projectID)")
      lines.append(String(repeating: "=", count: 80))
      lines.append("")

      if response.result.isEmpty {
        lines.append("No apps found in this project.")
        if let platform = platform {
          lines.append("(Filter: \(platform) apps only)")
        }
      } else {
        let platformFilter = platform != nil ? " (\(platform!) apps only)" : ""
        lines.append("Found \(response.result.count) app(s)\(platformFilter):")
        lines.append("")

        // Group apps by platform
        let iosApps = response.result.filter { $0.platform == "IOS" }
        let androidApps = response.result.filter { $0.platform == "ANDROID" }
        let webApps = response.result.filter { $0.platform == "WEB" }

        // iOS Apps
        if !iosApps.isEmpty {
          lines.append("iOS Apps (\(iosApps.count)):")
          lines.append(String(repeating: "-", count: 40))
          for app in iosApps.sorted(by: { $0.displayName ?? "" < $1.displayName ?? "" }) {
            lines.append("  Name:        \(app.displayName ?? "N/A")")
            lines.append("  App ID:      \(app.appId)")
            if let bundleId = app.bundleId {
              lines.append("  Bundle ID:   \(bundleId)")
            }
            if let namespace = app.namespace {
              lines.append("  Namespace:   \(namespace)")
            }
            lines.append("")
          }
        }

        // Android Apps
        if !androidApps.isEmpty {
          lines.append("Android Apps (\(androidApps.count)):")
          lines.append(String(repeating: "-", count: 40))
          for app in androidApps.sorted(by: { $0.displayName ?? "" < $1.displayName ?? "" }) {
            lines.append("  Name:          \(app.displayName ?? "N/A")")
            lines.append("  App ID:        \(app.appId)")
            if let packageName = app.packageName {
              lines.append("  Package Name:  \(packageName)")
            }
            if let namespace = app.namespace {
              lines.append("  Namespace:     \(namespace)")
            }
            lines.append("")
          }
        }

        // Web Apps
        if !webApps.isEmpty {
          lines.append("Web Apps (\(webApps.count)):")
          lines.append(String(repeating: "-", count: 40))
          for app in webApps.sorted(by: { $0.displayName ?? "" < $1.displayName ?? "" }) {
            lines.append("  Name:      \(app.displayName ?? "N/A")")
            lines.append("  App ID:    \(app.appId)")
            if let namespace = app.namespace {
              lines.append("  Namespace: \(namespace)")
            }
            lines.append("")
          }
        }
      }

      lines.append("Use the App ID with other Firebase tools (e.g., upload_dsyms_to_firebase)")

      logger.info(
        "Successfully listed Firebase apps",
        metadata: [
          "projectID": "\(projectID)",
          "count": "\(response.result.count)",
        ])

      return CallTool.Result(
        content: [
          .text(lines.joined(separator: "\n"))
        ]
      )

    } catch let error as FirebaseCLIError {
      logger.error("Firebase CLI error", metadata: ["error": "\(error.localizedDescription)"])
      throw MCPError.invalidRequest(error.localizedDescription)

    } catch {
      logger.error(
        "Failed to list Firebase apps",
        metadata: [
          "projectID": "\(projectID)",
          "error": "\(error.localizedDescription)",
        ])
      throw MCPError.invalidRequest("Failed to list Firebase apps: \(error.localizedDescription)")
    }
  }
}

// MARK: - Data Models

struct FirebaseAppsResponse: Codable, Sendable {
  let result: [FirebaseApp]
}

struct FirebaseApp: Codable, Sendable {
  let appId: String
  let displayName: String?
  let platform: String
  let bundleId: String?  // iOS
  let packageName: String?  // Android
  let namespace: String?
}
