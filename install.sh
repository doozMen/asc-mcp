#!/bin/bash
set -e

echo "Installing App Store Connect MCP server..."

# Build in release mode
echo "Building in release mode..."
xcrun swift build -c release

# Remove existing installation if present
if command -v appstoreconnect-mcp &> /dev/null; then
    echo "Removing existing installation..."
    rm -f ~/.swiftpm/bin/appstoreconnect-mcp
fi

# Install to ~/.swiftpm/bin
echo "Installing to ~/.swiftpm/bin..."
xcrun swift package experimental-install --product appstoreconnect-mcp

# Test version command
echo ""
echo "Installed version:"
appstoreconnect-mcp --version

# Verify installation
if command -v appstoreconnect-mcp &> /dev/null; then
    echo ""
    echo "✓ App Store Connect MCP installed successfully!"
    echo ""

    # Offer to add to Claude config automatically
    echo "Would you like to add this MCP server to Claude Desktop? (y/n)"
    read -r response

    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Adding to Claude Desktop configuration..."

        # Prompt for credentials
        echo ""
        echo "Enter your App Store Connect credentials:"
        echo -n "ASC_KEY_ID: "
        read -r ASC_KEY_ID
        echo -n "ASC_ISSUER_ID: "
        read -r ASC_ISSUER_ID
        echo -n "ASC_PRIVATE_KEY_PATH (full path to .p8 file): "
        read -r ASC_PRIVATE_KEY_PATH

        # Add using claude CLI
        claude add mcp appstoreconnect \
            --command appstoreconnect-mcp \
            --args "--log-level" "info" \
            --env "PATH=\$HOME/.swiftpm/bin:/usr/local/bin:/usr/bin:/bin" \
            --env "ASC_KEY_ID=$ASC_KEY_ID" \
            --env "ASC_ISSUER_ID=$ASC_ISSUER_ID" \
            --env "ASC_PRIVATE_KEY_PATH=$ASC_PRIVATE_KEY_PATH"

        echo ""
        echo "✓ MCP server added to Claude Desktop!"
        echo "Restart Claude Desktop to use the new server."
    else
        echo ""
        echo "Manual configuration:"
        echo "Add this to ~/Library/Application Support/Claude/claude_desktop_config.json:"
        echo ""
        echo '  "appstoreconnect": {'
        echo '    "command": "appstoreconnect-mcp",'
        echo '    "args": ["--log-level", "info"],'
        echo '    "env": {'
        echo '      "PATH": "$HOME/.swiftpm/bin:/usr/local/bin:/usr/bin:/bin",'
        echo '      "ASC_KEY_ID": "YOUR_KEY_ID",'
        echo '      "ASC_ISSUER_ID": "YOUR_ISSUER_ID",'
        echo '      "ASC_PRIVATE_KEY_PATH": "/path/to/AuthKey_XXXXXXXXXX.p8"'
        echo '    }'
        echo '  }'
        echo ""
        echo "Replace placeholder values with your actual credentials."
    fi
else
    echo "Installation failed. Check errors above."
    exit 1
fi
