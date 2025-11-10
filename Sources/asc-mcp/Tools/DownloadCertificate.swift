import AppStoreAPI
import AppStoreConnect
import Foundation
import Logging
import MCP

enum DownloadCertificateHandler {
  static func handle(
    arguments: [String: Value],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    // Extract required parameters
    guard let certificateID = arguments["certificate_id"]?.stringValue else {
      throw MCPError.invalidRequest("certificate_id is required")
    }

    guard let outputPath = arguments["output_path"]?.stringValue else {
      throw MCPError.invalidRequest("output_path is required")
    }

    logger.debug(
      "Downloading certificate",
      metadata: ["certificateID": "\(certificateID)", "outputPath": "\(outputPath)"])

    // Download certificate
    let fileURL = try await client.downloadCertificate(id: certificateID, outputPath: outputPath)

    // Get file size for display
    let fileSize =
      try FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? Int ?? 0
    let fileSizeKB = Double(fileSize) / 1024.0

    // Format response
    var lines: [String] = []
    lines.append("Certificate downloaded successfully!")
    lines.append("")
    lines.append("Certificate ID: \(certificateID)")
    lines.append("Downloaded to: \(fileURL.path)")
    lines.append("File size: \(String(format: "%.2f", fileSizeKB)) KB")
    lines.append("")
    lines.append("To install the certificate:")
    lines.append("  1. Double-click the .cer file to open Keychain Access")
    lines.append("  2. The certificate will be added to your login keychain")
    lines.append("  3. Move it to the System keychain if needed for code signing")

    return CallTool.Result(
      content: [
        .text(lines.joined(separator: "\n"))
      ]
    )
  }
}
