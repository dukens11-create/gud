#!/bin/bash

# Build iOS Device App Script
# This script builds the GUD Express app for physical iOS devices
# Requires proper code signing and provisioning profiles

set -e

echo "=========================================="
echo "GUD Express - iOS Device Build"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --release         Build in release mode (default: debug)"
    echo "  --export-ipa      Export IPA for distribution (implies --release)"
    echo "  --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Debug build for connected device"
    echo "  $0 --release          # Release build for connected device"
    echo "  $0 --export-ipa       # Build IPA for distribution"
    exit 1
}

# Parse command line arguments
BUILD_MODE="debug"
EXPORT_IPA=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --release)
            BUILD_MODE="release"
            shift
            ;;
        --export-ipa)
            BUILD_MODE="release"
            EXPORT_IPA=true
            shift
            ;;
        --help)
            show_usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_usage
            ;;
    esac
done

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Error: Flutter is not installed or not in PATH${NC}"
    echo "Please install Flutter: https://docs.flutter.dev/get-started/install"
    exit 1
fi

echo -e "${BLUE}📋 Flutter Doctor${NC}"
flutter doctor -v
echo ""

# Check code signing setup
echo -e "${BLUE}🔍 Checking code signing setup...${NC}"
echo -e "${YELLOW}⚠️  Important: Make sure you have:${NC}"
echo "  1. Selected a Development Team in Xcode"
echo "  2. Valid provisioning profile"
echo "  3. Valid signing certificate"
echo ""
echo -e "${YELLOW}To configure code signing:${NC}"
echo "  1. Open: ios/Runner.xcworkspace in Xcode"
echo "  2. Select Runner target"
echo "  3. Go to Signing & Capabilities"
echo "  4. Select your Team"
echo ""
read -p "Press Enter to continue (Ctrl+C to cancel)..."
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

# Build based on mode
if [ "$EXPORT_IPA" = true ]; then
    echo -e "${BLUE}🔨 Building IPA for distribution...${NC}"
    echo -e "${YELLOW}Note: Using ExportOptions.plist for export configuration${NC}"
    echo ""
    
    # Check if ExportOptions.plist exists
    if [ ! -f "ios/ExportOptions.plist" ]; then
        echo -e "${RED}❌ Error: ios/ExportOptions.plist not found${NC}"
        exit 1
    fi
    
    flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}=========================================="
        echo -e "✅ IPA build successful!"
        echo -e "==========================================${NC}"
        echo ""
        echo "IPA location: build/ios/ipa/"
        ls -lh build/ios/ipa/*.ipa 2>/dev/null || echo "IPA file not found"
        echo ""
        echo "Next steps:"
        echo "  1. Test IPA on device using Xcode Organizer"
        echo "  2. Upload to TestFlight using Transporter app"
        echo "  3. Or use: cd ios && bundle exec fastlane upload_testflight"
    else
        echo -e "${RED}❌ IPA build failed!${NC}"
        exit 1
    fi
else
    echo -e "${BLUE}🔨 Building for iOS device (${BUILD_MODE})...${NC}"
    
    if [ "$BUILD_MODE" = "release" ]; then
        flutter build ios --release --no-codesign
    else
        flutter build ios --debug --no-codesign
    fi
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}=========================================="
        echo -e "✅ Device build successful!"
        echo -e "==========================================${NC}"
        echo ""
        echo "To install on connected device:"
        echo "  1. Connect your iOS device via USB"
        echo "  2. Trust the device (if first time)"
        echo "  3. Run: flutter run -d <device-id>"
        echo "  4. Or open ios/Runner.xcworkspace in Xcode and run"
        echo ""
        echo "To list connected devices:"
        echo "  flutter devices"
        echo ""
    else
        echo -e "${RED}❌ Device build failed!${NC}"
        exit 1
    fi
fi
