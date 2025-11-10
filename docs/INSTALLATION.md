# Installation Guide

Complete installation instructions for the App Store Connect MCP Plugin for Claude Code.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Plugin Installation](#plugin-installation)
3. [MCP Server Installation](#mcp-server-installation)
4. [Credential Setup](#credential-setup)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required

- **macOS 13.0 or later**
- **Swift 6.0 or later** (included with Xcode 16+)
- **Xcode 16 or later** (for building the MCP server)
- **Claude Code** installed and configured
- **App Store Connect API credentials**

### Optional

- **Firebase CLI** (for Crashlytics integration)
  - Install: `npm install -g firebase-tools`
  - Verify: `firebase --version`

## Plugin Installation

### Option 1: Official Marketplace (Recommended)

Once published to the official Claude Code marketplace:

```bash
/plugin install appstoreconnect-mcp
```

### Option 2: Self-Hosted GitHub Marketplace

1. **Add the marketplace:**
   ```bash
   /plugin marketplace add github.com/doozMen/asc-mcp
   ```

2. **Install the plugin:**
   ```bash
   /plugin install appstoreconnect-mcp@doozMen
   ```

### Option 3: Local Installation (Development)

For testing or development:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/doozMen/asc-mcp.git
   cd asc-mcp
   ```

2. **Create a local marketplace:**
   ```bash
   mkdir -p ~/claude-dev-marketplace
   cp -r . ~/claude-dev-marketplace/appstoreconnect-mcp
   ```

3. **Create marketplace manifest:**
   ```bash
   cat > ~/claude-dev-marketplace/.claude-plugin/marketplace.json << 'EOF'
   {
     "name": "dev-marketplace",
     "owner": {
       "name": "Developer"
     },
     "plugins": [
       {
         "name": "appstoreconnect-mcp",
         "source": "./appstoreconnect-mcp/.claude-plugin/plugin.json",
         "description": "App Store Connect MCP development version"
       }
     ]
   }
   EOF
   ```

4. **Add marketplace and install:**
   ```bash
   /plugin marketplace add ~/claude-dev-marketplace
   /plugin install appstoreconnect-mcp@dev-marketplace
   ```

## MCP Server Installation

After plugin installation, the MCP server needs to be built and installed:

### Automated Installation (Recommended)

1. **Navigate to plugin directory:**
   ```bash
   cd ~/.claude/plugins/appstoreconnect-mcp
   ```

2. **Run installation script:**
   ```bash
   ./install.sh
   ```

   The script will:
   - Build the MCP server in release mode
   - Install to `~/.swiftpm/bin/appstoreconnect-mcp`
   - Verify the installation
   - Optionally configure Claude Code automatically

### Manual Installation

If you prefer manual steps:

1. **Navigate to plugin directory:**
   ```bash
   cd ~/.claude/plugins/appstoreconnect-mcp
   ```

2. **Build in release mode:**
   ```bash
   xcrun swift build -c release
   ```

3. **Remove existing installation (if any):**
   ```bash
   rm -f ~/.swiftpm/bin/appstoreconnect-mcp
   ```

4. **Install the executable:**
   ```bash
   xcrun swift package experimental-install --product appstoreconnect-mcp
   ```

5. **Verify installation:**
   ```bash
   which appstoreconnect-mcp
   appstoreconnect-mcp --version
   ```

   Expected output:
   ```
   /Users/yourusername/.swiftpm/bin/appstoreconnect-mcp
   1.0.0
   ```

## Credential Setup

You need App Store Connect API credentials to use this plugin.

### Step 1: Obtain Credentials from App Store Connect

1. Sign in to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **Users and Access > Keys**
3. Click the **+** button to create a new API key
4. Name it (e.g., "Claude Code MCP")
5. Select appropriate permissions:
   - **App Manager** (recommended) - Full access
   - **Developer** (minimum) - Read-only access to apps and builds
6. Click **Generate**
7. **Download the private key (.p8 file)** - **You can only download it once!**
8. Note the **Key ID** (e.g., "ABC123DEF4")
9. Note the **Issuer ID** (shown at the top, e.g., "12345678-1234-1234-1234-123456789012")

### Step 2: Secure Your Private Key

Store the .p8 file securely:

```bash
# Create secure directory
mkdir -p ~/.appstoreconnect
chmod 700 ~/.appstoreconnect

# Move the key
mv ~/Downloads/AuthKey_ABC123DEF4.p8 ~/.appstoreconnect/

# Set proper permissions
chmod 600 ~/.appstoreconnect/AuthKey_*.p8
```

**Security Best Practices:**
- Never commit .p8 files to version control
- Never share .p8 files
- Back up the .p8 file securely (you can't download it again)
- Use restrictive file permissions (600)

### Step 3: Configure Claude Code

#### Option A: Interactive Setup (Easiest)

Use the slash command in Claude Code:

```
/setup-credentials
```

Follow the interactive prompts.

#### Option B: Manual Configuration

Add the MCP server credentials manually:

```bash
claude add mcp appstoreconnect \
  --command appstoreconnect-mcp \
  --args "--log-level" "info" \
  --env "PATH=$HOME/.swiftpm/bin:/usr/local/bin:/usr/bin:/bin" \
  --env "ASC_KEY_ID=YOUR_KEY_ID" \
  --env "ASC_ISSUER_ID=YOUR_ISSUER_ID" \
  --env "ASC_PRIVATE_KEY_PATH=$HOME/.appstoreconnect/AuthKey_YOUR_KEY_ID.p8"
```

Replace placeholders:
- `YOUR_KEY_ID`: Your App Store Connect Key ID (e.g., "ABC123DEF4")
- `YOUR_ISSUER_ID`: Your Issuer ID (e.g., "12345678-1234-1234-1234-123456789012")
- `AuthKey_YOUR_KEY_ID.p8`: Your actual .p8 filename

#### Option C: Direct Configuration File Edit

Edit the Claude Code MCP configuration file:

**File location:**
- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`

**Add this to the `mcpServers` section:**

```json
{
  "mcpServers": {
    "appstoreconnect": {
      "command": "appstoreconnect-mcp",
      "args": ["--log-level", "info"],
      "env": {
        "PATH": "$HOME/.swiftpm/bin:/usr/local/bin:/usr/bin:/bin",
        "ASC_KEY_ID": "YOUR_KEY_ID",
        "ASC_ISSUER_ID": "YOUR_ISSUER_ID",
        "ASC_PRIVATE_KEY_PATH": "/Users/yourusername/.appstoreconnect/AuthKey_YOUR_KEY_ID.p8"
      }
    }
  }
}
```

**Important:** Use absolute paths (not `~` or `$HOME`) in JSON files.

## Verification

### Step 1: Restart Claude Code

After configuration changes, restart Claude Code completely.

### Step 2: Check Plugin Status

In Claude Code:

```
/plugin list
```

You should see `appstoreconnect-mcp` in the list.

### Step 3: Test MCP Server Connection

Try listing your apps:

```
List all my apps from App Store Connect
```

Expected response:
```
Found X apps in your App Store Connect account:
1. MyApp (com.example.myapp)
2. AnotherApp (com.example.anotherapp)
...
```

### Step 4: Test Slash Commands

Try a slash command:

```
/check-build-status
```

The assistant should ask for your app's bundle ID.

### Step 5: Test Agent

Mention crash-related tasks:

```
Help me download dSYMs for my latest build
```

The `ios-crash-manager` agent should activate and guide you through the workflow.

## Troubleshooting

### Plugin Installation Issues

**Problem:** Plugin not found
```bash
# List available marketplaces
/plugin marketplace list

# Add marketplace again
/plugin marketplace add github.com/doozMen/asc-mcp
```

**Problem:** Plugin installation fails
```bash
# Check plugin validation
cd /path/to/plugin
claude plugin validate .claude-plugin/plugin.json
```

### MCP Server Build Issues

**Problem:** Build fails with "Swift version mismatch"
```bash
# Check Swift version
swift --version

# Requires Swift 6.0+
# Update Xcode to version 16 or later
```

**Problem:** Installation directory not in PATH
```bash
# Add to ~/.zshrc or ~/.bash_profile
echo 'export PATH="$HOME/.swiftpm/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Credential Issues

**Problem:** "Missing required environment variables"
```bash
# Verify configuration
cat ~/Library/Application\ Support/Claude/claude_desktop_config.json | grep -A 10 appstoreconnect

# Test manually
export ASC_KEY_ID="YOUR_KEY_ID"
export ASC_ISSUER_ID="YOUR_ISSUER_ID"
export ASC_PRIVATE_KEY_PATH="$HOME/.appstoreconnect/AuthKey_*.p8"
appstoreconnect-mcp --log-level debug
```

**Problem:** "Invalid private key" or "Authentication failed"
```bash
# Check file permissions
ls -la ~/.appstoreconnect/

# Should show: -rw------- (600)

# Check file is readable
cat ~/.appstoreconnect/AuthKey_*.p8

# Should show: -----BEGIN PRIVATE KEY-----
```

**Problem:** "403 Forbidden"
- Your API key lacks necessary permissions
- Go to App Store Connect > Users and Access > Keys
- Delete old key and create new one with "App Manager" role

### Connection Issues

**Problem:** MCP server not connecting

1. **Check logs:**
   ```bash
   tail -f ~/Library/Logs/Claude/mcp-server-appstoreconnect-mcp.log
   ```

2. **Test server directly:**
   ```bash
   # Set environment variables
   export ASC_KEY_ID="YOUR_KEY_ID"
   export ASC_ISSUER_ID="YOUR_ISSUER_ID"
   export ASC_PRIVATE_KEY_PATH="$HOME/.appstoreconnect/AuthKey_*.p8"

   # Run with debug logging
   appstoreconnect-mcp --log-level debug
   ```

3. **Restart Claude Code:**
   - Quit completely (not just close window)
   - Relaunch

### Firebase Integration Issues

**Problem:** "Firebase command not found"
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Verify installation
firebase --version

# Login to Firebase
firebase login
```

**Problem:** Firebase upload fails
```bash
# Check Firebase project access
firebase projects:list

# Verify GoogleService-Info.plist exists in project
# Verify Firebase app ID format: "1:123456789:ios:abc123def456"
```

## Getting Help

If you encounter issues not covered here:

1. **Check logs:**
   ```bash
   tail -100 ~/Library/Logs/Claude/mcp-server-appstoreconnect-mcp.log
   ```

2. **Search existing issues:**
   https://github.com/doozMen/asc-mcp/issues

3. **Create a new issue:**
   - Include your macOS version
   - Include your Swift version (`swift --version`)
   - Include relevant log excerpts (redact sensitive data)
   - Describe steps to reproduce

4. **Community discussions:**
   https://github.com/doozMen/asc-mcp/discussions

## Next Steps

After successful installation:

1. **Explore slash commands:**
   - Try `/download-latest-dsyms`
   - Try `/check-build-status`

2. **Use the ios-crash-manager agent:**
   - Ask about crash symbolication
   - Request dSYM management help

3. **Automate workflows:**
   - Integrate into CI/CD pipelines
   - Create custom scripts using MCP tools

4. **Read full documentation:**
   - [README.md](README.md) - Complete feature documentation
   - [PLUGIN_README.md](PLUGIN_README.md) - Marketplace documentation

Enjoy streamlined iOS development workflows with Claude Code!
