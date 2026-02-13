#!/bin/bash

# iOS Code Signing Pre-Build Check
# This script validates code signing requirements before building

set -e

echo "================================================"
echo "  GUD Express - iOS Code Signing Pre-Build Check"
echo "================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Track if there are any errors
HAS_ERRORS=0
HAS_WARNINGS=0

echo -e "${BLUE}Checking code signing configuration...${NC}"
echo ""

# Check 1: Verify Xcode is installed
echo -n "Checking Xcode installation... "
if command -v xcodebuild &> /dev/null; then
    XCODE_VERSION=$(xcodebuild -version | head -n 1)
    echo -e "${GREEN}✓ $XCODE_VERSION${NC}"
else
    echo -e "${RED}✗ Xcode not found${NC}"
    echo "  Please install Xcode from the App Store"
    HAS_ERRORS=1
fi

# Check 2: Verify project file exists
echo -n "Checking project file... "
PROJECT_FILE="ios/Runner.xcodeproj/project.pbxproj"
if [ -f "$PROJECT_FILE" ]; then
    echo -e "${GREEN}✓ Found${NC}"
else
    echo -e "${RED}✗ Not found${NC}"
    echo "  Expected: $PROJECT_FILE"
    HAS_ERRORS=1
fi

# Check 3: Verify automatic code signing is enabled
echo -n "Checking automatic code signing... "
if grep -q "CODE_SIGN_STYLE = Automatic" "$PROJECT_FILE" 2>/dev/null; then
    echo -e "${GREEN}✓ Enabled${NC}"
else
    echo -e "${RED}✗ Not enabled${NC}"
    echo "  Run: ./scripts/configure_team.sh to fix"
    HAS_ERRORS=1
fi

# Check 4: Verify bundle identifier is configured
echo -n "Checking bundle identifier... "
BUNDLE_ID="com.gudexpress.gud_app"
if grep -q "PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID" "$PROJECT_FILE" 2>/dev/null; then
    echo -e "${GREEN}✓ $BUNDLE_ID${NC}"
else
    echo -e "${YELLOW}⚠ Bundle identifier might not be configured correctly${NC}"
    HAS_WARNINGS=1
fi

# Check 5: Check for DEVELOPMENT_TEAM environment variable
echo -n "Checking DEVELOPMENT_TEAM variable... "
if [ -n "$DEVELOPMENT_TEAM" ]; then
    echo -e "${GREEN}✓ Set to: $DEVELOPMENT_TEAM${NC}"
else
    echo -e "${YELLOW}⚠ Not set${NC}"
    echo "  Set it with: export DEVELOPMENT_TEAM=YOUR_TEAM_ID"
    echo "  Or configure it in Xcode: open ios/Runner.xcworkspace"
    HAS_WARNINGS=1
fi

# Check 6: Check if user is logged into Xcode (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -n "Checking Xcode account status... "
    
    # Try to get account info from Xcode preferences
    ACCOUNTS_PLIST="$HOME/Library/Preferences/com.apple.dt.Xcode.plist"
    if [ -f "$ACCOUNTS_PLIST" ]; then
        # Check if there are any accounts configured
        ACCOUNT_COUNT=$(defaults read com.apple.dt.Xcode 2>/dev/null | grep -c "DVTDeveloperAccountRegistry" || echo "0")
        if [ "$ACCOUNT_COUNT" -gt 0 ]; then
            echo -e "${GREEN}✓ Accounts configured${NC}"
        else
            echo -e "${YELLOW}⚠ No accounts found${NC}"
            echo "  Add your Apple ID in Xcode → Settings → Accounts"
            HAS_WARNINGS=1
        fi
    else
        echo -e "${YELLOW}⚠ Cannot verify (Xcode not configured)${NC}"
        HAS_WARNINGS=1
    fi
fi

# Check 7: Verify Flutter is installed and can build iOS
echo -n "Checking Flutter for iOS... "
if command -v flutter &> /dev/null; then
    if flutter doctor | grep -q "Xcode.*✓" || flutter doctor | grep -q "\[✓\] Xcode"; then
        echo -e "${GREEN}✓ Ready${NC}"
    else
        echo -e "${YELLOW}⚠ Flutter iOS toolchain might have issues${NC}"
        echo "  Run: flutter doctor -v for details"
        HAS_WARNINGS=1
    fi
else
    echo -e "${RED}✗ Flutter not found${NC}"
    echo "  Install Flutter from https://flutter.dev"
    HAS_ERRORS=1
fi

# Check 8: Check for CocoaPods
echo -n "Checking CocoaPods... "
if command -v pod &> /dev/null; then
    POD_VERSION=$(pod --version)
    echo -e "${GREEN}✓ Version $POD_VERSION${NC}"
else
    echo -e "${RED}✗ Not installed${NC}"
    echo "  Install with: sudo gem install cocoapods"
    HAS_ERRORS=1
fi

# Check 9: Verify ios/Podfile exists
echo -n "Checking Podfile... "
if [ -f "ios/Podfile" ]; then
    echo -e "${GREEN}✓ Found${NC}"
else
    echo -e "${RED}✗ Not found${NC}"
    echo "  Expected: ios/Podfile"
    HAS_ERRORS=1
fi

echo ""
echo "================================================"

# Summary
if [ $HAS_ERRORS -eq 0 ] && [ $HAS_WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "You're ready to build for iOS:"
    echo "  • For simulator: flutter build ios --simulator"
    echo "  • For device:    flutter build ios --release"
    echo ""
    exit 0
elif [ $HAS_ERRORS -gt 0 ]; then
    echo -e "${RED}✗ Found critical issues that must be fixed before building${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Fix the errors listed above"
    echo "  2. Run this script again to verify"
    echo "  3. See ios/CODE_SIGNING_SETUP.md for detailed instructions"
    echo ""
    exit 1
else
    echo -e "${YELLOW}⚠ Found warnings - build might work but could have issues${NC}"
    echo ""
    echo "Recommendations:"
    echo "  1. Review the warnings above"
    echo "  2. Set DEVELOPMENT_TEAM: export DEVELOPMENT_TEAM=YOUR_TEAM_ID"
    echo "  3. Configure team in Xcode: open ios/Runner.xcworkspace"
    echo "  4. See ios/CODE_SIGNING_SETUP.md for detailed instructions"
    echo ""
    echo "You can try building, but you might encounter code signing errors."
    echo ""
    
    # Ask if user wants to continue
    read -p "Continue with build anyway? (y/N): " CONTINUE
    if [[ "$CONTINUE" =~ ^[Yy]$ ]]; then
        exit 0
    else
        exit 1
    fi
fi
