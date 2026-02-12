# GUD Express - Trucking Management App

[![Build iOS](https://github.com/dukens11-create/gud/actions/workflows/build-ios.yml/badge.svg)](https://github.com/dukens11-create/gud/actions/workflows/build-ios.yml)
[![Android Build](https://github.com/dukens11-create/gud/actions/workflows/android-build.yml/badge.svg)](https://github.com/dukens11-create/gud/actions/workflows/android-build.yml)
[![Flutter CI](https://github.com/dukens11-create/gud/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/dukens11-create/gud/actions/workflows/flutter_ci.yml)

GUD Express Trucking Management App - Production Ready

---

## 🚨 Fix Build Error: "No keystores found"

**Are you seeing this error in Codemagic?**
```
No keystores with reference 'gud-release-key' were found from code signing identities.
```

**Quick Fix:**
1. 📋 See [QUICK_FIX_CHECKLIST.md](QUICK_FIX_CHECKLIST.md) for immediate step-by-step fix
2. 📖 See [CODEMAGIC_KEYSTORE_SETUP.md](CODEMAGIC_KEYSTORE_SETUP.md) for detailed guide with navigation help
3. 🆘 See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) if you're stuck

**TL;DR**: You need to upload a keystore to Codemagic dashboard with reference name **exactly** `gud-release-key`

**Generate keystore:**
```bash
./generate_keystore.sh
```

---

## 🔥 Fix Firestore Index Errors

**Are you seeing this error in CodeMagic, GitHub Actions, or locally?**
```
[cloud_firestore/failed-precondition] The query requires an index. 
You can create it here: https://console.firebase.google.com/...
```

### Quick Fix Steps:

1. **📋 Copy the Index Creation Link**
   - Find the error in your logs (CodeMagic, GitHub Actions, or local console)
   - Copy the full URL that starts with `https://console.firebase.google.com/...`

2. **🌐 Open Link in Browser**
   - Paste the URL into your browser
   - You'll be taken to Firebase Console with the index pre-configured

3. **✅ Create the Index**
   - Click the **"Create Index"** button in Firebase Console
   - Wait 2-5 minutes for the index to build (can take longer for large databases)
   - Index status will change from "Building" to "Enabled"

4. **🔄 Retry Your Build/Query**
   - Once the index is enabled, retry your failed build or operation
   - The error should be resolved

### Finding Firestore Indexes Manually

If you need to check or manage indexes manually:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Firestore Database** → **Indexes** tab
4. You'll see all composite indexes and their status

### Troubleshooting

**Error persists after creating the index?**
- ⏳ **Wait longer**: Large databases can take 10-30+ minutes to build indexes
- 🔍 **Check status**: Verify index status is "Enabled" in Firebase Console
- 🔄 **Clear cache**: Try clearing your app cache or restarting the development server
- 📝 **Verify fields**: Ensure field names match exactly (case-sensitive)

**Index already exists?**
- The index may still be building - check the status in Firebase Console
- If status shows "Error", delete the index and recreate it using the error link

### Important Notes

⚠️ **PR Automation Limitation**: Creating Firestore composite indexes **cannot be automated** through pull requests or CI/CD pipelines. This is a Firebase security requirement - indexes must be created manually in the Firebase Console by someone with appropriate access.

💡 **Best Practice**: When adding new queries that require composite indexes, document them in your PR and notify the team so indexes can be created before merging to production.

📖 **Detailed Documentation**: For comprehensive information about Firestore indexes, query patterns, and maintenance, see [FIRESTORE_INDEX_SETUP.md](FIRESTORE_INDEX_SETUP.md)

---

## Version
**Current Version**: 2.1.0+2

## Build Status
- **iOS**: Automated CI/CD with TestFlight deployment
- **Android**: Automated APK and AAB builds
- **Web**: Firebase hosting deployment

## Quick Links
- [iOS Code Signing Setup Guide](docs/ios_codesign_setup.md) - **Complete iOS code signing guide for all contributors**
- [iOS Code Signing Quick Setup](IOS_CODE_SIGNING_QUICK_SETUP.md) - 5-minute setup guide
- [iOS Local Build Guide](IOS_LOCAL_BUILD_GUIDE.md) - Complete local development guide
- [iOS Build & Deploy Guide](IOS_BUILD_AND_DEPLOY_GUIDE.md) - CI/CD and App Store
- [iOS Provisioning Guide](IOS_PROVISIONING_GUIDE.md) - Profile management
- [Android AAB Build Guide](AAB_BUILD_GUIDE.md) - Android builds
- [Deployment Guide](DEPLOYMENT.md) - General deployment info

---

## 🍎 First-Time iOS Development Setup

**New to iOS development on this project?** Follow this checklist to get building on iOS devices quickly.

### Prerequisites Checklist
- [ ] macOS with Xcode 14.0+ installed ([Download from App Store](https://apps.apple.com/us/app/xcode/id497799835))
- [ ] Flutter SDK installed and configured ([Installation Guide](https://docs.flutter.dev/get-started/install))
- [ ] Active Apple ID (free for testing, [$99/year Developer Program](https://developer.apple.com/programs/) for App Store)
- [ ] Repository cloned locally

### Quick Setup Steps

#### 1️⃣ Validate Your Environment (2 minutes)
```bash
# Run our automated setup checker
./scripts/check_ios_setup.sh
```
This script checks:
- ✅ Xcode installation
- ✅ Flutter SDK
- ✅ CocoaPods
- ✅ Project structure
- ✅ Code signing status

**Fix any issues** the script identifies before proceeding.

#### 2️⃣ Configure Your Development Team (5 minutes)

**Option A - Using Our Helper Script** (Recommended):
```bash
# Assists with team configuration
./scripts/configure_team.sh
```

**Option B - Manual Configuration**:
1. Open the project workspace:
   ```bash
   cd ios && open Runner.xcworkspace
   ```

2. In Xcode:
   - Select **Runner** target (left sidebar, blue icon)
   - Click **Signing & Capabilities** tab
   - Check **✓ Automatically manage signing**
   - Select your team from **Team** dropdown
   - Wait for Xcode to create provisioning profiles

3. Verify you see:
   - ✅ Signing Certificate: Apple Development
   - ✅ Provisioning Profile: Xcode Managed Profile

**Need Help?** See our [detailed visual guide](docs/ios_codesign_setup.md#setting-up-your-development-team) with step-by-step Xcode instructions.

#### 3️⃣ Build & Test (3 minutes)

**For Simulator** (no code signing needed):
```bash
# Build and run on iOS Simulator
flutter run
# Or use our helper script
./scripts/build_ios_simulator.sh
```

**For Physical Device**:
```bash
# Connect your iPhone/iPad via USB
# Trust the computer on your device
flutter devices  # Verify device is detected
flutter run      # Select your device

# Or use our helper script with device connected
./scripts/build_ios_device.sh
```

**First install on device?** You may need to:
1. On device: **Settings → General → VPN & Device Management**
2. Tap your developer profile
3. Tap **Trust**

#### 4️⃣ Troubleshooting Quick Fixes

**"No Team Found"**
```bash
# Open Xcode Preferences
# Xcode → Preferences → Accounts → Add Apple ID
```

**"Bundle ID Already Registered"**
- Change Bundle ID in Xcode to something unique (e.g., `com.yourname.gudexpress`)
- See [Bundle ID Guide](docs/ios_codesign_setup.md#understanding-bundle-ids)

**Build Fails After Team Selection**
```bash
# Clean and rebuild
flutter clean
cd ios && pod install && cd ..
flutter build ios
```

**More issues?** Check our comprehensive [Troubleshooting Guide](docs/ios_codesign_setup.md#troubleshooting)

### 📚 Complete Documentation

Once you've completed the quick setup:
- **[iOS Code Signing Setup Guide](docs/ios_codesign_setup.md)** - Comprehensive guide with visual Xcode instructions, troubleshooting FAQ, and CI/CD tips
- **[iOS Local Build Guide](IOS_LOCAL_BUILD_GUIDE.md)** - Deep dive into local development workflows
- **[iOS Build & Deploy Guide](IOS_BUILD_AND_DEPLOY_GUIDE.md)** - CI/CD automation and App Store deployment

### 🚀 Helper Scripts

We provide automation scripts in `scripts/` to streamline iOS development:

| Script | Purpose | Usage |
|--------|---------|-------|
| `check_ios_setup.sh` | Validate development environment | `./scripts/check_ios_setup.sh` |
| `configure_team.sh` | Configure Apple Developer Team | `./scripts/configure_team.sh` |
| `build_ios_simulator.sh` | Build for iOS Simulator (no signing) | `./scripts/build_ios_simulator.sh` |
| `build_ios_device.sh` | Build for physical devices | `./scripts/build_ios_device.sh` |

**Need Help?** See our [iOS Code Signing Setup Guide](docs/ios_codesign_setup.md) or open an issue.

---

## Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0 <4.0.0)
- Xcode (for iOS development)
- Android Studio (for Android development)

### Installation
```bash
# Clone the repository
git clone https://github.com/dukens11-create/gud.git

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## Deployment

### iOS

#### Code Signing Setup
**All contributors must configure iOS code signing to build for devices.**  
See [iOS Code Signing Setup Guide](docs/ios_codesign_setup.md) for complete instructions on:
- Opening the project in Xcode
- Configuring your Development Team
- Setting up automatic or manual signing
- Troubleshooting common issues
- CI/CD automation requirements

#### Local Development
For building and testing on your Mac:
- **Simulator builds**: See [IOS_LOCAL_BUILD_GUIDE.md](IOS_LOCAL_BUILD_GUIDE.md#building-for-simulator)
  - No code signing required
  - Quick start: `./scripts/build_ios_simulator.sh`
- **Device builds**: See [IOS_LOCAL_BUILD_GUIDE.md](IOS_LOCAL_BUILD_GUIDE.md#building-for-physical-device)
  - Requires Apple Developer account and code signing setup
  - Quick start: `./scripts/build_ios_device.sh`

#### CI/CD & App Store
For automated builds and App Store distribution:
- [IOS_BUILD_AND_DEPLOY_GUIDE.md](IOS_BUILD_AND_DEPLOY_GUIDE.md) - Complete CI/CD setup
- [IOS_BUILD_QUICK_START.md](IOS_BUILD_QUICK_START.md) - CI/CD quick reference

Key documentation:
- Setting up Apple Developer account
- Configuring certificates and provisioning profiles
- Building IPA and deploying to App Store Connect
- Using GitHub Actions for automated builds

### Android
See [AAB_BUILD_GUIDE.md](AAB_BUILD_GUIDE.md) for Android deployment instructions.

## Features
- Real-time GPS tracking
- Delivery management
- Driver and truck information
- Expense tracking
- Profile management with photo upload
- Push notifications
- Firebase integration

## License
Proprietary - All rights reserved