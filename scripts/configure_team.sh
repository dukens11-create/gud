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

# Backup the project file
cp "$PROJECT_FILE" "${PROJECT_FILE}.backup"
echo -e "${GREEN}✅ Project file backed up to ${PROJECT_FILE}.backup${NC}"

# Add DEVELOPMENT_TEAM to build settings
# We need to add it to both Debug and Release configurations

# Function to add DEVELOPMENT_TEAM after PRODUCT_BUNDLE_IDENTIFIER
add_development_team() {
    # Using sed to add DEVELOPMENT_TEAM after PRODUCT_BUNDLE_IDENTIFIER if not already present
    if ! grep -q "DEVELOPMENT_TEAM = $TEAM_ID" "$PROJECT_FILE"; then
        # Check if PRODUCT_BUNDLE_IDENTIFIER exists
        if ! grep -q "PRODUCT_BUNDLE_IDENTIFIER = com.gudexpress.gud_app" "$PROJECT_FILE"; then
            echo -e "${YELLOW}⚠️  Warning: Expected bundle identifier not found in project${NC}"
            echo "   Expected: PRODUCT_BUNDLE_IDENTIFIER = com.gudexpress.gud_app"
            echo "   The project structure might have changed."
            echo ""
            read -p "Continue anyway? (y/n): " CONTINUE
            if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
                echo "Aborted."
                exit 1
            fi
        fi
        
        # Add DEVELOPMENT_TEAM in Debug configuration
        sed -i.tmp "/PRODUCT_BUNDLE_IDENTIFIER = com.gudexpress.gud_app;/a\\
				DEVELOPMENT_TEAM = $TEAM_ID;
" "$PROJECT_FILE"
        
        # Remove the temporary file created by sed
        rm -f "${PROJECT_FILE}.tmp"
        
        # Verify the insertion was successful
        if grep -q "DEVELOPMENT_TEAM = $TEAM_ID" "$PROJECT_FILE"; then
            echo -e "${GREEN}✅ Added DEVELOPMENT_TEAM = $TEAM_ID to project configuration${NC}"
        else
            echo -e "${RED}❌ Failed to add DEVELOPMENT_TEAM to project${NC}"
            echo "   Please configure manually in Xcode"
            exit 1
        fi
    else
        echo -e "${YELLOW}ℹ️  DEVELOPMENT_TEAM already configured${NC}"
    fi
}

add_development_team

# Update ExportOptions.plist with Team ID
EXPORT_OPTIONS="ios/ExportOptions.plist"
if [ -f "$EXPORT_OPTIONS" ]; then
    echo ""
    echo -e "${BLUE}🔧 Updating ExportOptions.plist...${NC}"
    
    # Backup ExportOptions.plist
    cp "$EXPORT_OPTIONS" "${EXPORT_OPTIONS}.backup"
    
    # Replace YOUR_TEAM_ID with actual Team ID
    sed -i.tmp "s/YOUR_TEAM_ID/$TEAM_ID/g" "$EXPORT_OPTIONS"
    rm -f "${EXPORT_OPTIONS}.tmp"
    
    echo -e "${GREEN}✅ Updated ExportOptions.plist with Team ID${NC}"
fi

echo ""
echo -e "${GREEN}=========================================="
echo -e "✅ Development Team configured successfully!"
echo -e "==========================================${NC}"
echo ""
echo "Team ID: $TEAM_ID"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT - Required Manual Steps:${NC}"
echo "Due to Apple's code signing requirements, you must complete setup in Xcode:"
echo ""
echo "  1. Open the workspace:"
echo "     cd ios && open Runner.xcworkspace"
echo ""
echo "  2. In Xcode:"
echo "     • Select 'Runner' target in left sidebar"
echo "     • Click 'Signing & Capabilities' tab"
echo "     • Check '✓ Automatically manage signing'"
echo "     • Select your team from 'Team' dropdown"
echo "     • Wait for Xcode to create provisioning profiles"
echo ""
echo "  3. Verify:"
echo "     • 'Signing Certificate' shows: Apple Development"
echo "     • 'Provisioning Profile' shows: Xcode Managed Profile"
echo "     • No errors or warnings appear"
echo ""
echo -e "${BLUE}Troubleshooting:${NC}"
echo "  • If team doesn't appear: Log into Xcode with your Apple ID"
echo "    (Xcode → Preferences → Accounts → Add Account)"
echo "  • If profile fails: See docs/ios_codesign_setup.md"
echo "  • Run check script: ./scripts/check_ios_setup.sh"
echo ""
echo "Backup files created:"
echo "  - ${PROJECT_FILE}.backup"
if [ -f "${EXPORT_OPTIONS}.backup" ]; then
    echo "  - ${EXPORT_OPTIONS}.backup"
fi
echo ""
echo "📖 Full guide: docs/ios_codesign_setup.md"
echo ""
echo "If something goes wrong, restore from backups."
