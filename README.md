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