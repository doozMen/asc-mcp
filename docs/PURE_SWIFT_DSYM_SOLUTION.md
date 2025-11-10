# Pure Swift dSYM Download - No Fastlane Required

## The Problem with Fastlane

Fastlane adds:
- Ruby dependency
- Complex subprocess management  
- Additional authentication layers
- Unnecessary complexity

## Pure Swift Solution

The App Store Connect API (v1.6+) provides `dSYMUrl` directly in build responses. Download with native Swift URLSession.

## Implementation

### Step 1: Get Build with dSYM URL

```swift
import AppStoreConnect
import AppStoreAPI

// Get build with dSYM information
let build = try await client.send(
    Resources.v1.builds
        .id(buildId)
        .get(parameters: .init(include: [.buildBundles]))
)

// Extract dSYM URL from build bundles
if let buildBundles = build.included,
   let dSYMUrl = buildBundles.first?.attributes?.dSYMUrl {
    print("dSYM URL: \(dSYMUrl)")
}
```

### Step 2: Download dSYM with URLSession (Pure Swift)

```swift
import Foundation

func downloadDSYM(from urlString: String, to outputPath: String) async throws {
    guard let url = URL(string: urlString) else {
        throw DSYMError.invalidURL
    }
    
    // Download using URLSession (no subprocess needed!)
    let (tempURL, response) = try await URLSession.shared.download(from: url)
    
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw DSYMError.downloadFailed
    }
    
    // Move to output path
    let fileManager = FileManager.default
    let destinationURL = URL(fileURLWithPath: outputPath)
    
    // Create directory if needed
    try fileManager.createDirectory(
        at: destinationURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    
    // Move downloaded file
    if fileManager.fileExists(atPath: destinationURL.path) {
        try fileManager.removeItem(at: destinationURL)
    }
    try fileManager.moveItem(at: tempURL, to: destinationURL)
    
    print("✓ Downloaded to: \(outputPath)")
}

enum DSYMError: Error {
    case invalidURL
    case downloadFailed
    case fileOperationFailed
}
```

### Step 3: Unzip dSYM (Pure Swift)

The downloaded file is a .zip. Unzip with native Swift:

```swift
import Foundation

func unzipDSYM(zipPath: String, outputDirectory: String) throws {
    let fileManager = FileManager.default
    let zipURL = URL(fileURLWithPath: zipPath)
    let outputURL = URL(fileURLWithPath: outputDirectory)
    
    // Create output directory
    try fileManager.createDirectory(
        at: outputURL,
        withIntermediateDirectories: true
    )
    
    // Unzip using Foundation (macOS 10.15+)
    try fileManager.unzipItem(at: zipURL, to: outputURL)
    
    print("✓ Unzipped to: \(outputDirectory)")
}
```

### Complete MCP Tool Implementation

```swift
// In your MCP server

struct DownloadDSYMsInput: Codable {
    let buildId: String
    let outputPath: String
}

func handleDownloadDSYMs(_ input: DownloadDSYMsInput) async throws -> String {
    // 1. Get build from App Store Connect
    let build = try await client.send(
        Resources.v1.builds
            .id(input.buildId)
            .get(parameters: .init(include: [.buildBundles]))
    )
    
    // 2. Extract dSYM URL
    guard let buildBundles = build.included,
          let dSYMUrl = buildBundles.first?.attributes?.dSYMUrl else {
        throw DSYMError.noURLAvailable
    }
    
    // 3. Download (pure Swift)
    let zipPath = "\(input.outputPath)/dsyms.zip"
    try await downloadDSYM(from: dSYMUrl, to: zipPath)
    
    // 4. Unzip (pure Swift)
    try unzipDSYM(zipPath: zipPath, outputDirectory: input.outputPath)
    
    // 5. Clean up zip
    try FileManager.default.removeItem(atPath: zipPath)
    
    return "Downloaded and extracted dSYMs to: \(input.outputPath)"
}
```

## Important Note: Bitcode is Deprecated

Starting with Xcode 14, bitcode is no longer required and the App Store no longer accepts bitcode submissions. Debug symbols for past bitcode submissions remain available for download.

**This means:**
- For Xcode 14+ projects: dSYMs from App Store Connect are mostly irrelevant
- Use local archive dSYMs instead (much faster)
- Only download from App Store Connect for legacy bitcode builds

## Recommended Approach: Local Archive First

For most workflows, skip App Store Connect downloads entirely:

```swift
struct UploadDSYMsInput: Codable {
    let appName: String  // Optional: to find the right archive
    let archivePath: String?  // Optional: manual path
}

func handleUploadDSYMs(_ input: UploadDSYMsInput) async throws -> String {
    // 1. Find latest archive (no API call needed)
    let archivePath = input.archivePath ?? findLatestArchive()
    
    // 2. Get dSYMs from archive (instant, no download)
    let dsymPath = "\(archivePath)/dSYMs"
    
    // 3. Verify dSYMs exist
    let fileManager = FileManager.default
    guard fileManager.fileExists(atPath: dsymPath) else {
        throw DSYMError.noDSYMsInArchive
    }
    
    // 4. Upload to Firebase (bash script or pure Swift HTTP POST)
    try await uploadToFirebase(dsymPath: dsymPath)
    
    return "Uploaded dSYMs from archive: \(archivePath)"
}

func findLatestArchive() -> String {
    let archivesPath = "\(NSHomeDirectory())/Library/Developer/Xcode/Archives"
    // Find most recent .xcarchive
    // Return path
}
```

## Two-Workflow Strategy

### Workflow A: Local Archive (Fast, Recommended)
Use this for fresh builds:
1. Archive in Xcode
2. Find archive path
3. Get dSYMs directly from archive/dSYMs/
4. Upload to Firebase

**No API calls, no downloads, instant**

### Workflow B: App Store Connect (Slow, Legacy Only)
Only use for:
- Historical bitcode builds
- Builds not available locally
- Recovery scenarios

1. Find build via API
2. Get dSYMUrl from build bundles
3. Download with URLSession
4. Unzip
5. Upload to Firebase

## Updated MCP Tools

Simplify your MCP to two main tools:

### Tool 1: `upload_local_dsyms`
```json
{
  "name": "upload_local_dsyms",
  "description": "Upload dSYMs from local Xcode archive to Firebase (fast)",
  "inputSchema": {
    "type": "object",
    "properties": {
      "archive_path": {
        "type": "string",
        "description": "Path to .xcarchive, or auto-find latest"
      },
      "firebase_plist": {
        "type": "string", 
        "description": "Path to GoogleService-Info.plist"
      }
    }
  }
}
```

### Tool 2: `download_app_store_dsyms` 
```json
{
  "name": "download_app_store_dsyms",
  "description": "Download dSYMs from App Store Connect (legacy bitcode only)",
  "inputSchema": {
    "type": "object",
    "properties": {
      "build_id": {
        "type": "string",
        "description": "Build ID from App Store Connect"
      },
      "output_path": {
        "type": "string",
        "description": "Where to save dSYMs"
      }
    },
    "required": ["build_id", "output_path"]
  }
}
```

## No Subprocess Needed

Everything is pure Swift:
- ✅ URLSession for downloads
- ✅ FileManager for file operations
- ✅ Foundation unzipItem for extraction
- ✅ No Ruby
- ✅ No Fastlane
- ✅ No bash subprocesses

## Firebase Upload (Still Needs Bash)

Firebase upload script is still bash-based, but that's Firebase's requirement, not ours:

```swift
// This is acceptable - it's Firebase's tool
func uploadToFirebase(dsymPath: String, plistPath: String) throws {
    let script = "./Pods/FirebaseCrashlytics/upload-symbols"
    let process = Process()
    process.executableURL = URL(fileURLWithPath: script)
    process.arguments = ["-gsp", plistPath, "-p", "ios", dsymPath]
    try process.run()
    process.waitUntilExit()
}
```

Alternatively, use Firebase's REST API (pure Swift HTTP):
```swift
// Future enhancement: Direct Firebase API upload
// No bash script needed
```

## Summary

**Don't use Fastlane approach.** Instead:

1. **For fresh builds:** Use local archives (instant, no API)
2. **For legacy builds:** Use asc-swift + URLSession (pure Swift)
3. **Firebase upload:** Use their script (or implement REST API later)

**Zero Ruby, zero Fastlane, zero unnecessary complexity.** 🎯

## Tell Claude Code

```
Don't add Fastlane subprocess support. Instead:

1. For downloading from App Store Connect:
   - Use asc-swift to get build with dSYMUrl
   - Download with URLSession (pure Swift)
   - Unzip with FileManager.unzipItem

2. For most workflows:
   - Use local archive dSYMs directly
   - Path: ~/Library/Developer/Xcode/Archives/[date]/[app].xcarchive/dSYMs/
   - No API calls needed

Keep it pure Swift. No Ruby. No Fastlane.
```
