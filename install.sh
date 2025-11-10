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

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Credential Configuration Required"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "The plugin is installed, but needs App Store Connect credentials."
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
            echo "Enter your 1Password item name containing App Store Connect credentials:"
            echo "The item should have these fields:"
            echo "  - ASC Key ID"
            echo "  - ASC Issuer ID"
            echo "  - ASC Private Key Path"
            echo ""
            echo "Example: 'Dooz Apple developer' or 'App Store Connect API'"
            echo ""

            echo -n "1Password item name: "
            read -r OP_ITEM_NAME

            # Retrieve all credentials from the single item
            echo ""
            echo "Retrieving credentials from 1Password item '$OP_ITEM_NAME'..."

            ASC_KEY_ID=$(op item get "$OP_ITEM_NAME" --fields "label=ASC Key ID" 2>/dev/null)
            ASC_ISSUER_ID=$(op item get "$OP_ITEM_NAME" --fields "label=ASC Issuer ID" 2>/dev/null)
            ASC_PRIVATE_KEY_PATH=$(op item get "$OP_ITEM_NAME" --fields "label=ASC Private Key Path" 2>/dev/null)

            # Validate all fields were retrieved
            if [ -z "$ASC_KEY_ID" ]; then
                echo "Error: Field 'ASC Key ID' not found in 1Password item '$OP_ITEM_NAME'"
                echo "Make sure the item has a field labeled exactly 'ASC Key ID'"
                exit 1
            fi

            if [ -z "$ASC_ISSUER_ID" ]; then
                echo "Error: Field 'ASC Issuer ID' not found in 1Password item '$OP_ITEM_NAME'"
                echo "Make sure the item has a field labeled exactly 'ASC Issuer ID'"
                exit 1
            fi

            if [ -z "$ASC_PRIVATE_KEY_PATH" ]; then
                echo "Error: Field 'ASC Private Key Path' not found in 1Password item '$OP_ITEM_NAME'"
                echo "Make sure the item has a field labeled exactly 'ASC Private Key Path'"
                exit 1
            fi

    echo "✓ Retrieved 3 credentials from 1Password item '$OP_ITEM_NAME'"

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
    # Update .mcp.json in plugin directory with credentials
    echo ""
    echo "Updating plugin configuration with credentials..."

    # Create updated .mcp.json
    cat > "$PLUGIN_DIR/.mcp.json" <<EOF_MCP
{
  "mcpServers": {
    "asc": {
      "command": "asc",
      "env": {
        "PATH": "\$HOME/.swiftpm/bin:/usr/local/bin:/usr/bin:/bin",
        "ASC_KEY_ID": "$ASC_KEY_ID",
        "ASC_ISSUER_ID": "$ASC_ISSUER_ID",
        "ASC_PRIVATE_KEY_PATH": "$ASC_PRIVATE_KEY_PATH"
      }
    }
  }
}
EOF_MCP

    echo "✓ Plugin configured with App Store Connect credentials"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Installation Complete!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Plugin Location: $PLUGIN_DIR"
    echo "MCP Binary: ~/.swiftpm/bin/asc"
    echo "Configuration: $PLUGIN_DIR/.mcp.json"
    echo ""
    echo "🔄 Restart Claude Code to load the plugin"
    echo ""
    echo "Test with:"
    echo "  'List all my apps from App Store Connect'"
    echo "  'Show me the latest build for my app'"
    echo "  'Register bundle ID com.example.myapp'"
    echo ""
else
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Manual Configuration Required"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Edit $PLUGIN_DIR/.mcp.json and add your credentials:"
    echo ""
    echo '{
  "mcpServers": {
    "asc": {
      "command": "asc",
      "env": {
        "PATH": "$HOME/.swiftpm/bin:/usr/local/bin:/usr/bin:/bin",
        "ASC_KEY_ID": "YOUR_KEY_ID",
        "ASC_ISSUER_ID": "YOUR_ISSUER_ID",
        "ASC_PRIVATE_KEY_PATH": "/path/to/AuthKey_XXXXXXXXXX.p8"
      }
    }
  }
}'
    echo ""
    echo "Then restart Claude Code."
fi
