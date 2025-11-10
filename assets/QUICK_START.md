# Quick Start: Generate Assets for Marketplace

This guide will get you marketplace-ready assets in 10 minutes.

## Prerequisites

- macOS with Xcode Command Line Tools installed
- Claude Code with your plugin installed
- Git repository access

## Step 1: Generate Assets (5 minutes)

Run the master asset generation script:

```bash
cd /Users/stijnwillems/Developer/asc-mcp/assets
./generate-assets.sh
```

This interactive script will:
1. Generate icon.png automatically
2. Help you capture 5 screenshots interactively
3. Validate all assets
4. Commit to git
5. Guide you through manifest updates

## Step 2: Quick Asset Generation

### Option A: Automatic (Fastest)

```bash
cd /Users/stijnwillems/Developer/asc-mcp/assets

# Generate icon
swift IconGenerator.swift

# Open for review
open icon.png
```

### Option B: Manual Icon

If you prefer to create your own icon:
1. Read `ICON_DESIGN_GUIDE.md`
2. Use SF Symbols, Figma, or Canva
3. Save as `icon.png` (1024x1024px)

## Step 3: Capture Screenshots (5 minutes)

### Option A: Use Helper Script

```bash
cd /Users/stijnwillems/Developer/asc-mcp/assets
./capture-screenshots.sh
```

Follow the prompts to capture each of the 5 required screenshots.

### Option B: Manual Screenshot Capture

1. Open Claude Code
2. Read `screenshot-examples.md` for example outputs
3. Execute each workflow in Claude Code
4. Press Cmd+Shift+4, then spacebar
5. Click on Claude Code window to capture
6. Save as `screenshot-1.png` through `screenshot-5.png`

## Step 4: Review and Validate

```bash
cd /Users/stijnwillems/Developer/asc-mcp/assets

# View all assets
ls -lh *.png

# Open for review
open *.png

# Validate assets (check dimensions, format)
./generate-assets.sh
# Select option 4 (Validate assets)
```

## Step 5: Commit to Git

```bash
cd /Users/stijnwillems/Developer/asc-mcp

# Add assets
git add assets/icon.png assets/screenshot-*.png

# Commit
git commit -m "feat(assets): add plugin marketplace assets"

# Push to GitHub
git push origin main
```

## Step 6: Update Manifests with GitHub URLs

After pushing to GitHub, update these files with GitHub raw URLs:

### File: `.claude-plugin/plugin.json`

```json
{
  "icon": "https://raw.githubusercontent.com/doozMen/asc-mcp/main/assets/icon.png"
}
```

### File: `.claude-plugin/submission-metadata.json`

```json
{
  "icon": "https://raw.githubusercontent.com/doozMen/asc-mcp/main/assets/icon.png",
  "screenshots": [
    {
      "url": "https://raw.githubusercontent.com/doozMen/asc-mcp/main/assets/screenshot-1.png",
      "caption": "Download latest dSYMs with single command"
    },
    {
      "url": "https://raw.githubusercontent.com/doozMen/asc-mcp/main/assets/screenshot-2.png",
      "caption": "Upload dSYMs to Firebase Crashlytics automatically"
    },
    {
      "url": "https://raw.githubusercontent.com/doozMen/asc-mcp/main/assets/screenshot-3.png",
      "caption": "Check build status across all apps"
    },
    {
      "url": "https://raw.githubusercontent.com/doozMen/asc-mcp/main/assets/screenshot-4.png",
      "caption": "Interactive credential setup guide"
    },
    {
      "url": "https://raw.githubusercontent.com/doozMen/asc-mcp/main/assets/screenshot-5.png",
      "caption": "Find and manage Xcode archives"
    }
  ]
}
```

Commit the manifest updates:

```bash
git add .claude-plugin/plugin.json .claude-plugin/submission-metadata.json
git commit -m "feat(assets): update manifest URLs with GitHub assets"
git push origin main
```

## Step 7: Verify URLs

Open each GitHub raw URL in your browser to verify accessibility:

```bash
# Icon
open "https://raw.githubusercontent.com/doozMen/asc-mcp/main/assets/icon.png"

# Screenshots
open "https://raw.githubusercontent.com/doozMen/asc-mcp/main/assets/screenshot-1.png"
# ... repeat for all screenshots
```

## Step 8: Validate Plugin

```bash
/plugin validate .
```

Should now pass without asset warnings!

## Step 9: Test Installation

```bash
# Add marketplace
/plugin marketplace add github.com/doozMen/asc-mcp

# Install plugin
/plugin install appstoreconnect-mcp@doozMen
```

## Step 10: Submit to Marketplace

See `MARKETPLACE_SUBMISSION_GUIDE.md` for:
- Official marketplace submission process
- Community marketplace options
- Post-submission maintenance

## Troubleshooting

### Icon Generator Fails

```bash
# Check Swift is available
swift --version

# Run with error output
swift IconGenerator.swift 2>&1
```

### Screenshot Capture Fails

```bash
# Use manual capture instead
# Cmd+Shift+4, then spacebar, then click window
```

### Invalid Asset Dimensions

```bash
# Check dimensions
sips -g pixelWidth -g pixelHeight assets/icon.png

# Resize if needed
sips -Z 1024 assets/icon.png --out assets/icon.png
```

### GitHub Raw URLs Not Working

Wait a few minutes after pushing - GitHub CDN can take time to update.

## One-Line Asset Generation

For the fastest setup, run all steps at once:

```bash
cd /Users/stijnwillems/Developer/asc-mcp/assets && \
swift IconGenerator.swift && \
open icon.png && \
echo "Icon generated! Now run ./capture-screenshots.sh to capture screenshots"
```

## Time Estimate

- Icon generation: 1 minute (automatic)
- Screenshot capture: 5 minutes (interactive)
- Review and validate: 2 minutes
- Commit and push: 1 minute
- Update manifests: 1 minute

**Total: ~10 minutes**

## Next Steps

After generating assets:

1. Review all assets for quality
2. Commit to git and push to GitHub
3. Update manifest files with GitHub raw URLs
4. Validate plugin with `/plugin validate .`
5. Test self-hosted installation
6. Submit to official marketplace
7. Share with community

## Need Help?

- **Icon design**: See `ICON_DESIGN_GUIDE.md`
- **Screenshot examples**: See `screenshot-examples.md`
- **Marketplace submission**: See `MARKETPLACE_SUBMISSION_GUIDE.md`
- **Asset requirements**: See `README.md` in this directory

## Resources

All asset generation tools in this directory:

- `generate-assets.sh` - Master interactive script (recommended)
- `IconGenerator.swift` - Automatic icon generator
- `capture-screenshots.sh` - Screenshot capture helper
- `ICON_DESIGN_GUIDE.md` - Icon design reference
- `screenshot-examples.md` - Example outputs for screenshots
- `README.md` - Complete asset documentation

Start with `./generate-assets.sh` for the easiest experience!
