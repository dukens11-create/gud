# GUD Express - Trucking Management App

[![Build iOS](https://github.com/dukens11-create/gud/actions/workflows/build-ios.yml/badge.svg)](https://github.com/dukens11-create/gud/actions/workflows/build-ios.yml)
[![Android Build](https://github.com/dukens11-create/gud/actions/workflows/android-build.yml/badge.svg)](https://github.com/dukens11-create/gud/actions/workflows/android-build.yml)
[![Flutter CI](https://github.com/dukens11-create/gud/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/dukens11-create/gud/actions/workflows/flutter_ci.yml)

GUD Express Trucking Management App - Production Ready

## Version
**Current Version**: 2.1.0+2

## Build Status
- **iOS**: Automated CI/CD with TestFlight deployment (Codemagic & GitHub Actions)
- **Android**: Automated APK and AAB builds (Codemagic & GitHub Actions)
- **Web**: Firebase hosting deployment

## Quick Links
- [Codemagic Keystore Setup](KEYSTORE_SETUP.md) - **Start here for CI/CD setup**
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

## Codemagic CI/CD Setup

This project uses **Codemagic** for automated iOS and Android builds. 

### Quick Start

1. **First-time setup**: Follow the [Keystore Setup Guide](KEYSTORE_SETUP.md) to configure Android code signing
2. **Trigger builds**: Push to `main` branch or create a version tag (e.g., `v2.1.0`)
3. **Monitor builds**: Check [Codemagic Dashboard](https://codemagic.io/apps)

### Available Workflows

| Workflow | Purpose | Trigger | Artifacts |
|----------|---------|---------|-----------|
| `ios-debug` | iOS debug builds | Push to `develop` or `feature/*` | Debug .app |
| `ios-release` | iOS release with signing | Push to `main`, tags | Signed .ipa |
| `ios-workflow` | iOS without signing | Push to `main` | Unsigned .app |
| `android-debug` | Android debug APK | Push to `develop` or `feature/*` | Debug APK |
| `android-apk` | Android release APK | Push to `main` | Release APK |
| `android-aab` | Android App Bundle (Play Store) | Push to `main`, tags | Signed AAB |

### Key Features

- ✅ **Automatic code signing** for both iOS and Android
- ✅ **Keystore management** via Codemagic dashboard (keystore ref: `gud_keystore`)
- ✅ **Build triggers** on push, pull requests, and version tags
- ✅ **Artifact storage** for 30 days
- ✅ **Email notifications** on build success/failure
- ✅ **Optional TestFlight/Play Store** automatic uploads

### Required Setup

#### Android Code Signing
1. Generate or obtain the Android keystore (`gud_keystore.jks`)
2. Upload to Codemagic with reference name: **`gud_keystore`**
3. Set key alias: **`gud_key`**
4. See [KEYSTORE_SETUP.md](KEYSTORE_SETUP.md) for detailed instructions

#### iOS Code Signing
1. Add App Store Connect API key to Codemagic
2. Or upload certificates and provisioning profiles manually
3. See [KEYSTORE_SETUP.md](KEYSTORE_SETUP.md#ios-code-signing-setup) for details

### Troubleshooting

**"No keystores with reference 'gud_keystore' were found"**
- Ensure keystore is uploaded to Codemagic with exact name: `gud_keystore`
- Verify key alias is set to: `gud_key`
- See [KEYSTORE_SETUP.md](KEYSTORE_SETUP.md#troubleshooting) for full resolution steps

For other issues:
- Check [Codemagic build logs](https://codemagic.io/apps)
- Review [KEYSTORE_SETUP.md](KEYSTORE_SETUP.md) troubleshooting section
- Contact Codemagic support

## Deployment

### iOS
See [IOS_BUILD_AND_DEPLOY_GUIDE.md](IOS_BUILD_AND_DEPLOY_GUIDE.md) for complete instructions on:
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