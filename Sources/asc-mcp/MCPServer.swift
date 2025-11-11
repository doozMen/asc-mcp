import AppStoreConnect
import Foundation
import Logging
import MCP

actor MCPServer {
  private let server: Server
  private let logger: Logger
  private let ascClient: AppStoreConnectClientWrapper

  init(keyID: String, issuerID: String, privateKeyPath: String, keyExpiry: Int) async throws {
    self.logger = Logger(label: "mcp-server")

    self.ascClient = try AppStoreConnectClientWrapper(
      keyID: keyID,
      issuerID: issuerID,
      privateKeyPath: privateKeyPath,
      keyExpiry: keyExpiry
    )

    self.server = Server(
      name: "appstoreconnect-mcp",
      version: "0.0.1-alpha.3",
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
              "description": "Optional bundle ID filter (e.g., 'com.example.app')",
            ])
          ]),
        ])
      ),
      Tool(
        name: "get_app_status",
        description:
          "Get detailed status of an app by app ID or bundle ID. Returns app state, version info, and metadata.",
        inputSchema: .object([
          "type": "object",
          "properties": .object([
            "app_id": .object([
              "type": "string",
              "description": "App Store Connect app ID",
            ]),
            "bundle_id": .object([
              "type": "string",
              "description": "App bundle ID (e.g., 'com.example.app')",
            ]),
          ]),
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
              "description": "App Store Connect app ID",
            ]),
            "version_filter": .object([
              "type": "string",
              "description": "Optional version filter (e.g., '1.0.0')",
            ]),
          ]),
          "required": .array(["app_id"]),
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
              "description": "Build ID from App Store Connect",
            ]),
            "output_path": .object([
              "type": "string",
              "description": "Local file path where dSYMs should be downloaded",
            ]),
          ]),
          "required": .array(["build_id", "output_path"]),
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
              "description": "App Store Connect app ID",
            ])
          ]),
          "required": .array(["app_id"]),
        ])
      ),
      Tool(
        name: "upload_dsyms_to_firebase",
        description:
          "Upload dSYM files to Firebase Crashlytics. Can download from App Store Connect or use local files. Uses Firebase CLI (no CocoaPods dependency).",
        inputSchema: .object([
          "type": "object",
          "properties": .object([
            "firebase_app_id": .object([
              "type": "string",
              "description": "Firebase app ID (e.g., '1:123456789:ios:abc123def456')",
            ]),
            "build_id": .object([
              "type": "string",
              "description": "App Store Connect build ID (downloads dSYMs first)",
            ]),
            "archive_path": .object([
              "type": "string",
              "description": "Path to .xcarchive directory (uses archive/dSYMs)",
            ]),
            "dsyms_path": .object([
              "type": "string",
              "description": "Direct path to dSYMs directory",
            ]),
          ]),
          "required": .array(["firebase_app_id"]),
        ])
      ),
      Tool(
        name: "find_xcode_archives",
        description:
          "Find Xcode archives in ~/Library/Developer/Xcode/Archives. Filter by app name or bundle ID, or get latest only.",
        inputSchema: .object([
          "type": "object",
          "properties": .object([
            "app_name_filter": .object([
              "type": "string",
              "description": "Filter by app name (case-insensitive, partial match)",
            ]),
            "bundle_id_filter": .object([
              "type": "string",
              "description": "Filter by bundle ID (case-insensitive, partial match)",
            ]),
            "latest_only": .object([
              "type": "boolean",
              "description": "Return only the latest archive (default: false)",
            ]),
          ]),
        ])
      ),
      Tool(
        name: "list_firebase_projects",
        description:
          "List all Firebase projects you have access to. Shows project names, IDs, numbers, and resource locations.",
        inputSchema: .object([
          "type": "object",
          "properties": .object([:]),
        ])
      ),
      Tool(
        name: "get_firebase_project",
        description:
          "Get detailed information about a specific Firebase project, including resources and configuration.",
        inputSchema: .object([
          "type": "object",
          "properties": .object([
            "project_id": .object([
              "type": "string",
              "description": "Firebase project ID (e.g., 'myapp-ios-123abc')",
            ])
          ]),
          "required": .array(["project_id"]),
        ])
      ),
      Tool(
        name: "list_firebase_apps",
        description:
          "List all apps (iOS, Android, Web) in a Firebase project. Optionally filter by platform.",
        inputSchema: .object([
          "type": "object",
          "properties": .object([
            "project_id": .object([
              "type": "string",
              "description": "Firebase project ID",
            ]),
            "platform": .object([
              "type": "string",
              "description": "Optional platform filter: 'ios', 'android', or 'web'",
              "enum": .array(["ios", "android", "web"]),
            ]),
          ]),
          "required": .array(["project_id"]),
        ])
      ),
      Tool(
        name: "upload_build",
        description:
          "Upload an IPA file to App Store Connect using xcrun iTMSTransporter. Requires ASC_KEY_ID and ASC_ISSUER_ID environment variables.",
        inputSchema: .object([
          "type": "object",
          "properties": .object([
            "ipa_path": .object([
              "type": "string",
              "description": "Absolute path to the .ipa file to upload",
            ]),
            "platform": .object([
              "type": "string",
              "description": "Platform type (default: ios)",
              "enum": .array(["ios", "appletvos", "osx"]),
            ]),
          ]),
          "required": .array(["ipa_path"]),
        ])
      ),
      Tool(
        name: "validate_build",
        description:
          "Validate an IPA file before uploading to App Store Connect. Checks for common issues and signing problems.",
        inputSchema: .object([
          "type": "object",
          "properties": .object([
            "ipa_path": .object([
              "type": "string",
              "description": "Absolute path to the .ipa file to validate",
            ])
          ]),
          "required": .array(["ipa_path"]),
        ])
      ),
      Tool(
        name: "get_upload_status",
        description:
          "Check the upload and processing status of builds for an app. Shows the latest build and recent upload history.",
        inputSchema: .object([
          "type": "object",
          "properties": .object([
            "app_id": .object([
              "type": "string",
              "description": "App Store Connect app ID",
            ])
          ]),
          "required": .array(["app_id"]),
        ])
      ),
      Tool(
        name: "list_certificates",
        description:
          "List all certificates in App Store Connect. Optionally filter by certificate type.",
        inputSchema: .object([
          "type": "object",
          "properties": .object([
            "certificate_type": .object([
              "type": "string",
              "description":
                "Optional certificate type filter (e.g., 'IOS_DEVELOPMENT', 'IOS_DISTRIBUTION', 'DEVELOPER_ID_APPLICATION')",
              "enum": .array([
                "IOS_DEVELOPMENT",
                "IOS_DISTRIBUTION",
                "MAC_APP_DEVELOPMENT",
                "MAC_APP_DISTRIBUTION",
                "MAC_INSTALLER_DISTRIBUTION",
                "DEVELOPER_ID_APPLICATION",
                "DEVELOPER_ID_APPLICATION_G2",
                "DEVELOPER_ID_KEXT",
                "DEVELOPER_ID_KEXT_G2",
                "DEVELOPMENT",
                "DISTRIBUTION",
                "PASS_TYPE_ID",
                "PASS_TYPE_ID_WITH_NFC",
                "APPLE_PAY",
                "APPLE_PAY_MERCHANT_IDENTITY",
                "APPLE_PAY_PSP_IDENTITY",
                "APPLE_PAY_RSA",
                "IDENTITY_ACCESS",
              ]),
            ])
          ]),
        ])
      ),
      Tool(
        name: "create_certificate",
        description:
          "Create a new certificate in App Store Connect using a Certificate Signing Request (CSR).",
        inputSchema: .object([
          "type": "object",
          "properties": .object([
            "certificate_type": .object([
              "type": "string",
              "description": "Type of certificate to create",
              "enum": .array([
                "IOS_DEVELOPMENT",
                "IOS_DISTRIBUTION",
                "MAC_APP_DEVELOPMENT",
                "MAC_APP_DISTRIBUTION",
                "MAC_INSTALLER_DISTRIBUTION",
                "DEVELOPER_ID_APPLICATION",
                "DEVELOPER_ID_APPLICATION_G2",
                "DEVELOPER_ID_KEXT",
                "DEVELOPER_ID_KEXT_G2",
                "DEVELOPMENT",
                "DISTRIBUTION",
                "PASS_TYPE_ID",
                "PASS_TYPE_ID_WITH_NFC",
                "APPLE_PAY",
                "APPLE_PAY_MERCHANT_IDENTITY",
                "APPLE_PAY_PSP_IDENTITY",
                "APPLE_PAY_RSA",
                "IDENTITY_ACCESS",
              ]),
            ]),
            "csr_content": .object([
              "type": "string",
              "description": "Base64-encoded CSR content",
            ]),
          ]),
          "required": .array(["certificate_type", "csr_content"]),
        ])
      ),
      Tool(
        name: "revoke_certificate",
        description:
          "Revoke a certificate by ID. This permanently disables the certificate and it cannot be used for code signing.",
        inputSchema: .object([
          "type": "object",
          "properties": .object([
            "certificate_id": .object([
              "type": "string",
              "description": "Certificate ID to revoke",
            ])
          ]),
          "required": .array(["certificate_id"]),
        ])
      ),
      Tool(
        name: "download_certificate",
        description:
          "Download a certificate as a .cer file to the specified output path.",
        inputSchema: .object([
          "type": "object",
          "properties": .object([
            "certificate_id": .object([
              "type": "string",
              "description": "Certificate ID to download",
            ]),
            "output_path": .object([
              "type": "string",
              "description": "Local file path where the .cer file should be saved",
            ]),
          ]),
          "required": .array(["certificate_id", "output_path"]),
        ])
      ),
      Tool(
        name: "list_bundle_ids",
        description:
          "List all bundle IDs in App Store Connect. Optionally filter by platform or identifier.",
        inputSchema: .object([
          "type": "object",
          "properties": .object([
            "platform": .object([
              "type": "string",
              "description": "Optional platform filter",
              "enum": .array(["IOS", "MAC_OS", "UNIVERSAL"]),
            ]),
            "identifier_filter": .object([
              "type": "string",
              "description": "Optional partial match filter for bundle ID (e.g., 'com.example')",
            ]),
          ]),
        ])
      ),
      Tool(
        name: "register_bundle_id",
        description:
          "Register a new bundle ID in App Store Connect. Bundle ID must be in reverse domain notation.",
        inputSchema: .object([
          "type": "object",
          "properties": .object([
            "identifier": .object([
              "type": "string",
              "description": "Bundle ID in reverse domain notation (e.g., 'com.example.app')",
            ]),
            "name": .object([
              "type": "string",
              "description": "Display name for the bundle ID",
            ]),
            "platform": .object([
              "type": "string",
              "description": "Platform for the bundle ID",
              "enum": .array(["IOS", "MAC_OS", "UNIVERSAL"]),
            ]),
          ]),
          "required": .array(["identifier", "name", "platform"]),
        ])
      ),
      Tool(
        name: "get_bundle_id",
        description:
          "Get detailed information about a bundle ID including all enabled capabilities. Can use bundle ID or identifier.",
        inputSchema: .object([
          "type": "object",
          "properties": .object([
            "bundle_id": .object([
              "type": "string",
              "description":
                "Bundle ID (App Store Connect ID) or bundle identifier (e.g., 'com.example.app')",
            ])
          ]),
          "required": .array(["bundle_id"]),
        ])
      ),
      Tool(
        name: "update_bundle_id_capabilities",
        description:
          "Enable capabilities for a bundle ID. Capabilities already enabled will be skipped.",
        inputSchema: .object([
          "type": "object",
          "properties": .object([
            "bundle_id": .object([
              "type": "string",
              "description":
                "Bundle ID (App Store Connect ID) or bundle identifier (e.g., 'com.example.app')",
            ]),
            "capabilities": .object([
              "type": "array",
              "description":
                "Array of capability types to enable (e.g., ['PUSH_NOTIFICATIONS', 'ICLOUD'])",
              "items": .object([
                "type": "string",
                "enum": .array([
                  "ICLOUD",
                  "IN_APP_PURCHASE",
                  "GAME_CENTER",
                  "PUSH_NOTIFICATIONS",
                  "WALLET",
                  "INTER_APP_AUDIO",
                  "MAPS",
                  "ASSOCIATED_DOMAINS",
                  "PERSONAL_VPN",
                  "APP_GROUPS",
                  "HEALTHKIT",
                  "HOMEKIT",
                  "WIRELESS_ACCESSORY_CONFIGURATION",
                  "APPLE_PAY",
                  "DATA_PROTECTION",
                  "SIRIKIT",
                  "NETWORK_EXTENSIONS",
                  "MULTIPATH",
                  "HOT_SPOT",
                  "NFC_TAG_READING",
                  "CLASSKIT",
                  "AUTOFILL_CREDENTIAL_PROVIDER",
                  "ACCESS_WIFI_INFORMATION",
                  "NETWORK_CUSTOM_PROTOCOL",
                  "COREMEDIA_HLS_LOW_LATENCY",
                  "SYSTEM_EXTENSION_INSTALL",
                  "USER_MANAGEMENT",
                  "APPLE_ID_AUTH",
                ]),
              ]),
            ]),
          ]),
          "required": .array(["bundle_id", "capabilities"]),
        ])
      ),
      Tool(
        name: "list_profiles",
        description:
          "List all provisioning profiles in App Store Connect. Optionally filter by profile type or bundle ID.",
        inputSchema: .object([
          "type": "object",
          "properties": .object([
            "profile_type": .object([
              "type": "string",
              "description": "Optional profile type filter",
              "enum": .array([
                "IOS_APP_DEVELOPMENT",
                "IOS_APP_STORE",
                "IOS_APP_ADHOC",
                "IOS_APP_INHOUSE",
                "MAC_APP_DEVELOPMENT",
                "MAC_APP_STORE",
                "MAC_APP_DIRECT",
                "TVOS_APP_DEVELOPMENT",
                "TVOS_APP_STORE",
                "TVOS_APP_ADHOC",
              ]),
            ]),
            "bundle_id_filter": .object([
              "type": "string",
              "description": "Optional partial match filter for bundle ID (e.g., 'com.example')",
            ]),
          ]),
        ])
      ),
      Tool(
        name: "create_profile",
        description:
          "Create a new provisioning profile. Development and Ad Hoc profiles require device_ids. App Store profiles do not.",
        inputSchema: .object([
          "type": "object",
          "properties": .object([
            "name": .object([
              "type": "string",
              "description": "Name for the provisioning profile",
            ]),
            "profile_type": .object([
              "type": "string",
              "description": "Type of provisioning profile to create",
              "enum": .array([
                "IOS_APP_DEVELOPMENT",
                "IOS_APP_STORE",
                "IOS_APP_ADHOC",
                "IOS_APP_INHOUSE",
                "MAC_APP_DEVELOPMENT",
                "MAC_APP_STORE",
                "MAC_APP_DIRECT",
                "TVOS_APP_DEVELOPMENT",
                "TVOS_APP_STORE",
                "TVOS_APP_ADHOC",
              ]),
            ]),
            "bundle_id": .object([
              "type": "string",
              "description":
                "Bundle ID (App Store Connect ID) to associate with this profile",
            ]),
            "certificate_ids": .object([
              "type": "array",
              "description": "Array of certificate IDs to include in the profile",
              "items": .object([
                "type": "string"
              ]),
            ]),
            "device_ids": .object([
              "type": "array",
              "description":
                "Array of device IDs (required for development and ad hoc profiles, not used for app store profiles)",
              "items": .object([
                "type": "string"
              ]),
            ]),
          ]),
          "required": .array(["name", "profile_type", "bundle_id", "certificate_ids"]),
        ])
      ),
      Tool(
        name: "delete_profile",
        description:
          "Delete a provisioning profile by ID. This action cannot be undone.",
        inputSchema: .object([
          "type": "object",
          "properties": .object([
            "profile_id": .object([
              "type": "string",
              "description": "Profile ID to delete",
            ])
          ]),
          "required": .array(["profile_id"]),
        ])
      ),
      Tool(
        name: "download_profile",
        description:
          "Download a provisioning profile as a .mobileprovision file. The file can be double-clicked to install in Xcode.",
        inputSchema: .object([
          "type": "object",
          "properties": .object([
            "profile_id": .object([
              "type": "string",
              "description": "Profile ID to download",
            ]),
            "output_path": .object([
              "type": "string",
              "description": "Local file path where the .mobileprovision file should be saved",
            ]),
          ]),
          "required": .array(["profile_id", "output_path"]),
        ])
      ),
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

    case "upload_dsyms_to_firebase":
      return try await UploadDSYMsToFirebaseHandler.handle(
        arguments: params.arguments ?? [:],
        client: ascClient,
        logger: logger
      )

    case "find_xcode_archives":
      return try await FindXcodeArchivesHandler.handle(
        arguments: params.arguments ?? [:],
        client: ascClient,
        logger: logger
      )

    case "list_firebase_projects":
      return try await ListFirebaseProjectsHandler.handle(
        arguments: params.arguments ?? [:],
        client: ascClient,
        logger: logger
      )

    case "get_firebase_project":
      return try await GetFirebaseProjectHandler.handle(
        arguments: params.arguments ?? [:],
        client: ascClient,
        logger: logger
      )

    case "list_firebase_apps":
      return try await ListFirebaseAppsHandler.handle(
        arguments: params.arguments ?? [:],
        client: ascClient,
        logger: logger
      )

    case "upload_build":
      return try await UploadBuildHandler.handle(
        arguments: params.arguments ?? [:],
        client: ascClient,
        logger: logger
      )

    case "validate_build":
      return try await ValidateBuildHandler.handle(
        arguments: params.arguments ?? [:],
        client: ascClient,
        logger: logger
      )

    case "get_upload_status":
      return try await GetUploadStatusHandler.handle(
        arguments: params.arguments ?? [:],
        client: ascClient,
        logger: logger
      )

    case "list_certificates":
      return try await ListCertificatesHandler.handle(
        arguments: params.arguments ?? [:],
        client: ascClient,
        logger: logger
      )

    case "create_certificate":
      return try await CreateCertificateHandler.handle(
        arguments: params.arguments ?? [:],
        client: ascClient,
        logger: logger
      )

    case "revoke_certificate":
      return try await RevokeCertificateHandler.handle(
        arguments: params.arguments ?? [:],
        client: ascClient,
        logger: logger
      )

    case "download_certificate":
      return try await DownloadCertificateHandler.handle(
        arguments: params.arguments ?? [:],
        client: ascClient,
        logger: logger
      )

    case "list_bundle_ids":
      return try await ListBundleIdsHandler.handle(
        arguments: params.arguments ?? [:],
        client: ascClient,
        logger: logger
      )

    case "register_bundle_id":
      return try await RegisterBundleIdHandler.handle(
        arguments: params.arguments ?? [:],
        client: ascClient,
        logger: logger
      )

    case "get_bundle_id":
      return try await GetBundleIdHandler.handle(
        arguments: params.arguments ?? [:],
        client: ascClient,
        logger: logger
      )

    case "update_bundle_id_capabilities":
      return try await UpdateBundleIdCapabilitiesHandler.handle(
        arguments: params.arguments ?? [:],
        client: ascClient,
        logger: logger
      )

    case "list_profiles":
      return try await ListProfilesHandler.handle(
        arguments: params.arguments ?? [:],
        client: ascClient,
        logger: logger
      )

    case "create_profile":
      return try await CreateProfileHandler.handle(
        arguments: params.arguments ?? [:],
        client: ascClient,
        logger: logger
      )

    case "delete_profile":
      return try await DeleteProfileHandler.handle(
        arguments: params.arguments ?? [:],
        client: ascClient,
        logger: logger
      )

    case "download_profile":
      return try await DownloadProfileHandler.handle(
        arguments: params.arguments ?? [:],
        client: ascClient,
        logger: logger
      )

    default:
      throw MCPError.invalidRequest("Unknown tool: \(params.name)")
    }
  }
}
