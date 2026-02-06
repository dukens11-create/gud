# Deployment Guide

Complete guide for deploying the GUD Express Trucking Management App to production environments.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Firebase Setup](#firebase-setup)
- [Environment Configuration](#environment-configuration)
- [iOS Deployment](#ios-deployment)
- [Android Deployment](#android-deployment)
- [Web Deployment](#web-deployment)
- [Build Commands](#build-commands)
- [Release Checklist](#release-checklist)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

- **Flutter SDK**: Version 3.24.0 or higher
  ```bash
  flutter --version
  flutter doctor -v
  ```

- **Dart SDK**: Included with Flutter (>=3.0.0)

- **Git**: For version control
  ```bash
  git --version
  ```

- **Firebase CLI**: For Firebase deployment
  ```bash
  npm install -g firebase-tools
  firebase --version
  ```

### Platform-Specific Requirements

#### iOS
- macOS (Monterey 12.0 or higher)
- Xcode 14.0 or higher
- CocoaPods 1.11.0 or higher
- Apple Developer Account ($99/year)

#### Android
- Android Studio or Android SDK CLI tools
- Java JDK 11 or higher
- Android SDK Platform-Tools
- Google Play Developer Account ($25 one-time)

#### Web
- Modern web browser
- Firebase Hosting account

## Firebase Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter project name: `gud-express` (or your choice)
4. Enable Google Analytics (optional)
5. Click "Create Project"

### 2. Enable Firebase Services

#### Authentication
```bash
# Enable Email/Password authentication
firebase projects:list
firebase use <project-id>
```

In Firebase Console:
- Go to **Authentication** → **Sign-in method**
- Enable **Email/Password**
- Enable **Google** (optional)
- Enable **Apple** (optional, required for iOS)

#### Firestore Database
```bash
# Create Firestore database
```

In Firebase Console:
- Go to **Firestore Database** → **Create database**
- Choose **Production mode** for production
- Choose **Test mode** for development (temporary)
- Select a location (us-central, europe-west, etc.)

#### Storage
In Firebase Console:
- Go to **Storage** → **Get started**
- Start in **production mode** or **test mode**
- Choose same location as Firestore

#### Cloud Messaging (Optional)
- Go to **Cloud Messaging** → Enable

### 3. Add Apps to Firebase

#### Add Android App
```bash
# In Firebase Console
1. Click "Add app" → Android icon
2. Package name: com.gudexpress.gud_app
3. App nickname: GUD Express Android
4. Download google-services.json
5. Place in: android/app/google-services.json
```

#### Add iOS App
```bash
# In Firebase Console
1. Click "Add app" → iOS icon
2. Bundle ID: com.gudexpress.gudApp
3. App nickname: GUD Express iOS
4. Download GoogleService-Info.plist
5. Place in: ios/Runner/GoogleService-Info.plist
```

#### Add Web App
```bash
# In Firebase Console
1. Click "Add app" → Web icon
2. App nickname: GUD Express Web
3. Copy Firebase config
4. Update lib/firebase_options.dart
```

### 4. Configure Security Rules

#### Firestore Rules
```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules
```

Verify `firestore.rules`:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User authentication required
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
             request.auth.token.role == 'admin';
    }
    
    // Apply rules from firestore.rules file
  }
}
```

#### Storage Rules
```bash
# Deploy Storage rules
firebase deploy --only storage
```

### 5. Initialize Firebase in App

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for all platforms
flutterfire configure
```

## Environment Configuration

### 1. Create Environment Files

#### Development (.env.development)
```bash
# Firebase Configuration
FIREBASE_PROJECT_ID=gud-express-dev
FIREBASE_API_KEY=your-dev-api-key
FIREBASE_APP_ID=your-dev-app-id
FIREBASE_MESSAGING_SENDER_ID=your-dev-sender-id

# Environment
ENVIRONMENT=development
DEBUG_MODE=true

# API Configuration
API_BASE_URL=https://dev-api.gudexpress.com
```

#### Production (.env.production)
```bash
# Firebase Configuration
FIREBASE_PROJECT_ID=gud-express-prod
FIREBASE_API_KEY=your-prod-api-key
FIREBASE_APP_ID=your-prod-app-id
FIREBASE_MESSAGING_SENDER_ID=your-prod-sender-id

# Environment
ENVIRONMENT=production
DEBUG_MODE=false

# API Configuration
API_BASE_URL=https://api.gudexpress.com
```

### 2. Load Environment Variables

In `main.dart`:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // Load environment variables
  await dotenv.load(fileName: ".env.production");
  
  runApp(MyApp());
}
```

### 3. Secure Environment Files

Add to `.gitignore`:
```bash
# Environment files
.env
.env.development
.env.production
.env.*.local

# Sensitive files
android/key.properties
ios/Runner/GoogleService-Info.plist
android/app/google-services.json
```

## iOS Deployment

### 1. Prepare Xcode Project

```bash
# Open iOS project
open ios/Runner.xcworkspace
```

In Xcode:
1. Select **Runner** target
2. Update **Display Name**: "GUD Express"
3. Update **Bundle Identifier**: `com.gudexpress.gudApp`
4. Set **Version**: 2.0.0
5. Set **Build**: 1

### 2. Configure App Capabilities

Enable capabilities in Xcode:
- ✅ Push Notifications
- ✅ Background Modes (Location updates, Background fetch)
- ✅ Sign in with Apple (if using)

### 3. Update Info.plist

Add required permissions in `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>GUD Express needs your location to track deliveries and enable geofencing.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>GUD Express needs continuous location access for background delivery tracking.</string>

<key>NSCameraUsageDescription</key>
<string>GUD Express needs camera access to capture proof of delivery photos.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>GUD Express needs photo library access to save and upload delivery photos.</string>
```

### 4. Configure Signing

#### Manual Signing
1. Select **Runner** target
2. Go to **Signing & Capabilities**
3. Select your **Team**
4. Xcode will create provisioning profiles automatically

#### Automatic Signing with Fastlane
```bash
# Install Fastlane
sudo gem install fastlane -NV

# Initialize Fastlane
cd ios
fastlane init
```

Create `ios/fastlane/Fastfile`:
```ruby
default_platform(:ios)

platform :ios do
  desc "Push a new beta build to TestFlight"
  lane :beta do
    increment_build_number(xcodeproj: "Runner.xcodeproj")
    build_app(workspace: "Runner.xcworkspace", scheme: "Runner")
    upload_to_testflight
  end

  desc "Push a new release build to the App Store"
  lane :release do
    build_app(workspace: "Runner.xcworkspace", scheme: "Runner")
    upload_to_app_store
  end
end
```

### 5. Create App Store Connect Entry

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** → **New App**
3. Fill in:
   - Platform: iOS
   - Name: GUD Express
   - Primary Language: English
   - Bundle ID: com.gudexpress.gudApp
   - SKU: GUDEXPRESS001

### 6. Build for TestFlight

```bash
# Clean build
flutter clean
flutter pub get

# Build iOS archive
flutter build ios --release

# Or use Fastlane
cd ios
fastlane beta
```

### 7. Upload to TestFlight

#### Using Xcode
1. Open `ios/Runner.xcworkspace`
2. Select **Any iOS Device (arm64)** as destination
3. Product → Archive
4. Wait for archive to complete
5. Click **Distribute App**
6. Select **App Store Connect**
7. Upload and wait for processing

#### Using Fastlane
```bash
cd ios
fastlane beta
```

### 8. TestFlight Distribution

1. Go to App Store Connect → TestFlight
2. Add internal testers
3. Enable automatic distribution
4. Testers receive invite via email

### 9. Production Release

1. Complete App Store listing:
   - Description
   - Keywords
   - Screenshots (all required sizes)
   - Preview videos (optional)
   - Support URL
   - Privacy Policy URL

2. Submit for review:
   - Answer compliance questions
   - Submit for review
   - Wait for approval (1-3 days typically)

## Android Deployment

### 1. Create Keystore

```bash
# Create release keystore
keytool -genkey -v -keystore ~/gud-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias gud-key-alias

# Remember the passwords!
```

### 2. Configure Signing

Create `android/key.properties`:
```properties
storePassword=<store-password>
keyPassword=<key-password>
keyAlias=gud-key-alias
storeFile=/Users/<username>/gud-release-key.jks
```

Update `android/app/build.gradle`:
```gradle
// Load keystore properties
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

### 3. Update App Configuration

`android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        applicationId "com.gudexpress.gud_app"
        minSdkVersion 21
        targetSdkVersion 33
        versionCode 1
        versionName "2.0.0"
    }
}
```

`android/app/src/main/AndroidManifest.xml`:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.gudexpress.gud_app">

    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

    <application
        android:label="GUD Express"
        android:icon="@mipmap/ic_launcher">
        <!-- Application config -->
    </application>
</manifest>
```

### 4. Build Release APK/AAB

```bash
# Build APK
flutter build apk --release

# Build App Bundle (preferred for Play Store)
flutter build appbundle --release

# Output locations:
# APK: build/app/outputs/flutter-apk/app-release.apk
# AAB: build/app/outputs/bundle/release/app-release.aab
```

### 5. Create Play Store Entry

1. Go to [Google Play Console](https://play.google.com/console)
2. Click **Create app**
3. Fill in:
   - App name: GUD Express
   - Default language: English (US)
   - App or game: App
   - Free or paid: Free

### 6. Prepare Store Listing

Required assets:
- **App icon**: 512×512 PNG
- **Feature graphic**: 1024×500 PNG
- **Screenshots**: 
  - Phone: At least 2 (320-3840px)
  - 7-inch tablet: At least 2
  - 10-inch tablet: At least 2

Content:
- Short description (80 chars)
- Full description (4000 chars)
- Privacy policy URL
- Support email

### 7. Upload to Internal Testing

```bash
# Install Fastlane (if not already)
sudo gem install fastlane -NV

# Initialize Fastlane
cd android
fastlane init
```

Create `android/fastlane/Fastfile`:
```ruby
default_platform(:android)

platform :android do
  desc "Deploy to Internal Testing"
  lane :internal do
    upload_to_play_store(
      track: 'internal',
      aab: '../build/app/outputs/bundle/release/app-release.aab'
    )
  end

  desc "Deploy to Production"
  lane :production do
    upload_to_play_store(
      track: 'production',
      aab: '../build/app/outputs/bundle/release/app-release.aab'
    )
  end
end
```

Deploy:
```bash
cd android
fastlane internal
```

### 8. Production Release

1. Complete content rating questionnaire
2. Set up pricing & distribution
3. Review and release:
   - Move from internal → alpha → beta → production
   - Or direct to production
4. Submit for review
5. Wait for approval (hours to days)

## Web Deployment

### 1. Build Web App

```bash
# Build for production
flutter build web --release --web-renderer html

# Output: build/web/
```

### 2. Deploy to Firebase Hosting

```bash
# Initialize Firebase Hosting
firebase init hosting

# Select:
# - What do you want to use as your public directory? build/web
# - Configure as a single-page app? Yes
# - Set up automatic builds with GitHub? (Optional) Yes

# Deploy
firebase deploy --only hosting

# Your app is live at: https://gud-express.web.app
```

### 3. Configure Custom Domain

```bash
# Add custom domain in Firebase Console
# 1. Go to Hosting → Add custom domain
# 2. Enter your domain: app.gudexpress.com
# 3. Verify ownership (add TXT record to DNS)
# 4. Add A/AAAA records provided by Firebase
# 5. Wait for SSL provisioning (24 hours max)
```

### 4. Configure Environment

Update `web/index.html`:
```html
<script>
  // Firebase configuration
  const firebaseConfig = {
    apiKey: "YOUR_API_KEY",
    authDomain: "gud-express.firebaseapp.com",
    projectId: "gud-express",
    storageBucket: "gud-express.appspot.com",
    messagingSenderId: "YOUR_SENDER_ID",
    appId: "YOUR_APP_ID"
  };
</script>
```

## Build Commands

### Development Builds

```bash
# Android Debug APK
flutter build apk --debug

# iOS Debug build
flutter build ios --debug

# Run on device
flutter run
```

### Release Builds

```bash
# Android Release APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS Release
flutter build ios --release

# Web Release
flutter build web --release

# All platforms
flutter build apk --release && \
flutter build appbundle --release && \
flutter build ios --release && \
flutter build web --release
```

### Platform-Specific Options

```bash
# Android with specific target
flutter build apk --release --target-platform android-arm64

# iOS with specific configuration
flutter build ios --release --no-codesign

# Web with specific renderer
flutter build web --release --web-renderer canvaskit
```

## Release Checklist

### Pre-Release

- [ ] All tests passing (`flutter test`)
- [ ] Code analysis clean (`flutter analyze`)
- [ ] Code formatted (`flutter format lib test`)
- [ ] Version bumped in `pubspec.yaml`
- [ ] CHANGELOG.md updated
- [ ] Environment variables configured
- [ ] Firebase rules deployed
- [ ] Icons and splash screens updated

### iOS Release

- [ ] Bundle identifier configured
- [ ] Version and build number updated
- [ ] Signing configured
- [ ] Info.plist permissions updated
- [ ] TestFlight build uploaded
- [ ] Internal testing complete
- [ ] App Store listing complete
- [ ] Screenshots uploaded
- [ ] Submitted for review

### Android Release

- [ ] Package name configured
- [ ] Version code and name updated
- [ ] Keystore configured
- [ ] AndroidManifest permissions updated
- [ ] APK/AAB signed and built
- [ ] Internal testing complete
- [ ] Play Store listing complete
- [ ] Screenshots uploaded
- [ ] Content rating complete
- [ ] Submitted for review

### Web Release

- [ ] Build optimized for web
- [ ] Firebase Hosting configured
- [ ] Custom domain configured (if applicable)
- [ ] SSL certificate active
- [ ] Performance tested
- [ ] Cross-browser tested

### Post-Release

- [ ] Monitor crash reports
- [ ] Monitor user feedback
- [ ] Check analytics
- [ ] Respond to reviews
- [ ] Plan next release

## Troubleshooting

### iOS Issues

#### Build Failed - Provisioning Profile
```bash
# Solution 1: Clean and rebuild
flutter clean
cd ios
pod deintegrate
pod install
cd ..
flutter build ios

# Solution 2: Manual signing in Xcode
open ios/Runner.xcworkspace
# Select Runner → Signing & Capabilities → Select Team
```

#### Archive Upload Failed
```bash
# Use Application Loader or Transporter app
# Download from Mac App Store: "Transporter"
# Drag .ipa file to Transporter
```

#### Missing Compliance
```bash
# Add to Info.plist:
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

### Android Issues

#### Keystore Error
```bash
# Verify keystore
keytool -list -v -keystore ~/gud-release-key.jks

# Check key.properties path is correct
# Use absolute path instead of relative path
```

#### Build Failed - Dependency
```bash
# Update Gradle
cd android
./gradlew --version

# Clean and rebuild
cd ..
flutter clean
flutter pub get
flutter build appbundle --release
```

#### Play Store Rejection
Common reasons:
- Missing privacy policy
- Incomplete content rating
- Permission not justified
- Icon doesn't meet guidelines

### Web Issues

#### Build Errors
```bash
# Clear web cache
flutter clean
rm -rf build/web

# Rebuild
flutter build web --release
```

#### Firebase Hosting Errors
```bash
# Re-initialize
firebase logout
firebase login
firebase use <project-id>
firebase deploy --only hosting
```

#### Performance Issues
```bash
# Use CanvasKit renderer
flutter build web --release --web-renderer canvaskit

# Or HTML renderer for better compatibility
flutter build web --release --web-renderer html
```

### General Issues

#### Flutter Doctor Issues
```bash
flutter doctor -v
# Fix all issues before deploying
```

#### Dependency Conflicts
```bash
flutter pub upgrade
flutter pub outdated
```

#### Cache Issues
```bash
flutter clean
flutter pub cache repair
flutter pub get
```

## CI/CD Automation

### GitHub Actions

See `.github/workflows/` for:
- `android-build.yml` - Android builds
- `ios-build.yml` - iOS builds  
- `test.yml` - Automated testing
- `web-deploy.yml` - Web deployment

### Codemagic

See `codemagic.yaml` for build configuration.

## Support

For deployment issues:
- Check [Flutter Documentation](https://docs.flutter.dev/deployment)
- Review [Firebase Documentation](https://firebase.google.com/docs)
- Contact: support@gudexpress.com

---

**Last Updated**: Phase 11 Completion
**Version**: 2.0.0
