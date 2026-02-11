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

## Version
**Current Version**: 2.1.0+2

## Build Status
- **iOS**: Automated CI/CD with TestFlight deployment
- **Android**: Automated APK and AAB builds
- **Web**: Firebase hosting deployment

## Quick Links
- [iOS Build & Deploy Guide](IOS_BUILD_AND_DEPLOY_GUIDE.md)
- [Android AAB Build Guide](AAB_BUILD_GUIDE.md)
- [Deployment Guide](DEPLOYMENT.md)

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