import Foundation
import Logging
import MCP

enum GetFirebaseProjectHandler {
  static func handle(
    arguments: [String: Value],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    // Extract required project_id parameter
    guard let projectID = arguments["project_id"]?.stringValue else {
      throw MCPError.invalidParams("Missing required parameter: project_id")
    }

    logger.debug("Getting Firebase project details", metadata: ["projectID": "\(projectID)"])

    let firebaseCLI = FirebaseCLI(logger: logger)

    do {
      // Execute: firebase projects:get PROJECT_ID --json
      let (output, error) = try await firebaseCLI.executeCommand(
        arguments: ["projects:get", projectID, "--json"]
      )

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
      let project = try decoder.decode(FirebaseProjectDetail.self, from: jsonData)

      // Format detailed response
      var lines: [String] = []
      lines.append("Firebase Project Details")
      lines.append(String(repeating: "=", count: 80))
      lines.append("")
      lines.append("Display Name:     \(project.displayName)")
      lines.append("Project ID:       \(project.projectId)")
      lines.append("Project Number:   \(project.projectNumber)")
      lines.append("Name:             \(project.name)")

      if let state = project.state {
        lines.append("State:            \(state)")
      }

      lines.append("")
      lines.append("Resources:")
      if let resources = project.resources {
        if let locationId = resources.locationId {
          lines.append("  Location ID:           \(locationId)")
        }
        if let hostingSite = resources.hostingSite {
          lines.append("  Hosting Site:          \(hostingSite)")
        }
        if let storageBucket = resources.storageBucket {
          lines.append("  Storage Bucket:        \(storageBucket)")
        }
        if let databaseInstance = resources.realtimeDatabaseInstance {
          lines.append("  Database Instance:     \(databaseInstance)")
        }
      } else {
        lines.append("  No resources configured")
      }

      lines.append("")
      lines.append("To list apps in this project, use: list_firebase_apps")

      logger.info(
        "Successfully retrieved Firebase project details",
        metadata: [
          "projectID": "\(projectID)"
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
        "Failed to get Firebase project",
        metadata: [
          "projectID": "\(projectID)",
          "error": "\(error.localizedDescription)",
        ])
      throw MCPError.invalidRequest("Failed to get Firebase project: \(error.localizedDescription)")
    }
  }
}

// MARK: - Data Models

struct FirebaseProjectDetail: Codable, Sendable {
  let projectId: String
  let projectNumber: String
  let displayName: String
  let name: String
  let resources: FirebaseResources?
  let state: String?
}
