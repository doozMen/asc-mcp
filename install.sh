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
            echo "Enter your 1Password secret references:"
            echo "Format: op://vault-name/item-name/field-name"
            echo "Example: op://Private/App Store Connect/ASC Key ID"
            echo ""

            echo -n "ASC_KEY_ID reference: "
            read -r OP_KEY_ID_REF
            echo -n "ASC_ISSUER_ID reference: "
            read -r OP_ISSUER_ID_REF
            echo -n "ASC_PRIVATE_KEY_PATH reference: "
            read -r OP_KEY_PATH_REF

            # Retrieve values from 1Password
            echo ""
            echo "Retrieving credentials from 1Password..."
            ASC_KEY_ID=$(op read "$OP_KEY_ID_REF")
            ASC_ISSUER_ID=$(op read "$OP_ISSUER_ID_REF")
            ASC_PRIVATE_KEY_PATH=$(op read "$OP_KEY_PATH_REF")

            if [ -z "$ASC_KEY_ID" ] || [ -z "$ASC_ISSUER_ID" ] || [ -z "$ASC_PRIVATE_KEY_PATH" ]; then
                echo "Error: Failed to retrieve credentials from 1Password"
                exit 1
            fi

            echo "✓ Credentials retrieved successfully from 1Password"

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

        # Add using claude CLI
        claude mcp add appstoreconnect appstoreconnect-mcp \
            --log-level info \
            -s user \
            -e "PATH=\$HOME/.swiftpm/bin:/usr/local/bin:/usr/bin:/bin" \
            -e "ASC_KEY_ID=$ASC_KEY_ID" \
            -e "ASC_ISSUER_ID=$ASC_ISSUER_ID" \
            -e "ASC_PRIVATE_KEY_PATH=$ASC_PRIVATE_KEY_PATH"

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
