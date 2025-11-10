import AppStoreAPI
import AppStoreConnect
import Foundation
import Logging
import MCP

enum CreateCertificateHandler {
  static func handle(
    arguments: [String: Value],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    // Extract required parameters
    guard let certificateTypeString = arguments["certificate_type"]?.stringValue else {
      throw MCPError.invalidRequest("certificate_type is required")
    }

    guard let csrContent = arguments["csr_content"]?.stringValue else {
      throw MCPError.invalidRequest("csr_content is required")
    }

    // Parse certificate type
    guard let certificateType = CertificateType(rawValue: certificateTypeString) else {
      throw ASCError.invalidCertificateType(certificateTypeString)
    }

    logger.debug(
      "Creating certificate",
      metadata: [
        "certificateType": "\(certificateTypeString)",
        "csrLength": "\(csrContent.count)",
      ])

    // Create certificate
    let certificate = try await client.createCertificate(
      csrContent: csrContent,
      certificateType: certificateType
    )

    // Format response
    var lines: [String] = []
    lines.append("Certificate created successfully!")
    lines.append("")
    lines.append("Certificate ID: \(certificate.id)")

    if let type = certificate.attributes?.certificateType {
      lines.append("Type: \(type.rawValue)")
    }

    if let displayName = certificate.attributes?.displayName {
      lines.append("Display Name: \(displayName)")
    }

    if let expirationDate = certificate.attributes?.expirationDate {
      let dateFormatter = DateFormatter()
      dateFormatter.dateStyle = .long
      dateFormatter.timeStyle = .none
      lines.append("Expiration Date: \(dateFormatter.string(from: expirationDate))")
    }

    if let serialNumber = certificate.attributes?.serialNumber {
      lines.append("Serial Number: \(serialNumber)")
    }

    if let platform = certificate.attributes?.platform {
      lines.append("Platform: \(platform.rawValue)")
    }

    lines.append("")
    lines.append("Use 'download_certificate' to download the .cer file")

    return CallTool.Result(
      content: [
        .text(lines.joined(separator: "\n"))
      ]
    )
  }
}
