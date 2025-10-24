# Firebase Crashlytics dSYM Upload - Complete Guide

## Important: Firebase CLI vs dSYM Upload

**Firebase CLI (`firebase-tools`)** and **gcloud** are NOT used for dSYM uploads:
- ❌ `firebase-tools` - For web/backend Firebase features (hosting, functions, etc.)
- ❌ `gcloud` - For Google Cloud Platform infrastructure
- ✅ **Firebase iOS SDK upload script** - The correct tool for dSYM uploads

## The Right Tool: Firebase Crashlytics Upload Script

Firebase provides a dedicated upload script in the iOS SDK:
- **CocoaPods:** `./Pods/FirebaseCrashlytics/upload-symbols`
- **SPM:** Usually in DerivedData or build folder

## Three Upload Methods

### Method 1: Command Line Upload (Recommended for Automation)

This is what your MCP should use:

```bash
# Basic usage
./Pods/FirebaseCrashlytics/upload-symbols \
  -gsp /path/to/GoogleService-Info.plist \
  -p ios \
  /path/to/dSYMs

# Real example with local archive
./Pods/FirebaseCrashlytics/upload-symbols \
  -gsp ./GoogleService-Info.plist \
  -p ios \
  ~/Library/Developer/Xcode/Archives/2025-10-24/MyApp.xcarchive/dSYMs

# Upload specific dSYM file
./Pods/FirebaseCrashlytics/upload-symbols \
  -gsp ./GoogleService-Info.plist \
  -p ios \
  ~/Library/Developer/Xcode/Archives/2025-10-24/MyApp.xcarchive/dSYMs/MyApp.app.dSYM

# Upload zip file
./Pods/FirebaseCrashlytics/upload-symbols \
  -gsp ./GoogleService-Info.plist \
  -p ios \
  ./dSYMs.zip
```

**Parameters:**
- `-gsp` - Path to GoogleService-Info.plist
- `-p` - Platform (ios, mac, tvos)
- Last argument - Path to dSYM file(s), directory, or zip

### Method 2: Firebase Console Upload (Manual)

For one-off uploads:

1. Go to Firebase Console → Crashlytics → dSYMs tab
2. Click "Upload dSYM"
3. Drag and drop your .zip file containing dSYMs

**When to use:** Testing, emergency uploads, one-time fixes

### Method 3: Automatic Upload via Xcode Build Phase

For automatic uploads on every build:

1. Open Xcode → Your Target → Build Phases
2. Add "New Run Script Phase"
3. Add this script:

```bash
"${PODS_ROOT}/FirebaseCrashlytics/run"
```

**Important:** For Xcode 15+, add Input Files:

```
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}
$(TARGET_BUILD_DIR)/$(EXECUTABLE_PATH)
```

**When to use:** Development builds, continuous integration

## Pure Swift Implementation for MCP

```swift
import Foundation

struct FirebaseDSYMUploader {
    let googleServiceInfoPath: String
    let uploadScriptPath: String
    
    init(projectPath: String) {
        self.googleServiceInfoPath = "\(projectPath)/GoogleService-Info.plist"
        
        // Auto-detect upload script location
        if FileManager.default.fileExists(atPath: "\(projectPath)/Pods/FirebaseCrashlytics/upload-symbols") {
            self.uploadScriptPath = "\(projectPath)/Pods/FirebaseCrashlytics/upload-symbols"
        } else {
            // Try to find in SPM build folder
            self.uploadScriptPath = findSPMUploadScript(projectPath: projectPath)
        }
    }
    
    func upload(dsymPath: String) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: uploadScriptPath)
        process.arguments = [
            "-gsp", googleServiceInfoPath,
            "-p", "ios",
            dsymPath
        ]
        
        // Capture output
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        // Read output
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        let output = String(data: outputData, encoding: .utf8) ?? ""
        let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
        
        if process.terminationStatus != 0 {
            throw FirebaseUploadError.uploadFailed(errorOutput)
        }
        
        print("✓ Firebase upload successful")
        if !output.isEmpty {
            print(output)
        }
    }
    
    private func findSPMUploadScript(projectPath: String) -> String {
        // Look in common SPM locations
        // This is a simplified version - you'd need to search properly
        return "/path/to/spm/upload-symbols"
    }
}

enum FirebaseUploadError: Error {
    case uploadFailed(String)
    case scriptNotFound
}
```

## MCP Tool Implementation

```swift
struct UploadDSYMsToFirebaseInput: Codable {
    let dsymPath: String  // Can be directory, single .dSYM, or .zip
    let projectPath: String  // For finding GoogleService-Info.plist
}

func handleUploadDSYMsToFirebase(_ input: UploadDSYMsToFirebaseInput) async throws -> String {
    let uploader = FirebaseDSYMUploader(projectPath: input.projectPath)
    try await uploader.upload(dsymPath: input.dsymPath)
    
    return """
    ✓ dSYMs uploaded to Firebase Crashlytics
    
    View crashes at:
    https://console.firebase.google.com/project/[your-project]/crashlytics
    """
}
```

## Complete Workflow: Archive → Firebase

### Workflow A: Fresh Build (Fastest)

```swift
func uploadFromLatestArchive(projectPath: String) async throws {
    // 1. Find latest archive
    let archivesPath = "\(NSHomeDirectory())/Library/Developer/Xcode/Archives"
    let archives = try FileManager.default
        .contentsOfDirectory(atPath: archivesPath)
        .sorted(by: >)
    
    guard let latestArchive = archives.first else {
        throw DSYMError.noArchiveFound
    }
    
    // 2. Get dSYM path from archive
    let dsymPath = "\(archivesPath)/\(latestArchive)/dSYMs"
    
    // 3. Upload to Firebase
    let uploader = FirebaseDSYMUploader(projectPath: projectPath)
    try await uploader.upload(dsymPath: dsymPath)
}
```

### Workflow B: From App Store Connect (Slower)

```swift
func uploadFromAppStoreConnect(buildId: String, projectPath: String) async throws {
    // 1. Download from App Store Connect (see PURE_SWIFT_DSYM_SOLUTION.md)
    let tempPath = "/tmp/dsyms-\(UUID().uuidString)"
    try await downloadDSYMsFromASC(buildId: buildId, outputPath: tempPath)
    
    // 2. Upload to Firebase
    let uploader = FirebaseDSYMUploader(projectPath: projectPath)
    try await uploader.upload(dsymPath: tempPath)
    
    // 3. Clean up
    try FileManager.default.removeItem(atPath: tempPath)
}
```

## Error Handling

### Common Errors and Solutions

**Error: "Script not found"**
```
Solution: Verify Firebase SDK is installed
CocoaPods: Check Podfile includes Firebase/Crashlytics
SPM: Verify package is added to project
```

**Error: "GoogleService-Info.plist not found"**
```
Solution: Provide correct path with -gsp flag
Common locations:
- Project root
- App target folder
- Build output folder
```

**Error: "Invalid dSYM path"**
```
Solution: Verify path points to:
- .dSYM file
- Directory containing .dSYM files
- .zip file containing dSYMs
```

**Error: "Upload successful but still showing missing dSYMs in console"**
```
Solution: 
1. Wait 5-10 minutes for processing
2. Verify UUID matches between crash and dSYM
3. Check Debug Information Format = DWARF with dSYM File
```

## Finding Upload Script Location

### CocoaPods (Easy)
```bash
ls -la ./Pods/FirebaseCrashlytics/upload-symbols
```

### SPM (Needs Search)
```bash
# Find in DerivedData
find ~/Library/Developer/Xcode/DerivedData -name "upload-symbols" -type f

# Or in build folder
find . -name "upload-symbols" -type f
```

### Verify Script Works
```bash
# Test the script
./Pods/FirebaseCrashlytics/upload-symbols --help

# Should show usage information
```

## MCP Tool Definitions

### Tool 1: upload_dsyms_to_firebase

```json
{
  "name": "upload_dsyms_to_firebase",
  "description": "Upload dSYMs to Firebase Crashlytics from local path",
  "inputSchema": {
    "type": "object",
    "properties": {
      "dsym_path": {
        "type": "string",
        "description": "Path to dSYM file, directory, or zip"
      },
      "project_path": {
        "type": "string",
        "description": "Path to Xcode project (for GoogleService-Info.plist)"
      },
      "google_service_plist": {
        "type": "string",
        "description": "Optional: explicit path to GoogleService-Info.plist"
      }
    },
    "required": ["dsym_path", "project_path"]
  }
}
```

### Tool 2: upload_archive_to_firebase

```json
{
  "name": "upload_archive_to_firebase",
  "description": "Find latest archive and upload dSYMs to Firebase",
  "inputSchema": {
    "type": "object",
    "properties": {
      "project_path": {
        "type": "string",
        "description": "Path to Xcode project"
      },
      "archive_path": {
        "type": "string",
        "description": "Optional: specific archive path, or auto-find latest"
      }
    },
    "required": ["project_path"]
  }
}
```

## Comparison: Upload Methods

| Method | Speed | Automation | Use Case |
|--------|-------|------------|----------|
| Command Line | Fast | ✅ Easy | CI/CD, automation |
| Console Upload | Medium | ❌ Manual | One-off, testing |
| Xcode Build Phase | Fast | ✅ Automatic | Development builds |
| MCP Tool | Fast | ✅ On-demand | Developer workflow |

## Best Practice: Two-Step Process

### For Alexandre's Workflow:

**Step 1: Archive in Xcode**
- Normal Xcode archive process
- dSYMs generated locally

**Step 2: Upload to Firebase (via MCP)**
```
User: Upload dSYMs to Firebase

Agent: 
Finding latest archive... ✓
Archive: MyApp.xcarchive (Build 1.2.3)
Uploading to Firebase... ✓

Done! View crashes:
https://console.firebase.google.com/project/myapp/crashlytics
```

## Configuration Requirements

### Prerequisites

1. **Firebase iOS SDK installed** (CocoaPods or SPM)
2. **GoogleService-Info.plist** in project
3. **Debug Information Format** = DWARF with dSYM File
4. **Crashlytics enabled** in Firebase Console

### Verify Setup

```bash
# 1. Check upload script exists
ls -la ./Pods/FirebaseCrashlytics/upload-symbols

# 2. Check GoogleService-Info.plist exists
ls -la ./GoogleService-Info.plist

# 3. Test upload with dummy path
./Pods/FirebaseCrashlytics/upload-symbols -gsp ./GoogleService-Info.plist -p ios --help
```

## Summary for Your MCP

**Recommended Implementation:**

1. **Primary Tool:** `upload_archive_to_firebase`
   - Finds latest archive automatically
   - Gets dSYMs from archive/dSYMs/
   - Uploads using Firebase upload-symbols script
   - Fast and simple

2. **Secondary Tool:** `upload_dsyms_to_firebase`
   - For custom dSYM paths
   - Flexible input (file, directory, zip)
   - Same upload mechanism

3. **No TestFlight Upload Needed for Firebase**
   - Firebase only needs dSYMs
   - TestFlight is separate (optional)
   - Can upload to Firebase before/after/without TestFlight

**Key Point:** Firebase dSYM upload is **completely independent** from App Store Connect/TestFlight uploads. You can upload dSYMs to Firebase directly from your local archive without ever touching TestFlight.

## Architecture Decision

```
Local Archive → Firebase Crashlytics ✅ (Fast, recommended)
        ↓
        ↓ (optional, separate workflow)
        ↓
App Store Connect/TestFlight ✅ (For distribution)
```

Not:
```
Archive → App Store Connect → Download → Firebase ❌ (Slow, unnecessary)
```

## Tell Claude Code

```
For Firebase Crashlytics upload:

1. Use Firebase's upload-symbols script (comes with iOS SDK)
2. Location: ./Pods/FirebaseCrashlytics/upload-symbols
3. Command format:
   ./Pods/FirebaseCrashlytics/upload-symbols \
     -gsp GoogleService-Info.plist \
     -p ios \
     /path/to/dSYMs

4. For automation: wrap this in Swift Process execution
5. No Firebase CLI or gcloud needed - they're for different features
6. Upload directly from local archive (fastest)
7. TestFlight upload is separate and optional
```
