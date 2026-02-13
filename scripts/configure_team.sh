#!/bin/bash

# Configure Development Team Script
# This script helps set up the development team in the Xcode project
# for code signing

set -e

echo "=========================================="
echo "GUD Express - Configure Development Team"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_FILE="ios/Runner.xcodeproj/project.pbxproj"

# Check if project file exists
if [ ! -f "$PROJECT_FILE" ]; then
    echo -e "${RED}❌ Error: Project file not found at $PROJECT_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}This script will help you configure the Development Team for code signing.${NC}"
echo ""
echo -e "${YELLOW}⚠️  Before continuing:${NC}"
echo "  1. Make sure you have an active Apple Developer account"
echo "  2. Know your Team ID (10-character string, e.g., ABCDE12345)"
echo "  3. You must also configure this in Xcode (we'll show you how)"
echo ""
echo "To find your Team ID:"
echo "  1. Go to https://developer.apple.com/account"
echo "  2. Navigate to Membership section"
echo "  3. Your Team ID is listed there"
echo ""
echo -e "${BLUE}Note:${NC} This script updates the project file, but you'll still need to"
echo "      select your team in Xcode's Signing & Capabilities tab."
echo "      This is required by Apple's code signing policy."
echo ""
read -p "Press Enter to continue (Ctrl+C to cancel)..."
echo ""

# Prompt for Team ID
while true; do
    read -p "Enter your Apple Developer Team ID: " TEAM_ID
    
    # Validate Team ID format (should be 10 alphanumeric characters)
    if [[ $TEAM_ID =~ ^[A-Z0-9]{10}$ ]]; then
        break
    else
        echo -e "${RED}Invalid Team ID format. It should be 10 alphanumeric characters (e.g., ABCDE12345)${NC}"
    fi
done

echo ""
echo -e "${BLUE}🔧 Configuring Development Team...${NC}"

# Note: The project is already configured for automatic code signing with
# DEVELOPMENT_TEAM environment variable. This script helps you set it up.

# Check if DEVELOPMENT_TEAM is already configured in project
if grep -q 'DEVELOPMENT_TEAM = "$(DEVELOPMENT_TEAM)"' "$PROJECT_FILE"; then
    echo -e "${GREEN}✅ Project is configured for automatic code signing${NC}"
    echo "   DEVELOPMENT_TEAM uses environment variable"
else
    echo -e "${YELLOW}⚠️  Project configuration might need updating${NC}"
    echo "   Expected: DEVELOPMENT_TEAM = \"\$(DEVELOPMENT_TEAM)\""
fi

echo ""
echo -e "${BLUE}Setting up environment variable...${NC}"

# Detect shell
SHELL_NAME=$(basename "$SHELL")
case "$SHELL_NAME" in
    bash)
        SHELL_RC="$HOME/.bashrc"
        if [ -f "$HOME/.bash_profile" ]; then
            SHELL_RC="$HOME/.bash_profile"
        fi
        ;;
    zsh)
        SHELL_RC="$HOME/.zshrc"
        ;;
    *)
        SHELL_RC="$HOME/.profile"
        ;;
esac

echo "Detected shell: $SHELL_NAME"
echo "Configuration file: $SHELL_RC"
echo ""

# Check if DEVELOPMENT_TEAM is already set in the shell config
if [ -f "$SHELL_RC" ] && grep -q "export DEVELOPMENT_TEAM=" "$SHELL_RC"; then
    CURRENT_TEAM=$(grep "export DEVELOPMENT_TEAM=" "$SHELL_RC" | tail -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'")
    echo -e "${YELLOW}ℹ️  DEVELOPMENT_TEAM already set in $SHELL_RC${NC}"
    echo "   Current value: $CURRENT_TEAM"
    echo ""
    read -p "Update with new Team ID ($TEAM_ID)? (y/n): " UPDATE
    if [[ $UPDATE =~ ^[Yy]$ ]]; then
        # Comment out old entries
        sed -i.backup "/export DEVELOPMENT_TEAM=/s/^/# /" "$SHELL_RC"
        # Add new entry
        echo "" >> "$SHELL_RC"
        echo "# Apple Developer Team ID for iOS code signing" >> "$SHELL_RC"
        echo "export DEVELOPMENT_TEAM=\"$TEAM_ID\"" >> "$SHELL_RC"
        echo -e "${GREEN}✅ Updated $SHELL_RC${NC}"
        echo "   Old entries commented out, new value added"
    else
        echo "Skipped updating shell configuration"
    fi
else
    # Add DEVELOPMENT_TEAM to shell config
    echo "" >> "$SHELL_RC"
    echo "# Apple Developer Team ID for iOS code signing" >> "$SHELL_RC"
    echo "export DEVELOPMENT_TEAM=\"$TEAM_ID\"" >> "$SHELL_RC"
    echo -e "${GREEN}✅ Added DEVELOPMENT_TEAM to $SHELL_RC${NC}"
fi

# Set for current session
export DEVELOPMENT_TEAM="$TEAM_ID"
echo -e "${GREEN}✅ Set DEVELOPMENT_TEAM for current session${NC}"

# Note: ExportOptions.plist now uses $(DEVELOPMENT_TEAM) environment variable
# No need to modify it directly
EXPORT_OPTIONS="ios/ExportOptions.plist"
if [ -f "$EXPORT_OPTIONS" ]; then
    if grep -q '$(DEVELOPMENT_TEAM)' "$EXPORT_OPTIONS"; then
        echo ""
        echo -e "${GREEN}✅ ExportOptions.plist is configured to use DEVELOPMENT_TEAM variable${NC}"
    else
        echo ""
        echo -e "${YELLOW}⚠️  ExportOptions.plist might need manual update${NC}"
        echo "   Expected: <string>\$(DEVELOPMENT_TEAM)</string>"
    fi
fi

echo ""
echo -e "${GREEN}=========================================="
echo -e "✅ Development Team configured successfully!"
echo -e "==========================================${NC}"
echo ""
echo "Team ID: $TEAM_ID"
echo "Environment variable: DEVELOPMENT_TEAM=$TEAM_ID"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT - Next Steps:${NC}"
echo ""
echo -e "${BLUE}1. Reload your shell to apply the environment variable:${NC}"
echo "   source $SHELL_RC"
echo "   # Or open a new terminal window"
echo ""
echo -e "${BLUE}2. Complete setup in Xcode:${NC}"
echo "   cd ios && open Runner.xcworkspace"
echo ""
echo "   In Xcode:"
echo "     • Select 'Runner' target in left sidebar"
echo "     • Click 'Signing & Capabilities' tab"
echo "     • Check '✓ Automatically manage signing' (should already be checked)"
echo "     • Select your team from 'Team' dropdown"
echo "     • Wait for Xcode to create provisioning profiles"
echo ""
echo -e "${BLUE}3. Verify signing status:${NC}"
echo "     • 'Signing Certificate' should show: Apple Development"
echo "     • 'Provisioning Profile' should show: Xcode Managed Profile"
echo "     • No errors or warnings should appear"
echo ""
echo -e "${BLUE}4. Run the pre-build check:${NC}"
echo "   ./scripts/check_code_signing.sh"
echo ""
echo -e "${BLUE}5. Try building:${NC}"
echo "   flutter build ios --release"
echo ""
echo -e "${BLUE}Troubleshooting:${NC}"
echo "  • If team doesn't appear: Log into Xcode with your Apple ID"
echo "    (Xcode → Settings → Accounts → Add Account)"
echo "  • If profile fails: See ios/CODE_SIGNING_SETUP.md"
echo "  • Run diagnostic: ./scripts/check_ios_setup.sh"
echo ""
echo "📖 Complete documentation: ios/CODE_SIGNING_SETUP.md"
echo ""
