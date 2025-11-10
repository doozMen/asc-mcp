# Icon Design Guide for App Store Connect MCP Plugin

This guide provides detailed instructions for creating the plugin icon (1024x1024px PNG).

## Icon Requirements

- **Size**: 1024x1024px (minimum 512x512px)
- **Format**: PNG with transparency
- **Style**: Professional, iOS/Swift themed
- **Content**: App Store Connect + MCP branding
- **File**: `assets/icon.png`

## Design Concept

### Primary Theme: App Store Connect + Swift

**Color Palette:**
- **Primary**: App Store Connect Blue (#007AFF - iOS system blue)
- **Secondary**: Swift Orange (#F05138 - Swift logo color)
- **Accent**: Firebase Yellow/Orange (#FFA000 - Crashlytics flame)
- **Background**: White or gradient

**Visual Elements:**
1. iOS app icon style (rounded square)
2. App Store Connect symbol or badge
3. Swift bird silhouette or "S" symbol
4. Optional: Crashlytics flame icon
5. Optional: MCP/connection symbol

## Design Options

### Option 1: App Store Connect Badge with Swift Symbol

**Description:**
- Background: App Store Connect blue gradient
- Center: White Swift bird silhouette
- Corner: Small badge/symbol indicating MCP connection

**Implementation:**
```
┌──────────────────────────┐
│                          │
│      ╱╲                  │
│     ╱  ╲     [badge]     │
│    ╱    ╲                │
│   ╱ SWIFT ╲              │
│  ╱        ╲              │
│                          │
└──────────────────────────┘
   Blue gradient background
```

### Option 2: dSYM File Symbol

**Description:**
- Background: White or light gray
- Center: Stylized dSYM file icon
- Colors: Blue (App Store), Orange (Swift)
- Text: ".dSYM" in clean font

**Implementation:**
```
┌──────────────────────────┐
│                          │
│    ┌────────────┐        │
│    │ ┌────────┐ │        │
│    │ │ dSYM   │ │        │
│    │ │        │ │        │
│    │ └────────┘ │        │
│    └────────────┘        │
│                          │
└──────────────────────────┘
   File icon with badge
```

### Option 3: Connection/Integration Theme

**Description:**
- Background: Gradient (blue to orange)
- Center: Connection nodes (App Store ↔ MCP ↔ Firebase)
- Style: Modern, minimal, tech-focused

**Implementation:**
```
┌──────────────────────────┐
│                          │
│   (App Store)            │
│         ↓                │
│      [MCP]               │
│         ↓                │
│   (Firebase)             │
│                          │
└──────────────────────────┘
   Flow diagram style
```

## Design Tools

### Option 1: SF Symbols (macOS - Recommended for Simple Icons)

**Steps:**
1. Open SF Symbols app (included with Xcode)
2. Search for relevant symbols:
   - "app.badge" (App Store)
   - "swift" (Swift logo)
   - "flame" (Crashlytics)
   - "link" or "arrow.triangle.branch" (connection)
3. Export as PNG:
   - Select symbol
   - File > Export Custom Symbol Image
   - Size: 1024x1024px
   - Format: PNG with transparency
4. Layer multiple symbols in Preview or image editor

**SF Symbols to Use:**
- `app.badge` - App Store badge
- `swift` - Swift logo (if available)
- `flame.fill` - Fire/Crashlytics
- `arrow.down.doc.fill` - Download dSYMs
- `icloud.and.arrow.down` - Download from cloud

### Option 2: Figma (Web-Based, Free)

**Steps:**
1. Go to [figma.com](https://figma.com) and create account (free)
2. Create new design file
3. Set canvas: 1024x1024px
4. Design icon:
   - Add frame (1024x1024px)
   - Add rounded rectangle (iOS style corners)
   - Apply gradient or solid color
   - Add symbols/text
   - Export as PNG

**Figma Template:**
```
Frame: 1024x1024px
  └─ Background Rectangle
      ├─ Fill: Linear gradient (#007AFF → #0051D5)
      ├─ Corner radius: 226px (iOS app icon standard)
      └─ Symbol/Text layers
```

### Option 3: Canva (Online, Free Templates)

**Steps:**
1. Go to [canva.com](https://canva.com)
2. Search for "App Icon" templates
3. Customize with:
   - App Store Connect blue (#007AFF)
   - Swift orange (#F05138)
   - Text: "ASC" or "dSYM" or Swift symbol
4. Export as PNG (1024x1024px)

### Option 4: GIMP (Free, Open Source)

**Steps:**
1. Download GIMP from [gimp.org](https://gimp.org)
2. New Image: 1024x1024px
3. Add layers:
   - Background (gradient or solid)
   - Rounded rectangle (iOS style)
   - Text or symbols
4. Export as PNG with transparency

### Option 5: AI Generation (Claude/Midjourney/DALL-E)

**Prompt for Claude (or other AI):**
```
Create an iOS app icon (1024x1024px) for an App Store Connect MCP plugin.

Style: Modern, minimal, professional
Colors: App Store Connect blue (#007AFF), Swift orange (#F05138)
Elements:
- iOS app icon rounded square style
- App Store Connect theme
- Swift or dSYM symbol
- Optional: Small Firebase Crashlytics flame icon

The icon should represent:
- iOS development
- App Store Connect integration
- Build and crash symbolication workflow
- Professional developer tool

Background: Gradient from blue to darker blue
Icon style: SF Symbols aesthetic, clean lines
```

## Quick DIY Icon with macOS Tools

If you need a simple icon immediately:

### Method 1: SF Symbols + Preview

```bash
# 1. Open SF Symbols app
open -a "SF Symbols"

# 2. Find and export "app.badge" symbol at 1024x1024px
# 3. Save as icon-base.png

# 4. Open in Preview
open -a Preview icon-base.png

# 5. Use Tools > Annotate to:
#    - Add text overlay
#    - Add shapes
#    - Apply tint color

# 6. Export as PNG with transparency
```

### Method 2: TextEdit + Screenshot

```bash
# 1. Open TextEdit in rich text mode
# 2. Set font size to 512pt
# 3. Type emoji: 📦 or 🔧 or ⚡️
# 4. Take screenshot (Cmd+Shift+4)
# 5. Resize to 1024x1024px in Preview
```

### Method 3: Swift Code to Generate Icon

Create a simple Swift script using SwiftUI to generate the icon:

```swift
// IconGenerator.swift
import SwiftUI
import AppKit

@main
struct IconGenerator {
    static func main() {
        let size = CGSize(width: 1024, height: 1024)
        let image = generateIcon(size: size)

        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Developer/asc-mcp/assets/icon.png")

        if let data = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: data),
           let png = bitmap.representation(using: .png, properties: [:]) {
            try? png.write(to: url)
            print("Icon saved to: \(url.path)")
        }
    }

    static func generateIcon(size: CGSize) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()

        // Background gradient (App Store Connect blue)
        let gradient = NSGradient(colors: [
            NSColor(calibratedRed: 0.0, green: 0.48, blue: 1.0, alpha: 1.0), // #007AFF
            NSColor(calibratedRed: 0.0, green: 0.32, blue: 0.84, alpha: 1.0)  // Darker
        ])
        gradient?.draw(in: NSRect(origin: .zero, size: size), angle: 270)

        // Rounded rectangle (iOS style)
        let cornerRadius = size.width * 0.22
        let iconRect = NSRect(origin: .zero, size: size).insetBy(dx: 0, dy: 0)
        let path = NSBezierPath(roundedRect: iconRect, xRadius: cornerRadius, yRadius: cornerRadius)
        path.addClip()

        // Text (Swift or dSYM)
        let text = "dSYM"
        let font = NSFont.systemFont(ofSize: size.width * 0.20, weight: .bold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white
        ]
        let textSize = text.size(withAttributes: attributes)
        let textRect = NSRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        text.draw(in: textRect, withAttributes: attributes)

        image.unlockFocus()
        return image
    }
}
```

Run:
```bash
swift IconGenerator.swift
```

## Icon Color Codes

Use these exact colors for consistency:

```
App Store Connect Blue:
- Hex: #007AFF
- RGB: 0, 122, 255
- HSB: 211°, 100%, 100%

Swift Orange:
- Hex: #F05138
- RGB: 240, 81, 56
- HSB: 8°, 77%, 94%

Firebase Yellow/Orange:
- Hex: #FFA000
- RGB: 255, 160, 0
- HSB: 38°, 100%, 100%

Crashlytics Flame:
- Hex: #FF9800
- RGB: 255, 152, 0
- HSB: 36°, 100%, 100%
```

## Icon Style Guidelines

### Do's:
- ✓ Use iOS app icon rounded square shape
- ✓ Keep design simple and recognizable at small sizes
- ✓ Use App Store Connect brand colors
- ✓ Include transparency if needed
- ✓ Test at multiple sizes (512px, 256px, 128px, 64px)
- ✓ Use vector elements when possible
- ✓ Maintain 1:1 aspect ratio

### Don'ts:
- ✗ Use copyrighted logos without permission
- ✗ Include small text (unreadable at small sizes)
- ✗ Use too many colors (3-4 max)
- ✗ Make it too complex or detailed
- ✗ Use raster images that pixelate
- ✗ Forget to test at small sizes

## Testing Your Icon

Before finalizing:

1. **Size Test:**
   ```bash
   sips -g pixelWidth -g pixelHeight assets/icon.png
   # Should output: 1024x1024
   ```

2. **View at Multiple Sizes:**
   ```bash
   # Create thumbnails for testing
   sips -Z 512 assets/icon.png --out assets/icon-512.png
   sips -Z 256 assets/icon.png --out assets/icon-256.png
   sips -Z 128 assets/icon.png --out assets/icon-128.png
   sips -Z 64 assets/icon.png --out assets/icon-64.png

   # Open all in Preview
   open assets/icon*.png
   ```

3. **Check File Size:**
   ```bash
   du -h assets/icon.png
   # Should be under 500KB (compress if needed)
   ```

4. **Compress if Needed:**
   ```bash
   # Using ImageOptim (recommended)
   # Download from: https://imageoptim.com/mac

   # Or using pngquant
   pngquant --quality=80-95 assets/icon.png --output assets/icon.png
   ```

## Icon Examples from Popular Plugins

For inspiration, look at other MCP/Claude Code plugins:

- **Simple geometric shapes** (squares, circles)
- **Tool symbols** (wrench, hammer, gear)
- **Technology symbols** (code brackets, terminal)
- **Brand colors** (GitHub green, GitLab orange)

## Next Steps After Creating Icon

1. **Save as:** `assets/icon.png` (1024x1024px)

2. **Commit to repository:**
   ```bash
   git add assets/icon.png
   git commit -m "feat(assets): add plugin marketplace icon"
   git push origin main
   ```

3. **Update manifest files with GitHub raw URL:**
   ```json
   "icon": "https://raw.githubusercontent.com/doozMen/asc-mcp/main/assets/icon.png"
   ```

4. **Verify URL in browser:**
   ```
   https://raw.githubusercontent.com/doozMen/asc-mcp/main/assets/icon.png
   ```

5. **Validate plugin:**
   ```bash
   /plugin validate .
   ```

## Need Help?

If you need assistance:

1. **Ask Claude to generate icon concepts** (AI generation)
2. **Use SF Symbols** (easiest for macOS developers)
3. **Hire a designer** (Fiverr, 99designs for professional quality)
4. **Community contributions** (open GitHub issue requesting icon design help)

## Recommended Approach

For this plugin, I recommend:

**Option 1 (Simplest):**
1. Use SF Symbols app
2. Export "app.badge" symbol at 1024x1024px
3. Tint with App Store Connect blue (#007AFF)
4. Add "dSYM" text overlay in white

**Option 2 (Best Quality):**
1. Use Figma (free, web-based)
2. Create 1024x1024px frame
3. Design with iOS app icon rounded corners
4. Export as PNG

**Option 3 (Fastest):**
1. Use the Swift code generator above
2. Modify text/colors as needed
3. Run script to generate PNG

All three options will produce a valid, professional icon suitable for marketplace submission.
