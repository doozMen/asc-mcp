# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

**asc-mcp** is a Model Context Protocol (MCP) server providing comprehensive App Store Connect API integration for iOS developers. Built with Swift 6.0, it offers 25 tools for managing apps, builds, certificates, provisioning profiles, and Firebase Crashlytics integration.

**Binary Name**: `asc` (installed to `~/.swiftpm/bin/asc`)

## Key Commands

### Build & Install

```bash
# Quick install (recommended)
./install.sh

# Manual build
xcrun swift build -c release

# Manual install (remove old binary first)
rm -f ~/.swiftpm/bin/asc
xcrun swift package experimental-install --product appstoreconnect-mcp

# Verify installation
which asc
asc --version
```

### Testing

```bash
# Run all tests
xcrun swift test

# Run specific test
xcrun swift test --filter InputValidationTests

# Run with debug logging
xcrun swift test 2>&1 | grep -v "Test Suite"
```

### Code Formatting

```bash
# Lint
swift format lint -s -p -r Sources Tests Package.swift

# Auto-fix
swift format format -p -r -i Sources Tests Package.swift
```

### Local Development

```bash
# Set credentials
export ASC_KEY_ID="YOUR_KEY_ID"
export ASC_ISSUER_ID="YOUR_ISSUER_ID"
export ASC_PRIVATE_KEY_PATH="/path/to/AuthKey_XXX.p8"

# Run with different log levels
xcrun swift run appstoreconnect-mcp --log-level debug
xcrun swift run appstoreconnect-mcp --log-level info  # Default
```

## Architecture

### Actor-Based Concurrency

The codebase uses Swift 6.0 strict concurrency with two main actors:

1. **`MCPServer` (Sources/asc-mcp/MCPServer.swift)**
   - Main MCP protocol handler
   - Registers 25 tools with JSON schema definitions
   - Routes tool calls to handler functions
   - Manages MCP stdio transport lifecycle

2. **`AppStoreConnectClientWrapper` (Sources/asc-mcp/AppStoreConnectClient.swift)**
   - Thread-safe wrapper around `asc-swift` library
   - Handles JWT authentication and private key loading
   - Provides high-level API methods for App Store Connect operations
   - Maps API errors to custom `ASCError` types

### Tool Handler Pattern

Each MCP tool has a dedicated handler file in `Sources/asc-mcp/Tools/`:

```swift
// Example: ListApps.swift
enum ListAppsHandler {
  static func handle(
    arguments: [String: JSONValue],
    client: AppStoreConnectClientWrapper,
    logger: Logger
  ) async throws -> CallTool.Result {
    // 1. Parse arguments from JSON
    // 2. Call client methods
    // 3. Format response
    // 4. Return MCP result
  }
}
```

**Tool Categories**:
- **App Management**: `ListApps`, `GetAppStatus`, `ListBuilds`, `DownloadDSYMs`, `GetLatestBuild`
- **Firebase**: `UploadDSYMsToFirebase`, `FindXcodeArchives`, `ListFirebaseProjects`, `GetFirebaseProject`, `ListFirebaseApps`
- **Build Distribution**: `UploadBuild`, `ValidateBuild`, `GetUploadStatus`
- **Certificates**: `ListCertificates`, `CreateCertificate`, `RevokeCertificate`, `DownloadCertificate`
- **Bundle IDs**: `ListBundleIds`, `RegisterBundleId`, `GetBundleId`, `UpdateBundleIdCapabilities`
- **Provisioning Profiles**: `ListProfiles`, `CreateProfile`, `DeleteProfile`, `DownloadProfile`

### CLI Utilities (Sources/asc-mcp/Utilities/)

Thread-safe actors wrapping external CLI tools:

1. **`FirebaseCLI`**: Firebase CLI integration
   - Auto-detects installation path (Homebrew, npm global)
   - Caches path for performance
   - Executes `firebase crashlytics:symbols:upload` commands
   - No CocoaPods dependency

2. **`TransporterCLI`**: xcrun iTMSTransporter integration
   - Uploads IPA files to App Store Connect
   - Validates builds before upload
   - Uses native macOS tooling via `xcrun`

3. **`ArchiveFinder`**: Xcode archive discovery
   - Scans `~/Library/Developer/Xcode/Archives`
   - Filters by app name, bundle ID, or latest
   - Parses `Info.plist` for metadata

4. **`FormatHelpers`**: Output formatting utilities
   - Table rendering for lists
   - JSON pretty-printing
   - Build state formatting

### Error Handling Strategy

**Custom Error Types**:
```swift
enum ASCError: Error, LocalizedError {
  case authenticationFailed(String)
  case apiError(Int, String)
  case notFound(String)
  case rateLimitExceeded
  case invalidPrivateKey(String)
  case invalidBundleID(String)
  case buildNotFound(String)
  case downloadFailed(String)
}
```

**HTTP Error Mapping**:
- **401**: Authentication failed - check credentials
- **403**: Insufficient permissions - verify API key roles
- **404**: Resource not found - verify IDs
- **429**: Rate limit exceeded - retry with backoff

### Logging Architecture

All logging uses `swift-log` to **stderr** (stdout reserved for MCP protocol):

```swift
logger.debug("Detailed operation logs")
logger.info("High-level status")
logger.warning("Non-fatal issues")
logger.error("Operation failures")
logger.critical("Fatal errors")
```

**Log Levels**:
- `--log-level debug`: Verbose (API calls, responses, file operations)
- `--log-level info`: Default (operation status, success/failure)
- `--log-level warn`: Warnings only
- `--log-level error`: Errors only

### Authentication Flow

1. **Environment Variables** (required):
   - `ASC_KEY_ID`: App Store Connect API Key ID
   - `ASC_ISSUER_ID`: App Store Connect Issuer ID
   - `ASC_PRIVATE_KEY_PATH`: Path to `.p8` private key file
   - `ASC_KEY_EXPIRY`: JWT expiry in seconds (default: 1200)

2. **JWT Token Generation**:
   - Uses `asc-swift` library's JWT authenticator
   - Loads private key from filesystem
   - Creates time-limited tokens (20 minutes default)
   - Tokens auto-refresh on API calls

3. **Client Initialization** (App.swift:41-65):
   ```swift
   let server = try await MCPServer(
     keyID: keyID,
     issuerID: issuerID,
     privateKeyPath: privateKeyPath,
     keyExpiry: keyExpiry
   )
   ```

### Download dSYMs Implementation

Pure Swift implementation (no Ruby, no Fastlane):

**Flow** (AppStoreConnectClient.swift:189-318):
1. Fetch build with `includeBuildBundles: true`
2. Verify build is in `VALID` processing state
3. Extract dSYM URL from `BuildBundle` items
4. Download ZIP with `URLSession`
5. Extract with system `unzip` command via `swift-subprocess`
6. Return directory path containing `.dSYM` files

**Key Details**:
- Uses `URLSession.shared.download(from:)` for native Swift download
- No shell scripts or external dependencies
- Validates HTTP status codes (200-299)
- Cleans up temporary ZIP files after extraction

### Firebase Integration

**Supported Sources** (UploadDSYMsToFirebase.swift):
1. **App Store Connect**: Downloads dSYMs via `download_dsyms` tool
2. **Xcode Archive**: Uses `.xcarchive/dSYMs/` directory
3. **Direct Path**: Custom dSYM directory

**Upload Flow**:
1. Resolve dSYM source (build ID, archive, or path)
2. Locate Firebase CLI via `FirebaseCLI.detectFirebaseCLI()`
3. Execute `firebase crashlytics:symbols:upload --app <firebase_app_id> <dsym_paths>`
4. Return success/failure with detailed logs

## Dependencies

**Swift Packages** (Package.swift):
- `modelcontextprotocol/swift-sdk` (v0.9.0+): MCP protocol implementation
- `apple/swift-log` (v1.5.0+): Structured logging
- `apple/swift-argument-parser` (v1.3.0+): CLI argument parsing
- `aaronsky/asc-swift` (v1.0.0+): App Store Connect API client
- `swiftlang/swift-subprocess` (v0.1.1+): Safe subprocess execution

**External Tools** (runtime dependencies):
- **Firebase CLI**: `npm install -g firebase-tools` or `brew install firebase-cli`
- **Xcode Command Line Tools**: `xcode-select --install` (for iTMSTransporter)

## Configuration Patterns

### Claude Desktop Integration

**User-Level Settings** (`~/.claude/settings.json`):
```json
{
  "env": {
    "PATH": "/Users/<USERNAME>/.swiftpm/bin:/usr/local/bin:/usr/bin:/bin",
    "ASC_KEY_ID": "YOUR_KEY_ID",
    "ASC_ISSUER_ID": "YOUR_ISSUER_ID",
    "ASC_PRIVATE_KEY_PATH": "/Users/<USERNAME>/.appstoreconnect/AuthKey_XXX.p8"
  }
}
```

**Plugin Configuration** (`.mcp.json`):
```json
{
  "mcpServers": {
    "asc": {
      "command": "asc",
      "args": ["--log-level", "info"]
    }
  }
}
```

**Important**: Never hardcode credentials in `.mcp.json`. Always use user-level settings.

### 1Password Integration

The `install.sh` script supports automated credential retrieval:

```bash
# Interactive installation with 1Password
./install.sh
# Choose "y" for 1Password integration
# Enter item name containing fields: "ASC Key ID", "ASC Issuer ID", "ASC Private Key Path"
```

## Testing Strategy

**Test Organization** (Tests/asc-mcp-tests/):
- `InputValidationTests.swift`: Argument parsing and validation
- `ErrorHandlingTests.swift`: Error mapping and recovery
- `EnvironmentConfigTests.swift`: Environment variable handling
- `AppStoreConnectMCPTests.swift`: Integration tests (requires credentials)

**Running Specific Tests**:
```bash
# Input validation
xcrun swift test --filter InputValidationTests

# Error handling
xcrun swift test --filter ErrorHandlingTests

# Environment config
xcrun swift test --filter EnvironmentConfigTests
```

## Common Development Scenarios

### Adding a New Tool

1. Create handler file in `Sources/asc-mcp/Tools/NewTool.swift`
2. Add tool schema to `MCPServer.getTools()` (MCPServer.swift:52-614)
3. Add case to `MCPServer.handleToolCall()` (MCPServer.swift:617-799)
4. Implement handler with pattern:
   ```swift
   enum NewToolHandler {
     static func handle(
       arguments: [String: JSONValue],
       client: AppStoreConnectClientWrapper,
       logger: Logger
     ) async throws -> CallTool.Result {
       // Implementation
     }
   }
   ```
5. Add tests in `Tests/asc-mcp-tests/`
6. Update README.md tool count and documentation

### Debugging MCP Communication

**View MCP Logs**:
```bash
# macOS
tail -f ~/Library/Logs/Claude/mcp-server-asc.log

# Filter for errors
grep ERROR ~/Library/Logs/Claude/mcp-server-asc.log
```

**Test Tool Directly**:
```bash
# Export credentials
export ASC_KEY_ID="..."
export ASC_ISSUER_ID="..."
export ASC_PRIVATE_KEY_PATH="..."

# Run with debug logging
xcrun swift run appstoreconnect-mcp --log-level debug < test_request.json
```

### Working with App Store Connect API

**API Error Troubleshooting**:
1. Check `mapAPIError()` in `AppStoreConnectClient.swift:604-619`
2. Review API response in logs (debug level)
3. Verify JWT token generation (check key ID prefix in startup logs)
4. Test credentials with `list_apps` tool (simplest test)

**Rate Limiting**:
- App Store Connect API has undocumented rate limits
- Implement exponential backoff for 429 errors
- Cache results when possible (e.g., app lists)

### Extending Firebase Support

Current Firebase tools use `FirebaseCLI` actor:
- `uploadDSYMs()`: Symbol upload
- `executeCommand()`: Generic command wrapper

To add new Firebase features:
1. Add method to `FirebaseCLI` actor (FirebaseCLI.swift)
2. Create handler in `Tools/`
3. Use existing `detectFirebaseCLI()` for installation detection

## Troubleshooting

### "Missing required environment variables"
- Check `~/.claude/settings.json` has `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY_PATH`
- Restart Claude Code after updating settings
- Verify PATH includes `~/.swiftpm/bin`

### "Invalid private key"
- Verify `.p8` file path is absolute, not relative
- Check file permissions: `chmod 600 /path/to/AuthKey_XXX.p8`
- Ensure it's an App Store Connect API key, not a developer certificate

### "Firebase CLI not found"
- Install: `npm install -g firebase-tools` or `brew install firebase-cli`
- Login: `firebase login`
- Test: `firebase projects:list`

### "Build processing state is not VALID"
- Wait for App Store Connect to process the build (10-30 minutes)
- Check build status with `get_app_status` tool
- dSYMs only available for builds in `VALID` state

### Binary not found after installation
```bash
# Check installation
ls -la ~/.swiftpm/bin/asc

# Verify PATH
echo $PATH | grep '.swiftpm/bin'

# Reinstall
rm -f ~/.swiftpm/bin/asc
xcrun swift package experimental-install --product appstoreconnect-mcp
```

## Plugin Distribution

**Part of PromptPing Marketplace**:
- Free tier plugin (submitted to Anthropic)
- Source: [github.com/doozMen/asc-mcp](https://github.com/doozMen/asc-mcp)
- Marketplace entry: `asc-mcp` in `.claude-plugin/plugin.json`

**Installation via Marketplace**:
```bash
/plugin marketplace add github.com/doozMen/promptping-marketplace
/plugin install asc-mcp
```
