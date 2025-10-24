import AppStoreAPI
import AppStoreConnect
import Foundation
import Logging
import MCP

enum GetLatestBuildHandler {
    static func handle(
        arguments: [String: Value],
        client: AppStoreConnectClientWrapper,
        logger: Logger
    ) async throws -> CallTool.Result {
        // Extract required app ID
        guard let appID = arguments["app_id"]?.stringValue else {
            throw MCPError.invalidParams("Missing required parameter: app_id")
        }
        
        logger.debug("Getting latest build", metadata: ["appID": "\(appID)"])
        
        // Get latest build
        let build = try await client.getLatestBuild(appID: appID)
        
        // Format response
        var lines: [String] = []
        lines.append("Latest Build")
        lines.append("============")
        lines.append("")
        
        let version = build.attributes?.version ?? "Unknown"
        let processingState = build.attributes?.processingState?.rawValue ?? "Unknown"

        lines.append("Version: \(version)")
        lines.append("ID: \(build.id)")
        lines.append("Processing State: \(processingState)")

        if let uploadedDate = build.attributes?.uploadedDate {
            let formatter = ISO8601DateFormatter()
            lines.append("Uploaded: \(formatter.string(from: uploadedDate))")
        }

        if let expirationDate = build.attributes?.expirationDate {
            let formatter = ISO8601DateFormatter()
            lines.append("Expires: \(formatter.string(from: expirationDate))")
        }

        if let isExpired = build.attributes?.isExpired {
            lines.append("Expired: \(isExpired ? "Yes" : "No")")
        }

        if let minOsVersion = build.attributes?.minOsVersion {
            lines.append("Min OS Version: \(minOsVersion)")
        }

        if let usesNonExemptEncryption = build.attributes?.usesNonExemptEncryption {
            lines.append("Uses Non-Exempt Encryption: \(usesNonExemptEncryption ? "Yes" : "No")")
        }

        return CallTool.Result(
            content: [
                .text(lines.joined(separator: "\n"))
            ]
        )
    }
}
