# Provisioning Profile Management

This document describes the provisioning profile management tools available in the App Store Connect MCP server.

## Overview

The MCP server provides four tools for managing provisioning profiles via the App Store Connect API:

1. **list_profiles** - List all provisioning profiles with optional filtering
2. **create_profile** - Create a new provisioning profile
3. **delete_profile** - Delete a provisioning profile
4. **download_profile** - Download a profile as a .mobileprovision file

## Tools

### list_profiles

List all provisioning profiles in App Store Connect. Optionally filter by profile type or bundle ID.

**Parameters:**
- `profile_type` (optional): Filter by profile type
  - `IOS_APP_DEVELOPMENT` - iOS Development
  - `IOS_APP_STORE` - iOS App Store
  - `IOS_APP_ADHOC` - iOS Ad Hoc
  - `IOS_APP_INHOUSE` - iOS Enterprise (In-House)
  - `MAC_APP_DEVELOPMENT` - macOS Development
  - `MAC_APP_STORE` - macOS App Store
  - `MAC_APP_DIRECT` - macOS Direct Distribution
  - `TVOS_APP_DEVELOPMENT` - tvOS Development
  - `TVOS_APP_STORE` - tvOS App Store
  - `TVOS_APP_ADHOC` - tvOS Ad Hoc
- `bundle_id_filter` (optional): Partial match filter for bundle ID (e.g., "com.example")

**Output:**
Table with the following columns:
- Profile name
- Profile type
- Status (ACTIVE/INVALID)
- Associated bundle ID
- Expiration date
- Profile ID

**Example:**
```json
{
  "profile_type": "IOS_APP_STORE",
  "bundle_id_filter": "com.example"
}
```

### create_profile

Create a new provisioning profile. Development and Ad Hoc profiles require device IDs. App Store profiles do not.

**Parameters:**
- `name` (required): Name for the provisioning profile
- `profile_type` (required): Type of provisioning profile to create
  - See profile types in `list_profiles` above
- `bundle_id` (required): Bundle ID (App Store Connect ID) to associate with this profile
- `certificate_ids` (required): Array of certificate IDs to include in the profile
- `device_ids` (optional): Array of device IDs
  - **Required** for development and ad hoc profiles
  - **Not used** for app store profiles

**Output:**
- Profile ID
- Profile name
- Profile type
- Status
- Expiration date
- UUID

**Example:**
```json
{
  "name": "My App Store Profile",
  "profile_type": "IOS_APP_STORE",
  "bundle_id": "ABC1234567",
  "certificate_ids": ["CERT123", "CERT456"]
}
```

**Example with devices (development profile):**
```json
{
  "name": "My Development Profile",
  "profile_type": "IOS_APP_DEVELOPMENT",
  "bundle_id": "ABC1234567",
  "certificate_ids": ["CERT789"],
  "device_ids": ["DEV001", "DEV002", "DEV003"]
}
```

**Profile Type Requirements:**

| Profile Type | Requires Devices | Use Case |
|--------------|-----------------|----------|
| IOS_APP_DEVELOPMENT | Yes | Development testing on registered devices |
| IOS_APP_STORE | No | App Store distribution |
| IOS_APP_ADHOC | Yes | Ad hoc distribution to specific devices |
| IOS_APP_INHOUSE | No | Enterprise in-house distribution |
| MAC_APP_DEVELOPMENT | Yes | macOS development testing |
| MAC_APP_STORE | No | Mac App Store distribution |
| MAC_APP_DIRECT | No | Direct macOS distribution outside App Store |
| TVOS_APP_DEVELOPMENT | Yes | tvOS development testing |
| TVOS_APP_STORE | No | tvOS App Store distribution |
| TVOS_APP_ADHOC | Yes | tvOS ad hoc distribution |

### delete_profile

Delete a provisioning profile by ID. This action cannot be undone.

**Parameters:**
- `profile_id` (required): Profile ID to delete

**Output:**
Confirmation message with the deleted profile ID.

**Example:**
```json
{
  "profile_id": "PROFILE123"
}
```

**Warning:** Deleting a profile is permanent and cannot be undone. Ensure you have a backup or can recreate the profile if needed.

### download_profile

Download a provisioning profile as a .mobileprovision file. The file can be double-clicked to install in Xcode.

**Parameters:**
- `profile_id` (required): Profile ID to download
- `output_path` (required): Local file path where the .mobileprovision file should be saved

**Output:**
- Downloaded file path
- File size
- Installation instructions

**Example:**
```json
{
  "profile_id": "PROFILE123",
  "output_path": "/Users/username/Downloads/MyApp.mobileprovision"
}
```

**Installation Methods:**

1. **Double-click**: Double-click the .mobileprovision file to install it in Xcode
2. **Manual**: Copy to `~/Library/MobileDevice/Provisioning Profiles/`
3. **Xcode**: The profile will appear in Xcode's signing settings

## Common Workflows

### Creating a Development Profile

1. List certificates to get certificate IDs:
   ```json
   { "certificate_type": "IOS_DEVELOPMENT" }
   ```

2. List devices to get device IDs (or register new devices first)

3. List bundle IDs to get the bundle ID:
   ```json
   { "identifier_filter": "com.example.myapp" }
   ```

4. Create the profile:
   ```json
   {
     "name": "MyApp Development",
     "profile_type": "IOS_APP_DEVELOPMENT",
     "bundle_id": "BUNDLE_ID_HERE",
     "certificate_ids": ["CERT_ID_1", "CERT_ID_2"],
     "device_ids": ["DEVICE_ID_1", "DEVICE_ID_2"]
   }
   ```

5. Download the profile:
   ```json
   {
     "profile_id": "NEW_PROFILE_ID",
     "output_path": "/path/to/save/profile.mobileprovision"
   }
   ```

### Creating an App Store Profile

1. List certificates to get distribution certificate IDs:
   ```json
   { "certificate_type": "IOS_DISTRIBUTION" }
   ```

2. List bundle IDs to get the bundle ID:
   ```json
   { "identifier_filter": "com.example.myapp" }
   ```

3. Create the profile (no devices needed):
   ```json
   {
     "name": "MyApp App Store",
     "profile_type": "IOS_APP_STORE",
     "bundle_id": "BUNDLE_ID_HERE",
     "certificate_ids": ["DISTRIBUTION_CERT_ID"]
   }
   ```

4. Download the profile:
   ```json
   {
     "profile_id": "NEW_PROFILE_ID",
     "output_path": "/path/to/save/profile.mobileprovision"
   }
   ```

### Refreshing an Expired Profile

1. List profiles to find the expired one:
   ```json
   { "bundle_id_filter": "com.example.myapp" }
   ```

2. Delete the old profile:
   ```json
   { "profile_id": "OLD_PROFILE_ID" }
   ```

3. Create a new profile with the same settings (see workflows above)

4. Download and install the new profile

## Error Handling

The tools provide detailed error messages for common issues:

- **Missing required parameters**: "Missing required parameter: {parameter_name}"
- **Invalid profile type**: "Invalid profile type: {type}"
- **Missing devices for development profile**: "Profile type {type} requires device_ids to be specified"
- **Profile not found**: "No profile content available for profile {id}"
- **Download failure**: "Failed to decode profile content for profile {id}"

## API Reference

These tools use the following App Store Connect API endpoints:

- `GET /v1/profiles` - List profiles
- `POST /v1/profiles` - Create profile
- `DELETE /v1/profiles/{id}` - Delete profile
- `GET /v1/profiles/{id}` - Get profile (for download)

For more information, see the [App Store Connect API documentation](https://developer.apple.com/documentation/appstoreconnectapi).

## Implementation Details

The provisioning profile tools are implemented in the following files:

- **Client Methods**: `/Sources/appstoreconnect-mcp/AppStoreConnectClient+Profiles.swift`
- **Tool Handlers**:
  - `/Sources/appstoreconnect-mcp/Tools/ListProfiles.swift`
  - `/Sources/appstoreconnect-mcp/Tools/CreateProfile.swift`
  - `/Sources/appstoreconnect-mcp/Tools/DeleteProfile.swift`
  - `/Sources/appstoreconnect-mcp/Tools/DownloadProfile.swift`

The implementation follows the existing tool pattern:
- Actor-based client wrapper for thread safety
- Comprehensive error handling with ASCError
- Structured logging for debugging
- Type-safe parameter validation
- Base64 decoding for profile content
- URLSession for profile download (no external dependencies)
