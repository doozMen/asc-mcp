#!/bin/bash

echo "Installing App Store Connect MCP Plugin..."
echo ""

# Check if running from plugin directory or source repo
if [ -f ".claude-plugin/plugin.json" ]; then
    PLUGIN_DIR="$(pwd)"
    echo "Installing from plugin directory: $PLUGIN_DIR"
else
    echo "Error: Must run from plugin directory (should contain .claude-plugin/plugin.json)"
    exit 1
fi

# Remove existing installation first (before building)
echo ""
if command -v appstoreconnect-mcp &> /dev/null; then
    echo "Removing existing installation..."
    rm -f ~/.swiftpm/bin/appstoreconnect-mcp
fi

# Also check for 'asc' binary (new shorter name)
if command -v asc &> /dev/null; then
    echo "Removing existing 'asc' installation..."
    rm -f ~/.swiftpm/bin/asc
fi

# Enable exit on error AFTER optional binary removal
set -e

# Build the Swift MCP server
BUILD_CONFIG="${BUILD_CONFIG:-release}"
echo "Building MCP server in $BUILD_CONFIG mode..."
xcrun swift build -c "$BUILD_CONFIG"

# Install to ~/.swiftpm/bin
echo "Installing to ~/.swiftpm/bin..."
xcrun swift package experimental-install --product asc

# Verify installation
if ! command -v asc &> /dev/null; then
    echo "Error: Installation failed"
    exit 1
fi

# Test version command
echo ""
echo "Installed version:"
asc --version

# Configure plugin
echo ""
echo "✓ MCP server binary installed successfully!"
echo ""

# Plugin is automatically discovered by Claude Code from .claude-plugin/plugin.json
# But we still need to configure App Store Connect credentials

# Check if running in non-interactive mode (e.g., from build-all-mcps.sh)
if [ ! -t 0 ]; then
    # Non-interactive mode - skip credential configuration
    echo ""
    echo "✓ Installation complete!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 Configure Credentials in ~/.claude/settings.json"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Add App Store Connect credentials to ~/.claude/settings.json:"
    echo ""
    echo '"env": {'
    echo '  "ASC_KEY_ID": "YOUR_KEY_ID",'
    echo '  "ASC_ISSUER_ID": "YOUR_ISSUER_ID",'
    echo '  "ASC_PRIVATE_KEY_PATH": "/path/to/AuthKey_XXXXXXXXXX.p8"'
    echo '}'
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Plugin Installation via Claude Code"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Install the plugin via PromptPing Marketplace:"
    echo ""
    echo "  /plugin marketplace add github:doozMen/promptping-marketplace"
    echo "  /plugin install asc-mcp"
    echo ""
    echo "Then restart Claude Code."
    exit 0
fi

# Interactive mode - check if credentials already configured
echo ""
SETTINGS_FILE="$HOME/.claude/settings.json"

# Check if credentials already exist in settings
CREDS_CONFIGURED=false
if [ -f "$SETTINGS_FILE" ]; then
    if grep -q "ASC_KEY_ID" "$SETTINGS_FILE" && \
       grep -q "ASC_ISSUER_ID" "$SETTINGS_FILE" && \
       grep -q "ASC_PRIVATE_KEY_PATH" "$SETTINGS_FILE"; then
        CREDS_CONFIGURED=true
    fi
fi

if [ "$CREDS_CONFIGURED" = true ]; then
    echo "✓ App Store Connect credentials already configured in ~/.claude/settings.json"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Installation Complete!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Your asc-mcp MCP server binary is installed."
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Plugin Installation via Claude Code"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Install the plugin via PromptPing Marketplace:"
    echo ""
    echo "  /plugin marketplace add github:doozMen/promptping-marketplace"
    echo "  /plugin install asc-mcp"
    echo ""
    echo "Or for local development:"
    echo ""
    echo "  /plugin marketplace add /Users/\$USER/Developer/promptping-marketplace"
    echo "  /plugin install asc-mcp"
    echo ""
    echo "Then restart Claude Code to load the plugin."
    echo ""
    exit 0
fi

# Credentials not configured - offer setup
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Credential Configuration (Optional)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "The plugin is installed. Configure App Store Connect credentials now?"
echo ""
echo "You can also add them later to ~/.claude/settings.json"
echo ""
echo "Configure credentials using 1Password? (y/n)"
read -r use_1password

if [[ "$use_1password" =~ ^[Yy]$ ]]; then
    # Verify 1Password CLI is installed
            if ! command -v op &> /dev/null; then
                echo "Error: 1Password CLI (op) not found. Install with: brew install 1password-cli"
                exit 1
            fi

            echo ""
            echo "Retrieving App Store Connect credentials from 1Password..."
            echo ""

            # Retrieve credentials from the Dooz Apple developer item
            OP_ITEM_NAME="Dooz Apple developer"

            ASC_KEY_ID=$(op item get "$OP_ITEM_NAME" --fields "label=ASC Key ID" 2>/dev/null)
            ASC_ISSUER_ID=$(op item get "$OP_ITEM_NAME" --fields "label=ASC Issuer ID" 2>/dev/null)

            # Extract the private key file from 1Password
            mkdir -p ~/.appstoreconnect

            # Get the file name from the item
            PRIVATE_KEY_FILE=$(op item get "$OP_ITEM_NAME" --format json 2>/dev/null | jq -r '.files[0].name' 2>/dev/null)

            if [ -z "$PRIVATE_KEY_FILE" ]; then
                echo "Error: No private key file found in 1Password item '$OP_ITEM_NAME'"
                exit 1
            fi

            # Download the private key file
            op item get "$OP_ITEM_NAME" "$PRIVATE_KEY_FILE" > ~/.appstoreconnect/"$PRIVATE_KEY_FILE" 2>/dev/null

            ASC_PRIVATE_KEY_PATH="$HOME/.appstoreconnect/$PRIVATE_KEY_FILE"

            # Set proper permissions on the private key
            chmod 600 "$ASC_PRIVATE_KEY_PATH"

            # Validate all fields were retrieved
            if [ -z "$ASC_KEY_ID" ]; then
                echo "Error: Field 'ASC Key ID' not found in 1Password item '$OP_ITEM_NAME'"
                exit 1
            fi

            if [ -z "$ASC_ISSUER_ID" ]; then
                echo "Error: Field 'ASC Issuer ID' not found in 1Password item '$OP_ITEM_NAME'"
                exit 1
            fi

            if [ ! -f "$ASC_PRIVATE_KEY_PATH" ]; then
                echo "Error: Private key file not found at $ASC_PRIVATE_KEY_PATH"
                exit 1
            fi

    echo "✓ Retrieved 3 credentials from 1Password item '$OP_ITEM_NAME'"
    echo "  - ASC Key ID: ${ASC_KEY_ID:0:8}..."
    echo "  - ASC Issuer ID: ${ASC_ISSUER_ID:0:8}..."
    echo "  - Private Key: $PRIVATE_KEY_FILE"

else
    # Manual credential entry
    echo ""
    echo "Enter your App Store Connect credentials:"
    echo -n "ASC_KEY_ID: "
    read -r ASC_KEY_ID
    echo -n "ASC_ISSUER_ID: "
    read -r ASC_ISSUER_ID
    echo -n "ASC_PRIVATE_KEY_PATH (full path to .p8 file): "
    read -r ASC_PRIVATE_KEY_PATH
fi

# Check if credentials were provided
if [ -n "$ASC_KEY_ID" ] && [ -n "$ASC_ISSUER_ID" ] && [ -n "$ASC_PRIVATE_KEY_PATH" ]; then
    echo ""
    echo "✓ Credentials retrieved from 1Password"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Add Credentials to Claude Settings"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Add these credentials to ~/.claude/settings.json:"
    echo ""
    echo '"env": {'
    echo '  "ASC_KEY_ID": "'$ASC_KEY_ID'",'
    echo '  "ASC_ISSUER_ID": "'$ASC_ISSUER_ID'",'
    echo '  "ASC_PRIVATE_KEY_PATH": "'$ASC_PRIVATE_KEY_PATH'"'
    echo '}'
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Plugin Installation via Claude Code"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Install the plugin via PromptPing Marketplace:"
    echo ""
    echo "  /plugin marketplace add github:doozMen/promptping-marketplace"
    echo "  /plugin install asc-mcp"
    echo ""
    echo "Then restart Claude Code to load the credentials."
    echo ""
    exit 0
else
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Installation Complete (Credentials Optional)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Your asc-mcp MCP server binary is installed!"
    echo ""
    echo "To add App Store Connect credentials later:"
    echo ""
    echo "1. Edit ~/.claude/settings.json"
    echo "2. Add to the 'env' section:"
    echo ""
    echo '"env": {'
    echo '  "ASC_KEY_ID": "YOUR_KEY_ID",'
    echo '  "ASC_ISSUER_ID": "YOUR_ISSUER_ID",'
    echo '  "ASC_PRIVATE_KEY_PATH": "/path/to/AuthKey_XXXXXXXXXX.p8"'
    echo '}'
    echo ""
    echo "3. Restart Claude Code"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Plugin Installation via Claude Code"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Install the plugin via PromptPing Marketplace:"
    echo ""
    echo "  /plugin marketplace add github:doozMen/promptping-marketplace"
    echo "  /plugin install asc-mcp"
    echo ""
    echo "Then restart Claude Code."
    echo ""
    exit 0
fi
