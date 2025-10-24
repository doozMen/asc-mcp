# dSYM Download Implementation

## Overview

The `download_dsyms` tool has been implemented with a comprehensive solution that addresses the App Store Connect API's limitation regarding direct dSYM file downloads.

## API Limitation

**Important**: The App Store Connect API does not provide a direct endpoint to download dSYM files. This is a documented limitation of Apple's API.

The API provides:
- Build information (version, upload date, processing state)
- Build relationships (app, icons, diagnostic signatures)
- **No direct dSYM download URL**

## Implementation Strategy

Since direct downloads are not possible via the API, the implementation focuses on providing maximum value to users by:

1. **Verifying Build State**: Confirms the build exists and has valid processing state
2. **Generating Actionable Information**: Creates detailed instructions for alternative download methods
3. **Automating Where Possible**: Provides ready-to-use Fastlane commands with app-specific details

## What the Tool Does

### 1. Build Verification
```swift
let build = try await getBuild(id: buildID)

guard let processingState = build.attributes?.processingState else {
    throw ASCError.downloadFailed("Build processing state is unknown")
}

guard processingState == .valid else {
    throw ASCError.downloadFailed("Build must be in VALID state to have dSYMs")
}
```

### 2. Information File Creation
Creates a comprehensive text file with:
- Build metadata (ID, version, upload date, processing state)
- Alternative download methods
- Ready-to-use Fastlane commands with app bundle ID
- Instructions for crash symbolication

### 3. App-Specific Details
```swift
if let appID = build.relationships?.app?.data?.id {
    let app = try await getApp(id: appID)
    if let bundleID = app.attributes?.bundleID {
        // Include bundle-ID-specific Fastlane commands
    }
}
```

## Alternative Methods Provided

### 1. Xcode Organizer (Manual)
- Window > Organizer
- Select Archives
- Click "Download Debug Symbols"

### 2. App Store Connect Web Portal
- Navigate to TestFlight > Build
- Click "Download dSYM"

### 3. Fastlane Automation (Recommended for CI/CD)
```bash
fastlane run download_dsyms app_identifier:com.example.app version:1.0.0
```

Or in Fastfile:
```ruby
lane :download_symbols do
  download_dsyms(
    app_identifier: "com.example.app",
    version: "1.0.0"
  )
end
```

### 4. Xcode Archive Export
For original archives:
```bash
xcodebuild -exportArchive \
  -archivePath /path/to/YourApp.xcarchive \
  -exportPath /path/to/output \
  -exportOptionsPlist /path/to/ExportOptions.plist
```

## File Structure

### Input
- `build_id`: App Store Connect build ID
- `output_path`: Directory for information file

### Output
File: `dsym-download-info-{buildID}.txt`

Content includes:
```
dSYM Download Information
=========================

Build ID: abc123-def456
Version: 1.0.0
Uploaded: 2025-10-24 13:00:00 +0000
Processing State: VALID

IMPORTANT: App Store Connect API Limitation
-------------------------------------------
The App Store Connect API does not provide a direct endpoint to download dSYM files.
This is a known limitation of the API.

Alternative Methods to Download dSYMs:
--------------------------------------

1. Xcode Organizer (Recommended for manual downloads):
   - Open Xcode
   - Window > Organizer
   - Select Archives
   - Find your build and click "Download Debug Symbols"

[... detailed instructions ...]

App Bundle ID: com.example.app

Fastlane Command for this app:
fastlane run download_dsyms app_identifier:com.example.app version:1.0.0
```

## Error Handling

### Build Not Found
```swift
throw ASCError.buildNotFound("Build not found: {buildID}")
```

### Invalid Processing State
```swift
throw ASCError.downloadFailed("Build must be in VALID state to have dSYMs. Current state: {state}")
```

### App Information Unavailable
```swift
logger.warning("Could not fetch app information", metadata: ["appID": "\(appID)"])
// Continues without bundle ID-specific commands
```

## User Experience

### Tool Call
```json
{
  "name": "download_dsyms",
  "arguments": {
    "build_id": "abc123-def456",
    "output_path": "/Users/developer/dsyms"
  }
}
```

### Response
```
dSYM Download Information
=========================

IMPORTANT: The App Store Connect API does not provide direct dSYM downloads.
A detailed information file has been created with alternative methods.

Information File: /Users/developer/dsyms/dsym-download-info-abc123-def456.txt

--- File Content ---
[... full information file content ...]

--- Summary ---
Alternative methods available:
  1. Xcode Organizer (manual download)
  2. App Store Connect web portal
  3. Fastlane automation (recommended for CI/CD)
  4. Xcode archive export

For automation, consider using Fastlane's download_dsyms action.
```

## Benefits of This Approach

1. **Transparency**: Users understand the API limitation immediately
2. **Actionable**: Provides multiple concrete solutions
3. **Automation-Ready**: Fastlane commands are ready to copy/paste
4. **Complete**: All relevant build information included
5. **Educational**: Teaches users about crash symbolication workflow

## Future Considerations

### Potential Enhancements
1. **Fastlane Integration**: Directly shell out to Fastlane if available
2. **Credential Sharing**: Use same ASC credentials for Fastlane
3. **Web Scraping**: Technically possible but fragile and violates ToS
4. **Custom API**: Apple could add this endpoint in the future

### Monitoring Apple's API
Check for updates:
- [App Store Connect API Documentation](https://developer.apple.com/documentation/appstoreconnectapi)
- [asc-swift Release Notes](https://github.com/aaronsky/asc-swift/releases)
- Developer forums for API announcements

## Code Quality

### Swift 6.0 Compliance
- Actor isolation for thread safety
- Sendable conformance throughout
- Proper async/await patterns
- Comprehensive error handling

### Testing
All validation tests pass:
- ✓ Build ID validation
- ✓ Output path validation
- ✓ Error message accuracy
- ✓ Parameter extraction

### Documentation
- Inline code documentation
- README updated with API limitation
- PROJECT_SUMMARY.md includes implementation notes
- This dedicated implementation document

## Related Files

- `/Users/stijnwillems/Developer/asc-mcp/Sources/appstoreconnect-mcp/AppStoreConnectClient.swift` (lines 152-282)
- `/Users/stijnwillems/Developer/asc-mcp/Sources/appstoreconnect-mcp/Tools/DownloadDSYMs.swift`
- `/Users/stijnwillems/Developer/asc-mcp/README.md` (download_dsyms section)
- `/Users/stijnwillems/Developer/asc-mcp/PROJECT_SUMMARY.md` (dSYM Download Implementation section)

## Conclusion

While the App Store Connect API doesn't support direct dSYM downloads, this implementation provides maximum value by:
- Verifying build availability and state
- Providing comprehensive alternative solutions
- Generating app-specific automation commands
- Educating users about the complete workflow

The implementation is production-ready, well-tested, and follows Swift 6.0 best practices.
