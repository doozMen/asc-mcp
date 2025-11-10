import AppStoreAPI
import Foundation

enum FormatHelpers {
  nonisolated(unsafe) static let dateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    return formatter
  }()

  static func formatDate(_ date: Date) -> String {
    dateFormatter.string(from: date)
  }

  static func formatBuildInfo(_ build: Build) -> [String] {
    var lines: [String] = []

    let version = build.attributes?.version ?? "Unknown"
    let processingState = build.attributes?.processingState?.rawValue ?? "Unknown"

    lines.append("Version: \(version)")
    lines.append("ID: \(build.id)")
    lines.append("Processing State: \(processingState)")

    if let uploadedDate = build.attributes?.uploadedDate {
      lines.append("Uploaded: \(formatDate(uploadedDate))")
    }

    if let expirationDate = build.attributes?.expirationDate {
      lines.append("Expires: \(formatDate(expirationDate))")
    }

    if let isExpired = build.attributes?.isExpired {
      lines.append("Expired: \(isExpired ? "Yes" : "No")")
    }

    return lines
  }
}
