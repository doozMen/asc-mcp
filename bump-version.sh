#!/bin/bash

# ASC MCP Version Bump Script
# Usage: ./bump-version.sh <new-version>
# Example: ./bump-version.sh 1.0.0-alpha.2
# Example: ./bump-version.sh 2.10.0

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <new-version>"
    echo ""
    echo "Examples:"
    echo "  $0 0.0.1-alpha.1     # Bump to alpha release"
    echo "  $0 0.1.0-beta.1      # Bump to beta release"
    echo "  $0 1.0.0             # Bump to stable release"
    echo ""
    echo "Version will be updated in:"
    echo "  - .claude-plugin/plugin.json (plugin version)"
    echo "  - Sources/asc-mcp/App.swift (CLI version)"
    echo "  - Sources/asc-mcp/MCPServer.swift (MCP server version)"
    exit 1
fi

NEW_VERSION=$1

# Validate version format (basic check)
if ! [[ $NEW_VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
    echo "Error: Invalid version format: $NEW_VERSION"
    echo "Expected format: X.Y.Z or X.Y.Z-prerelease (e.g., 1.0.0, 1.0.0-alpha.1)"
    exit 1
fi

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Update plugin.json
PLUGIN_JSON="$CURRENT_DIR/.claude-plugin/plugin.json"
if [ -f "$PLUGIN_JSON" ]; then
    sed -i '' "s/\"version\": \"[^\"]*\"/\"version\": \"$NEW_VERSION\"/" "$PLUGIN_JSON"
    echo "✓ Updated plugin.json to version $NEW_VERSION"
else
    echo "⚠ Warning: plugin.json not found at $PLUGIN_JSON"
fi

# Update App.swift CLI version
APP_SWIFT="$CURRENT_DIR/Sources/asc-mcp/App.swift"
if [ -f "$APP_SWIFT" ]; then
    sed -i '' "s/version: \"[^\"]*\"/version: \"$NEW_VERSION\"/" "$APP_SWIFT"
    echo "✓ Updated App.swift to version $NEW_VERSION"
else
    echo "⚠ Warning: App.swift not found at $APP_SWIFT"
fi

# Update MCPServer.swift server version
MCP_SWIFT="$CURRENT_DIR/Sources/asc-mcp/MCPServer.swift"
if [ -f "$MCP_SWIFT" ]; then
    sed -i '' "s/version: \"[^\"]*\"/version: \"$NEW_VERSION\"/" "$MCP_SWIFT"
    echo "✓ Updated MCPServer.swift to version $NEW_VERSION"
else
    echo "⚠ Warning: MCPServer.swift not found at $MCP_SWIFT"
fi

echo ""
echo "Version bump complete! ✨"
echo "New version: $NEW_VERSION"
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff"
echo "  2. Commit changes: git add . && git commit -m 'chore: Bump version to $NEW_VERSION'"
echo "  3. Create git tag: git tag v$NEW_VERSION"
echo "  4. Build: swift build -c release"
echo "  5. Install: ./install.sh"
