# Production Deployment Guide

**Version:** 2.0.0  
**Last Updated:** 2026-02-06

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Environment Configuration](#environment-configuration)
- [Firebase Setup](#firebase-setup)
- [Secrets and API Keys](#secrets-and-api-keys)
- [iOS Deployment](#ios-deployment)
- [Android Deployment](#android-deployment)
- [Web Deployment](#web-deployment)
- [Post-Deployment Verification](#post-deployment-verification)
- [Rollback Procedures](#rollback-procedures)
- [Troubleshooting](#troubleshooting)
- [Monitoring and Maintenance](#monitoring-and-maintenance)

---

## Overview

This guide covers deploying GUD Express to production across all platforms: iOS App Store, Google Play Store, and Firebase Hosting (Web).

### Deployment Checklist

- [ ] Firebase project configured
- [ ] Environment variables set
- [ ] API keys configured
- [ ] Security rules deployed
- [ ] Testing completed
- [ ] App signed with production certificates
- [ ] Store listings prepared
- [ ] Monitoring enabled
- [ ] Backup/rollback plan ready

---

## Prerequisites

### Required Tools

```bash
# Flutter SDK (3.24.0+)
flutter --version

# Firebase CLI
npm install -g firebase-tools
firebase --version

# Xcode (macOS only, for iOS)
xcode-select --install

# Android Studio (for Android)
# Download from: https://developer.android.com/studio

# Fastlane (optional, for automation)
sudo gem install fastlane
```

### Required Accounts

1. **Firebase Account** - [console.firebase.google.com](https://console.firebase.google.com)
2. **Google Cloud Account** - [console.cloud.google.com](https://console.cloud.google.com)
3. **Apple Developer Account** - [$99/year](https://developer.apple.com)
4. **Google Play Developer Account** - [$25 one-time](https://play.google.com/console)

### System Requirements

- **macOS** - Required for iOS builds
- **Linux/macOS/Windows** - For Android and Web builds
- **Disk Space** - 20GB+ free
- **RAM** - 8GB minimum, 16GB recommended

---

## Environment Configuration

### 1. Environment Files

Create environment-specific configuration:

**.env.production:**
```bash
# Firebase Configuration
FIREBASE_PROJECT_ID=your-production-project
FIREBASE_API_KEY=your-production-api-key
FIREBASE_APP_ID=your-production-app-id

# Google Maps API
GOOGLE_MAPS_API_KEY_ANDROID=your-android-maps-key
GOOGLE_MAPS_API_KEY_IOS=your-ios-maps-key
GOOGLE_MAPS_API_KEY_WEB=your-web-maps-key

# App Configuration
APP_NAME=GUD Express
APP_BUNDLE_ID=com.gudexpress.app
APP_VERSION=2.0.0
BUILD_NUMBER=1

# Feature Flags
ENABLE_CRASHLYTICS=true
ENABLE_ANALYTICS=true
ENABLE_BACKGROUND_LOCATION=true
ENABLE_PUSH_NOTIFICATIONS=true

# API Endpoints (if using Cloud Functions)
CLOUD_FUNCTIONS_URL=https://us-central1-your-project.cloudfunctions.net
```

### 2. Load Environment Variables

**lib/config/env_config.dart:**
```dart
class EnvConfig {
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'development-project',
  );
  
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );
  
  static const bool enableCrashlytics = bool.fromEnvironment(
    'ENABLE_CRASHLYTICS',
    defaultValue: false,
  );
  
  // Load environment on startup
  static Future<void> load() async {
    // Load environment variables from .env files
    // Implementation depends on your setup
  }
}
```

### 3. Build Commands with Environment

```bash
# iOS Production Build
flutter build ios --release \
  --dart-define=FIREBASE_PROJECT_ID=your-prod-project \
  --dart-define=ENABLE_CRASHLYTICS=true

# Android Production Build
flutter build appbundle --release \
  --dart-define=FIREBASE_PROJECT_ID=your-prod-project \
  --dart-define=ENABLE_CRASHLYTICS=true

# Web Production Build
flutter build web --release \
  --dart-define=FIREBASE_PROJECT_ID=your-prod-project
```

---

## Firebase Setup

### 1. Create Production Firebase Project

```bash
# Login to Firebase
firebase login

# Create new project (or use existing)
firebase projects:create gud-express-prod

# Set as current project
firebase use gud-express-prod
```

### 2. Enable Required Services

In Firebase Console:

1. **Authentication**
   - Enable Email/Password
   - Enable Google Sign-In (optional)
   - Enable Apple Sign-In (optional)
   - Configure authorized domains

2. **Firestore Database**
   - Create database in production mode
   - Deploy security rules: `firebase deploy --only firestore:rules`

3. **Storage**
   - Create default bucket
   - Deploy security rules: `firebase deploy --only storage:rules`

4. **Cloud Messaging**
   - Enable FCM
   - Generate server key
   - Add to backend configuration

5. **Crashlytics**
   - Enable in Firebase Console
   - No additional setup needed

6. **Analytics**
   - Enabled by default
   - Review data retention settings

### 3. Configure Firebase Apps

```bash
# Register iOS app
firebase apps:create ios com.gudexpress.app

# Register Android app
firebase apps:create android com.gudexpress.app

# Register Web app
firebase apps:create web "GUD Express Web"

# Download configuration files
# iOS: GoogleService-Info.plist → ios/Runner/
# Android: google-services.json → android/app/
# Web: Firebase config in index.html
```

### 4. Deploy Security Rules

```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage:rules

# Deploy all rules
firebase deploy --only firestore:rules,storage:rules
```

### 5. Deploy Cloud Functions (if any)

```bash
# Navigate to functions directory
cd functions

# Install dependencies
npm install

# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:sendNotification
```

---

## Secrets and API Keys

### 1. Google Maps API Keys

**Get API Keys:**
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create new project or select existing
3. Enable APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Maps JavaScript API
4. Create credentials (API keys)
5. Restrict keys by platform and API

**Configure in App:**

**android/app/src/main/AndroidManifest.xml:**
```xml
<manifest>
    <application>
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_ANDROID_MAPS_KEY"/>
    </application>
</manifest>
```

**ios/Runner/AppDelegate.swift:**
```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_IOS_MAPS_KEY")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

**web/index.html:**
```html
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_WEB_MAPS_KEY"></script>
```

### 2. Secure Secret Storage

**Never commit secrets to Git:**

**.gitignore:**
```
.env
.env.local
.env.production
google-services.json
GoogleService-Info.plist
*.keystore
*.jks
```

**Use CI/CD Secret Management:**
```yaml
# GitHub Actions example
env:
  GOOGLE_MAPS_API_KEY: ${{ secrets.GOOGLE_MAPS_API_KEY }}
  FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
```

---

## iOS Deployment

### 1. Prerequisites

- macOS with Xcode 14+
- Apple Developer Account ($99/year)
- App Store Connect access

### 2. Configure iOS Project

**ios/Runner/Info.plist:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>GUD Express</string>
    <key>CFBundleIdentifier</key>
    <string>com.gudexpress.app</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>2.0.0</string>
    
    <!-- Required permissions -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>GUD Express needs your location to track deliveries</string>
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>GUD Express needs background location for real-time tracking</string>
    <key>NSCameraUsageDescription</key>
    <string>Camera is needed to capture proof of delivery photos</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Access photos to upload proof of delivery</string>
</dict>
</plist>
```

### 3. Code Signing

1. **Create App ID in Apple Developer Portal**
   - Bundle ID: `com.gudexpress.app`
   - Enable capabilities: Push Notifications, Background Modes

2. **Create Provisioning Profile**
   - Type: App Store
   - Link to App ID and certificates

3. **Configure in Xcode**
   ```bash
   open ios/Runner.xcworkspace
   ```
   - Select Runner target
   - Signing & Capabilities
   - Select your team
   - Automatic signing (or manual with provisioning profile)

### 4. Build for Release

```bash
# Clean build
flutter clean
flutter pub get

# Build iOS release
flutter build ios --release

# Or build IPA directly
flutter build ipa --release
```

### 5. Upload to App Store Connect

**Option A: Using Xcode**
```bash
# Open Xcode
open ios/Runner.xcworkspace

# Product → Archive
# Upload to App Store
```

**Option B: Using Command Line**
```bash
# Build IPA
flutter build ipa --release

# Upload with xcrun (requires App Store Connect API key)
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/*.ipa \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID
```

**Option C: Using Fastlane**
```bash
cd ios
fastlane release
```

### 6. App Store Connect Setup

1. **Create App Listing**
   - App name: GUD Express
   - Primary category: Business
   - Subcategory: Productivity

2. **Prepare Metadata**
   - App description (4000 chars max)
   - Keywords (100 chars max)
   - Screenshots (required sizes)
   - App icon (1024x1024)

3. **Submit for Review**
   - Select build
   - Complete App Privacy details
   - Export Compliance: No encryption (or complete questionnaire)
   - Submit

### 7. TestFlight (Beta Testing)

```bash
# Upload beta build
flutter build ipa --release
# Upload to TestFlight via App Store Connect

# Invite testers via email
# They install TestFlight app and accept invite
```

---

## Android Deployment

### 1. Configure Android Project

**android/app/build.gradle:**
```gradle
android {
    namespace "com.gudexpress.app"
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.gudexpress.app"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "2.0.0"
    }
    
    signingConfigs {
        release {
            storeFile file(RELEASE_STORE_FILE)
            storePassword RELEASE_STORE_PASSWORD
            keyAlias RELEASE_KEY_ALIAS
            keyPassword RELEASE_KEY_PASSWORD
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

### 2. Generate Signing Key

```bash
# Generate keystore
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload

# Save keystore in secure location (NOT in repo)
# Document passwords in secure password manager
```

**android/key.properties:**
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/path/to/upload-keystore.jks
```

**android/app/build.gradle (load properties):**
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

### 3. Configure Permissions

**android/app/src/main/AndroidManifest.xml:**
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Required permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="32"/>
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    
    <application
        android:label="GUD Express"
        android:icon="@mipmap/ic_launcher">
        <!-- App configuration -->
    </application>
</manifest>
```

### 4. Build for Release

```bash
# Clean build
flutter clean
flutter pub get

# Build App Bundle (recommended)
flutter build appbundle --release

# Or build APK
flutter build apk --release --split-per-abi
```

**Output locations:**
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`
- APK: `build/app/outputs/apk/release/app-release.apk`

### 5. Upload to Google Play Console

1. **Create App**
   - Go to [Google Play Console](https://play.google.com/console)
   - Create app
   - App name: GUD Express
   - Default language: English (US)
   - App or game: App
   - Free or paid: Free

2. **Prepare Store Listing**
   - Short description (80 chars)
   - Full description (4000 chars)
   - Screenshots (required sizes)
   - Feature graphic (1024x500)
   - App icon (512x512)

3. **Content Rating**
   - Complete questionnaire
   - Target audience
   - Privacy policy URL

4. **App Content**
   - Privacy policy
   - Data safety section
   - Target audience and content

5. **Release**
   ```
   Production → Create new release → Upload AAB → Save → Review → Start rollout
   ```

### 6. Internal/Beta Testing

```bash
# Upload to internal testing track
# Add testers via email
# They can install from Play Store "Testing" section

# Or create closed/open beta track
```

---

## Web Deployment

### 1. Configure Web Build

**web/index.html:**
```html
<!DOCTYPE html>
<html>
<head>
  <base href="/">
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>GUD Express - Trucking Management</title>
  
  <!-- PWA -->
  <link rel="manifest" href="manifest.json">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">
  <meta name="theme-color" content="#0175C2">
  
  <!-- Firebase -->
  <script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js"></script>
  <script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-auth-compat.js"></script>
  <script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-firestore-compat.js"></script>
  
  <script>
    const firebaseConfig = {
      apiKey: "YOUR_WEB_API_KEY",
      authDomain: "your-project.firebaseapp.com",
      projectId: "your-project",
      storageBucket: "your-project.appspot.com",
      messagingSenderId: "123456789",
      appId: "1:123456789:web:abcdef",
    };
    firebase.initializeApp(firebaseConfig);
  </script>
</head>
<body>
  <script src="main.dart.js" type="application/javascript"></script>
</body>
</html>
```

**web/manifest.json:**
```json
{
  "name": "GUD Express",
  "short_name": "GUD Express",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#FFFFFF",
  "theme_color": "#0175C2",
  "description": "Professional trucking and logistics management",
  "orientation": "portrait",
  "icons": [
    {
      "src": "icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

### 2. Build for Production

```bash
# Build web release
flutter build web --release --web-renderer canvaskit

# Output: build/web/
```

**Optimize Build:**
```bash
# Use HTML renderer for faster load (less features)
flutter build web --release --web-renderer html

# Use auto (default, chooses best)
flutter build web --release --web-renderer auto
```

### 3. Deploy to Firebase Hosting

**firebase.json:**
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(js|css)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=31536000, immutable"
          }
        ]
      }
    ]
  }
}
```

**Deploy:**
```bash
# Login to Firebase
firebase login

# Initialize hosting (first time only)
firebase init hosting

# Build and deploy
flutter build web --release
firebase deploy --only hosting

# Or deploy to specific environment
firebase use production
firebase deploy --only hosting
```

### 4. Custom Domain (Optional)

```bash
# Add custom domain in Firebase Console
# Hosting → Add custom domain
# Follow DNS verification steps

# Or via CLI
firebase hosting:channel:deploy preview --expires 7d
```

---

## Post-Deployment Verification

### 1. Smoke Tests

Test critical user flows after deployment:

- [ ] User can login with valid credentials
- [ ] Admin can create a new load
- [ ] Driver can view assigned loads
- [ ] Driver can mark load as picked up
- [ ] Driver can upload POD photo
- [ ] Admin can view all loads
- [ ] Real-time updates work correctly
- [ ] Push notifications are received (if enabled)
- [ ] Location tracking works (if enabled)

### 2. Monitor Firebase Console

Check for errors and usage:

```
Firebase Console → 
- Authentication → Users (verify registrations work)
- Firestore → Data (verify writes are happening)
- Storage → Files (verify uploads work)
- Crashlytics → Dashboard (check for crashes)
- Analytics → Dashboard (verify events)
```

### 3. Check App Performance

```
Firebase Console → Performance →
- App start time
- Screen rendering
- Network requests
```

### 4. Review Logs

```bash
# Android logcat
adb logcat | grep Flutter

# iOS logs
xcrun simctl spawn booted log stream --predicate 'processImagePath contains "Runner"'

# Web console
# Check browser developer console
```

---

## Rollback Procedures

### iOS Rollback

**Option 1: Remove from Sale**
```
App Store Connect → Your App → Pricing and Availability → 
Remove from sale (temporary)
```

**Option 2: Release Previous Version**
```
App Store Connect → Your App → App Store → 
Submit previous build for review
```

### Android Rollback

**Option 1: Halt Rollout**
```
Play Console → Production → 
Halt rollout (stops at current percentage)
```

**Option 2: Release Previous Version**
```
Play Console → Production → Create new release → 
Select previous bundle → Review → Start rollout
```

### Web Rollback

```bash
# Deploy previous version
firebase hosting:rollback

# Or redeploy previous build
# Keep backup of previous build/web folder
firebase deploy --only hosting
```

### Database Rollback

**Firestore:**
- No automatic rollback
- Use backups: `gcloud firestore export gs://bucket-name`
- Restore: `gcloud firestore import gs://bucket-name/[export-folder]`

**Security Rules:**
```bash
# Deploy previous rules
firebase deploy --only firestore:rules --project=prod
```

---

## Troubleshooting

### Common Issues

#### 1. Build Failures

**Problem:** iOS build fails with signing errors

**Solution:**
```bash
# Clean and rebuild
flutter clean
cd ios
pod install
cd ..
flutter build ios --release
```

**Problem:** Android build fails with Gradle errors

**Solution:**
```bash
# Update Gradle
cd android
./gradlew clean
./gradlew build
cd ..
flutter build appbundle --release
```

#### 2. Firebase Issues

**Problem:** App can't connect to Firebase

**Solution:**
- Verify `google-services.json` and `GoogleService-Info.plist` are present
- Check Firebase project ID matches
- Verify Firebase is initialized in `main.dart`
- Check app SHA-1 fingerprint registered (Android)

#### 3. API Key Issues

**Problem:** Google Maps not loading

**Solution:**
- Verify API key is correct
- Check API key restrictions in Cloud Console
- Ensure Maps SDK is enabled for platform
- Check for billing enabled on Cloud project

#### 4. Permission Errors

**Problem:** Location/camera permissions denied

**Solution:**
- Verify permissions in AndroidManifest.xml and Info.plist
- Add usage descriptions
- Request permissions at runtime with permission_handler
- Test on physical device (not simulator)

#### 5. Release Build Crashes

**Problem:** App crashes in release but works in debug

**Solution:**
- Check for missing --dart-define values
- Verify ProGuard rules (Android)
- Enable Crashlytics and check logs
- Test release build locally: `flutter run --release`

---

## Monitoring and Maintenance

### 1. Set Up Alerts

**Firebase Crashlytics:**
```
Firebase Console → Crashlytics → 
- Set velocity alerts
- Set regression alerts
- Configure email notifications
```

**Firebase Performance:**
```
Firebase Console → Performance → 
- Set threshold alerts
- Monitor screen traces
- Track network requests
```

### 2. Regular Maintenance

**Weekly:**
- [ ] Check Crashlytics for new crashes
- [ ] Review Analytics for usage patterns
- [ ] Monitor app ratings and reviews

**Monthly:**
- [ ] Update dependencies: `flutter pub upgrade`
- [ ] Review performance metrics
- [ ] Analyze user feedback
- [ ] Plan feature updates

**Quarterly:**
- [ ] Update Flutter SDK
- [ ] Update Firebase SDKs
- [ ] Security audit
- [ ] Performance optimization

### 3. Update Process

```bash
# 1. Update dependencies
flutter pub upgrade

# 2. Test thoroughly
flutter test
flutter test integration_test/

# 3. Increment version
# pubspec.yaml: version: 2.0.1+2

# 4. Build and deploy
flutter build ios --release
flutter build appbundle --release
firebase deploy --only hosting

# 5. Submit to stores
# Follow iOS/Android deployment steps
```

---

## Additional Resources

### Documentation
- [Flutter Deployment Guide](https://flutter.dev/docs/deployment)
- [Firebase Hosting Docs](https://firebase.google.com/docs/hosting)
- [App Store Connect Help](https://developer.apple.com/app-store-connect/)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)

### Tools
- [Fastlane](https://fastlane.tools/) - Automate iOS and Android deployments
- [Codemagic](https://codemagic.io/) - CI/CD for Flutter
- [GitHub Actions](https://github.com/features/actions) - CI/CD automation

### Best Practices
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Google Play Policy](https://play.google.com/about/developer-content-policy/)
- [Firebase Best Practices](https://firebase.google.com/docs/projects/learn-more)

---

**Last Updated:** 2026-02-06  
**Maintained By:** GUD Express Development Team  
**Related Documents:**
- [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
- [TESTING.md](TESTING.md)
- [PRODUCTION_READINESS_STATUS.md](PRODUCTION_READINESS_STATUS.md)
