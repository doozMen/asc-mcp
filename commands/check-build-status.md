---
description: Check the status of app builds in App Store Connect
---

# Check Build Status

Get comprehensive information about apps and builds in App Store Connect.

## Workflow Options

### 1. Check Latest Build
1. Ask for app bundle ID
2. Use `get_app_status` to get app details
3. Use `get_latest_build` to get latest build info
4. Display formatted build status

### 2. List All Builds
1. Ask for app bundle ID
2. Use `get_app_status` to get app ID
3. Use `list_builds` to get all builds
4. Display formatted list with versions, build numbers, upload dates

### 3. Check Specific Version
1. Ask for app bundle ID and version number
2. Use `list_builds` with version filter
3. Display matching builds

## Information to Display

For each build, show:
- App name and bundle ID
- Version number (e.g., "2.1.0")
- Build number (e.g., "42")
- Upload date and time
- Processing state
- TestFlight status
- App Store submission status (if applicable)
- Whether dSYMs are available

## Example Output Format

```
App: MyAwesomeApp (com.example.myapp)
Latest Build: v2.1.0 (42)
Uploaded: 2025-10-24 14:30 UTC
Status: VALID
TestFlight: Available
dSYMs: ✓ Available for download
```

## Error Handling

- Verify app exists in App Store Connect
- Handle apps with no builds
- Display helpful messages for build processing states
- Suggest next steps based on build status
