#!/bin/bash

# GUD Express AAB Build Script
# This script builds a release Android App Bundle for Google Play Store

set -e

echo "=========================================="
echo "GUD Express AAB Build Script"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if key.properties exists
if [ ! -f "android/key.properties" ]; then
    echo -e "${RED}ERROR: android/key.properties not found!${NC}"
    echo "Please create key.properties from key.properties.template"
    echo "See AAB_BUILD_GUIDE.md for instructions"
    exit 1
fi

# Check if keystore file exists
KEYSTORE_PATH=$(grep "storeFile=" android/key.properties | cut -d'=' -f2)
if [ ! -f "$KEYSTORE_PATH" ]; then
    echo -e "${RED}ERROR: Keystore file not found at: $KEYSTORE_PATH${NC}"
    echo "Please generate a keystore or update key.properties"
    echo "See AAB_BUILD_GUIDE.md for instructions"
    exit 1
fi

echo -e "${YELLOW}Step 1/4: Cleaning previous builds...${NC}"
flutter clean
echo -e "${GREEN}✓ Clean completed${NC}"
echo ""

echo -e "${YELLOW}Step 2/4: Getting dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

echo -e "${YELLOW}Step 3/4: Building release AAB...${NC}"
echo "This may take several minutes..."
flutter build appbundle --release
echo -e "${GREEN}✓ AAB build completed${NC}"
echo ""

echo -e "${YELLOW}Step 4/4: Verifying build...${NC}"
AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
if [ -f "$AAB_PATH" ]; then
    AAB_SIZE=$(du -h "$AAB_PATH" | cut -f1)
    echo -e "${GREEN}✓ AAB file created successfully${NC}"
    echo ""
    echo "=========================================="
    echo -e "${GREEN}BUILD SUCCESSFUL!${NC}"
    echo "=========================================="
    echo ""
    echo "AAB Location: $AAB_PATH"
    echo "AAB Size: $AAB_SIZE"
    echo ""
    echo "Next steps:"
    echo "1. Test the AAB using bundletool (see AAB_BUILD_GUIDE.md)"
    echo "2. Upload to Google Play Console"
    echo "3. Create a release in Google Play Console"
    echo ""
else
    echo -e "${RED}ERROR: AAB file was not created${NC}"
    exit 1
fi
