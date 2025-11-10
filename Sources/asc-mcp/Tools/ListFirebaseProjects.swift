import Foundation
import Logging
import MCP

enum ListFirebaseProjectsHandler {
  static func handle(
    arguments: [String: Value],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    logger.debug("Listing Firebase projects")

    let firebaseCLI = FirebaseCLI(logger: logger)

    do {
      // Execute: firebase projects:list --json
      let (output, error) = try await firebaseCLI.executeCommand(
        arguments: ["projects:list", "--json"]
      )

      // Check for authentication errors
      if error.contains("not logged in") || error.contains("authentication") {
        throw FirebaseCLIError.notLoggedIn
      }

      // Parse JSON response
      guard let jsonData = output.data(using: .utf8) else {
        throw FirebaseCLIError.jsonParsingFailed("Unable to convert output to data")
      }

      let decoder = JSONDecoder()
      let response = try decoder.decode(FirebaseProjectsResponse.self, from: jsonData)

      // Format response
      var lines: [String] = []
      lines.append("Firebase Projects")
      lines.append(String(repeating: "=", count: 80))
      lines.append("")

      if response.result.isEmpty {
        lines.append("No Firebase projects found.")
        lines.append("")
        lines.append("Ensure you have access to at least one Firebase project.")
      } else {
        lines.append("Found \(response.result.count) project(s):")
        lines.append("")

        // Create formatted table
        let maxNameLength = response.result.map { $0.displayName.count }.max() ?? 20
        let maxIDLength = response.result.map { $0.projectId.count }.max() ?? 20
        let maxNumberLength = response.result.map { $0.projectNumber.count }.max() ?? 15

        // Header
        let nameHeader = "Display Name".padding(
          toLength: max(maxNameLength, 12), withPad: " ", startingAt: 0)
        let idHeader = "Project ID".padding(
          toLength: max(maxIDLength, 10), withPad: " ", startingAt: 0)
        let numberHeader = "Project Number".padding(
          toLength: max(maxNumberLength, 14), withPad: " ", startingAt: 0)
        let locationHeader = "Resource Location"

        lines.append("\(nameHeader) | \(idHeader) | \(numberHeader) | \(locationHeader)")
        lines.append(String(repeating: "-", count: 80))

        // Projects
        for project in response.result.sorted(by: { $0.displayName < $1.displayName }) {
          let name = project.displayName.padding(
            toLength: max(maxNameLength, 12), withPad: " ", startingAt: 0)
          let id = project.projectId.padding(
            toLength: max(maxIDLength, 10), withPad: " ", startingAt: 0)
          let number = project.projectNumber.padding(
            toLength: max(maxNumberLength, 14), withPad: " ", startingAt: 0)
          let location = project.resources?.locationId ?? "N/A"

          lines.append("\(name) | \(id) | \(number) | \(location)")
        }
      }

      lines.append("")
      lines.append("To get details on a specific project, use: get_firebase_project")

      logger.info(
        "Successfully listed Firebase projects",
        metadata: [
          "count": "\(response.result.count)"
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
        "Failed to list Firebase projects",
        metadata: [
          "error": "\(error.localizedDescription)"
        ])
      throw MCPError.invalidRequest(
        "Failed to list Firebase projects: \(error.localizedDescription)")
    }
  }
}

// MARK: - Data Models

struct FirebaseProjectsResponse: Codable, Sendable {
  let result: [FirebaseProject]
}

struct FirebaseProject: Codable, Sendable {
  let projectId: String
  let projectNumber: String
  let displayName: String
  let name: String
  let resources: FirebaseResources?
  let state: String?
}

struct FirebaseResources: Codable, Sendable {
  let hostingSite: String?
  let realtimeDatabaseInstance: String?
  let storageBucket: String?
  let locationId: String?
}
