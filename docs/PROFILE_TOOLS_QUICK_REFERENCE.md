# Provisioning Profile Tools - Quick Reference

## Available Tools

### 1. list_profiles
List all provisioning profiles with optional filtering.

**Parameters:**
- `profile_type` (optional): Filter by type (e.g., "IOS_APP_STORE")
- `bundle_id_filter` (optional): Filter by bundle ID (e.g., "com.example")

**Example:**
```bash
{
  "profile_type": "IOS_APP_DEVELOPMENT",
  "bundle_id_filter": "com.mycompany"
}
```

---

### 2. create_profile
Create a new provisioning profile.

**Parameters:**
- `name` (required): Profile name
- `profile_type` (required): Type (e.g., "IOS_APP_DEVELOPMENT")
- `bundle_id` (required): Bundle ID from App Store Connect
- `certificate_ids` (required): Array of certificate IDs
- `device_ids` (optional): Array of device IDs (required for dev/adhoc)

**Example - App Store:**
```bash
{
  "name": "MyApp AppStore Profile",
  "profile_type": "IOS_APP_STORE",
  "bundle_id": "ABC1234567",
  "certificate_ids": ["CERT123456"]
}
```

**Example - Development:**
```bash
{
  "name": "MyApp Dev Profile",
  "profile_type": "IOS_APP_DEVELOPMENT",
  "bundle_id": "ABC1234567",
  "certificate_ids": ["CERT123456"],
  "device_ids": ["DEV001", "DEV002"]
}
```

---

### 3. delete_profile
Delete a provisioning profile (permanent action).

**Parameters:**
- `profile_id` (required): Profile ID to delete

**Example:**
```bash
{
  "profile_id": "PROFILE123456"
}
```

---

### 4. download_profile
Download a provisioning profile as .mobileprovision file.

**Parameters:**
- `profile_id` (required): Profile ID to download
- `output_path` (required): Where to save the file

**Example:**
```bash
{
  "profile_id": "PROFILE123456",
  "output_path": "/Users/myuser/Downloads/MyApp.mobileprovision"
}
```

---

## Profile Types

| Type | Requires Devices | Use Case |
|------|-----------------|----------|
| IOS_APP_DEVELOPMENT | Yes | Development testing |
| IOS_APP_STORE | No | App Store distribution |
| IOS_APP_ADHOC | Yes | Ad hoc distribution |
| IOS_APP_INHOUSE | No | Enterprise distribution |
| MAC_APP_DEVELOPMENT | Yes | macOS development |
| MAC_APP_STORE | No | Mac App Store |
| MAC_APP_DIRECT | No | Direct macOS distribution |
| TVOS_APP_DEVELOPMENT | Yes | tvOS development |
| TVOS_APP_STORE | No | tvOS App Store |
| TVOS_APP_ADHOC | Yes | tvOS ad hoc |

---

## Common Workflows

### Get Certificate and Device IDs

Before creating a profile, you need:

1. **Certificate IDs**: Use `list_certificates` tool
2. **Bundle IDs**: Use `list_bundle_ids` or `get_bundle_id` tool
3. **Device IDs**: Use device management tools (when available)

### Create & Download Development Profile

1. List certificates:
```bash
{ "certificate_type": "IOS_DEVELOPMENT" }
```

2. Create profile:
```bash
{
  "name": "Dev Profile",
  "profile_type": "IOS_APP_DEVELOPMENT",
  "bundle_id": "BUNDLE_ID",
  "certificate_ids": ["CERT_ID"],
  "device_ids": ["DEVICE_ID_1", "DEVICE_ID_2"]
}
```

3. Download profile:
```bash
{
  "profile_id": "NEW_PROFILE_ID",
  "output_path": "/path/to/save.mobileprovision"
}
```

4. Install: Double-click the .mobileprovision file

---

## File Locations

**Implementation:**
- Client: `/Sources/appstoreconnect-mcp/AppStoreConnectClient+Profiles.swift`
- Tools: `/Sources/appstoreconnect-mcp/Tools/{List,Create,Delete,Download}Profile.swift`

**Documentation:**
- Full Guide: `/docs/PROVISIONING_PROFILES.md`
- Summary: `/IMPLEMENTATION_SUMMARY.md`

---

## Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| Missing required parameter | Parameter not provided | Check required parameters |
| Invalid profile type | Unknown type string | Use exact type strings from list |
| Requires device_ids | Dev/AdHoc without devices | Add device_ids array |
| Profile not found | Invalid profile ID | Verify ID with list_profiles |
| Download failed | Profile content unavailable | Check profile is ACTIVE |

---

## Installation Methods

After downloading a .mobileprovision file:

1. **Xcode (Recommended)**: Double-click the file
2. **Manual**: Copy to `~/Library/MobileDevice/Provisioning Profiles/`
3. **Verify**: Check Xcode → Settings → Accounts → Manage Certificates

---

For more details, see `/docs/PROVISIONING_PROFILES.md`
