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

## 🔥 Firestore Index Setup

### Quick Deploy (One Command)

Deploy all required Firestore indexes with a single command:

```bash
bash scripts/deploy-indexes.sh
```

**What this does:**
- ✅ Checks if Firebase CLI is installed
- ✅ Verifies Firebase authentication
- ✅ Deploys all indexes from `firestore.indexes.json`
- ✅ Provides clear success/error messages

**Alternative (manual deployment):**
```bash
firebase deploy --only firestore:indexes
```

⏱️ **Note**: After deployment, indexes take 2-5 minutes to build (up to 30 minutes for large databases). Check status in [Firebase Console](https://console.firebase.google.com/project/_/firestore/indexes).

### First-Time Setup

If you haven't set up Firebase CLI yet:

```bash
# Install Firebase CLI globally
npm install -g firebase-tools

# Login to Firebase
firebase login

# Deploy indexes
bash scripts/deploy-indexes.sh
```

### Fixing "Index Required" Errors

**See the error below?**
```
[cloud_firestore/failed-precondition] The query requires an index.
```

**Quick fix options:**

1. **Option 1 - Use the deployment script** (Recommended):
   ```bash
   bash scripts/deploy-indexes.sh
   ```

2. **Option 2 - Use the error link**:
   - Copy the URL from the error message
   - Open it in your browser
   - Click "Create Index" in Firebase Console

3. **Option 3 - Manual deployment**:
   ```bash
   firebase deploy --only firestore:indexes
   ```

### Documentation

- 📚 **[Quick Start Guide](FIRESTORE_INDEX_QUICKSTART.md)** - 2-minute setup with troubleshooting
- 📖 **[Detailed Documentation](FIRESTORE_INDEX_SETUP.md)** - Complete index reference and query patterns
- 🔧 **[Troubleshooting Guide](TROUBLESHOOTING.md)** - Common issues and solutions

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