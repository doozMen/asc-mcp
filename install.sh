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

        # Check if user wants to use 1Password
        echo ""
        echo "Do you use 1Password for credential management? (y/n)"
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

        # Add to both Claude Desktop and Claude Code
        echo ""
        echo "Adding MCP server to Claude Desktop and Claude Code..."

        # Add to Claude Desktop (user scope)
        claude mcp add -s user appstoreconnect appstoreconnect-mcp \
            -e "PATH=\$HOME/.swiftpm/bin:/usr/local/bin:/usr/bin:/bin" \
            -e "ASC_KEY_ID=$ASC_KEY_ID" \
            -e "ASC_ISSUER_ID=$ASC_ISSUER_ID" \
            -e "ASC_PRIVATE_KEY_PATH=$ASC_PRIVATE_KEY_PATH"

        echo "✓ Added to Claude Desktop"

        # Also add to Claude Code (if different config location)
        # Claude Code uses the same user scope, so one command covers both
        # But we can verify by checking both config files

        echo ""
        echo "✓ MCP server configured for:"
        echo "  - Claude Desktop"
        echo "  - Claude Code"
        echo ""
        echo "Restart Claude Desktop and Claude Code to use the new MCP server."
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
