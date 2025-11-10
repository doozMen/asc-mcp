# Bundle ID Management Implementation

Implementation of Issue #3 - Bundle ID Management tools for App Store Connect MCP server.

## Overview

This implementation adds 4 MCP tools for managing bundle identifiers through the App Store Connect API:

1. `list_bundle_ids` - List all bundle IDs with optional filtering
2. `register_bundle_id` - Register a new bundle ID
3. `get_bundle_id` - Get detailed bundle ID information with capabilities
4. `update_bundle_id_capabilities` - Enable capabilities for a bundle ID

## Implementation Details

### Files Created

#### 1. Tool Handlers

**Sources/appstoreconnect-mcp/Tools/ListBundleIds.swift**
- Lists all bundle IDs in App Store Connect
- Optional filters: platform (IOS/MAC_OS/UNIVERSAL), identifier pattern
- Output: Formatted table with identifier, name, platform, and ID

**Sources/appstoreconnect-mcp/Tools/RegisterBundleId.swift**
- Registers new bundle IDs with validation
- Required parameters: identifier, name, platform
- Validates bundle ID format (reverse domain notation)
- Output: Confirmation with full bundle ID details

**Sources/appstoreconnect-mcp/Tools/GetBundleId.swift**
- Retrieves detailed bundle ID information
- Works with either App Store Connect ID or bundle identifier
- Includes all enabled capabilities
- Output: Complete bundle ID details and capability list

**Sources/appstoreconnect-mcp/Tools/UpdateBundleIdCapabilities.swift**
- Enables capabilities for bundle IDs
- Skips already-enabled capabilities
- Supports all App Store Connect capability types
- Output: Summary of newly enabled and existing capabilities

#### 2. Core Client Methods

Added to **Sources/appstoreconnect-mcp/AppStoreConnectClient.swift**:

```swift
// List bundle IDs with optional filters
func listBundleIDs(platform: BundleIDPlatform?, identifierFilter: String?) async throws -> [BundleID]

// Get bundle ID by ID (includes capabilities)
func getBundleID(id: String) async throws -> BundleID

// Find bundle ID by identifier string
func findBundleIDByIdentifier(_ identifier: String) async throws -> BundleID

// Register new bundle ID with validation
func registerBundleID(identifier: String, name: String, platform: BundleIDPlatform) async throws -> BundleID

// Get capabilities for a bundle ID
func getBundleIDCapabilities(bundleIDID: String) async throws -> [BundleIDCapability]

// Enable a capability
func enableBundleIDCapability(bundleIDID: String, capabilityType: CapabilityType) async throws -> BundleIDCapability
```

#### 3. Bundle ID Validator

Added **BundleIDValidator** enum to validate bundle ID format:
- Ensures reverse domain notation (e.g., com.example.app)
- Minimum 2 components separated by dots
- Alphanumeric characters with hyphens allowed (not at start/end)
- Validates each component with regex pattern

### MCP Server Integration

Updated **Sources/appstoreconnect-mcp/MCPServer.swift**:

- Added 4 tool definitions with complete schemas
- Added handler cases in `handleToolCall` switch statement
- Capability enum includes all 28 supported capability types

## API Usage

### List Bundle IDs

```bash
# List all bundle IDs
claude mcp call list_bundle_ids

# Filter by platform
claude mcp call list_bundle_ids '{"platform": "IOS"}'

# Filter by identifier pattern
claude mcp call list_bundle_ids '{"identifier_filter": "com.example"}'
```

### Register Bundle ID

```bash
claude mcp call register_bundle_id '{
  "identifier": "com.example.myapp",
  "name": "My App",
  "platform": "IOS"
}'
```

### Get Bundle ID Details

```bash
# By identifier
claude mcp call get_bundle_id '{"bundle_id": "com.example.myapp"}'

# By App Store Connect ID
claude mcp call get_bundle_id '{"bundle_id": "ABC123XYZ"}'
```

### Update Capabilities

```bash
claude mcp call update_bundle_id_capabilities '{
  "bundle_id": "com.example.myapp",
  "capabilities": ["PUSH_NOTIFICATIONS", "ICLOUD", "APP_GROUPS"]
}'
```

## Supported Capabilities

The implementation supports all 28 App Store Connect capability types:

- ICLOUD
- IN_APP_PURCHASE
- GAME_CENTER
- PUSH_NOTIFICATIONS
- WALLET
- INTER_APP_AUDIO
- MAPS
- ASSOCIATED_DOMAINS
- PERSONAL_VPN
- APP_GROUPS
- HEALTHKIT
- HOMEKIT
- WIRELESS_ACCESSORY_CONFIGURATION
- APPLE_PAY
- DATA_PROTECTION
- SIRIKIT
- NETWORK_EXTENSIONS
- MULTIPATH
- HOT_SPOT
- NFC_TAG_READING
- CLASSKIT
- AUTOFILL_CREDENTIAL_PROVIDER
- ACCESS_WIFI_INFORMATION
- NETWORK_CUSTOM_PROTOCOL
- COREMEDIA_HLS_LOW_LATENCY
- SYSTEM_EXTENSION_INSTALL
- USER_MANAGEMENT
- APPLE_ID_AUTH

## Error Handling

Comprehensive error handling includes:

- Bundle ID format validation
- Platform enum validation
- Capability type validation
- ASCError types for API failures
- Duplicate capability detection (automatic skip)
- Clear error messages for invalid inputs

## Testing

Build verification:
```bash
swift build
# Build complete! (3.54s)
```

Format verification:
```bash
swift format lint -s -p -r Sources/appstoreconnect-mcp/
# All files properly formatted
```

## Implementation Notes

### Bundle ID Validation

The BundleIDValidator ensures:
1. Reverse domain notation format
2. Minimum 2 components (e.g., com.example)
3. Valid characters in each component
4. No hyphens at component start/end

### Capability Management

- `update_bundle_id_capabilities` is idempotent
- Already-enabled capabilities are skipped, not re-created
- Shows clear summary of new vs. existing capabilities
- Supports enabling multiple capabilities in one call

### Flexible ID Resolution

Both `get_bundle_id` and `update_bundle_id_capabilities` accept:
- Bundle identifiers (com.example.app) - auto-detected by presence of dots
- App Store Connect IDs (ABC123XYZ) - direct lookup

This provides flexibility for users who may have either format.

## Code Quality

- Follows existing project patterns
- Swift 6.0 actor isolation for thread safety
- Comprehensive logging with structured metadata
- Type-safe enums for platforms and capabilities
- Clear, descriptive error messages
- Formatted with Swift 6 native formatter

## Dependencies

Uses existing asc-swift package APIs:
- `Resources.v1.bundleIDs.*` - Bundle ID management
- `Resources.v1.bundleIDCapabilities.*` - Capability management
- `BundleID`, `BundleIDPlatform`, `CapabilityType` types

## Future Enhancements

Potential additions:
1. Delete bundle ID support
2. Update bundle ID name
3. List all available capabilities for a platform
4. Bulk capability enable/disable
5. Capability settings configuration (for capabilities with options)
