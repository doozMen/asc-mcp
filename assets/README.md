# Plugin Assets

This directory contains visual assets for the App Store Connect MCP Plugin marketplace listing.

## Required Assets

### Icon (Required)

**Filename:** `icon.png`

**Specifications:**
- **Size:** 1024x1024px (minimum 512x512px)
- **Format:** PNG with transparency
- **Style:** Professional, recognizable at small sizes
- **Content:** App Store Connect + Firebase Crashlytics branding
- **Design Guidelines:**
  - Use iOS/Swift recognizable elements
  - Include App Store Connect blue
  - Optional: Firebase Crashlytics flame icon
  - Avoid text (icon should work at any size)

**Example Concept:**
- iOS app icon style with rounded corners
- App Store Connect blue background
- White Swift bird silhouette or dSYM symbol
- Optional flame accent for Crashlytics integration

### Screenshots (3-5 recommended)

**Filenames:** `screenshot-1.png` through `screenshot-5.png`

**Specifications:**
- **Size:** 1280x800px or larger (16:10 aspect ratio recommended)
- **Format:** PNG or JPEG
- **Quality:** High resolution, readable text

#### Screenshot 1: Download Latest dSYMs
**Caption:** "Download latest dSYMs with single command"

**Content:**
- Show Claude Code interface
- User asking: "Download the latest dSYMs for my app"
- Claude executing workflow
- Success message with file location

#### Screenshot 2: Upload to Firebase Crashlytics
**Caption:** "Upload dSYMs to Firebase Crashlytics automatically"

**Content:**
- Show Firebase upload workflow
- User requesting upload
- Claude downloading from App Store Connect
- Upload success confirmation

#### Screenshot 3: Check Build Status
**Caption:** "Check build status across all apps"

**Content:**
- Show list_apps or list_builds output
- Multiple apps displayed
- Version numbers, build numbers, dates
- Status indicators (TestFlight, App Store)

#### Screenshot 4: Interactive Credential Setup
**Caption:** "Interactive credential setup guide"

**Content:**
- Show /setup-credentials command
- Step-by-step guidance
- Security best practices
- Successful configuration

#### Screenshot 5: Find Xcode Archives
**Caption:** "Find and manage Xcode archives"

**Content:**
- Show find_xcode_archives output
- List of local archives
- Dates, versions, build numbers
- dSYM availability indicators

## Creating Assets

### Icon Design

If you don't have design tools, you can:

1. **Use SF Symbols (macOS):**
   - App: SF Symbols app (included with Xcode)
   - Export at 1024x1024px
   - Use symbols: "swift", "app.badge", "flame"

2. **Use Online Tools:**
   - [Canva](https://www.canva.com) - Free icon templates
   - [Figma](https://www.figma.com) - Professional design tool
   - [GIMP](https://www.gimp.org) - Free image editor

3. **Use AI Generation:**
   - Request icon generation from Claude with specific requirements
   - Refine with editing tools

### Screenshot Capture

1. **Use Claude Code in action:**
   - Actually use the plugin
   - Capture real interactions
   - Show authentic output

2. **Screen Capture (macOS):**
   - Cmd+Shift+4: Select area
   - Cmd+Shift+5: Screenshot tool with options
   - Capture at Retina resolution

3. **Edit for Clarity:**
   - Annotate with arrows/highlights if needed
   - Redact sensitive information (app IDs, keys)
   - Ensure text is readable
   - Crop to relevant content

### Example Screenshot Flow

**Good Screenshot:**
```
┌────────────────────────────────────────┐
│ Claude Code                        × │
├────────────────────────────────────────┤
│ You:                                   │
│ Download the latest dSYMs for my app   │
│                                        │
│ Claude:                                │
│ What's your app's bundle ID?           │
│                                        │
│ You:                                   │
│ com.example.myapp                      │
│                                        │
│ Claude:                                │
│ [Using get_app_status...]              │
│ Found: MyApp (v2.1.0, build 42)        │
│                                        │
│ [Using get_latest_build...]            │
│ Latest build: 42 (2025-10-24)          │
│                                        │
│ [Using download_dsyms...]              │
│ ✓ dSYMs downloaded successfully!       │
│ Location: /Users/you/dsyms/...         │
└────────────────────────────────────────┘
```

**Bad Screenshot:**
- Blurry or low resolution
- Text too small to read
- Shows errors or incomplete operations
- Contains sensitive/personal information
- Cluttered with irrelevant UI elements

## Asset Hosting

### GitHub Raw URLs (Recommended)

Once assets are committed to the repository:

```
https://raw.githubusercontent.com/doozMen/asc-mcp/main/assets/icon.png
https://raw.githubusercontent.com/doozMen/asc-mcp/main/assets/screenshot-1.png
```

These URLs are used in:
- `plugin.json` (icon field)
- `submission-metadata.json` (icon and screenshots fields)
- `marketplace.json` (optional)

### Alternative Hosting

If needed, you can also use:
- GitHub Releases (attach assets to release)
- CDN services (Cloudinary, imgix)
- Your own hosting

**Important:** Use HTTPS URLs that are publicly accessible.

## Asset Checklist

Before submitting to marketplace:

- [ ] Icon created (1024x1024px PNG)
- [ ] 3-5 screenshots captured
- [ ] All images are high quality
- [ ] No sensitive information visible
- [ ] Assets committed to repository
- [ ] GitHub raw URLs verified accessible
- [ ] URLs updated in manifests:
  - [ ] `.claude-plugin/plugin.json`
  - [ ] `.claude-plugin/submission-metadata.json`
  - [ ] `.claude-plugin/marketplace.json` (if using)
- [ ] Images display correctly in browser

## Current Status

**TODO:** Assets need to be created

1. Create icon.png (1024x1024px)
2. Capture 5 screenshots showing plugin features
3. Commit assets to repository
4. Update manifest files with GitHub raw URLs
5. Verify URLs are accessible

## Need Help?

If you need assistance with asset creation:

1. **Icon Design:**
   - Ask Claude to generate concepts
   - Use design tools mentioned above
   - Community contributions welcome

2. **Screenshots:**
   - Install and use the plugin
   - Capture real interactions
   - Edit for clarity

3. **Contributions:**
   - Fork repository
   - Add assets
   - Submit pull request

Thank you for helping make this plugin discoverable!
