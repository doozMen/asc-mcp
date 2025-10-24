import AppStoreConnect
import Foundation
import Logging
import MCP

enum UploadDSYMsToFirebaseHandler {
  static func handle(
    arguments: [String: Value],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    // Extract required firebase_app_id
    guard let firebaseAppID = arguments["firebase_app_id"]?.stringValue else {
      throw MCPError.invalidParams("Missing required parameter: firebase_app_id")
    }

    // Extract one of: build_id, archive_path, or dsyms_path
    let buildID = arguments["build_id"]?.stringValue
    let archivePath = arguments["archive_path"]?.stringValue
    let dsymsPath = arguments["dsyms_path"]?.stringValue

    // Validate that exactly one source is provided
    let sources = [buildID, archivePath, dsymsPath].compactMap { $0 }
    guard sources.count == 1 else {
      throw MCPError.invalidParams(
        "Must provide exactly one of: build_id, archive_path, or dsyms_path"
      )
    }

    logger.debug(
      "Preparing to upload dSYMs to Firebase",
      metadata: [
        "firebaseAppID": "\(firebaseAppID)",
        "buildID": "\(buildID ?? "none")",
        "archivePath": "\(archivePath ?? "none")",
        "dsymsPath": "\(dsymsPath ?? "none")",
      ])

    // Determine the dSYMs directory path
    let dsymDirectory: URL

    if let buildID = buildID {
      // Download from App Store Connect first
      logger.info("Downloading dSYMs from App Store Connect", metadata: ["buildID": "\(buildID)"])

      // Create temporary directory for download
      let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("firebase-dsyms-\(UUID().uuidString)")

      dsymDirectory = try await client.downloadDSYMs(buildID: buildID, outputPath: tempDir.path)

    } else if let archivePath = archivePath {
      // Use archive/dSYMs directory
      let archiveURL = URL(filePath: archivePath)
      guard FileManager.default.fileExists(atPath: archiveURL.path) else {
        throw MCPError.invalidParams("Archive path does not exist: \(archivePath)")
      }

      dsymDirectory = archiveURL.appendingPathComponent("dSYMs")

      guard FileManager.default.fileExists(atPath: dsymDirectory.path) else {
        throw MCPError.invalidParams(
          "dSYMs directory not found in archive: \(dsymDirectory.path)"
        )
      }

    } else if let dsymsPath = dsymsPath {
      // Use direct path
      dsymDirectory = URL(filePath: dsymsPath)

      guard FileManager.default.fileExists(atPath: dsymDirectory.path) else {
        throw MCPError.invalidParams("dSYMs path does not exist: \(dsymsPath)")
      }

    } else {
      throw MCPError.invalidParams("Internal error: no dSYM source provided")
    }

    // Verify the directory contains .dSYM files
    let fileManager = FileManager.default
    guard let contents = try? fileManager.contentsOfDirectory(atPath: dsymDirectory.path) else {
      throw MCPError.invalidParams("Cannot read dSYMs directory: \(dsymDirectory.path)")
    }

    let dsymFiles = contents.filter { $0.hasSuffix(".dSYM") }
    guard !dsymFiles.isEmpty else {
      throw MCPError.invalidParams(
        "No .dSYM files found in directory: \(dsymDirectory.path)"
      )
    }

    logger.info(
      "Found dSYM files to upload",
      metadata: [
        "count": "\(dsymFiles.count)",
        "directory": "\(dsymDirectory.path)",
      ])

    // Create FirebaseCLI actor and upload dSYMs
    let firebaseCLI = FirebaseCLI(logger: logger)

    do {
      // Get full paths for upload
      let dsymPaths = dsymFiles.map { dsymDirectory.appendingPathComponent($0).path }

      let (output, error) = try await firebaseCLI.uploadDSYMs(
        firebaseAppID: firebaseAppID,
        dsymPaths: dsymPaths
      )

      // Format success response
      var lines: [String] = []
      lines.append("✓ dSYMs Uploaded to Firebase Successfully")
      lines.append("")
      lines.append("Firebase App ID: \(firebaseAppID)")
      lines.append("dSYM Directory: \(dsymDirectory.path)")
      lines.append("")
      lines.append("Uploaded \(dsymFiles.count) dSYM file(s):")
      for file in dsymFiles.sorted() {
        lines.append("  - \(file)")
      }
      lines.append("")
      lines.append("Firebase CLI Output:")
      lines.append(output)

      if !error.isEmpty {
        lines.append("")
        lines.append("Warnings/Info:")
        lines.append(error)
      }

      lines.append("")
      lines.append("The symbols are now available in Firebase Crashlytics for crash symbolication.")

      logger.info(
        "Successfully uploaded dSYMs to Firebase",
        metadata: [
          "firebaseAppID": "\(firebaseAppID)",
          "fileCount": "\(dsymFiles.count)",
        ])

      return CallTool.Result(
        content: [
          .text(lines.joined(separator: "\n"))
        ]
      )

    } catch {
      logger.error(
        "Failed to upload dSYMs to Firebase",
        metadata: [
          "firebaseAppID": "\(firebaseAppID)",
          "error": "\(error.localizedDescription)",
        ])

      throw MCPError.invalidRequest(
        "Failed to upload dSYMs to Firebase: \(error.localizedDescription)"
      )
    }
  }
}
