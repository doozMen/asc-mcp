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
        
        logger.debug("Preparing dSYM download information", metadata: [
            "buildID": "\(buildID)",
            "outputPath": "\(outputPath)"
        ])

        // Get dSYM download information
        let infoFileURL = try await client.downloadDSYMs(buildID: buildID, outputPath: outputPath)

        // Read the information file content
        let infoContent = try String(contentsOf: infoFileURL, encoding: .utf8)

        // Format response with clear indication of API limitation
        var lines: [String] = []
        lines.append("dSYM Download Information")
        lines.append("=========================")
        lines.append("")
        lines.append("IMPORTANT: The App Store Connect API does not provide direct dSYM downloads.")
        lines.append("A detailed information file has been created with alternative methods.")
        lines.append("")
        lines.append("Information File: \(infoFileURL.path)")
        lines.append("")
        lines.append("--- File Content ---")
        lines.append(infoContent)
        lines.append("")
        lines.append("--- Summary ---")
        lines.append("Alternative methods available:")
        lines.append("  1. Xcode Organizer (manual download)")
        lines.append("  2. App Store Connect web portal")
        lines.append("  3. Fastlane automation (recommended for CI/CD)")
        lines.append("  4. Xcode archive export")
        lines.append("")
        lines.append("For automation, consider using Fastlane's download_dsyms action.")

        return CallTool.Result(
            content: [
                .text(lines.joined(separator: "\n"))
            ]
        )
    }
}
