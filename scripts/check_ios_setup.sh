#!/bin/bash

# iOS Setup Check Script
# This script checks your iOS development environment setup

echo "=========================================="
echo "GUD Express - iOS Setup Check"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Track overall status
ISSUES_FOUND=0

echo -e "${BLUE}Checking iOS development environment...${NC}"
echo ""

# Check 1: macOS
echo -n "1. Operating System: "
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${GREEN}✓ macOS detected${NC}"
    sw_vers
else
    echo -e "${RED}✗ Not macOS${NC}"
    echo "  iOS development requires macOS"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi
echo ""

# Check 2: Xcode
echo -n "2. Xcode: "
if command -v xcodebuild &> /dev/null; then
    XCODE_VERSION=$(xcodebuild -version | head -n 1)
    echo -e "${GREEN}✓ $XCODE_VERSION${NC}"
    xcodebuild -version
    
    # Check Xcode command line tools
    XCODE_PATH=$(xcode-select -p)
    echo "   Path: $XCODE_PATH"
else
    echo -e "${RED}✗ Not installed${NC}"
    echo "  Install from Mac App Store or run: xcode-select --install"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi
echo ""

# Check 3: Flutter
echo -n "3. Flutter: "
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    echo -e "${GREEN}✓ $FLUTTER_VERSION${NC}"
    flutter --version | grep -E "Flutter|Dart"
else
    echo -e "${RED}✗ Not installed${NC}"
    echo "  Install from: https://docs.flutter.dev/get-started/install"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi
echo ""

# Check 4: CocoaPods
echo -n "4. CocoaPods: "
if command -v pod &> /dev/null; then
    POD_VERSION=$(pod --version)
    echo -e "${GREEN}✓ Version $POD_VERSION${NC}"
else
    echo -e "${RED}✗ Not installed${NC}"
    echo "  Install with: sudo gem install cocoapods"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi
echo ""

# Check 5: Ruby
echo -n "5. Ruby: "
if command -v ruby &> /dev/null; then
    RUBY_VERSION=$(ruby --version | awk '{print $2}')
    echo -e "${GREEN}✓ Version $RUBY_VERSION${NC}"
else
    echo -e "${YELLOW}⚠ Not found${NC}"
    echo "  macOS usually includes Ruby, check your PATH"
fi
echo ""

# Check 6: Project structure
echo "6. Project Structure:"
if [ -d "ios" ]; then
    echo -e "   ${GREEN}✓${NC} ios/ directory exists"
    
    if [ -f "ios/Runner.xcworkspace/contents.xcworkspacedata" ]; then
        echo -e "   ${GREEN}✓${NC} Runner.xcworkspace exists"
    else
        echo -e "   ${RED}✗${NC} Runner.xcworkspace not found"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
    
    if [ -f "ios/Podfile" ]; then
        echo -e "   ${GREEN}✓${NC} Podfile exists"
    else
        echo -e "   ${YELLOW}⚠${NC} Podfile not found"
    fi
    
    if [ -f "ios/ExportOptions.plist" ]; then
        echo -e "   ${GREEN}✓${NC} ExportOptions.plist exists"
    else
        echo -e "   ${YELLOW}⚠${NC} ExportOptions.plist not found"
    fi
else
    echo -e "   ${RED}✗${NC} ios/ directory not found"
    echo "   Run this script from the project root directory"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi
echo ""

# Check 7: Code Signing (if on macOS and Xcode installed)
if [[ "$OSTYPE" == "darwin"* ]] && command -v xcodebuild &> /dev/null; then
    echo "7. Code Signing:"
    
    # Check for certificates
    CERT_COUNT=$(security find-identity -v -p codesigning | grep "iPhone" | wc -l)
    if [ "$CERT_COUNT" -gt 0 ]; then
        echo -e "   ${GREEN}✓${NC} Found $CERT_COUNT signing certificate(s)"
        security find-identity -v -p codesigning | grep "iPhone" | head -3
    else
        echo -e "   ${YELLOW}⚠${NC} No iOS signing certificates found"
        echo "   This is normal if you haven't set up code signing yet"
    fi
    
    # Check for provisioning profiles
    if [ -d "$HOME/Library/MobileDevice/Provisioning Profiles" ]; then
        PROFILE_COUNT=$(ls -1 "$HOME/Library/MobileDevice/Provisioning Profiles" 2>/dev/null | wc -l)
        if [ "$PROFILE_COUNT" -gt 0 ]; then
            echo -e "   ${GREEN}✓${NC} Found $PROFILE_COUNT provisioning profile(s)"
        else
            echo -e "   ${YELLOW}⚠${NC} No provisioning profiles found"
            echo "   This is normal if you haven't set up code signing yet"
        fi
    fi
    
    # Check Team ID in project
    if [ -f "ios/Runner.xcodeproj/project.pbxproj" ]; then
        if grep -q "DEVELOPMENT_TEAM" ios/Runner.xcodeproj/project.pbxproj; then
            TEAM_ID=$(grep "DEVELOPMENT_TEAM" ios/Runner.xcodeproj/project.pbxproj | head -1 | awk '{print $3}' | tr -d ';')
            if [ "$TEAM_ID" != "" ]; then
                echo -e "   ${GREEN}✓${NC} Development Team configured: $TEAM_ID"
            else
                echo -e "   ${YELLOW}⚠${NC} Development Team not set"
            fi
        else
            echo -e "   ${YELLOW}⚠${NC} Development Team not configured"
            echo "   Run: ./scripts/configure_team.sh"
        fi
    fi
    echo ""
fi

# Check 8: Flutter Dependencies
echo "8. Flutter Dependencies:"
if [ -f "pubspec.yaml" ]; then
    echo -e "   ${GREEN}✓${NC} pubspec.yaml exists"
    
    if [ -d ".dart_tool" ]; then
        echo -e "   ${GREEN}✓${NC} Dependencies installed"
    else
        echo -e "   ${YELLOW}⚠${NC} Dependencies not installed"
        echo "   Run: flutter pub get"
    fi
else
    echo -e "   ${RED}✗${NC} pubspec.yaml not found"
    echo "   Are you in the project root directory?"
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi
echo ""

# Check 9: iOS Pods
if [ -d "ios" ]; then
    echo "9. iOS CocoaPods:"
    if [ -d "ios/Pods" ]; then
        echo -e "   ${GREEN}✓${NC} CocoaPods dependencies installed"
        
        if [ -f "ios/Podfile.lock" ]; then
            echo -e "   ${GREEN}✓${NC} Podfile.lock exists"
        fi
    else
        echo -e "   ${YELLOW}⚠${NC} CocoaPods dependencies not installed"
        echo "   Run: cd ios && pod install"
    fi
    echo ""
fi

# Check 10: Connected Devices
if command -v flutter &> /dev/null; then
    echo "10. Available Devices:"
    DEVICES=$(flutter devices 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo "$DEVICES" | grep -E "iPhone|iPad|iOS Simulator|macOS" | while read line; do
            echo -e "    ${GREEN}✓${NC} $line"
        done
        
        DEVICE_COUNT=$(echo "$DEVICES" | grep -c -E "iPhone|iPad|iOS Simulator")
        if [ "$DEVICE_COUNT" -eq 0 ]; then
            echo -e "    ${YELLOW}⚠${NC} No iOS devices or simulators available"
            echo "    Open Simulator or connect an iOS device"
        fi
    else
        echo -e "    ${YELLOW}⚠${NC} Unable to detect devices"
    fi
    echo ""
fi

# Summary
echo "=========================================="
if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✓ Setup looks good!${NC}"
    echo ""
    echo "You can now:"
    echo "  • Build for simulator: ./scripts/build_ios_simulator.sh"
    echo "  • Build for device: ./scripts/build_ios_device.sh"
    echo "  • Configure team: ./scripts/configure_team.sh"
    echo ""
    echo "For more info, see: IOS_LOCAL_BUILD_GUIDE.md"
else
    echo -e "${YELLOW}⚠ Found $ISSUES_FOUND issue(s)${NC}"
    echo ""
    echo "Please resolve the issues above before building."
    echo ""
    echo "Quick fixes:"
    echo "  • Install Xcode from Mac App Store"
    echo "  • Install Flutter: https://docs.flutter.dev/get-started/install"
    echo "  • Install CocoaPods: sudo gem install cocoapods"
    echo "  • Run: flutter pub get && cd ios && pod install"
    echo ""
    echo "For detailed setup, see: IOS_LOCAL_BUILD_GUIDE.md"
fi
echo "=========================================="
