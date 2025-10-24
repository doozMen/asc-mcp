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
        
        logger.debug("Downloading dSYMs", metadata: [
            "buildID": "\(buildID)",
            "outputPath": "\(outputPath)"
        ])
        
        // Download dSYMs
        let dSymURL = try await client.downloadDSYMs(buildID: buildID, outputPath: outputPath)
        
        // Format response
        var lines: [String] = []
        lines.append("dSYM Download")
        lines.append("=============")
        lines.append("")
        lines.append("Build ID: \(buildID)")
        lines.append("Output Path: \(dSymURL.path)")
        lines.append("")
        lines.append("Note: dSYM download prepared. The actual download from App Store Connect")
        lines.append("may require additional API calls depending on the build's dSYM availability.")
        
        return CallTool.Result(
            content: [
                .text(lines.joined(separator: "\n"))
            ]
        )
    }
}
