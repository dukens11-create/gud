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
echo ""
echo "To find your Team ID:"
echo "  1. Go to https://developer.apple.com/account"
echo "  2. Navigate to Membership section"
echo "  3. Your Team ID is listed there"
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
        # Add DEVELOPMENT_TEAM in Debug configuration
        sed -i.tmp "/PRODUCT_BUNDLE_IDENTIFIER = com.gudexpress.gud_app;/a\\
				DEVELOPMENT_TEAM = $TEAM_ID;
" "$PROJECT_FILE"
        
        # Remove the temporary file created by sed
        rm -f "${PROJECT_FILE}.tmp"
        
        echo -e "${GREEN}✅ Added DEVELOPMENT_TEAM = $TEAM_ID to project configuration${NC}"
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
echo "Next steps:"
echo "  1. Open ios/Runner.xcworkspace in Xcode"
echo "  2. Select Runner target"
echo "  3. Go to Signing & Capabilities"
echo "  4. Verify your team is selected"
echo "  5. Xcode will automatically create provisioning profiles"
echo ""
echo "Backup files created:"
echo "  - ${PROJECT_FILE}.backup"
echo "  - ${EXPORT_OPTIONS}.backup (if applicable)"
echo ""
echo "If something goes wrong, you can restore from backups."
