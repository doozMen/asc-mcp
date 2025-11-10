#!/bin/bash
# Screenshot Capture Helper Script
# Helps capture the 5 required screenshots for marketplace submission

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR"

echo "═══════════════════════════════════════════════════════════════"
echo "  App Store Connect MCP Plugin - Screenshot Capture Helper"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "This script will help you capture 5 screenshots for marketplace"
echo "submission using macOS built-in screencapture tool."
echo ""
echo "Required screenshots:"
echo "  1. Download latest dSYMs workflow"
echo "  2. Upload to Firebase Crashlytics"
echo "  3. Build status checking"
echo "  4. Interactive credential setup"
echo "  5. Find Xcode archives"
echo ""
echo "Screenshots will be saved to: $ASSETS_DIR"
echo ""

# Function to capture a single screenshot
capture_screenshot() {
    local number=$1
    local description=$2
    local filename="screenshot-${number}.png"
    local filepath="${ASSETS_DIR}/${filename}"

    echo "──────────────────────────────────────────────────────────────"
    echo "Screenshot ${number}/5: ${description}"
    echo "──────────────────────────────────────────────────────────────"
    echo ""
    echo "Steps:"
    echo "  1. Set up the Claude Code window with the example interaction"
    echo "  2. Press ENTER when ready to capture"
    echo "  3. Click on the Claude Code window to capture it"
    echo ""
    echo "Refer to: assets/screenshot-examples.md for example output"
    echo ""
    read -p "Press ENTER when ready to capture, or 's' to skip: " response

    if [[ "$response" == "s" ]]; then
        echo "Skipped screenshot ${number}"
        echo ""
        return
    fi

    echo "Capturing screenshot in 3 seconds..."
    sleep 1
    echo "2..."
    sleep 1
    echo "1..."
    sleep 1

    # Capture the active window
    # -w: window mode (click to select window)
    # -T 0: no delay
    screencapture -w -T 0 "$filepath"

    if [ -f "$filepath" ]; then
        echo "✓ Screenshot saved: ${filename}"

        # Get dimensions
        local dimensions=$(sips -g pixelWidth -g pixelHeight "$filepath" 2>/dev/null | grep -E 'pixelWidth|pixelHeight' | awk '{print $2}')
        local width=$(echo "$dimensions" | head -n1)
        local height=$(echo "$dimensions" | tail -n1)

        echo "  Dimensions: ${width}x${height}px"

        # Check if dimensions meet requirements
        if [ "$width" -lt 1280 ] || [ "$height" -lt 800 ]; then
            echo "  ⚠️  Warning: Screenshot is smaller than recommended 1280x800px"
        else
            echo "  ✓ Dimensions OK"
        fi

        # Get file size
        local size=$(du -h "$filepath" | cut -f1)
        echo "  File size: ${size}"

        # Open screenshot for review
        echo ""
        read -p "Open screenshot for review? (y/N): " review
        if [[ "$review" == "y" || "$review" == "Y" ]]; then
            open "$filepath"
        fi
    else
        echo "✗ Failed to capture screenshot"
    fi

    echo ""
}

# Main capture sequence
echo "Starting screenshot capture sequence..."
echo ""

capture_screenshot 1 "Download latest dSYMs workflow"
capture_screenshot 2 "Upload dSYMs to Firebase Crashlytics"
capture_screenshot 3 "Check build status across apps"
capture_screenshot 4 "Interactive credential setup guide"
capture_screenshot 5 "Find and manage Xcode archives"

echo "═══════════════════════════════════════════════════════════════"
echo "  Screenshot Capture Complete!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "Captured screenshots:"
ls -lh "${ASSETS_DIR}"/screenshot-*.png 2>/dev/null || echo "No screenshots captured"
echo ""
echo "Next steps:"
echo "  1. Review screenshots in Preview/Finder"
echo "  2. Edit if needed (redact sensitive info, crop, annotate)"
echo "  3. Ensure all are 1280x800px or larger"
echo "  4. Commit to git:"
echo "     git add assets/screenshot-*.png"
echo "     git commit -m 'feat(assets): add marketplace screenshots'"
echo "     git push origin main"
echo "  5. Update submission-metadata.json with GitHub raw URLs"
echo "  6. Validate plugin: /plugin validate ."
echo ""
echo "See assets/screenshot-examples.md for content guidelines"
echo ""
