# App Store Connect MCP Server - Project Summary

## Overview

Successfully built a complete Model Context Protocol (MCP) server for App Store Connect API integration using Swift 6.0 and the official MCP Swift SDK.

## Project Structure

```
appstoreconnect-mcp/
├── Package.swift               # Swift Package Manager manifest
├── Sources/
│   └── appstoreconnect-mcp/
│       ├── App.swift           # Main entry point with @main
│       ├── MCPServer.swift     # MCP server actor implementation
│       ├── AppStoreConnectClient.swift  # ASC API client wrapper
│       └── Tools/              # Tool handlers
│           ├── ListApps.swift
│           ├── GetAppStatus.swift
│           ├── ListBuilds.swift
│           ├── DownloadDSYMs.swift
│           └── GetLatestBuild.swift
├── Tests/
│   └── appstoreconnect-mcp-tests/
│       └── AppStoreConnectMCPTests.swift
├── README.md                   # Comprehensive documentation
├── install.sh                  # Automated installation script
├── LICENSE                     # MIT License
└── .gitignore                  # Git ignore rules

```

## Key Technologies

- **Swift 6.0**: Latest Swift version with full concurrency support
- **MCP Swift SDK 0.10.2**: Official Model Context Protocol SDK
- **asc-swift 1.4.1**: App Store Connect API client library
- **ArgumentParser**: Command-line interface
- **swift-log**: Structured logging to stderr
- **StdioTransport**: Standard input/output transport for MCP

## Architecture

### Actor-Based Design
- `MCPServer`: Main server actor handling MCP protocol
- `AppStoreConnectClientWrapper`: Thread-safe wrapper around ASC API client
- All tool handlers implemented as enums with static methods for simplicity

### MCP Tools Implemented

1. **list_apps**: List all apps with optional bundle ID filtering
2. **get_app_status**: Get detailed app information by ID or bundle ID
3. **list_builds**: List builds for an app with optional version filtering
4. **download_dsyms**: Download dSYM files for crash symbolication
5. **get_latest_build**: Get the most recent build for an app

### Error Handling

- Proper use of `MCPError` for protocol-level errors
- Custom `ASCError` type for App Store Connect specific errors
- Comprehensive error mapping for HTTP errors (401, 403, 404, 429)
- Graceful error messages for missing parameters and invalid inputs

## Authentication

Uses JWT-based authentication with App Store Connect API:
- Key ID (`ASC_KEY_ID`)
- Issuer ID (`ASC_ISSUER_ID`)
- Private Key Path (`ASC_PRIVATE_KEY_PATH`)
- Key Expiry (`ASC_KEY_EXPIRY`, optional, default 1200 seconds)

## Installation

```bash
# Build and install
./install.sh

# Or manually
swift build -c release
swift package experimental-install
```

## Configuration

Add to Claude Desktop config (`~/Library/Application Support/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "appstoreconnect": {
      "command": "appstoreconnect-mcp",
      "args": ["--log-level", "info"],
      "env": {
        "PATH": "$HOME/.swiftpm/bin:/usr/local/bin:/usr/bin:/bin",
        "ASC_KEY_ID": "YOUR_KEY_ID",
        "ASC_ISSUER_ID": "YOUR_ISSUER_ID",
        "ASC_PRIVATE_KEY_PATH": "/path/to/AuthKey_XXXXXXXXXX.p8"
      }
    }
  }
}
```

## Build Notes

### Swift 6 Concurrency
- All code follows Swift 6.0 strict concurrency model
- Actors used for thread safety
- Sendable conformance throughout

### MCP Protocol
- Uses StdioTransport for communication
- JSON-RPC 2.0 over stdio with newline delimiters
- Proper tool schema definitions using Value dictionaries

### Dependencies
- MCP SDK version 0.10.2
- asc-swift version 1.4.1
- ArgumentParser for CLI parsing
- swift-log for structured logging

## Challenges Solved

1. **@main Attribute Issue**: Swift 6 requires no top-level code when using @main. Resolved by creating separate App.swift file and removing main.swift.

2. **Name Conflicts**: Initial `App` struct conflicted with AppStoreAPI's `App` type. Renamed to `AppStoreConnectCommand`.

3. **MCP API Changes**: Adapted to MCP SDK's actual API:
   - `Server.start(transport:)` instead of `run()`
   - `CallTool.Parameters` instead of `CallTool.Request`
   - `Tool.Content.text(String)` instead of `.text(.init(text:))`
   - Value dictionaries for inputSchema instead of custom DSL

4. **Build API Differences**: App Store Connect API uses `version` and `isExpired` instead of `buildNumber` and `expired`.

5. **Parameter Ordering**: ASC API requires specific parameter order (e.g., `filterVersion` before `filterApp`).

## Testing

```bash
# Run tests
swift test

# Build
swift build

# Run with debug logging
swift run appstoreconnect-mcp --log-level debug
```

## File Paths

All file paths mentioned in this document use absolute paths:

- Project: `/Users/stijnwillems/Developer/asc-mcp`
- Installation: `~/.swiftpm/bin/appstoreconnect-mcp`
- Config: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Logs: `~/Library/Logs/Claude/mcp-server-appstoreconnect-mcp.log`

## dSYM Download Implementation

**API Limitation**: The App Store Connect API does not provide a direct endpoint to download dSYM files. This is a known limitation documented by Apple.

**Current Implementation**:
- Verifies build exists and has valid processing state
- Creates an information file with alternative download methods
- Provides ready-to-use Fastlane commands with the app's bundle ID
- Includes comprehensive instructions for manual and automated downloads

**Alternative Methods Provided**:
1. Xcode Organizer (manual download)
2. App Store Connect web portal
3. Fastlane automation (recommended for CI/CD)
4. Xcode archive export

## Next Steps

1. Test with real App Store Connect credentials
2. Add more tools as needed (version management, review submissions, etc.)
3. Add comprehensive integration tests
4. Consider adding pagination support for large result sets
5. Add caching for frequently accessed data

## License

MIT License - See LICENSE file for details
