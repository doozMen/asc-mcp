#!/bin/bash
#
# Plugin Validation Script
#
# Validates the App Store Connect MCP Plugin structure and manifests
# before distribution or marketplace submission.
#

set -e

echo "🔍 Validating App Store Connect MCP Plugin..."
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track validation status
ERRORS=0
WARNINGS=0

# Helper functions
error() {
    echo -e "${RED}✗ ERROR: $1${NC}"
    ERRORS=$((ERRORS + 1))
}

warning() {
    echo -e "${YELLOW}⚠ WARNING: $1${NC}"
    WARNINGS=$((WARNINGS + 1))
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

check_file() {
    if [ -f "$1" ]; then
        success "Found: $1"
        return 0
    else
        error "Missing: $1"
        return 1
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        success "Found directory: $1"
        return 0
    else
        error "Missing directory: $1"
        return 1
    fi
}

# 1. Check directory structure
echo "📁 Checking directory structure..."
check_dir ".claude-plugin"
check_dir "commands"
check_dir "agents"
check_dir "assets"
check_dir "Sources"
check_dir "Tests"
echo ""

# 2. Check required plugin files
echo "📄 Checking required files..."
check_file ".claude-plugin/plugin.json"
check_file ".claude-plugin/marketplace.json"
check_file ".claude-plugin/submission-metadata.json"
check_file ".mcp.json"
check_file "Package.swift"
check_file "README.md"
check_file "PLUGIN_README.md"
check_file "INSTALLATION.md"
check_file "CHANGELOG.md"
check_file "LICENSE"
check_file "install.sh"
echo ""

# 3. Check commands
echo "📝 Checking slash commands..."
COMMAND_COUNT=$(find commands -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$COMMAND_COUNT" -gt 0 ]; then
    success "Found $COMMAND_COUNT command(s)"
    find commands -type f -name "*.md" | while read -r cmd; do
        echo "  - $(basename "$cmd")"
    done
else
    warning "No commands found in commands/ directory"
fi
echo ""

# 4. Check agents
echo "🤖 Checking agents..."
AGENT_COUNT=$(find agents -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$AGENT_COUNT" -gt 0 ]; then
    success "Found $AGENT_COUNT agent(s)"
    find agents -type f -name "*.md" | while read -r agent; do
        echo "  - $(basename "$agent")"
    done
else
    warning "No agents found in agents/ directory"
fi
echo ""

# 5. Validate JSON files
echo "🔧 Validating JSON manifests..."

validate_json() {
    local file=$1
    if [ -f "$file" ]; then
        if python3 -m json.tool "$file" > /dev/null 2>&1; then
            success "Valid JSON: $file"
            return 0
        else
            error "Invalid JSON: $file"
            return 1
        fi
    else
        error "File not found: $file"
        return 1
    fi
}

validate_json ".claude-plugin/plugin.json"
validate_json ".claude-plugin/marketplace.json"
validate_json ".claude-plugin/submission-metadata.json"
validate_json ".mcp.json"
echo ""

# 6. Check for required fields in plugin.json
echo "🔍 Checking plugin.json fields..."
if [ -f ".claude-plugin/plugin.json" ]; then
    # Check required fields
    for field in "name" "version" "description" "author" "repository" "license"; do
        if jq -e ".$field" .claude-plugin/plugin.json > /dev/null 2>&1; then
            success "Has required field: $field"
        else
            error "Missing required field: $field"
        fi
    done

    # Check author is object format
    if jq -e '.author | type == "object"' .claude-plugin/plugin.json > /dev/null 2>&1; then
        success "Author field is object format"
    else
        error "Author must be object format with name/email/url"
    fi
fi
echo ""

# 7. Check MCP server executable
echo "🚀 Checking MCP server..."
if command -v appstoreconnect-mcp &> /dev/null; then
    success "MCP server installed at: $(which appstoreconnect-mcp)"
    VERSION=$(appstoreconnect-mcp --version 2>&1 || echo "unknown")
    echo "   Version: $VERSION"
else
    warning "MCP server not installed (run ./install.sh)"
fi
echo ""

# 8. Check Swift project
echo "🦅 Checking Swift project..."
if swift package describe > /dev/null 2>&1; then
    success "Swift package is valid"
else
    error "Swift package validation failed"
fi
echo ""

# 9. Check tests
echo "🧪 Checking tests..."
TEST_COUNT=$(find Tests -type f -name "*.swift" 2>/dev/null | wc -l | tr -d ' ')
if [ "$TEST_COUNT" -gt 0 ]; then
    success "Found $TEST_COUNT test file(s)"
else
    warning "No test files found"
fi
echo ""

# 10. Check assets
echo "🎨 Checking assets..."
if [ -f "assets/icon.png" ]; then
    success "Found icon.png"
else
    warning "Missing assets/icon.png (required for marketplace)"
fi

SCREENSHOT_COUNT=$(find assets -type f -name "screenshot-*.png" 2>/dev/null | wc -l | tr -d ' ')
if [ "$SCREENSHOT_COUNT" -ge 3 ]; then
    success "Found $SCREENSHOT_COUNT screenshot(s)"
elif [ "$SCREENSHOT_COUNT" -gt 0 ]; then
    warning "Found only $SCREENSHOT_COUNT screenshot(s), 3-5 recommended"
else
    warning "No screenshots found (3-5 required for marketplace)"
fi
echo ""

# 11. Check documentation
echo "📚 Checking documentation..."
for doc in "README.md" "PLUGIN_README.md" "INSTALLATION.md" "CONTRIBUTING.md" "CHANGELOG.md" "QUICK_START.md"; do
    if [ -f "$doc" ]; then
        LINES=$(wc -l < "$doc" | tr -d ' ')
        if [ "$LINES" -gt 10 ]; then
            success "$doc ($LINES lines)"
        else
            warning "$doc is very short ($LINES lines)"
        fi
    fi
done
echo ""

# 12. Check .gitignore
echo "🚫 Checking .gitignore..."
if [ -f ".gitignore" ]; then
    if grep -q "\.p8" .gitignore; then
        success ".gitignore excludes .p8 files"
    else
        error ".gitignore should exclude .p8 files (credentials)"
    fi

    if grep -q "\.agent-workspace" .gitignore; then
        success ".gitignore excludes .agent-workspace"
    else
        warning ".gitignore should exclude .agent-workspace"
    fi
fi
echo ""

# 13. Check install script
echo "⚙️  Checking install script..."
if [ -f "install.sh" ]; then
    if [ -x "install.sh" ]; then
        success "install.sh is executable"
    else
        error "install.sh is not executable (run: chmod +x install.sh)"
    fi
fi
echo ""

# 14. Security checks
echo "🔒 Security checks..."
if find . -name "*.p8" -type f 2>/dev/null | grep -q .; then
    error "Found .p8 files in repository! Remove immediately!"
else
    success "No .p8 credential files found"
fi

if find . -name "*.env" -type f 2>/dev/null | grep -q .; then
    warning "Found .env files - ensure they're in .gitignore"
else
    success "No .env files found"
fi
echo ""

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Validation Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
    echo ""
    echo "Your plugin is ready for distribution!"
    echo ""
    echo "Next steps:"
    echo "  1. Create assets (icon + screenshots)"
    echo "  2. Commit and push to GitHub"
    echo "  3. Tag release: git tag -a v1.0.0 -m 'Release v1.0.0'"
    echo "  4. Test self-hosted: /plugin marketplace add github.com/doozMen/asc-mcp"
    echo "  5. Submit to official marketplace"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Validation completed with warnings${NC}"
    echo ""
    echo "Warnings: $WARNINGS"
    echo ""
    echo "These are non-critical but should be addressed before marketplace submission."
    exit 0
else
    echo -e "${RED}❌ Validation failed${NC}"
    echo ""
    echo "Errors: $ERRORS"
    echo "Warnings: $WARNINGS"
    echo ""
    echo "Please fix errors before distribution."
    exit 1
fi
