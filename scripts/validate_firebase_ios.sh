#!/bin/bash

##############################################################################
# iOS Firebase Configuration Validation Script
# 
# This script validates that GoogleService-Info.plist:
# 1. Exists in the correct location
# 2. Does not contain placeholder values
# 3. Contains all required keys
# 4. Has valid structure
#
# Usage: ./scripts/validate_firebase_ios.sh
# Exit codes:
#   0 - Validation passed
#   1 - Validation failed
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PLIST_PATH="ios/Runner/GoogleService-Info.plist"
REQUIRED_KEYS=(
    "CLIENT_ID"
    "REVERSED_CLIENT_ID"
    "GOOGLE_APP_ID"
    "API_KEY"
    "PROJECT_ID"
    "BUNDLE_ID"
    "GCM_SENDER_ID"
)

# Counters
ERRORS=0
WARNINGS=0

echo -e "${BLUE}🔍 iOS Firebase Configuration Validation${NC}"
echo ""

##############################################################################
# Check if file exists
##############################################################################
echo -n "Checking if GoogleService-Info.plist exists... "
if [ ! -f "$PLIST_PATH" ]; then
    echo -e "${RED}❌ FAILED${NC}"
    echo ""
    echo -e "${RED}ERROR: GoogleService-Info.plist not found at: $PLIST_PATH${NC}"
    echo ""
    echo "To fix this issue:"
    echo "  1. Download GoogleService-Info.plist from Firebase Console"
    echo "     URL: https://console.firebase.google.com/project/gud-express/settings/general"
    echo "  2. Place it at: $PLIST_PATH"
    echo "  3. See docs/FIREBASE_IOS_SETUP.md for detailed instructions"
    echo ""
    exit 1
else
    echo -e "${GREEN}✅ OK${NC}"
fi

##############################################################################
# Check for placeholder values
##############################################################################
echo -n "Checking for placeholder values... "
if grep -q "placeholder" "$PLIST_PATH"; then
    echo -e "${RED}❌ FAILED${NC}"
    echo ""
    echo -e "${RED}ERROR: Placeholder values detected in $PLIST_PATH${NC}"
    echo ""
    echo "Found placeholder values in the following locations:"
    grep -n "placeholder" "$PLIST_PATH" | while IFS=: read -r line_num line_content; do
        echo "  Line $line_num: ${line_content}"
    done
    echo ""
    echo "To fix this issue:"
    echo "  1. Go to Firebase Console: https://console.firebase.google.com/project/gud-express"
    echo "  2. Navigate to Project Settings > General"
    echo "  3. Scroll to 'Your apps' section"
    echo "  4. Find or register iOS app with Bundle ID: com.gudexpress.gud_app"
    echo "  5. Download the correct GoogleService-Info.plist"
    echo "  6. Replace $PLIST_PATH with the downloaded file"
    echo ""
    echo "See docs/FIREBASE_IOS_SETUP.md for detailed step-by-step instructions"
    echo ""
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✅ OK${NC}"
fi

##############################################################################
# Check for required keys
##############################################################################
echo -n "Checking for required keys... "
MISSING_KEYS=()

for key in "${REQUIRED_KEYS[@]}"; do
    if ! grep -q "<key>$key</key>" "$PLIST_PATH"; then
        MISSING_KEYS+=("$key")
    fi
done

if [ ${#MISSING_KEYS[@]} -gt 0 ]; then
    echo -e "${RED}❌ FAILED${NC}"
    echo ""
    echo -e "${RED}ERROR: Missing required keys in $PLIST_PATH:${NC}"
    for key in "${MISSING_KEYS[@]}"; do
        echo "  - $key"
    done
    echo ""
    echo "The GoogleService-Info.plist file is incomplete or corrupted."
    echo "Please download a fresh copy from Firebase Console."
    echo ""
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✅ OK${NC}"
fi

##############################################################################
# Check PROJECT_ID value
##############################################################################
echo -n "Checking PROJECT_ID value... "
if grep -A 1 "<key>PROJECT_ID</key>" "$PLIST_PATH" | grep -q "<string>gud-express</string>"; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${YELLOW}⚠️  WARNING${NC}"
    echo ""
    echo -e "${YELLOW}WARNING: PROJECT_ID may not be set to 'gud-express'${NC}"
    echo "Expected: gud-express"
    echo "Actual: $(grep -A 1 "<key>PROJECT_ID</key>" "$PLIST_PATH" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/' | xargs)"
    echo ""
    echo "This may be intentional if using a different Firebase project."
    echo "If not, please download the correct file from Firebase Console."
    echo ""
    WARNINGS=$((WARNINGS + 1))
fi

##############################################################################
# Check BUNDLE_ID value
##############################################################################
echo -n "Checking BUNDLE_ID value... "
if grep -A 1 "<key>BUNDLE_ID</key>" "$PLIST_PATH" | grep -q "<string>com.gudexpress.gud_app</string>"; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${YELLOW}⚠️  WARNING${NC}"
    echo ""
    echo -e "${YELLOW}WARNING: BUNDLE_ID may not match expected value${NC}"
    echo "Expected: com.gudexpress.gud_app"
    echo "Actual: $(grep -A 1 "<key>BUNDLE_ID</key>" "$PLIST_PATH" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/' | xargs)"
    echo ""
    echo "This may be intentional if using a custom bundle ID."
    echo "Ensure this matches your iOS app configuration in Xcode."
    echo ""
    WARNINGS=$((WARNINGS + 1))
fi

##############################################################################
# Validate XML structure
##############################################################################
echo -n "Validating XML structure... "
if command -v xmllint &> /dev/null; then
    if xmllint --noout "$PLIST_PATH" 2>/dev/null; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${RED}❌ FAILED${NC}"
        echo ""
        echo -e "${RED}ERROR: Invalid XML structure in $PLIST_PATH${NC}"
        echo ""
        echo "The file may be corrupted. Please download a fresh copy from Firebase Console."
        echo ""
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${YELLOW}⚠️  SKIPPED${NC} (xmllint not available)"
fi

##############################################################################
# Check file permissions
##############################################################################
echo -n "Checking file permissions... "
if [ -r "$PLIST_PATH" ]; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ FAILED${NC}"
    echo ""
    echo -e "${RED}ERROR: Cannot read $PLIST_PATH${NC}"
    echo ""
    echo "File permissions may be incorrect. Try:"
    echo "  chmod 644 $PLIST_PATH"
    echo ""
    ERRORS=$((ERRORS + 1))
fi

##############################################################################
# Summary
##############################################################################
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
    echo ""
    echo "Your iOS Firebase configuration is valid and ready to use."
    echo ""
    exit 0
elif [ $ERRORS -eq 0 ] && [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Validation completed with $WARNINGS warning(s)${NC}"
    echo ""
    echo "Your configuration may work, but please review the warnings above."
    echo ""
    exit 0
else
    echo -e "${RED}❌ Validation failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
    echo ""
    echo "Please fix the errors above before building for iOS."
    echo ""
    echo "For detailed setup instructions, see:"
    echo "  docs/FIREBASE_IOS_SETUP.md"
    echo ""
    echo "For quick help:"
    echo "  1. Go to: https://console.firebase.google.com/project/gud-express/settings/general"
    echo "  2. Download GoogleService-Info.plist for iOS app"
    echo "  3. Replace $PLIST_PATH with the downloaded file"
    echo "  4. Run this script again: ./scripts/validate_firebase_ios.sh"
    echo ""
    exit 1
fi
