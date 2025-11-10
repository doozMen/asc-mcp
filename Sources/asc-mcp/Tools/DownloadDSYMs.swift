import AppStoreAPI
import AppStoreConnect
import Foundation
import Logging
import MCP

enum DownloadDSYMsHandler {
  static func handle(
    arguments: [String: Value],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    // Extract required parameters
    guard let buildID = arguments["build_id"]?.stringValue else {
      throw MCPError.invalidParams("Missing required parameter: build_id")
    }

    guard let outputPath = arguments["output_path"]?.stringValue else {
      throw MCPError.invalidParams("Missing required parameter: output_path")
    }

    logger.debug(
      "Preparing dSYM download information",
      metadata: [
        "buildID": "\(buildID)",
        "outputPath": "\(outputPath)",
      ])

    // Download and extract dSYMs (pure Swift implementation)
    let dsymDirectory = try await client.downloadDSYMs(buildID: buildID, outputPath: outputPath)

    // List extracted dSYM files
    let fileManager = FileManager.default
    var dsymFiles: [String] = []
    if let contents = try? fileManager.contentsOfDirectory(atPath: dsymDirectory.path) {
      dsymFiles = contents.filter { $0.hasSuffix(".dSYM") }
    }

    // Format response
    var lines: [String] = []
    lines.append("✓ dSYMs Downloaded Successfully")
    lines.append("")
    lines.append("Build ID: \(buildID)")
    lines.append("dSYM Directory: \(dsymDirectory.path)")
    lines.append("")
    lines.append("Downloaded \(dsymFiles.count) dSYM file(s):")
    for file in dsymFiles {
      lines.append("  - \(file)")
    }
    lines.append("")
    lines.append("The dSYM files are ready to use for crash symbolication.")
    lines.append(
      "You can now upload them to Firebase Crashlytics or use them with crash analysis tools.")

    return CallTool.Result(
      content: [
        .text(lines.joined(separator: "\n"))
      ]
    )
  }
}
