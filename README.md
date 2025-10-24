# App Store Connect MCP Server

MCP server for App Store Connect API integration. Provides tools to query apps, builds, and download dSYM files through the Model Context Protocol.

## Features

- **list_apps**: List all apps with optional bundle ID filtering
- **get_app_status**: Get detailed app information and status
- **list_builds**: List builds for an app with optional version filtering
- **download_dsyms**: Download dSYM files for crash symbolication
- **get_latest_build**: Get the most recent build for an app
- JWT authentication with App Store Connect API
- Comprehensive error handling for API errors (401, 403, 404, 429)
- Actor-based architecture for thread safety

## Prerequisites

- macOS 13.0+
- Swift 6.0+
- App Store Connect API credentials (Key ID, Issuer ID, Private Key)

## Installation

### 1. Build and Install

```bash
# Build in release mode
swift build -c release

# Install to ~/.swiftpm/bin
swift package experimental-install
```

Verify installation:
```bash
which appstoreconnect-mcp
```

### 2. Get App Store Connect API Credentials

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

Download dSYM files for a specific build (used for crash symbolication).

**Parameters**:
- `build_id` (required): Build ID from App Store Connect
- `output_path` (required): Local directory path where dSYMs should be saved

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

## Development

### Build

```bash
swift build
```

### Test

```bash
swift test
```

### Run Locally

```bash
# Set environment variables
export ASC_KEY_ID="YOUR_KEY_ID"
export ASC_ISSUER_ID="YOUR_ISSUER_ID"
export ASC_PRIVATE_KEY_PATH="/path/to/AuthKey_XXXXXXXXXX.p8"

# Run with debug logging
swift run appstoreconnect-mcp --log-level debug
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
