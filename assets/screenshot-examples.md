# Screenshot Examples for App Store Connect MCP Plugin

This document contains example command outputs that should be captured as screenshots for the marketplace listing.

## Screenshot 1: Download Latest dSYMs

**Caption:** "Download latest dSYMs with single command"

**Example Interaction:**

```
You:
Download the latest dSYMs for com.example.myapp

Claude:
I'll download the latest dSYMs for your app. Let me get the latest build information.

[Using get_app_status tool]
Found app: MyApp
Bundle ID: com.example.myapp
App ID: 1234567890

[Using get_latest_build tool]
Latest build found:
- Version: 2.1.0
- Build Number: 42
- Upload Date: 2025-10-24
- Processing Status: VALID

[Using download_dsyms tool]
Downloading dSYMs from App Store Connect...
Download complete: 12.4 MB
Extracting dSYMs...
✓ Successfully extracted dSYM files

Location: /Users/developer/dsyms/MyApp-2.1.0-42/
Files:
- MyApp.app.dSYM
- MyFramework.framework.dSYM
- MyExtension.appex.dSYM

Next steps:
- Upload to Firebase Crashlytics with /upload-dsyms-to-crashlytics
- Use for local crash symbolication
```

---

## Screenshot 2: Upload to Firebase Crashlytics

**Caption:** "Upload dSYMs to Firebase Crashlytics automatically"

**Example Interaction:**

```
You:
Upload the latest dSYMs to Firebase Crashlytics for my app

Claude:
I'll help you upload dSYMs to Firebase Crashlytics. What's your Firebase app ID?

You:
1:123456789012:ios:abc123def456

Claude:
[Using get_app_status tool]
Found app: MyApp (com.example.myapp)

[Using get_latest_build tool]
Latest build: 2.1.0 (build 42)

[Using upload_dsyms_to_firebase tool]
Uploading dSYMs to Firebase Crashlytics...

Source: App Store Connect build abc123-def456
Firebase App: 1:123456789012:ios:abc123def456

Upload progress:
✓ MyApp.app.dSYM (8.2 MB)
✓ MyFramework.framework.dSYM (3.1 MB)
✓ MyExtension.appex.dSYM (1.1 MB)

✓ Successfully uploaded 3 dSYM files to Firebase Crashlytics

Verification:
- Check Firebase Console: Crashlytics > Settings > dSYM Files
- New crashes will now be symbolicated with build 2.1.0 (42)
```

---

## Screenshot 3: Check Build Status

**Caption:** "Check build status across all apps"

**Example Interaction:**

```
You:
Show me the status of all my apps in App Store Connect

Claude:
[Using list_apps tool]
Found 4 apps in your App Store Connect account:

1. MyApp
   Bundle ID: com.example.myapp
   App ID: 1234567890
   Latest Version: 2.1.0 (build 42)
   Status: Ready for Sale
   Last Updated: 2025-10-24

2. MyApp Pro
   Bundle ID: com.example.myapp.pro
   App ID: 1234567891
   Latest Version: 3.0.1 (build 67)
   Status: In Review
   Submitted: 2025-10-23

3. MyApp Lite
   Bundle ID: com.example.myapp.lite
   App ID: 1234567892
   Latest Version: 1.5.2 (build 28)
   Status: Ready for Sale
   Last Updated: 2025-10-15

4. Internal Testing App
   Bundle ID: com.example.internal
   App ID: 1234567893
   Latest Version: 0.9.0 (build 5)
   Status: TestFlight Only
   Last Updated: 2025-10-20

Total: 4 apps
```

---

## Screenshot 4: Interactive Credential Setup

**Caption:** "Interactive credential setup guide"

**Example Interaction:**

```
You:
/setup-credentials

Claude:
# App Store Connect API Credentials Setup

I'll guide you through setting up your App Store Connect API credentials securely.

## Step 1: Create API Key in App Store Connect

1. Sign in to App Store Connect: https://appstoreconnect.apple.com
2. Navigate to: Users and Access > Keys
3. Click the + button to create a new API key
4. Choose a name: "MCP Server"
5. Select access: "Developer" role (minimum required)
6. Click "Generate"

## Step 2: Download Your Private Key

⚠️ Important: You can only download this once!

1. Download the .p8 file (e.g., AuthKey_ABCD1234.p8)
2. Save it securely (recommended: ~/.config/appstoreconnect/)
3. Note the Key ID (shown above the key name)
4. Note the Issuer ID (shown at the top of the Keys page)

## Step 3: Configure Environment Variables

Add these to your Claude Code configuration:

ASC_KEY_ID=ABCD1234
ASC_ISSUER_ID=12345678-1234-1234-1234-123456789012
ASC_PRIVATE_KEY_PATH=/Users/you/.config/appstoreconnect/AuthKey_ABCD1234.p8

## Step 4: Test Connection

Would you like me to test your credentials by listing your apps?

You:
Yes, test the connection

Claude:
[Using list_apps tool]
✓ Successfully connected to App Store Connect API
✓ Found 4 apps in your account

Your credentials are working correctly!
```

---

## Screenshot 5: Find Xcode Archives

**Caption:** "Find and manage Xcode archives"

**Example Interaction:**

```
You:
Find all Xcode archives for MyApp

Claude:
[Using find_xcode_archives tool]
Searching Xcode archives in: ~/Library/Developer/Xcode/Archives

Found 5 archives for "MyApp":

1. MyApp 2.1.0 (42)
   Date: 2025-10-24 14:32:15
   Bundle ID: com.example.myapp
   Path: ~/Library/Developer/Xcode/Archives/2025-10-24/MyApp 2025-10-24, 2.32 PM.xcarchive
   dSYMs: ✓ Available (3 files, 12.4 MB)

2. MyApp 2.0.1 (38)
   Date: 2025-10-20 11:15:42
   Bundle ID: com.example.myapp
   Path: ~/Library/Developer/Xcode/Archives/2025-10-20/MyApp 2025-10-20, 11.15 AM.xcarchive
   dSYMs: ✓ Available (3 files, 11.8 MB)

3. MyApp 2.0.0 (35)
   Date: 2025-10-15 16:48:23
   Bundle ID: com.example.myapp
   Path: ~/Library/Developer/Xcode/Archives/2025-10-15/MyApp 2025-10-15, 4.48 PM.xcarchive
   dSYMs: ✓ Available (3 files, 11.2 MB)

4. MyApp 1.9.5 (33)
   Date: 2025-10-10 09:22:18
   Bundle ID: com.example.myapp
   Path: ~/Library/Developer/Xcode/Archives/2025-10-10/MyApp 2025-10-10, 9.22 AM.xcarchive
   dSYMs: ✓ Available (3 files, 10.9 MB)

5. MyApp 1.9.4 (31)
   Date: 2025-10-05 13:55:07
   Bundle ID: com.example.myapp
   Path: ~/Library/Developer/Xcode/Archives/2025-10-05/MyApp 2025-10-05, 1.55 PM.xcarchive
   dSYMs: ✓ Available (3 files, 10.7 MB)

Total archives: 5
Total size: 60.3 MB

You can upload dSYMs from any archive using:
/upload-dsyms-to-crashlytics with archive_path parameter
```

---

## Screenshot Capture Instructions

### For Each Screenshot:

1. **Setup Claude Code Session:**
   - Start fresh conversation
   - Ensure plugin is installed and configured
   - Use realistic app names/IDs (can redact later)

2. **Execute Commands:**
   - Type the example commands above
   - Let Claude execute the actual tools
   - Capture the full interaction

3. **Capture Screenshot:**
   ```bash
   # macOS: Use Cmd+Shift+4 then spacebar to capture window
   # OR use screencapture command:
   screencapture -w -T 0 screenshot-1.png
   # -w: Capture window
   # -T 0: No delay
   ```

4. **Edit Screenshot:**
   - Crop to 1280x800px (or maintain 16:10 ratio)
   - Redact sensitive information:
     - Real app IDs
     - Real bundle IDs
     - API keys/credentials
     - Personal paths (replace with /Users/developer/...)
   - Ensure text is readable
   - Add annotations if needed (arrows, highlights)

5. **Save in Assets Directory:**
   ```bash
   mv screenshot.png /Users/stijnwillems/Developer/asc-mcp/assets/screenshot-1.png
   ```

## Tools for Screenshot Editing

### Basic Editing (macOS):
- **Preview**: Built-in, good for basic crops/annotations
- **Pixelmator**: $39.99, professional quality
- **Acorn**: $29.99, powerful editing

### Advanced Editing:
- **GIMP**: Free, full-featured editor
- **Photoshop**: Professional, subscription
- **Figma**: Free for personal use, web-based

### Screenshot Automation:
```bash
# Create a script to automate screenshots
#!/bin/bash
# Take 5 screenshots with 10-second intervals
for i in {1..5}; do
  echo "Prepare for screenshot $i in 3 seconds..."
  sleep 3
  screencapture -w -T 0 "screenshot-$i.png"
  echo "Screenshot $i captured"
  sleep 7
done
```

## Redaction Tools

### For Sensitive Information:

**Preview (macOS):**
1. Open screenshot
2. Tools > Annotate > Shapes
3. Draw rectangle over sensitive text
4. Fill with solid color
5. Save

**ImageMagick (CLI):**
```bash
# Blur specific region
convert screenshot.png -region 400x50+100+200 -blur 0x8 screenshot-redacted.png

# Add rectangle overlay
convert screenshot.png -fill white -draw "rectangle 100,200,500,250" screenshot-redacted.png
```

## Quality Checklist

Before saving each screenshot:

- [ ] Resolution: 1280x800px minimum
- [ ] Format: PNG (better for text/UI)
- [ ] Text: Readable at full size
- [ ] Sensitive info: Redacted or replaced
- [ ] UI: Clean, professional appearance
- [ ] Content: Shows key feature clearly
- [ ] Caption: Matches screenshot content
- [ ] File size: Under 5MB (compressed PNG)

## Example File Names

Save screenshots as:
- `screenshot-1.png` - Download dSYMs
- `screenshot-2.png` - Upload to Crashlytics
- `screenshot-3.png` - Build status
- `screenshot-4.png` - Credential setup
- `screenshot-5.png` - Xcode archives

## Next Steps

After creating all screenshots:

1. **Commit to Repository:**
   ```bash
   git add assets/screenshot-*.png
   git commit -m "feat(assets): add marketplace screenshots"
   git push origin main
   ```

2. **Update Manifest Files:**
   Update `.claude-plugin/submission-metadata.json` with GitHub raw URLs:
   ```json
   "screenshots": [
     {
       "url": "https://raw.githubusercontent.com/doozMen/asc-mcp/main/assets/screenshot-1.png",
       "caption": "Download latest dSYMs with single command"
     }
     // ... add all 5
   ]
   ```

3. **Verify URLs:**
   Open each GitHub raw URL in browser to confirm accessibility.

4. **Validate Plugin:**
   ```bash
   /plugin validate .
   ```

## Alternative: Use Actual Plugin Output

If you prefer real screenshots over examples:

1. Install the plugin locally
2. Run actual commands with real data
3. Capture genuine interactions
4. Redact sensitive information afterward

This provides authentic screenshots showing the plugin working correctly.
