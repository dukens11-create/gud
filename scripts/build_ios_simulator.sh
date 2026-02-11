#!/bin/bash

# Build iOS Simulator App Script
# This script builds the GUD Express app for iOS simulator
# No code signing or provisioning profiles required for simulator builds

set -e

echo "=========================================="
echo "GUD Express - iOS Simulator Build"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Error: Flutter is not installed or not in PATH${NC}"
    echo "Please install Flutter: https://docs.flutter.dev/get-started/install"
    exit 1
fi

echo -e "${BLUE}📋 Flutter Doctor${NC}"
flutter doctor -v
echo ""

# Clean previous builds
echo -e "${BLUE}🧹 Cleaning previous builds...${NC}"
flutter clean
echo -e "${GREEN}✅ Clean complete${NC}"
echo ""

# Get dependencies
echo -e "${BLUE}📦 Getting dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

# Install CocoaPods dependencies
echo -e "${BLUE}🍎 Installing CocoaPods dependencies...${NC}"
cd ios
pod install
cd ..
echo -e "${GREEN}✅ CocoaPods dependencies installed${NC}"
echo ""

# Build for simulator
echo -e "${BLUE}🔨 Building for iOS simulator...${NC}"
flutter build ios --simulator --debug
echo ""

# Check if build was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}=========================================="
    echo -e "✅ Simulator build successful!"
    echo -e "==========================================${NC}"
    echo ""
    echo "To run on simulator:"
    echo "  1. Open Xcode simulator or run: open -a Simulator"
    echo "  2. Run: flutter run -d <simulator-device-id>"
    echo "  3. Or use: flutter run (will prompt for device)"
    echo ""
    echo "To list available simulators:"
    echo "  flutter devices"
    echo ""
else
    echo -e "${RED}=========================================="
    echo -e "❌ Simulator build failed!"
    echo -e "==========================================${NC}"
    exit 1
fi
