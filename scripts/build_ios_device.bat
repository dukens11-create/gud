@echo off
REM Build iOS Device App Script (Windows)
REM This script is for Windows users with remote Mac access
REM It provides instructions for building on Mac

echo ==========================================
echo GUD Express - iOS Device Build
echo ==========================================
echo.
echo Note: iOS builds require macOS with Xcode installed.
echo.
echo This script provides instructions for building on Mac.
echo For automated builds, transfer this project to a Mac and run:
echo   scripts/build_ios_device.sh
echo.
echo ==========================================
echo Manual Steps on Mac:
echo ==========================================
echo.
echo 1. Install Flutter and Xcode on your Mac
echo 2. Clone this repository
echo 3. Open Terminal and navigate to project directory
echo 4. Run: chmod +x scripts/build_ios_device.sh
echo 5. Run: ./scripts/build_ios_device.sh --help
echo.
echo For Debug Build:
echo   ./scripts/build_ios_device.sh
echo.
echo For Release Build:
echo   ./scripts/build_ios_device.sh --release
echo.
echo For IPA Export:
echo   ./scripts/build_ios_device.sh --export-ipa
echo.
echo Alternatively, you can run these commands manually:
echo.
echo   flutter clean
echo   flutter pub get
echo   cd ios ^&^& pod install ^&^& cd ..
echo   flutter build ios --release
echo   flutter run -d [device-id]
echo.
pause
