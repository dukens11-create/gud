@echo off
REM GUD Express AAB Build Script for Windows
REM This script builds a release Android App Bundle for Google Play Store

echo ==========================================
echo GUD Express AAB Build Script
echo ==========================================
echo.

REM Check if key.properties exists
if not exist "android\key.properties" (
    echo ERROR: android\key.properties not found!
    echo Please create key.properties from key.properties.template
    echo See AAB_BUILD_GUIDE.md for instructions
    exit /b 1
)

REM Note: Checking keystore file existence is complex in batch, so we skip it
REM The build will fail if the keystore is missing

echo Step 1/4: Cleaning previous builds...
call flutter clean
if errorlevel 1 (
    echo ERROR: Flutter clean failed
    exit /b 1
)
echo [OK] Clean completed
echo.

echo Step 2/4: Getting dependencies...
call flutter pub get
if errorlevel 1 (
    echo ERROR: Flutter pub get failed
    exit /b 1
)
echo [OK] Dependencies installed
echo.

echo Step 3/4: Building release AAB...
echo This may take several minutes...
call flutter build appbundle --release
if errorlevel 1 (
    echo ERROR: AAB build failed
    exit /b 1
)
echo [OK] AAB build completed
echo.

echo Step 4/4: Verifying build...
set AAB_PATH=build\app\outputs\bundle\release\app-release.aab
if exist "%AAB_PATH%" (
    echo [OK] AAB file created successfully
    echo.
    echo ==========================================
    echo BUILD SUCCESSFUL!
    echo ==========================================
    echo.
    echo AAB Location: %AAB_PATH%
    echo.
    echo Next steps:
    echo 1. Test the AAB using bundletool (see AAB_BUILD_GUIDE.md)
    echo 2. Upload to Google Play Console
    echo 3. Create a release in Google Play Console
    echo.
) else (
    echo ERROR: AAB file was not created
    exit /b 1
)
