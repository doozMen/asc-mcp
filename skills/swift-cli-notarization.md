# Swift CLI Notarization Skill

Reference guide for building, signing, notarizing, and distributing Swift command-line tools without Xcode GUI.

## Swift Package Manager CLI Setup

### Initialize Project

```bash
# Create new executable project
mkdir my-cli
cd my-cli
swift package init --type executable

# Project structure created:
# ├── Package.swift
# ├── Sources/
# │   └── my-cli/
# │       └── main.swift
# └── Tests/
```

### Build for Release

```bash
# Build release binary (optimized)
swift build -c release

# Binary location
# .build/release/my-cli

# Verify binary works
./.build/release/my-cli --version
```

## Code Signing

### Prerequisites

- Developer ID Application certificate (from Apple Developer account)
- `xcode-select --install` (command line tools only, no Xcode needed)
- Entitlements plist (for hardened runtime)

### Entitlements File

Create `entitlements.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <false/>
    <key>com.apple.security.cs.disable-executable-page-protect</key>
    <false/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <false/>
    <key>com.apple.security.get-task-allow</key>
    <false/>
</dict>
</plist>
```

### Sign Binary

```bash
# Get certificate name
security find-identity -v -p codesigning

# Find Developer ID Application certificate
# "Developer ID Application: Your Name (TEAM_ID)"

# Set variables
BINARY_NAME="my-cli"
IDENTITY="Developer ID Application: Your Name (TEAM_ID)"

# Copy binary to project root
cp .build/release/$BINARY_NAME ./$BINARY_NAME

# Sign binary
codesign --sign "$IDENTITY" \
  --options runtime \
  --entitlements entitlements.plist \
  --timestamp \
  --force \
  ./$BINARY_NAME

# Verify signature
codesign -vvv --deep --strict ./$BINARY_NAME

# Check signature details
codesign -dv ./$BINARY_NAME
```

## Notarization

### Prepare Submission

```bash
BINARY_NAME="my-cli"

# Create zip for notarization
ditto -c -k --keepParent ./$BINARY_NAME ${BINARY_NAME}.zip

# Verify zip contents
unzip -l ${BINARY_NAME}.zip
```

### Submit for Notarization

```bash
# Requirements:
# - Apple ID (email)
# - Team ID
# - App-specific password (generate at appleid.apple.com > Security)

xcrun notarytool submit ${BINARY_NAME}.zip \
  --apple-id "your@email.com" \
  --team-id "TEAM_ID" \
  --password "app-specific-password" \
  --wait

# Output example:
# id: 12345-67890-abcdef-ghijk
# status: Accepted
```

### Staple Ticket

```bash
# Attach notarization ticket to binary
xcrun stapler staple ./$BINARY_NAME

# Verify stapling
xcrun stapler validate ./$BINARY_NAME
```

## Distribution Workflow

### Complete Release Script

```bash
#!/bin/bash
set -e

BINARY_NAME="my-cli"
IDENTITY="Developer ID Application: Your Name (TEAM_ID)"
APPLE_ID="your@email.com"
TEAM_ID="TEAM_ID"
APP_PASSWORD="app-specific-password"

echo "🔨 Building release binary..."
swift build -c release

echo "📋 Signing binary..."
cp .build/release/$BINARY_NAME ./$BINARY_NAME

codesign --sign "$IDENTITY" \
  --options runtime \
  --entitlements entitlements.plist \
  --timestamp \
  --force \
  ./$BINARY_NAME

echo "✅ Verifying signature..."
codesign -vvv --deep --strict ./$BINARY_NAME

echo "📦 Preparing for notarization..."
ditto -c -k --keepParent ./$BINARY_NAME ${BINARY_NAME}.zip

echo "🍎 Submitting for notarization..."
xcrun notarytool submit ${BINARY_NAME}.zip \
  --apple-id "$APPLE_ID" \
  --team-id "$TEAM_ID" \
  --password "$APP_PASSWORD" \
  --wait

echo "🎁 Stapling notarization ticket..."
xcrun stapler staple ./$BINARY_NAME

echo "✅ Release binary ready: ./$BINARY_NAME"
```

## File Access and Permissions

### Runtime File Access

Swift CLI tools on macOS need explicit user permissions for file access:

```swift
import Foundation

// Check file access capabilities
func checkFileAccess() {
    let testPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Documents")

    if !FileManager.default.isReadableFile(atPath: testPath.path) {
        print("⚠️  Need file access permissions")
        print("macOS will prompt when you try to access protected files")
        print("Allow access in System Settings > Privacy & Security")
    }
}

// Request permission for file dialog (for CLI tools)
func requestFileAccess() {
    let openPanel = NSOpenPanel()
    openPanel.message = "Select file to process:"
    openPanel.showsResizableHiddenFilesPanel = true
    openPanel.canChooseFiles = true
    openPanel.canChooseDirectories = false

    if openPanel.runModal() == .OK,
       let url = openPanel.url {
        // User selected file
        processFile(at: url)
    }
}

// Import for file access
import AppKit
```

### User Data Protection

For tools accessing sensitive locations:

```bash
# User must explicitly grant permission
# System Settings > Privacy & Security > Files and Folders

# Request folder access in entitlements
defaults write com.apple.LaunchServices/com.yourcompany.yourapp \
  LSFileQuarantineEnabled -bool false
```

## Distribution Methods

### Direct Download

```bash
# GitHub releases with pre-signed binaries
# Users can verify signature:
codesign -vvv --deep --strict ~/Downloads/my-cli

# Or use:
spctl -a -v ~/Downloads/my-cli
```

### Homebrew Distribution

```ruby
# Formula: my-cli.rb
class MyCli < Formula
  desc "My command line tool"
  homepage "https://github.com/yourrepo/my-cli"
  version "1.0.0"

  url "https://github.com/yourrepo/my-cli/releases/download/v1.0.0/my-cli"
  sha256 "abc123..."

  def install
    bin.install "my-cli"
  end

  test do
    assert_match /version 1.0.0/, shell_output("#{bin}/my-cli --version")
  end
end
```

### SPM experimental-install

```bash
# Users can install directly:
swift package experimental-install \
  --product my-cli \
  https://github.com/yourrepo/my-cli.git
```

## Troubleshooting

### Signature Issues

```bash
# Check signature validity
codesign -v ./$BINARY_NAME

# Remove old signature
codesign --remove-signature ./$BINARY_NAME

# Re-sign
codesign --sign "$IDENTITY" --options runtime \
  --entitlements entitlements.plist \
  --timestamp --force ./$BINARY_NAME
```

### Notarization Failures

```bash
# Get detailed notarization status
xcrun notarytool info [SUBMISSION_ID] \
  --apple-id "your@email.com" \
  --team-id "TEAM_ID" \
  --password "app-specific-password"

# Download notarization log
xcrun notarytool log [SUBMISSION_ID] \
  --apple-id "your@email.com" \
  --team-id "TEAM_ID" \
  --password "app-specific-password" \
  notification.json

# Common issues:
# - Code not hardened (add entitlements)
# - Code contains unsigned dependencies (rebuild)
# - Ad-hoc signing used (must use Developer ID)
```

### Gatekeeper Bypass

Users can run unsigned/unnotarized CLI tools:

```bash
# Remove quarantine flag
xattr -d com.apple.quarantine ./my-cli

# Or allow in System Settings > Security & Privacy
# Click "Open" when warned about unidentified developer
```

## Best Practices

1. **Version Management**: Use semantic versioning (1.0.0)
2. **Release Notes**: Document signing certificate, notarization status
3. **User Communication**: Explain why notarization is needed
4. **Incremental Releases**: Test with beta users before release
5. **Keep Certificates Fresh**: Renew Developer ID certificates annually
6. **Automate Signing**: Include in CI/CD pipeline (GitHub Actions, etc)
7. **Test Locally**: Verify both signed and unsigned binary behavior

## Related Resources

- [App Store Connect MCP](../README.md) - Manage builds via App Store Connect API
- [Firebase Integration](../docs/firebase-integration.md) - Upload dSYMs for crash symbolication
- [Apple Code Signing Documentation](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
