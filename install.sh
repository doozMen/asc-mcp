#!/bin/bash
set -e

echo "Installing App Store Connect MCP server..."

# Build in release mode
echo "Building in release mode..."
swift build -c release

# Remove existing installation if present
if command -v appstoreconnect-mcp &> /dev/null; then
    echo "Removing existing installation..."
    rm -f ~/.swiftpm/bin/appstoreconnect-mcp
fi

# Install to ~/.swiftpm/bin
echo "Installing to ~/.swiftpm/bin..."
swift package experimental-install

# Verify installation
if command -v appstoreconnect-mcp &> /dev/null; then
    echo ""
    echo "Success! App Store Connect MCP installed."
    echo ""
    echo "Add to Claude Desktop config:"
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
    echo "Remember to replace the placeholder values with your actual credentials!"
else
    echo "Installation failed. Check errors above."
    exit 1
fi
