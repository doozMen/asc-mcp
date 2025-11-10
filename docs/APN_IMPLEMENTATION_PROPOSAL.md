# APN Certificate Management - Alternative Implementation Proposal

## Summary

The original Issue #5 requested APN certificate tools, but the App Store Connect API doesn't support direct APN certificate management. Instead, I propose implementing **Push Notification Capability Management** tools that provide real value for APN setup workflows.

## Proposed Implementation

### Tool 1: `list_bundle_ids`
**Purpose**: List all Bundle IDs with optional filtering and capability information

**Parameters**:
- `identifier_filter` (optional): Filter by bundle ID (e.g., "com.example.app")
- `name_filter` (optional): Filter by name
- `platform` (optional): IOS, MAC_OS, or UNIVERSAL
- `include_capabilities` (optional): Include capability information (default: false)

**Output**: Table with:
- Bundle ID identifier
- Name
- Platform
- App ID (if linked)
- Push Notifications capability status

### Tool 2: `get_bundle_id_capabilities`
**Purpose**: Get all capabilities for a specific Bundle ID, with focus on Push Notifications

**Parameters**:
- `bundle_id` (required): Bundle ID identifier (e.g., "com.example.app")

**Output**:
- Bundle ID details
- Complete list of enabled capabilities
- Push Notifications configuration (if enabled)
- Settings and environment details

### Tool 3: `enable_push_notifications`
**Purpose**: Enable Push Notifications capability for a Bundle ID

**Parameters**:
- `bundle_id` (required): Bundle ID identifier
- `development` (optional): Enable development environment (default: true)
- `production` (optional): Enable production environment (default: true)

**Output**:
- Success confirmation
- Capability ID
- Next steps for APN setup (instructions for creating .p8 key or certificate)

### Tool 4: `get_apn_setup_guide`
**Purpose**: Generate comprehensive APN setup instructions

**Parameters**:
- `bundle_id` (required): Bundle ID identifier
- `firebase_project_id` (optional): Firebase project ID for Firebase-specific instructions
- `method` (optional): "token" (recommended) or "certificate"

**Output**: Step-by-step guide including:
- Current capability status
- Instructions for creating APNs Auth Key (.p8) or Certificate (.cer)
- Firebase Console upload instructions
- Testing checklist
- Troubleshooting tips

## Implementation Details

### AppStoreConnectClient Extensions

Add methods to `AppStoreConnectClientWrapper`:

```swift
/// List Bundle IDs with optional filters
func listBundleIDs(
  identifierFilter: String? = nil,
  nameFilter: String? = nil,
  platform: String? = nil,
  includeCapabilities: Bool = false
) async throws -> [BundleID]

/// Get Bundle ID by identifier
func getBundleID(identifier: String) async throws -> BundleID

/// Get capabilities for a Bundle ID
func getBundleIDCapabilities(bundleID: String) async throws -> [BundleIDCapability]

/// Enable push notifications capability
func enablePushNotifications(bundleID: String) async throws -> BundleIDCapability
```

### Error Handling

Add new error types:
```swift
case bundleIDNotFound(String)
case capabilityAlreadyEnabled(String)
case invalidPlatform(String)
```

### Firebase Integration

The `get_apn_setup_guide` tool will provide instructions for:
1. Firebase Console navigation
2. APNs key/certificate upload steps
3. Configuration verification
4. Testing push notifications

## Benefits

1. **Practical Automation**: Automates the capability enablement step
2. **Clear Guidance**: Provides step-by-step instructions for manual steps
3. **Comprehensive**: Covers the entire APN setup workflow
4. **Firebase Integration**: Includes Firebase-specific guidance
5. **Error Prevention**: Helps users avoid common configuration mistakes

## Future Enhancements

1. **Certificate Expiration Tracking**: Track certificate expiration dates (if stored separately)
2. **Configuration Validation**: Verify APNs configuration completeness
3. **Multi-App Management**: Batch operations for multiple Bundle IDs
4. **Notification Testing**: Integration with APNs testing tools

## Files to Create

1. `Sources/appstoreconnect-mcp/Tools/ListBundleIDs.swift`
2. `Sources/appstoreconnect-mcp/Tools/GetBundleIDCapabilities.swift`
3. `Sources/appstoreconnect-mcp/Tools/EnablePushNotifications.swift`
4. `Sources/appstoreconnect-mcp/Tools/GetApnSetupGuide.swift`

## Files to Modify

1. `Sources/appstoreconnect-mcp/AppStoreConnectClient.swift` - Add Bundle ID methods
2. `Sources/appstoreconnect-mcp/MCPServer.swift` - Register new tools
3. `Sources/appstoreconnect-mcp/AppStoreConnectClient.swift` - Add error cases

## Decision Required

Should I proceed with this alternative implementation? It provides real value even though it doesn't match the original issue's technical spec (which wasn't feasible).
