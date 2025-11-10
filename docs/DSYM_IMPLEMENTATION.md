# Pure Swift dSYM Download Implementation

## Overview

The `download_dsyms` tool downloads and extracts dSYM files from App Store Connect using **pure Swift** - no Ruby, no Fastlane, no unnecessary dependencies.

## How It Works

### API Discovery

The App Store Connect API (v1.6+) provides `dSYMURL` in the `BuildBundle` resource. This was previously undocumented but is available in the `asc-swift` library.

### Implementation Steps

#### 1. Fetch Build with Build Bundles

```swift
let buildResponse = try await client.send(
    Resources.v1.builds
        .id(buildID)
        .get(include: [.buildBundles])
)
```

The `include: [.buildBundles]` parameter tells the API to include build bundle data in the response's `included` array.

#### 2. Extract dSYM URL from Build Bundles

```swift
let buildBundles = buildResponse.included?.compactMap { item -> BuildBundle? in
    if case .buildBundle(let bundle) = item {
        return bundle
    }
    return nil
}

guard let dSYMUrl = buildBundles.first(where: {
    $0.attributes?.dSYMURL != nil
})?.attributes?.dSYMURL else {
    throw ASCError.downloadFailed("No dSYM URL available")
}
```

**Key Discovery**: The `BuildBundle.attributes.dSYMURL` property contains a direct download link to the dSYM ZIP file.

#### 3. Download with URLSession (Pure Swift)

```swift
let (tempURL, response) = try await URLSession.shared.download(from: dSYMUrl)

guard let httpResponse = response as? HTTPURLResponse,
      (200...299).contains(httpResponse.statusCode) else {
    throw ASCError.downloadFailed("HTTP error")
}

// Move to output directory
let zipPath = outputURL.appendingPathComponent("dsyms-\(buildID).zip")
try FileManager.default.moveItem(at: tempURL, to: zipPath)
```

**No subprocess required** - URLSession handles the entire download natively.

#### 4. Extract with System Unzip

```swift
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
process.arguments = ["-q", zipPath.path, "-d", dsymDir.path]
try process.run()
process.waitUntilExit()
```

**Note**: Uses `/usr/bin/unzip` which is pre-installed on all macOS systems. Foundation's `FileManager.unzipItem` doesn't exist.

#### 5. Clean Up and Return

```swift
// Remove ZIP file
try FileManager.default.removeItem(at: zipPath)

// Return directory with extracted dSYMs
return dsymDir  // Contains .dSYM files ready to use
```

## Pure Swift Components

| Component | Technology | Notes |
|-----------|-----------|-------|
| API Client | `asc-swift` | Swift package for App Store Connect |
| HTTP Download | `URLSession` | Native Swift, async/await |
| File Operations | `FileManager` | Foundation, no subprocess |
| ZIP Extraction | `/usr/bin/unzip` | System command (macOS native) |
| Authentication | JWT | Pure Swift crypto |

**No External Dependencies:**
- ❌ No Ruby
- ❌ No Fastlane
- ❌ No custom Swift packages for download/unzip
- ✅ 100% native Swift + system tools

## Error Handling

Comprehensive error handling for:

### Build State Validation
```swift
guard processingState == .valid else {
    throw ASCError.downloadFailed(
        "Build must be in VALID state. Current: \(processingState.rawValue)"
    )
}
```

### dSYM URL Availability
```swift
guard let dSYMUrl = buildBundles.first(...)?.attributes?.dSYMURL else {
    throw ASCError.downloadFailed(
        "No dSYM URL available. Symbols not included or not ready."
    )
}
```

### HTTP Errors
```swift
guard (200...299).contains(httpResponse.statusCode) else {
    throw ASCError.downloadFailed("HTTP \(statusCode)")
}
```

### Extraction Failures
```swift
guard process.terminationStatus == 0 else {
    let errorMessage = String(data: errorData, encoding: .utf8)
    throw ASCError.downloadFailed("Unzip failed: \(errorMessage)")
}
```

## Architecture

```
MCP Server
    ↓
DownloadDSYMsHandler
    ↓
AppStoreConnectClientWrapper (Actor)
    ↓
┌──────────────────────────────────────┐
│ 1. Get Build (include buildBundles)  │
│    ↓                                  │
│ 2. Extract dSYMURL from BuildBundle  │
│    ↓                                  │
│ 3. URLSession.download (pure Swift)  │
│    ↓                                  │
│ 4. FileManager.moveItem              │
│    ↓                                  │
│ 5. Process.run (/usr/bin/unzip)     │
│    ↓                                  │
│ 6. Return dSYM directory path        │
└──────────────────────────────────────┘
```

## Usage Example

**Tool Call:**
```json
{
  "name": "download_dsyms",
  "arguments": {
    "build_id": "a1b2c3d4-e5f6-7890",
    "output_path": "/Users/developer/MyApp/dSYMs"
  }
}
```

**Response:**
```
✓ dSYMs Downloaded Successfully

Build ID: a1b2c3d4-e5f6-7890
dSYM Directory: /Users/developer/MyApp/dSYMs/dSYMs

Downloaded 3 dSYM file(s):
  - MyApp.app.dSYM
  - MyAppExtension.appex.dSYM
  - MyAppWidget.appex.dSYM

The dSYM files are ready to use for crash symbolication.
You can now upload them to Firebase Crashlytics or use with crash analysis tools.
```

## When dSYMs Are Available

**Available:**
- After build processing completes (state: VALID)
- For App Store and TestFlight builds
- For archived builds

**Not Available:**
- During build processing (state: PROCESSING)
- For debug builds (not uploaded)
- For builds older than Apple's retention period

## Firebase Crashlytics Upload

Once downloaded, upload to Firebase using their script:

```bash
./Pods/FirebaseCrashlytics/upload-symbols \
  -gsp GoogleService-Info.plist \
  -p ios \
  /Users/developer/MyApp/dSYMs/dSYMs
```

Or via Firebase CLI:
```bash
firebase crashlytics:symbols:upload \
  --app=YOUR_FIREBASE_APP_ID \
  /Users/developer/MyApp/dSYMs/dSYMs
```

## Advantages Over Alternative Methods

| Method | Speed | Automation | Dependencies | API Integration |
|--------|-------|------------|--------------|-----------------|
| **Pure Swift (This)** | Fast | ✅ Full | None | ✅ Native |
| Xcode Organizer | Slow | ❌ Manual | Xcode | ❌ No |
| Web Portal | Slow | ❌ Manual | Browser | ❌ No |
| Third-party tools | Medium | ⚠️ Partial | Ruby/etc | ⚠️ Wrapper |

## Security

- **JWT Authentication**: Uses your App Store Connect API credentials
- **Temporary Files**: ZIP files are deleted after extraction
- **Local Storage Only**: dSYMs saved to your specified directory
- **No Cloud Services**: No intermediate servers, direct Apple API

## Testing

To test without real credentials:

```swift
// Mock the BuildResponse with dSYMURL
let mockBundle = BuildBundle(id: "test", attributes: .init(
    dSYMURL: URL(string: "https://example.com/test.zip")
))
```

## Future Enhancements

Possible improvements (all pure Swift):
1. **Parallel downloads** - Download multiple builds concurrently
2. **Resume support** - Handle interrupted downloads
3. **Checksum validation** - Verify download integrity
4. **Firebase direct upload** - Skip local storage, upload directly

All achievable without adding external dependencies.

## Summary

✅ **Real dSYM downloads** (not just info files)
✅ **Pure Swift implementation** (no Ruby)
✅ **Zero Fastlane dependency**
✅ **Native URLSession** (async/await)
✅ **Actor-safe** (thread-safe concurrent access)
✅ **Production-ready** (comprehensive error handling)

The implementation proves that sophisticated App Store Connect automation is possible using only Swift and Apple's native tools.
