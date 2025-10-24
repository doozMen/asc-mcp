# Changelog

All notable changes to the App Store Connect MCP Plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-24

### Added

#### MCP Server Tools
- `list_apps` - List all apps in App Store Connect with optional bundle ID filtering
- `get_app_status` - Get detailed app information and current status
- `list_builds` - List builds for an app with optional version filtering
- `download_dsyms` - Download and extract dSYM files (pure Swift implementation)
- `get_latest_build` - Get the most recent build for an app
- `upload_dsyms_to_firebase` - Upload dSYMs to Firebase Crashlytics
- `find_xcode_archives` - Search local Xcode archives by app name or bundle ID

#### Slash Commands
- `/download-latest-dsyms` - Automated workflow to download latest dSYM files
- `/upload-dsyms-to-crashlytics` - Complete workflow for Firebase Crashlytics uploads
- `/check-build-status` - Check build status and details
- `/setup-credentials` - Interactive guide for App Store Connect credential setup

#### Agents
- `ios-crash-manager` - Expert agent for crash symbolication and dSYM management
  - Automates multi-step workflows
  - Provides troubleshooting guidance
  - Integrates App Store Connect and Firebase Crashlytics operations

#### Plugin Infrastructure
- Claude Code plugin manifest (`.claude-plugin/plugin.json`)
- MCP server configuration (`.mcp.json`)
- Marketplace metadata for distribution
- Installation script with interactive credential setup
- Comprehensive documentation

#### Technical Features
- Pure Swift 6.0 implementation
- Actor-based architecture for thread safety
- Modern async/await patterns
- Comprehensive error handling for API errors (401, 403, 404, 429)
- JWT authentication with App Store Connect API
- Logging to stderr with configurable levels (debug, info, warn, error)

### Technical Details

#### Architecture
- MCP server: `appstoreconnect-mcp` (Swift executable)
- Dependencies:
  - asc-swift 1.0.0+ (App Store Connect API client)
  - swift-mcp 0.9.0+ (Model Context Protocol SDK)
  - swift-argument-parser 1.3.0+ (CLI argument parsing)
  - swift-log 1.5.0+ (Logging infrastructure)

#### Requirements
- macOS 13.0 or later
- Swift 6.0 or later
- App Store Connect API credentials (Key ID, Issuer ID, Private Key)
- Optional: Firebase CLI for Crashlytics integration

#### Security
- Credentials stored in Claude Code configuration or environment variables
- Private keys (.p8 files) never transmitted
- Sensitive data redacted from logs
- Proper file permission recommendations

### Distribution

- GitHub repository: https://github.com/doozMen/asc-mcp
- Self-hosted marketplace support
- Official Claude Code marketplace submission ready
- Community marketplace compatible

## [Unreleased]

### Planned Features
- Support for App Store submission status checks
- TestFlight beta group management
- Build notes and changelog retrieval
- Multi-app batch operations
- Crash log download and analysis
- Integration with additional crash reporting platforms

---

[1.0.0]: https://github.com/doozMen/asc-mcp/releases/tag/v1.0.0
