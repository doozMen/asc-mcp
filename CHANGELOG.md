# Changelog

All notable changes to the asc-mcp project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.1-alpha.4] - 2025-11-11

### Changed

#### Installation Script
- **Plugin Installation Instructions**: Added comprehensive plugin installation guide to `install.sh`
  - Includes PromptPing Marketplace installation commands
  - Shows both GitHub and local development installation paths
  - Visible in all exit paths (credentials configured, 1Password setup, manual setup, or declined)
  - Consistent with marketplace distribution model

### Documentation
- Enhanced installation workflow to guide users through both binary and plugin setup
- Clarifies the two-step process: binary installation → plugin installation via marketplace

## [0.0.1-alpha.3] - 2025-11-11

### Fixed

#### Plugin Validation
- **Agent/Skill Paths**: Fixed plugin.json to use array of individual `.md` file paths
  - Claude Code validator requires explicit `.md` endings
  - Changed from directory paths to individual file paths for validation compliance
  - Agents: `["./agents/app-store-connect-specialist.md", "./agents/ios-crash-manager.md"]`
  - Skills: `["./skills/swift-cli-notarization.md"]`

### Changed
- Version bumped to `0.0.1-alpha.3` in all version references
- Successfully validated plugin structure with Claude Code validator

## [0.0.1-alpha.2] - 2025-11-11

### Added

#### New Agents
- **App Store Connect Specialist Agent** (`@app-store-connect-specialist`)
  - Specialized agent for App Store Connect API operations
  - Restricted tool access (only asc-mcp and Firebase MCP)
  - 5 core workflows: dSYM download, Firebase upload, certificate creation, profile management, TestFlight uploads
  - Comprehensive error handling and authentication guidance
  - Safe, auditable operations with explicit confirmation for irreversible actions

#### New Skills
- **Swift CLI Notarization Skill** (`swift-cli-notarization.md`)
  - Complete reference guide for building Swift CLI tools with SPM
  - Code signing with Developer ID certificates
  - Notarization workflow with Apple notarytool
  - Distribution methods (GitHub releases, Homebrew, SPM experimental-install)
  - File access permissions and user data protection
  - Release automation scripts and troubleshooting guide

#### Documentation Updates
- Enhanced `README.md` with plugin components overview
- Updated `CLAUDE.md` with agents and skills reference
- Created this `CHANGELOG.md` for release tracking

#### Plugin Configuration
- Updated `plugin.json` to reference agents and skills directories
- Version bumped to `0.0.1-alpha.2` in all version references

### Changed

- Updated binary product name documentation (consistently using `asc` instead of mixed references)
- Improved 1Password integration documentation with clear field extraction flow
- Enhanced CLAUDE.md with complete agent invocation examples

### Fixed

- Corrected all binary installation references to use correct product name (`asc`)
- Fixed Manual Installation section in README.md to reference correct binary names

## [0.0.1-alpha.1] - 2025-11-11

### Added

#### Enhanced Authentication
- **1Password Integration**: Automated credential retrieval from "Dooz Apple developer" vault
- **Private Key Management**: Automatic download to `~/.appstoreconnect/` with secure permissions (600)
- **Streamlined Setup**: Install script now guides users to add credentials to `~/.claude/settings.json`

#### Documentation
- Comprehensive CLAUDE.md with full architecture documentation
- Detailed 1Password integration guide in install.sh
- Clear separation of concerns: plugin config (minimal) vs user settings (credentials)

### Changed

- Version bumped from `0.0.1-alpha.0` to `0.0.1-alpha.1`
- Updated install.sh to use 1Password item: "Dooz Apple developer"
- Improved authentication flow documentation in CLAUDE.md

### Fixed

- Binary product name now consistently referenced as `asc` throughout documentation
- Fixed all references to use `xcrun swift package experimental-install --product asc`
- Updated Local Development section to use correct binary name

## [0.0.1-alpha.0] - 2025-11-04

### Added

#### Initial Release
- **25 MCP Tools** organized into 6 categories:
  - App Management (5 tools): list_apps, get_app_status, list_builds, download_dsyms, get_latest_build
  - Certificate Management (4 tools): list_certificates, create_certificate, revoke_certificate, download_certificate
  - Bundle ID Management (4 tools): list_bundle_ids, register_bundle_id, get_bundle_id, update_bundle_id_capabilities
  - Provisioning Profiles (4 tools): list_profiles, create_profile, delete_profile, download_profile
  - Build Distribution (3 tools): upload_build, validate_build, get_upload_status
  - Firebase Integration (5 tools): upload_dsyms_to_firebase, find_xcode_archives, list_firebase_projects, get_firebase_project, list_firebase_apps

#### Features
- Pure Swift implementation (no Ruby, no Fastlane, no CocoaPods)
- JWT authentication with App Store Connect API
- Firebase CLI integration for crash symbol uploads
- Comprehensive error handling (401, 403, 404, 429 errors)
- Actor-based architecture for thread-safe operations
- Native Swift dSYM download (no shell scripts needed)
- Support for multiple dSYM source types (ASC, Xcode archive, direct path)

#### Documentation
- Comprehensive README.md with all tool descriptions
- Setup instructions for App Store Connect credentials
- Configuration guide for Claude Desktop
- Testing strategy and troubleshooting guide

#### Configuration
- Interactive install.sh script
- Manual build and installation instructions
- Environment variable setup guide
- Firebase CLI integration detection

### Technical Details

- **Language**: Swift 6.0
- **Architecture**: Actor-based with strict concurrency
- **Dependencies**:
  - modelcontextprotocol/swift-sdk (MCP protocol)
  - apple/swift-log (logging)
  - apple/swift-argument-parser (CLI arguments)
  - aaronsky/asc-swift (App Store Connect API)
  - swiftlang/swift-subprocess (safe subprocess execution)
- **Platforms**: macOS 13.0+
- **License**: MIT

---

## Notes for Contributors

### Version Numbering

- **Alpha Releases** (0.0.1-alpha.X): Pre-release versions for feature development
- **Beta Releases** (0.0.1-beta.X): Later pre-release for testing
- **Stable Releases** (X.Y.Z): Production-ready versions

### Release Process

1. Update version in:
   - `App.swift` (CommandConfiguration version)
   - `MCPServer.swift` (Server version)
   - `.claude-plugin/plugin.json` (plugin.json version)

2. Run `swift package update` to refresh Package.lock

3. Update documentation:
   - README.md (if features changed)
   - CLAUDE.md (if architecture changed)
   - CHANGELOG.md (always, with full change details)

4. Create GitHub release with detailed notes

### Breaking Changes

None yet (alpha releases).

### Known Issues

None currently.

### Future Roadmap

- [ ] Support for App Store Connect Sandbox environment
- [ ] Batch operations for certificate/profile management
- [ ] Direct Xcode build integration
- [ ] Advanced caching for API responses
- [ ] CLI tool for standalone use (outside Claude Code)
