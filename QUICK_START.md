# Quick Start Guide

Get up and running with the App Store Connect MCP Plugin in 5 minutes.

## Prerequisites Check

Before starting, verify you have:

- [ ] macOS 13.0 or later
- [ ] Xcode 16 or later installed (`xcode-select --install`)
- [ ] App Store Connect account
- [ ] App Store Connect API key ([Get one here](https://appstoreconnect.apple.com))

## 1. Install Plugin (1 minute)

### From GitHub (Self-Hosted)

```bash
# Add marketplace
/plugin marketplace add github.com/doozMen/asc-mcp

# Install plugin
/plugin install appstoreconnect-mcp@doozMen
```

### From Official Marketplace (When Available)

```bash
/plugin install appstoreconnect-mcp
```

## 2. Build MCP Server (2 minutes)

```bash
# Navigate to plugin directory
cd ~/.claude/plugins/appstoreconnect-mcp

# Run installation script
./install.sh

# Follow prompts to add credentials (or skip and configure later)
```

Expected output:
```
Building in release mode...
[Build output...]
Installing to ~/.swiftpm/bin...
✓ App Store Connect MCP installed successfully!
```

## 3. Configure Credentials (2 minutes)

### Get Your Credentials

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **Users and Access > Keys**
3. Create new API key (click **+**)
4. Download `.p8` file (only available once!)
5. Note **Key ID** and **Issuer ID**

### Option A: Interactive Setup

In Claude Code:
```
/setup-credentials
```

Follow the prompts.

### Option B: Command Line

```bash
# Secure your private key
mkdir -p ~/.appstoreconnect
mv ~/Downloads/AuthKey_*.p8 ~/.appstoreconnect/
chmod 600 ~/.appstoreconnect/AuthKey_*.p8

# Add to Claude Code
claude add mcp appstoreconnect \
  --command appstoreconnect-mcp \
  --args "--log-level" "info" \
  --env "PATH=$HOME/.swiftpm/bin:/usr/local/bin:/usr/bin:/bin" \
  --env "ASC_KEY_ID=YOUR_KEY_ID" \
  --env "ASC_ISSUER_ID=YOUR_ISSUER_ID" \
  --env "ASC_PRIVATE_KEY_PATH=$HOME/.appstoreconnect/AuthKey_YOUR_KEY_ID.p8"
```

Replace `YOUR_KEY_ID` and `YOUR_ISSUER_ID` with your actual values.

## 4. Verify Installation (30 seconds)

Restart Claude Code, then try:

```
List all my apps from App Store Connect
```

You should see your apps listed!

## 5. Try Key Features (30 seconds each)

### Download Latest dSYMs

```
Download the latest dSYMs for my app
```

Claude will ask for your bundle ID, then download the dSYMs automatically.

### Check Build Status

```
/check-build-status
```

See the status of all your builds.

### Upload to Firebase Crashlytics

```
Upload the latest dSYMs to Firebase Crashlytics
```

Claude will guide you through the upload process.

## Common First-Time Issues

### "Missing required environment variables"

**Fix:** Credentials not configured properly
```bash
# Check Claude config
cat ~/Library/Application\ Support/Claude/claude_desktop_config.json | grep -A 10 appstoreconnect

# Reconfigure if needed
claude add mcp appstoreconnect ...
```

### "Command not found: appstoreconnect-mcp"

**Fix:** Installation didn't complete or PATH not set
```bash
# Verify installation
which appstoreconnect-mcp
# Should show: /Users/you/.swiftpm/bin/appstoreconnect-mcp

# If not found, reinstall
cd ~/.claude/plugins/appstoreconnect-mcp
./install.sh

# Add to PATH if needed
echo 'export PATH="$HOME/.swiftpm/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### "Authentication failed"

**Fix:** Invalid credentials
- Verify Key ID and Issuer ID are correct
- Check .p8 file path is correct
- Ensure .p8 file has read permissions (`chmod 600 ...`)
- Try creating a new API key in App Store Connect

### Plugin not loading

**Fix:** Restart Claude Code completely
```bash
# Quit Claude Code (not just close window)
# Relaunch
```

## What's Next?

Now that you're set up, explore:

### Slash Commands

- `/download-latest-dsyms` - Download dSYMs workflow
- `/upload-dsyms-to-crashlytics` - Upload to Firebase
- `/check-build-status` - Check build information
- `/setup-credentials` - Reconfigure credentials

### Agent

Ask about crash-related tasks to invoke the `ios-crash-manager` agent:
- "Help me symbolicate crashes"
- "Download dSYMs for build 42"
- "Upload my Xcode archive to Crashlytics"

### Advanced Features

- **Archive Management**: "Find my Xcode archives from last week"
- **Batch Operations**: "Download dSYMs for all my apps"
- **Status Monitoring**: "Show me all TestFlight builds"
- **CI/CD Integration**: Use tools in automated workflows

## Get Help

- **Documentation**: [INSTALLATION.md](INSTALLATION.md) - Detailed setup guide
- **Full README**: [README.md](README.md) - Complete feature documentation
- **Marketplace**: [PLUGIN_README.md](PLUGIN_README.md) - User guide
- **Issues**: [GitHub Issues](https://github.com/doozMen/asc-mcp/issues)
- **Discussions**: [GitHub Discussions](https://github.com/doozMen/asc-mcp/discussions)

## Quick Command Reference

### MCP Tools (use via natural language)

```
"List all my apps"                    → list_apps
"Get status of com.example.app"       → get_app_status
"List builds for app 123456"          → list_builds
"Download dSYMs for build abc-123"    → download_dsyms
"Get latest build for app 123456"     → get_latest_build
"Upload dSYMs to Firebase"            → upload_dsyms_to_firebase
"Find my Xcode archives"              → find_xcode_archives
```

### Slash Commands (use directly)

```
/download-latest-dsyms                → Automated dSYM download
/upload-dsyms-to-crashlytics          → Upload to Firebase
/check-build-status                   → Build information
/setup-credentials                    → Configure API credentials
```

### Agent Invocation (automatic)

Mention these keywords:
- dSYMs, crash symbolication, Firebase Crashlytics
- App Store Connect builds, TestFlight
- Xcode archives

## Optional: Firebase Crashlytics Setup

For dSYM upload features:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Verify installation
firebase --version

# Login to Firebase
firebase login

# Get your Firebase app ID
# Format: 1:123456789:ios:abc123def456
# Found in: Firebase Console > Project Settings > Your Apps
```

You're all set! Start automating your iOS workflows with Claude Code.
