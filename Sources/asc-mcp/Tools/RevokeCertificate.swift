import AppStoreAPI
import AppStoreConnect
import Foundation
import Logging
import MCP

enum RevokeCertificateHandler {
  static func handle(
    arguments: [String: Value],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    // Extract required parameter
    guard let certificateID = arguments["certificate_id"]?.stringValue else {
      throw MCPError.invalidRequest("certificate_id is required")
    }

    logger.debug("Revoking certificate", metadata: ["certificateID": "\(certificateID)"])

    // Get certificate details before revoking for confirmation message
    let certificate = try await client.getCertificate(id: certificateID)
    let displayName =
      certificate.attributes?.displayName ?? certificate.attributes?.name ?? "Unknown"
    let type = certificate.attributes?.certificateType?.rawValue ?? "Unknown"

    // Revoke certificate
    try await client.revokeCertificate(id: certificateID)

    // Format response
    var lines: [String] = []
    lines.append("Certificate revoked successfully!")
    lines.append("")
    lines.append("Certificate ID: \(certificateID)")
    lines.append("Name: \(displayName)")
    lines.append("Type: \(type)")
    lines.append("")
    lines.append(
      "Note: This certificate has been permanently revoked and can no longer be used for code signing."
    )

    return CallTool.Result(
      content: [
        .text(lines.joined(separator: "\n"))
      ]
    )
  }
}
