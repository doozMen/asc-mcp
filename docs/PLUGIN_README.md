# App Store Connect MCP Plugin for Claude Code

Seamlessly integrate App Store Connect and Firebase Crashlytics into your Claude Code workflow. Automate dSYM management, build monitoring, and crash symbolication for iOS development.

## Features

### App Store Connect Integration
- **List Apps**: Query all apps in your App Store Connect account with optional filtering
- **Build Status**: Get detailed information about builds, versions, and processing states
- **Latest Build**: Quick access to the most recent build for any app
- **dSYM Downloads**: Pure Swift implementation to download and extract dSYM files

### Firebase Crashlytics Integration
- **Automated Uploads**: Upload dSYMs to Firebase Crashlytics from multiple sources
- **Archive Discovery**: Find and use local Xcode archives
- **Flexible Sources**: Support for App Store Connect, Xcode archives, or direct paths

### Slash Commands
- `/download-latest-dsyms` - Download dSYM files from latest build
- `/upload-dsyms-to-crashlytics` - Upload dSYMs to Firebase
- `/check-build-status` - Check build status and information
- `/setup-credentials` - Interactive credential setup guide

### Specialized Agent
- **ios-crash-manager** - Expert agent for crash symbolication workflows
  - Automates multi-step dSYM workflows
  - Troubleshoots crash symbolication issues
  - Provides best practices for crash reporting

## Installation

### Prerequisites

- macOS 13.0 or later
- Swift 6.0 or later (included with Xcode 16+)
- App Store Connect API credentials ([Get credentials](https://appstoreconnect.apple.com))
- Optional: Firebase CLI for Crashlytics integration

### Quick Install

1. **Install the plugin:**
   ```bash
   /plugin install appstoreconnect-mcp@<marketplace-name>
   ```

2. **Build and install the MCP server:**
   ```bash
   cd ~/.claude/plugins/appstoreconnect-mcp
   ./install.sh
   ```

3. **Configure credentials:**

   The installation script will prompt you to add credentials to Claude Code. You'll need:
   - **ASC_KEY_ID**: Your App Store Connect API Key ID
   - **ASC_ISSUER_ID**: Your App Store Connect Issuer ID
   - **ASC_PRIVATE_KEY_PATH**: Path to your .p8 private key file

   Alternatively, use the `/setup-credentials` command in Claude Code for interactive setup.

### Getting App Store Connect API Credentials

1. Sign in to [App Store Connect](https://appstoreconnect.apple.com)
2. Go to **Users and Access > Keys**
3. Click **+** to create a new API key
4. Select permissions (minimum: "Developer" or "App Manager")
5. Download the private key (.p8 file) - **can only be downloaded once!**
6. Note the **Key ID** and **Issuer ID**

**Security Note**: Store your .p8 file securely. Never commit it to version control.

## Usage Examples

### Download Latest dSYMs

```
You: Download the latest dSYMs for my app
Claude: What's your app's bundle ID?
You: com.example.myapp
Claude: [Downloads and extracts dSYMs automatically]

       ✓ dSYMs downloaded for MyApp v2.1.0 (build 42)
       Location: /Users/you/dsyms/MyApp-2.1.0-42/
```

### Upload to Firebase Crashlytics

```
You: Upload the latest dSYMs to Firebase Crashlytics
Claude: What's your Firebase app ID?
You: 1:123456789:ios:abc123def456
Claude: What's your app's bundle ID?
You: com.example.myapp
Claude: [Downloads dSYMs and uploads to Firebase]

       ✓ dSYMs uploaded successfully to Firebase Crashlytics
       Processing may take 5-10 minutes.
```

### Check Build Status

```
You: What's the status of my latest build?
Claude: Which app?
You: com.example.myapp
Claude: [Retrieves build information]

       App: MyAwesomeApp (com.example.myapp)
       Latest Build: v2.1.0 (42)
       Uploaded: 2025-10-24 14:30 UTC
       Status: VALID
       TestFlight: Available
       dSYMs: ✓ Available
```

### Find Xcode Archives

```
You: Find my Xcode archives from last week
Claude: [Searches ~/Library/Developer/Xcode/Archives]

       Found 3 archives:
       1. MyApp 2.1.0 (42) - 2025-10-24 14:30
       2. MyApp 2.0.9 (41) - 2025-10-23 10:15
       3. MyApp 2.0.8 (40) - 2025-10-22 16:45
```

## Architecture

### Pure Swift Implementation
- No Ruby dependencies (no Fastlane required)
- No CocoaPods dependencies
- Modern Swift 6.0 with strict concurrency
- Actor-based architecture for thread safety

### MCP Server
- Implements Model Context Protocol for Claude Code integration
- 7 specialized tools for App Store Connect and Firebase
- Comprehensive error handling and logging
- JWT authentication with App Store Connect API

### Components
- **MCP Server**: `appstoreconnect-mcp` executable (Swift)
- **Slash Commands**: 4 workflow automation commands
- **Agent**: iOS crash management specialist
- **Tools**: 7 MCP tools for API integration

## Troubleshooting

### Common Issues

**"Missing required environment variables"**
- Solution: Run `/setup-credentials` command or check your .p8 file path

**"Authentication failed"**
- Verify Key ID and Issuer ID are correct
- Check .p8 file has proper read permissions
- Ensure API key hasn't been revoked in App Store Connect

**"Build does not have dSYMs available"**
- Recent builds may still be processing
- Wait a few minutes and try again
- Verify build completed successfully in App Store Connect

**"Firebase command not found"**
- Install Firebase CLI: `npm install -g firebase-tools`
- Verify installation: `firebase --version`

### Logs

Check MCP server logs for detailed error information:
```bash
tail -f ~/Library/Logs/Claude/mcp-server-appstoreconnect-mcp.log
```

## Use Cases

### For iOS Developers
- Quick access to build information without opening App Store Connect
- Automated dSYM downloads for crash investigation
- TestFlight build monitoring
- Version history tracking

### For CI/CD Automation
- Automate dSYM uploads in release workflows
- Monitor build processing status
- Integrate with Firebase Crashlytics automatically
- Archive management and verification

### For Crash Analysis
- Fast dSYM retrieval for specific builds
- Batch uploads to Firebase Crashlytics
- UUID verification and matching
- Historical archive searches

## Technical Details

### Dependencies
- [asc-swift](https://github.com/aaronsky/asc-swift) - App Store Connect API client
- [swift-mcp](https://github.com/modelcontextprotocol/swift-sdk) - Model Context Protocol SDK
- [swift-argument-parser](https://github.com/apple/swift-argument-parser) - CLI argument parsing
- [swift-log](https://github.com/apple/swift-log) - Logging infrastructure

### Requirements
- macOS 13.0+
- Swift 6.0+
- Xcode 16+ (for building)
- App Store Connect API credentials

### Optional Requirements
- Firebase CLI (for Crashlytics integration)
- Node.js 18+ (for Firebase CLI)

## Privacy & Security

- **Credentials**: Stored securely in Claude Code configuration or environment variables
- **API Keys**: Never transmitted outside your local machine
- **Private Keys**: .p8 files remain on your filesystem
- **Data**: No data is sent to external services except App Store Connect and Firebase (when you explicitly trigger uploads)
- **Logging**: Sensitive data (keys, tokens) is redacted from logs

## Support

- **Issues**: [GitHub Issues](https://github.com/doozMen/asc-mcp/issues)
- **Documentation**: [Full README](https://github.com/doozMen/asc-mcp/blob/main/README.md)
- **Discussions**: [GitHub Discussions](https://github.com/doozMen/asc-mcp/discussions)

## License

MIT License - see [LICENSE](https://github.com/doozMen/asc-mcp/blob/main/LICENSE) for details.

## Author

**Stijn Willems** ([@doozMen](https://github.com/doozMen))

iOS developer and Swift enthusiast passionate about developer experience and automation.

## Changelog

### Version 1.0.0 (2025-10-24)
- Initial release
- 7 MCP tools for App Store Connect and Firebase
- 4 slash commands for common workflows
- iOS crash manager agent
- Pure Swift implementation
- Interactive credential setup

## Contributing

Contributions welcome! See [CONTRIBUTING.md](https://github.com/doozMen/asc-mcp/blob/main/CONTRIBUTING.md) for guidelines.

## Acknowledgments

- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)
- [Model Context Protocol](https://modelcontextprotocol.io)
- [asc-swift](https://github.com/aaronsky/asc-swift) by Aaron Sky
- Claude Code team at Anthropic
