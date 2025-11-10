#!/bin/bash
# Master Asset Generation Script
# Generates all required assets for marketplace submission

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR"

echo "═══════════════════════════════════════════════════════════════"
echo "  App Store Connect MCP Plugin - Asset Generation"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "This script will help you generate all required assets for"
echo "marketplace submission:"
echo ""
echo "  Required:"
echo "    - Icon (1024x1024px PNG)"
echo "    - 3-5 Screenshots (1280x800px or larger)"
echo ""
echo "Assets will be saved to: $ASSETS_DIR"
echo ""

# Function to check if file exists
file_exists() {
    [ -f "$1" ]
}

# Function to display menu
show_menu() {
    echo "──────────────────────────────────────────────────────────────"
    echo "What would you like to do?"
    echo "──────────────────────────────────────────────────────────────"
    echo ""
    echo "  1) Generate icon (automatic)"
    echo "  2) Capture screenshots (interactive)"
    echo "  3) View asset status"
    echo "  4) Validate assets"
    echo "  5) Open example outputs for screenshots"
    echo "  6) Open icon design guide"
    echo "  7) Commit assets to git"
    echo "  8) Update manifest URLs"
    echo "  9) Exit"
    echo ""
}

# Function to generate icon
generate_icon() {
    echo ""
    echo "Generating icon..."
    echo "──────────────────────────────────────────────────────────────"
    echo ""

    if file_exists "$ASSETS_DIR/icon.png"; then
        echo "⚠️  Warning: icon.png already exists"
        read -p "Overwrite existing icon? (y/N): " overwrite
        if [[ "$overwrite" != "y" && "$overwrite" != "Y" ]]; then
            echo "Cancelled"
            return
        fi
    fi

    # Run Swift icon generator
    if file_exists "$ASSETS_DIR/IconGenerator.swift"; then
        swift "$ASSETS_DIR/IconGenerator.swift"

        if file_exists "$ASSETS_DIR/icon.png"; then
            echo ""
            read -p "Open icon for review? (y/N): " review
            if [[ "$review" == "y" || "$review" == "Y" ]]; then
                open "$ASSETS_DIR/icon.png"
            fi
        fi
    else
        echo "✗ IconGenerator.swift not found"
        echo "Please ensure IconGenerator.swift exists in: $ASSETS_DIR"
    fi

    echo ""
    read -p "Press ENTER to continue..."
}

# Function to capture screenshots
capture_screenshots() {
    echo ""
    echo "Launching screenshot capture tool..."
    echo "──────────────────────────────────────────────────────────────"
    echo ""

    if file_exists "$ASSETS_DIR/capture-screenshots.sh"; then
        "$ASSETS_DIR/capture-screenshots.sh"
    else
        echo "✗ capture-screenshots.sh not found"
        echo "Please ensure capture-screenshots.sh exists in: $ASSETS_DIR"
        echo ""
        read -p "Press ENTER to continue..."
    fi
}

# Function to view asset status
view_status() {
    echo ""
    echo "Asset Status"
    echo "──────────────────────────────────────────────────────────────"
    echo ""

    # Check icon
    if file_exists "$ASSETS_DIR/icon.png"; then
        local icon_size=$(sips -g pixelWidth -g pixelHeight "$ASSETS_DIR/icon.png" 2>/dev/null | grep -E 'pixelWidth|pixelHeight' | awk '{print $2}' | tr '\n' 'x' | sed 's/x$/px/')
        local icon_filesize=$(du -h "$ASSETS_DIR/icon.png" | cut -f1)
        echo "✓ Icon: icon.png ($icon_size, $icon_filesize)"
    else
        echo "✗ Icon: Missing (required)"
    fi

    echo ""

    # Check screenshots
    local screenshot_count=0
    for i in {1..5}; do
        if file_exists "$ASSETS_DIR/screenshot-$i.png"; then
            local size=$(sips -g pixelWidth -g pixelHeight "$ASSETS_DIR/screenshot-$i.png" 2>/dev/null | grep -E 'pixelWidth|pixelHeight' | awk '{print $2}' | tr '\n' 'x' | sed 's/x$/px/')
            local filesize=$(du -h "$ASSETS_DIR/screenshot-$i.png" | cut -f1)
            echo "✓ Screenshot $i: screenshot-$i.png ($size, $filesize)"
            ((screenshot_count++))
        fi
    done

    if [ $screenshot_count -eq 0 ]; then
        echo "✗ Screenshots: None captured (3-5 required)"
    elif [ $screenshot_count -lt 3 ]; then
        echo "⚠️  Screenshots: $screenshot_count captured (3-5 required, need at least 3)"
    else
        echo ""
        echo "✓ Screenshots: $screenshot_count captured"
    fi

    echo ""

    # Summary
    local ready=true
    if ! file_exists "$ASSETS_DIR/icon.png"; then
        ready=false
    fi
    if [ $screenshot_count -lt 3 ]; then
        ready=false
    fi

    echo "──────────────────────────────────────────────────────────────"
    if [ "$ready" = true ]; then
        echo "✓ Assets ready for marketplace submission!"
    else
        echo "⚠️  Assets incomplete - please complete required items above"
    fi
    echo "──────────────────────────────────────────────────────────────"
    echo ""
    read -p "Press ENTER to continue..."
}

# Function to validate assets
validate_assets() {
    echo ""
    echo "Validating Assets"
    echo "──────────────────────────────────────────────────────────────"
    echo ""

    local errors=0

    # Validate icon
    if file_exists "$ASSETS_DIR/icon.png"; then
        echo "Checking icon.png..."

        # Check dimensions
        local width=$(sips -g pixelWidth "$ASSETS_DIR/icon.png" 2>/dev/null | grep pixelWidth | awk '{print $2}')
        local height=$(sips -g pixelHeight "$ASSETS_DIR/icon.png" 2>/dev/null | grep pixelHeight | awk '{print $2}')

        if [ "$width" -ge 512 ] && [ "$height" -ge 512 ]; then
            if [ "$width" -eq "$height" ]; then
                echo "  ✓ Dimensions: ${width}x${height}px (valid)"
            else
                echo "  ✗ Dimensions: ${width}x${height}px (must be square)"
                ((errors++))
            fi
        else
            echo "  ✗ Dimensions: ${width}x${height}px (minimum 512x512px)"
            ((errors++))
        fi

        # Check format
        local format=$(sips -g format "$ASSETS_DIR/icon.png" 2>/dev/null | grep format | awk '{print $2}')
        if [ "$format" = "png" ]; then
            echo "  ✓ Format: PNG"
        else
            echo "  ✗ Format: $format (must be PNG)"
            ((errors++))
        fi

        # Recommend 1024x1024
        if [ "$width" -eq 1024 ] && [ "$height" -eq 1024 ]; then
            echo "  ✓ Recommended size: 1024x1024px"
        elif [ "$width" -ge 512 ] && [ "$height" -ge 512 ]; then
            echo "  ⚠️  Recommended: 1024x1024px (current: ${width}x${height}px)"
        fi
    else
        echo "✗ icon.png not found"
        ((errors++))
    fi

    echo ""

    # Validate screenshots
    local screenshot_count=0
    for i in {1..5}; do
        if file_exists "$ASSETS_DIR/screenshot-$i.png"; then
            echo "Checking screenshot-$i.png..."
            ((screenshot_count++))

            local width=$(sips -g pixelWidth "$ASSETS_DIR/screenshot-$i.png" 2>/dev/null | grep pixelWidth | awk '{print $2}')
            local height=$(sips -g pixelHeight "$ASSETS_DIR/screenshot-$i.png" 2>/dev/null | grep pixelHeight | awk '{print $2}')

            if [ "$width" -ge 1280 ] && [ "$height" -ge 800 ]; then
                echo "  ✓ Dimensions: ${width}x${height}px"
            else
                echo "  ⚠️  Dimensions: ${width}x${height}px (recommended: 1280x800px minimum)"
            fi

            local format=$(sips -g format "$ASSETS_DIR/screenshot-$i.png" 2>/dev/null | grep format | awk '{print $2}')
            echo "  ✓ Format: $(echo $format | tr '[:lower:]' '[:upper:]')"
        fi
    done

    if [ $screenshot_count -lt 3 ]; then
        echo "✗ Only $screenshot_count screenshot(s) found (3-5 required)"
        ((errors++))
    elif [ $screenshot_count -gt 5 ]; then
        echo "⚠️  $screenshot_count screenshots found (3-5 recommended)"
    else
        echo "✓ Screenshot count: $screenshot_count (valid)"
    fi

    echo ""
    echo "──────────────────────────────────────────────────────────────"

    if [ $errors -eq 0 ]; then
        echo "✓ All assets valid!"
    else
        echo "✗ Found $errors error(s) - please fix before submitting"
    fi

    echo "──────────────────────────────────────────────────────────────"
    echo ""
    read -p "Press ENTER to continue..."
}

# Function to open examples
open_examples() {
    echo ""
    if file_exists "$ASSETS_DIR/screenshot-examples.md"; then
        open "$ASSETS_DIR/screenshot-examples.md"
        echo "✓ Opened screenshot-examples.md"
    else
        echo "✗ screenshot-examples.md not found"
    fi
    echo ""
    read -p "Press ENTER to continue..."
}

# Function to open icon guide
open_icon_guide() {
    echo ""
    if file_exists "$ASSETS_DIR/ICON_DESIGN_GUIDE.md"; then
        open "$ASSETS_DIR/ICON_DESIGN_GUIDE.md"
        echo "✓ Opened ICON_DESIGN_GUIDE.md"
    else
        echo "✗ ICON_DESIGN_GUIDE.md not found"
    fi
    echo ""
    read -p "Press ENTER to continue..."
}

# Function to commit assets
commit_assets() {
    echo ""
    echo "Committing Assets to Git"
    echo "──────────────────────────────────────────────────────────────"
    echo ""

    cd "$(dirname "$ASSETS_DIR")"

    # Check what assets exist
    local assets_to_commit=()

    if file_exists "$ASSETS_DIR/icon.png"; then
        assets_to_commit+=("assets/icon.png")
    fi

    for i in {1..5}; do
        if file_exists "$ASSETS_DIR/screenshot-$i.png"; then
            assets_to_commit+=("assets/screenshot-$i.png")
        fi
    done

    if [ ${#assets_to_commit[@]} -eq 0 ]; then
        echo "✗ No assets found to commit"
        echo ""
        read -p "Press ENTER to continue..."
        return
    fi

    echo "Assets to commit:"
    for asset in "${assets_to_commit[@]}"; do
        echo "  - $asset"
    done
    echo ""

    read -p "Commit these assets? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Cancelled"
        echo ""
        read -p "Press ENTER to continue..."
        return
    fi

    # Git add
    git add "${assets_to_commit[@]}"

    # Git commit
    git commit -m "feat(assets): add plugin marketplace assets

- Add icon.png (1024x1024px)
- Add ${#assets_to_commit[@]} screenshot(s) for marketplace listing

Screenshots show:
- Download latest dSYMs workflow
- Upload to Firebase Crashlytics
- Build status checking
- Credential setup guide
- Xcode archive management"

    echo ""
    echo "✓ Assets committed"
    echo ""

    read -p "Push to remote? (y/N): " push
    if [[ "$push" == "y" || "$push" == "Y" ]]; then
        git push origin main
        echo "✓ Pushed to remote"
    fi

    echo ""
    read -p "Press ENTER to continue..."
}

# Function to update manifest URLs
update_manifests() {
    echo ""
    echo "Updating Manifest URLs"
    echo "──────────────────────────────────────────────────────────────"
    echo ""
    echo "After committing assets to GitHub, you need to update these files"
    echo "with GitHub raw URLs:"
    echo ""
    echo "  1. .claude-plugin/plugin.json"
    echo "  2. .claude-plugin/submission-metadata.json"
    echo "  3. .claude-plugin/marketplace.json (if using)"
    echo ""
    echo "GitHub raw URL format:"
    echo "  https://raw.githubusercontent.com/doozMen/asc-mcp/main/assets/icon.png"
    echo "  https://raw.githubusercontent.com/doozMen/asc-mcp/main/assets/screenshot-1.png"
    echo ""
    echo "See MARKETPLACE_SUBMISSION_GUIDE.md for detailed instructions"
    echo ""
    read -p "Open MARKETPLACE_SUBMISSION_GUIDE.md? (y/N): " open_guide
    if [[ "$open_guide" == "y" || "$open_guide" == "Y" ]]; then
        open "$(dirname "$ASSETS_DIR")/MARKETPLACE_SUBMISSION_GUIDE.md"
    fi
    echo ""
    read -p "Press ENTER to continue..."
}

# Main loop
while true; do
    clear
    show_menu
    read -p "Select option (1-9): " choice

    case $choice in
    1) generate_icon ;;
    2) capture_screenshots ;;
    3) view_status ;;
    4) validate_assets ;;
    5) open_examples ;;
    6) open_icon_guide ;;
    7) commit_assets ;;
    8) update_manifests ;;
    9)
        echo ""
        echo "Exiting. Good luck with your marketplace submission!"
        echo ""
        exit 0
        ;;
    *)
        echo ""
        echo "Invalid option. Please select 1-9."
        sleep 2
        ;;
    esac
done
