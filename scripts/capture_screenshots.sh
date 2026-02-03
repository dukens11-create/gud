#!/bin/bash

echo "🚀 GUD Express Screenshot Capture Script"
echo "========================================="
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create screenshots directory if it doesn't exist
mkdir -p screenshots/mobile
mkdir -p screenshots/desktop

echo -e "${BLUE}📱 Starting Flutter app in Chrome for screenshot capture...${NC}"
echo ""

# Start Flutter web in Chrome
flutter run -d chrome --web-renderer html &
FLUTTER_PID=$!

echo "Flutter app starting (PID: $FLUTTER_PID)..."
echo "Please wait for the app to load completely."
echo ""
echo "========================================="
echo "SCREENSHOT CAPTURE INSTRUCTIONS"
echo "========================================="
echo ""
echo "The app will open in Chrome. Please capture these screens:"
echo ""
echo "✅ Mobile View (Use Chrome DevTools Device Toolbar - F12):"
echo "   1. Login screen"
echo "   2. Driver dashboard"
echo "   3. Driver load detail"
echo "   4. Upload POD screen"
echo "   5. Driver earnings"
echo "   6. Driver expenses"
echo "   7. Admin dashboard"
echo "   8. Create load form"
echo "   9. Manage drivers"
echo "   10. Admin expenses"
echo "   11. Statistics dashboard"
echo ""
echo "✅ Desktop View (Full browser window):"
echo "   1. Login screen"
echo "   2. Driver dashboard"
echo "   3. Admin dashboard"
echo "   4. Statistics dashboard"
echo ""
echo "Save screenshots to:"
echo "  - Mobile: screenshots/mobile/"
echo "  - Desktop: screenshots/desktop/"
echo ""
echo -e "${GREEN}Press Ctrl+C when done capturing screenshots${NC}"
echo ""

# Wait for user to finish
wait $FLUTTER_PID
