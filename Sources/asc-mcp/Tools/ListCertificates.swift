import AppStoreAPI
import AppStoreConnect
import Foundation
import Logging
import MCP

enum ListCertificatesHandler {
  static func handle(
    arguments: [String: Value],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    // Extract optional certificate type filter
    let certificateTypeString = arguments["certificate_type"]?.stringValue

    // Parse certificate type if provided
    var certificateType: CertificateType?
    if let typeString = certificateTypeString {
      guard let parsed = CertificateType(rawValue: typeString) else {
        throw ASCError.invalidCertificateType(typeString)
      }
      certificateType = parsed
    }

    logger.debug(
      "Listing certificates", metadata: ["certificateType": "\(certificateTypeString ?? "all")"])

    // Fetch certificates
    let certificates = try await client.listCertificates(certificateTypeFilter: certificateType)

    // Format response
    var lines: [String] = []
    lines.append("Found \(certificates.count) certificate(s)")
    lines.append("")

    if !certificates.isEmpty {
      lines.append(String(repeating: "-", count: 100))
      lines.append(
        String(
          format: "%-30s %-25s %-20s %-15s %s",
          "NAME", "TYPE", "EXPIRES", "STATUS", "ID"
        )
      )
      lines.append(String(repeating: "-", count: 100))

      for cert in certificates {
        let name = cert.attributes?.displayName ?? cert.attributes?.name ?? "Unknown"
        let type = cert.attributes?.certificateType?.rawValue ?? "Unknown"
        let expirationDate = cert.attributes?.expirationDate
        let isActivated = cert.attributes?.isActivated ?? false

        // Format expiration date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        let expiresStr = expirationDate.map { dateFormatter.string(from: $0) } ?? "N/A"

        // Determine status
        let status: String
        if !isActivated {
          status = "INACTIVE"
        } else if let expDate = expirationDate, expDate < Date() {
          status = "EXPIRED"
        } else {
          status = "ACTIVE"
        }

        lines.append(
          String(
            format: "%-30s %-25s %-20s %-15s %s",
            String(name.prefix(28)),
            String(type.prefix(23)),
            String(expiresStr.prefix(18)),
            status,
            cert.id
          )
        )
      }

      lines.append(String(repeating: "-", count: 100))
    }

    return CallTool.Result(
      content: [
        .text(lines.joined(separator: "\n"))
      ]
    )
  }
}
