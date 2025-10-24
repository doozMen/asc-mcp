# App Store Connect MCP Server

MCP server for App Store Connect API integration. Provides tools to query apps, builds, and download dSYM files through the Model Context Protocol.

## Features

### App Store Connect Tools
- **list_apps**: List all apps with optional bundle ID filtering
- **get_app_status**: Get detailed app information and status
- **list_builds**: List builds for an app with optional version filtering
- **download_dsyms**: Download dSYM files for crash symbolication
- **get_latest_build**: Get the most recent build for an app

### Firebase Crashlytics Tools
- **upload_dsyms_to_firebase**: Upload dSYMs to Firebase Crashlytics (supports ASC download, local archive, or direct path)
- **find_xcode_archives**: Search local Xcode archives by app name or bundle ID

### Technical Features
- Pure Swift implementation (no Ruby, no Fastlane, no CocoaPods)
- JWT authentication with App Store Connect API
- Firebase CLI integration for crash symbol uploads
- Comprehensive error handling for API errors (401, 403, 404, 429)
- Actor-based architecture for thread safety

## Prerequisites

- macOS 13.0+
- Swift 6.0+
- App Store Connect API credentials (Key ID, Issuer ID, Private Key)

## Installation

### Quick Install

Use the provided installation script:

```bash
./install.sh
```

This script will:
- Build the project in release mode
- Remove any existing installation
- Install to `~/.swiftpm/bin`
- Verify the installation

### Manual Installation

If you prefer manual installation:

```bash
# Build in release mode
xcrun swift build -c release

# Install to ~/.swiftpm/bin (experimental-install doesn't support overwriting)
rm -f ~/.swiftpm/bin/appstoreconnect-mcp
xcrun swift package experimental-install --product appstoreconnect-mcp

# Verify installation
which appstoreconnect-mcp
appstoreconnect-mcp --version
```

### Get App Store Connect API Credentials

1. Sign in to [App Store Connect](https://appstoreconnect.apple.com)
2. Go to Users and Access > Keys
3. Create a new API key with appropriate permissions
4. Download the private key (.p8 file)
5. Note the Key ID and Issuer ID

## Configuration

### Environment Variables

The server requires the following environment variables:

- `ASC_KEY_ID` (required): Your App Store Connect API Key ID
- `ASC_ISSUER_ID` (required): Your App Store Connect Issuer ID
- `ASC_PRIVATE_KEY_PATH` (required): Path to your .p8 private key file
- `ASC_KEY_EXPIRY` (optional): JWT expiry time in seconds (default: 1200)

### Claude Desktop Configuration

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
        "ASC_PRIVATE_KEY_PATH": "/path/to/your/AuthKey_XXXXXXXXXX.p8"
      }
    }
  }
}
```

**Security Note**: Store your private key securely. Consider using environment variables or a secrets manager instead of hardcoding paths in the config file.

## Usage

### Tool: list_apps

List all apps in your App Store Connect account.

**Parameters**:
- `bundle_id_filter` (optional): Filter by bundle ID (e.g., "com.example.app")

**Example**:
```json
{
  "name": "list_apps",
  "arguments": {}
}
```

**Example with filter**:
```json
{
  "name": "list_apps",
  "arguments": {
    "bundle_id_filter": "com.example.myapp"
  }
}
```

### Tool: get_app_status

Get detailed status and information about a specific app.

**Parameters**:
- `app_id` (optional): App Store Connect app ID
- `bundle_id` (optional): App bundle ID

**Note**: At least one of `app_id` or `bundle_id` must be provided.

**Example**:
```json
{
  "name": "get_app_status",
  "arguments": {
    "bundle_id": "com.example.myapp"
  }
}
```

### Tool: list_builds

List builds for a specific app.

**Parameters**:
- `app_id` (required): App Store Connect app ID
- `version_filter` (optional): Filter by version (e.g., "1.0.0")

**Example**:
```json
{
  "name": "list_builds",
  "arguments": {
    "app_id": "1234567890"
  }
}
```

**Example with version filter**:
```json
{
  "name": "list_builds",
  "arguments": {
    "app_id": "1234567890",
    "version_filter": "2.1.0"
  }
}
```

### Tool: download_dsyms

Download and extract dSYM files from App Store Connect for crash symbolication.

**Implementation**: Pure Swift using URLSession (no Ruby, no Fastlane, no subprocesses).

**Parameters**:
- `build_id` (required): Build ID from App Store Connect
- `output_path` (required): Local directory path where dSYMs should be extracted

**Example**:
```json
{
  "name": "download_dsyms",
  "arguments": {
    "build_id": "abc123-def456",
    "output_path": "/Users/developer/dsyms"
  }
}
```

**What It Does**:
1. Fetches build from App Store Connect API (with buildBundles included)
2. Extracts dSYM URL from build bundle data
3. Downloads dSYM ZIP file using URLSession (pure Swift)
4. Extracts dSYMs using system unzip command
5. Returns path to extracted .dSYM files

**Output**:
- Actual .dSYM files downloaded and extracted
- Ready to upload to Firebase Crashlytics or use with crash analysis tools
- No manual steps required

### Tool: get_latest_build

Get the most recent build for a specific app.

**Parameters**:
- `app_id` (required): App Store Connect app ID

**Example**:
```json
{
  "name": "get_latest_build",
  "arguments": {
    "app_id": "1234567890"
  }
}
```

### Tool: upload_dsyms_to_firebase

Upload dSYM files to Firebase Crashlytics for crash symbolication. Supports three source options: download from App Store Connect, use local Xcode archive, or use direct dSYM path.

**Implementation**: Uses Firebase CLI (`firebase crashlytics:symbols:upload`) - no CocoaPods dependency.

**Parameters**:
- `firebase_app_id` (required): Firebase app ID (e.g., "1:123456789:ios:abc123def456")
- Exactly one of the following:
  - `build_id`: App Store Connect build ID (downloads dSYMs first)
  - `archive_path`: Path to .xcarchive directory (uses archive/dSYMs)
  - `dsyms_path`: Direct path to dSYMs directory

**Example - Upload from App Store Connect:**
```json
{
  "name": "upload_dsyms_to_firebase",
  "arguments": {
    "firebase_app_id": "1:123456789:ios:abc123def456",
    "build_id": "abc123-def456"
  }
}
```

**Example - Upload from local archive:**
```json
{
  "name": "upload_dsyms_to_firebase",
  "arguments": {
    "firebase_app_id": "1:123456789:ios:abc123def456",
    "archive_path": "/Users/developer/Library/Developer/Xcode/Archives/2025-10-24/MyApp.xcarchive"
  }
}
```

**Prerequisites**:
- Firebase CLI installed (`npm install -g firebase-tools`)
- GoogleService-Info.plist in project
- Firebase project configured

### Tool: find_xcode_archives

Search for Xcode archives in `~/Library/Developer/Xcode/Archives`. Filter by app name or bundle ID, or get the latest archive.

**Parameters**:
- `app_name_filter` (optional): Filter by app name (case-insensitive, partial match)
- `bundle_id_filter` (optional): Filter by bundle ID (case-insensitive, partial match)
- `latest_only` (optional): Return only latest archive (default: false)

**Example - Find latest archive:**
```json
{
  "name": "find_xcode_archives",
  "arguments": {
    "latest_only": true
  }
}
```

**Example - Find by app name:**
```json
{
  "name": "find_xcode_archives",
  "arguments": {
    "app_name_filter": "MyApp"
  }
}
```

**Output**: Lists archives with name, bundle ID, version, build number, creation date, path, and dSYM availability.

## Development

### Build

```bash
# Debug build
xcrun swift build

# Release build
xcrun swift build -c release
```

### Test

```bash
xcrun swift test
```

### Run Locally

```bash
# Set environment variables
export ASC_KEY_ID="YOUR_KEY_ID"
export ASC_ISSUER_ID="YOUR_ISSUER_ID"
export ASC_PRIVATE_KEY_PATH="/path/to/AuthKey_XXXXXXXXXX.p8"

# Run with debug logging
xcrun swift run appstoreconnect-mcp --log-level debug

# Available log levels: debug, info, warn, error
xcrun swift run appstoreconnect-mcp --log-level info
```

### Format Code

```bash
# Lint
swift format lint -s -p -r Sources Tests Package.swift

# Auto-fix
swift format format -p -r -i Sources Tests Package.swift
```

## Architecture

### Actor-Based Design

The server uses Swift 6.0 actors for thread-safe concurrent access:

- `MCPServer`: Main MCP protocol handler
- `AppStoreConnectClientWrapper`: Thread-safe wrapper around asc-swift client

### Error Handling

Common App Store Connect API errors are properly mapped:

- **401 Unauthorized**: Authentication failed - check credentials
- **403 Forbidden**: Insufficient permissions - check API key roles
- **404 Not Found**: Resource doesn't exist - verify IDs
- **429 Too Many Requests**: Rate limit exceeded - retry later

### Logging

All logging goes to stderr to keep stdout clean for MCP protocol:

- `debug`: Detailed operation logs
- `info`: High-level operation status
- `warn`: Non-fatal issues
- `error`: Operation failures
- `critical`: Fatal errors

## Troubleshooting

### Common Issues

**"Missing required environment variables"**
- Ensure `ASC_KEY_ID`, `ASC_ISSUER_ID`, and `ASC_PRIVATE_KEY_PATH` are set
- Verify the environment variables are in the Claude Desktop config

**"Invalid private key"**
- Check the path to your .p8 file is correct
- Ensure the file has proper read permissions
- Verify it's a valid App Store Connect API private key

**"Authentication failed"**
- Verify your Key ID and Issuer ID are correct
- Check that your API key hasn't been revoked
- Ensure the key has necessary permissions in App Store Connect

**"Rate limit exceeded"**
- The App Store Connect API has rate limits
- Wait a few minutes before retrying
- Consider reducing the frequency of API calls

### Logs

Check Claude Desktop logs for detailed error information:
- macOS: `~/Library/Logs/Claude/mcp-server-appstoreconnect-mcp.log`

View logs in real-time:
```bash
tail -f ~/Library/Logs/Claude/mcp-server-appstoreconnect-mcp.log
```

### Testing Connection

To verify your credentials work, try listing apps:

```bash
export ASC_KEY_ID="YOUR_KEY_ID"
export ASC_ISSUER_ID="YOUR_ISSUER_ID"
export ASC_PRIVATE_KEY_PATH="/path/to/AuthKey_XXXXXXXXXX.p8"

swift run appstoreconnect-mcp --log-level debug
```

Then in Claude Desktop, try:
> Can you list all my apps from App Store Connect?

## Resources

- [App Store Connect API Documentation](https://developer.apple.com/documentation/appstoreconnectapi)
- [asc-swift Library](https://github.com/aaronsky/asc-swift)
- [Model Context Protocol](https://modelcontextprotocol.io)
- [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk)

## License

MIT

## Contributing

Contributions are welcome! Please ensure:

- Code follows Swift 6.0 conventions
- All tests pass (`swift test`)
- Code is formatted (`swift format`)
- Actors are used for thread safety
- Errors are properly handled and logged
