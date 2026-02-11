# Build Scripts

This directory contains automated build scripts for the GUD Express app.

## Available Scripts

### Android Build Scripts

#### `build_aab.sh` (Linux/macOS)
Bash script for building release AAB on Unix-based systems.

**Usage:**
```bash
chmod +x scripts/build_aab.sh
./scripts/build_aab.sh
```

#### `build_aab.bat` (Windows)
Batch script for building release AAB on Windows systems.

**Usage:**
```cmd
scripts\build_aab.bat
```

### iOS Build Scripts

#### `build_ios_simulator.sh` (Linux/macOS)
Bash script for building iOS app for simulator (no code signing required).

**Usage:**
```bash
chmod +x scripts/build_ios_simulator.sh
./scripts/build_ios_simulator.sh
```

**Note:** Simulator builds do not require code signing or provisioning profiles.

#### `build_ios_device.sh` (Linux/macOS)
Bash script for building iOS app for physical devices.

**Usage:**
```bash
chmod +x scripts/build_ios_device.sh
./scripts/build_ios_device.sh           # Debug build
./scripts/build_ios_device.sh --release # Release build
./scripts/build_ios_device.sh --export-ipa # Build and export IPA
```

**Note:** Device builds require proper code signing setup. See [IOS_LOCAL_BUILD_GUIDE.md](../IOS_LOCAL_BUILD_GUIDE.md) for setup instructions.

#### `build_ios_simulator.bat` (Windows)
Provides instructions for Windows users on how to build for iOS simulator on a Mac.

#### `build_ios_device.bat` (Windows)
Provides instructions for Windows users on how to build for iOS devices on a Mac.

#### `configure_team.sh` (Linux/macOS)
Helper script to configure Apple Developer Team ID in Xcode project for code signing.

**Usage:**
```bash
chmod +x scripts/configure_team.sh
./scripts/configure_team.sh
```

This script will:
- Prompt for your Apple Developer Team ID
- Update the Xcode project with the Team ID
- Update ExportOptions.plist
- Create backups of modified files

## Prerequisites

### For Android Builds

Before running Android scripts, ensure you have:

1. **key.properties configured** - See [AAB_BUILD_GUIDE.md](../AAB_BUILD_GUIDE.md)
2. **Keystore generated** - See [AAB_BUILD_GUIDE.md](../AAB_BUILD_GUIDE.md#keystore-generation)
3. **Flutter installed** - Run `flutter doctor` to verify
4. **All dependencies installed** - Run `flutter pub get`

### For iOS Builds

Before running iOS scripts, ensure you have:

1. **macOS with Xcode installed** - Xcode 14.0 or later
2. **Flutter installed** - Run `flutter doctor` to verify
3. **CocoaPods installed** - Run `sudo gem install cocoapods`
4. **Apple Developer account** (for device builds only)

#### Simulator Builds
- ✅ No code signing required
- ✅ No Apple Developer account required
- ✅ Free to use

#### Device Builds
- ⚠️ Code signing required
- ⚠️ Apple Developer account required (free or paid)
- ⚠️ Must configure development team

See [IOS_LOCAL_BUILD_GUIDE.md](../IOS_LOCAL_BUILD_GUIDE.md) for detailed setup instructions.

## What the Scripts Do

### Android Scripts

Both Android scripts perform the following steps:

1. **Validate** - Check that key.properties and keystore exist
2. **Clean** - Remove previous build artifacts (`flutter clean`)
3. **Dependencies** - Install Flutter packages (`flutter pub get`)
4. **Build** - Create the release AAB (`flutter build appbundle --release`)
5. **Verify** - Confirm the AAB was created successfully

### iOS Simulator Scripts

1. **Validate** - Check Flutter installation
2. **Clean** - Remove previous build artifacts
3. **Dependencies** - Install Flutter and CocoaPods packages
4. **Build** - Create simulator build (`flutter build ios --simulator`)

### iOS Device Scripts

1. **Validate** - Check Flutter installation and code signing setup
2. **Clean** - Remove previous build artifacts
3. **Dependencies** - Install Flutter and CocoaPods packages
4. **Build** - Create device build or IPA based on options

## Output

### Android AAB
The AAB file will be created at:
```
build/app/outputs/bundle/release/app-release.aab
```

### iOS Simulator Build
The simulator build will be created at:
```
build/ios/iphonesimulator/Runner.app
```

### iOS Device Build
The device build will be created at:
```
build/ios/iphoneos/Runner.app
```

### iOS IPA (for distribution)
The IPA file will be created at:
```
build/ios/ipa/gud_app.ipa
```

## Troubleshooting

### Android Issues

If the Android script fails, check:
- Flutter is installed and in PATH
- key.properties exists in android/ directory
- Keystore file path in key.properties is correct
- All dependencies are up to date

For detailed troubleshooting, see [AAB_BUILD_GUIDE.md](../AAB_BUILD_GUIDE.md#troubleshooting)

### iOS Issues

If iOS scripts fail, check:
- macOS and Xcode are properly installed
- Flutter is installed and in PATH
- CocoaPods is installed (`pod --version`)
- For device builds: code signing is configured

For detailed troubleshooting, see [IOS_LOCAL_BUILD_GUIDE.md](../IOS_LOCAL_BUILD_GUIDE.md#troubleshooting)

## Quick Commands

### Android
```bash
# Build AAB (Linux/macOS)
./scripts/build_aab.sh

# Build AAB (Windows)
scripts\build_aab.bat
```

### iOS
```bash
# Simulator build
./scripts/build_ios_simulator.sh

# Device debug build
./scripts/build_ios_device.sh

# Device release build
./scripts/build_ios_device.sh --release

# Export IPA for distribution
./scripts/build_ios_device.sh --export-ipa

# Configure development team
./scripts/configure_team.sh
```

## Related Documentation

- [AAB_BUILD_GUIDE.md](../AAB_BUILD_GUIDE.md) - Android build guide
- [IOS_LOCAL_BUILD_GUIDE.md](../IOS_LOCAL_BUILD_GUIDE.md) - iOS local build guide
- [IOS_BUILD_AND_DEPLOY_GUIDE.md](../IOS_BUILD_AND_DEPLOY_GUIDE.md) - iOS CI/CD guide
- [README.md](../README.md) - Main project documentation
