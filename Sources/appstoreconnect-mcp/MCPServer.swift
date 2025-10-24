import AppStoreConnect
import Foundation
import Logging
import MCP

actor MCPServer {
    private let server: Server
    private let logger: Logger
    private let ascClient: AppStoreConnectClientWrapper
    
    init(keyID: String, issuerID: String, privateKeyPath: String, keyExpiry: Int) {
        self.logger = Logger(label: "mcp-server")
        
        do {
            self.ascClient = try AppStoreConnectClientWrapper(
                keyID: keyID,
                issuerID: issuerID,
                privateKeyPath: privateKeyPath,
                keyExpiry: keyExpiry
            )
        } catch {
            logger.critical("Failed to initialize App Store Connect client", metadata: ["error": "\(error)"])
            fatalError("Failed to initialize App Store Connect client: \(error)")
        }
        
        self.server = Server(
            name: "appstoreconnect-mcp",
            version: "1.0.0",
            capabilities: .init(
                prompts: nil,
                resources: nil,
                tools: .init(listChanged: false)
            )
        )
    }
    
    func run() async throws {
        // Register tool handlers
        await server.withMethodHandler(ListTools.self) { _ in
            await ListTools.Result(tools: self.getTools())
        }

        await server.withMethodHandler(CallTool.self) { request in
            try await self.handleToolCall(request)
        }

        logger.info("MCP server starting with stdio transport")

        // Create and start stdio transport
        let transport = StdioTransport()
        try await server.start(transport: transport)

        // Wait for server to complete
        await server.waitUntilCompleted()
    }
    
    private func getTools() -> [Tool] {
        [
            Tool(
                name: "list_apps",
                description: "List all apps in App Store Connect. Optionally filter by bundle ID.",
                inputSchema: .object([
                    "type": "object",
                    "properties": .object([
                        "bundle_id_filter": .object([
                            "type": "string",
                            "description": "Optional bundle ID filter (e.g., 'com.example.app')"
                        ])
                    ])
                ])
            ),
            Tool(
                name: "get_app_status",
                description: "Get detailed status of an app by app ID or bundle ID. Returns app state, version info, and metadata.",
                inputSchema: .object([
                    "type": "object",
                    "properties": .object([
                        "app_id": .object([
                            "type": "string",
                            "description": "App Store Connect app ID"
                        ]),
                        "bundle_id": .object([
                            "type": "string",
                            "description": "App bundle ID (e.g., 'com.example.app')"
                        ])
                    ])
                ])
            ),
            Tool(
                name: "list_builds",
                description: "List builds for a specific app. Optionally filter by version number.",
                inputSchema: .object([
                    "type": "object",
                    "properties": .object([
                        "app_id": .object([
                            "type": "string",
                            "description": "App Store Connect app ID"
                        ]),
                        "version_filter": .object([
                            "type": "string",
                            "description": "Optional version filter (e.g., '1.0.0')"
                        ])
                    ]),
                    "required": .array(["app_id"])
                ])
            ),
            Tool(
                name: "download_dsyms",
                description: "Download dSYM files for a specific build to the specified output path.",
                inputSchema: .object([
                    "type": "object",
                    "properties": .object([
                        "build_id": .object([
                            "type": "string",
                            "description": "Build ID from App Store Connect"
                        ]),
                        "output_path": .object([
                            "type": "string",
                            "description": "Local file path where dSYMs should be downloaded"
                        ])
                    ]),
                    "required": .array(["build_id", "output_path"])
                ])
            ),
            Tool(
                name: "get_latest_build",
                description: "Get the most recent build for a specific app.",
                inputSchema: .object([
                    "type": "object",
                    "properties": .object([
                        "app_id": .object([
                            "type": "string",
                            "description": "App Store Connect app ID"
                        ])
                    ]),
                    "required": .array(["app_id"])
                ])
            )
        ]
    }
    
    private func handleToolCall(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        logger.debug("Handling tool call", metadata: ["tool": "\(params.name)"])

        switch params.name {
        case "list_apps":
            return try await ListAppsHandler.handle(
                arguments: params.arguments ?? [:],
                client: ascClient,
                logger: logger
            )

        case "get_app_status":
            return try await GetAppStatusHandler.handle(
                arguments: params.arguments ?? [:],
                client: ascClient,
                logger: logger
            )

        case "list_builds":
            return try await ListBuildsHandler.handle(
                arguments: params.arguments ?? [:],
                client: ascClient,
                logger: logger
            )

        case "download_dsyms":
            return try await DownloadDSYMsHandler.handle(
                arguments: params.arguments ?? [:],
                client: ascClient,
                logger: logger
            )

        case "get_latest_build":
            return try await GetLatestBuildHandler.handle(
                arguments: params.arguments ?? [:],
                client: ascClient,
                logger: logger
            )

        default:
            throw MCPError.invalidRequest("Unknown tool: \(params.name)")
        }
    }
}
