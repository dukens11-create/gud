# Production Deployment Guide

Complete guide for deploying the GUD Express Trucking Management application with Firebase backend to production.

## ⚠️ Important Note

This guide is for deploying the **production version with Firebase integration**. The application requires Firebase services to function.

For the demo version deployment, see `DEPLOYMENT.md`.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Firebase Production Setup](#firebase-production-setup)
3. [Building for Production](#building-for-production)
4. [Android Deployment](#android-deployment)
5. [iOS Deployment](#ios-deployment)
6. [Web Deployment](#web-deployment)
7. [Post-Deployment](#post-deployment)
8. [Monitoring](#monitoring)

---

## Prerequisites

### Required Accounts
✅ Google Firebase account (separate production project)  
✅ Google Play Console account (for Android)  
✅ Apple Developer account (for iOS - $99/year)  
✅ Domain name (optional, for custom web domain)  

### Required Tools
```bash
# Flutter SDK (latest stable)
flutter --version

# Firebase CLI
npm install -g firebase-tools

# Android Studio (for Android builds)
# Xcode (for iOS builds, Mac only)
```

### Pre-Deployment Checklist
- [ ] All features tested in development
- [ ] Firebase development environment working
- [ ] Security rules tested
- [ ] Documentation complete
- [ ] Version number updated in pubspec.yaml

---

## Firebase Production Setup

### 1. Create Production Firebase Project

```bash
# Create separate project from development
# Name: gud-express-production
```

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add Project"
3. Name: **GUD Express Production**
4. Enable Google Analytics (recommended)
5. Click "Create Project"

### 2. Add Apps to Firebase Project

#### For Android:
```bash
1. Click Android icon
2. Package name: com.gudexpress.app (or your package)
3. Download google-services.json
4. Place in: android/app/google-services.json
```

#### For iOS:
```bash
1. Click iOS icon  
2. Bundle ID: com.gudexpress.app (match Xcode)
3. Download GoogleService-Info.plist
4. Place in: ios/Runner/GoogleService-Info.plist
```

#### For Web:
```bash
1. Click Web icon
2. App nickname: GUD Express Web
3. Copy configuration
4. Update lib/firebase_options.dart
```

### 3. Enable Firebase Services

#### Authentication
```
Firebase Console → Authentication → Get Started
→ Sign-in method → Email/Password → Enable
```

#### Firestore Database
```
Firebase Console → Firestore Database → Create Database
→ Start in production mode
→ Choose location (us-central1 recommended)
→ Enable
```

#### Storage
```
Firebase Console → Storage → Get Started
→ Start in production mode
→ Use default location
→ Done
```

### 4. Deploy Security Rules

#### Firestore Rules
```bash
# Copy from FIRESTORE_RULES.md
Firebase Console → Firestore → Rules tab
# Paste rules and click Publish
```

#### Storage Rules
```bash
# Copy from STORAGE_RULES.md
Firebase Console → Storage → Rules tab
# Paste rules and click Publish
```

### 5. Create First Admin User

**Method 1: Firebase Console**
```bash
1. Authentication → Users → Add User
   Email: admin@yourcompany.com
   Password: [Strong Password - save securely!]
   
2. Copy the User UID

3. Firestore → Data → Start collection
   Collection ID: users
   Document ID: [Paste User UID]
   
4. Add fields:
   role: "admin" (string)
   name: "Admin User" (string)
   email: "admin@yourcompany.com" (string)
   phone: "+1234567890" (string)
   truckNumber: "N/A" (string)
   isActive: true (boolean)
   createdAt: [Use current timestamp]
```

**Method 2: Using App (after deployment)**
```dart
// Temporarily modify auth rules to allow registration
// Then use the app's driver creation feature
// Don't forget to restore strict rules after!
```

---

## Building for Production

### Update Version Number

Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1  # Format: version+buildNumber
```

### Update Firebase Configuration

Edit `lib/firebase_options.dart` with production credentials.

**Important**: Keep separate configs for dev and prod!

---

## Android Deployment

### 1. Configure App

Edit `android/app/build.gradle`:
```gradle
defaultConfig {
    applicationId "com.gudexpress.app"
    minSdkVersion 21
    targetSdkVersion 34
    versionCode 1
    versionName "1.0.0"
}
```

### 2. Generate Upload Keystore

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload

# Answer all prompts
# SAVE THE PASSWORDS SECURELY!
```

### 3. Configure Signing

Create `android/key.properties`:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/Users/your-username/upload-keystore.jks
```

Add to `android/app/build.gradle`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
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
        }
    }
}
```

### 4. Build App Bundle

```bash
# Build for Google Play Store
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

### 5. Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Create app
3. Complete store listing:
   - App name: GUD Express
   - Short description (80 chars max)
   - Full description (4000 chars max)
   - Screenshots (phone + tablet)
   - Feature graphic (1024x500)
   - App icon (512x512)
4. Set category: Business / Productivity
5. Add privacy policy URL
6. Content rating questionnaire
7. Upload app-release.aab
8. Create release → Production
9. Review and rollout

---

## iOS Deployment

### 1. Configure Xcode

```bash
# Open iOS workspace
cd ios
open Runner.xcworkspace
```

In Xcode:
1. Runner → General
2. Display Name: GUD Express
3. Bundle Identifier: com.gudexpress.app
4. Version: 1.0.0
5. Build: 1
6. Deployment Target: iOS 12.0+

### 2. Signing & Capabilities

1. Signing & Capabilities tab
2. Team: [Your Apple Developer Team]
3. Enable "Automatically manage signing"
4. Verify provisioning profile created

### 3. Build and Archive

```bash
# Clean build
flutter clean

# Build iOS
flutter build ios --release

# Or in Xcode:
# Product → Archive
```

### 4. App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. My Apps → + → New App
3. Platforms: iOS
4. Name: GUD Express
5. Bundle ID: com.gudexpress.app
6. SKU: GUDEXPRESS001
7. User Access: Full Access

### 5. Submit for Review

1. Upload via Xcode Organizer
2. Wait for processing (10-30 minutes)
3. Select build in App Store Connect
4. Complete app information
5. Add screenshots (all required sizes)
6. Submit for review
7. Wait for approval (24-48 hours typical)

---

## Web Deployment

### 1. Build Web App

```bash
flutter build web --release

# Output: build/web/
```

### 2. Deploy to Firebase Hosting

```bash
# Login to Firebase
firebase login

# Initialize hosting
firebase init hosting
# Select project: gud-express-production
# Public directory: build/web
# Single-page app: Yes
# Overwrite index.html: No

# Deploy
firebase deploy --only hosting

# App live at: https://YOUR_PROJECT_ID.web.app
```

### 3. Custom Domain (Optional)

```bash
Firebase Console → Hosting → Add custom domain
# Follow DNS setup instructions
# Example: app.gudexpress.com
```

---

## Post-Deployment

### Test Production App

#### Authentication Flow
- [ ] Admin login works
- [ ] Driver login works
- [ ] Logout works
- [ ] Cannot access without login

#### Admin Functions
- [ ] Create driver
- [ ] Create load with auto-generated number
- [ ] Assign load to driver
- [ ] View all loads in real-time
- [ ] See driver list

#### Driver Functions
- [ ] See assigned loads only
- [ ] View load details
- [ ] Update load status
- [ ] Upload POD with camera
- [ ] View earnings

### Configure Monitoring

```bash
Firebase Console → Performance
# Enable performance monitoring

Firebase Console → Crashlytics  
# Enable crash reporting

Firebase Console → Analytics
# Review user engagement
```

### Set Up Alerts

```bash
Firebase Console → Project Settings → Integrations
# Email alerts for:
- Crashes above 1%
- Quota exceeded
- Billing threshold
```

---

## Monitoring

### Daily Checks
- [ ] Check crashlytics for new crashes
- [ ] Review user feedback
- [ ] Monitor active users
- [ ] Check Firebase quota usage

### Weekly Reviews
- [ ] Performance metrics
- [ ] User retention rates
- [ ] Feature usage analytics
- [ ] Storage and bandwidth costs

### Monthly Tasks
- [ ] Security audit
- [ ] Update dependencies
- [ ] Review Firebase costs
- [ ] Backup Firestore data
- [ ] Update documentation

### Key Metrics

| Metric | Target | Tool |
|--------|--------|------|
| Crash-free rate | > 99% | Crashlytics |
| App startup | < 3s | Performance |
| Daily Active Users | Track | Analytics |
| Load creation time | < 5s | Performance |

---

## Troubleshooting

### Common Production Issues

#### Users can't login
```
Check:
✓ Firebase Authentication enabled
✓ Email/Password provider enabled  
✓ User document exists in /users/{uid}
✓ Role field is "admin" or "driver"
✓ Firestore rules published
```

#### Permission denied in Firestore
```
Check:
✓ Firestore rules deployed
✓ User authenticated
✓ User role matches rule requirements
✓ DriverId matches user UID
```

#### Images won't upload
```
Check:
✓ Storage rules deployed
✓ File size under 10MB
✓ File is image type (jpg, png)
✓ User is authenticated
✓ Storage bucket configured
```

#### App crashes on startup
```
Check:
✓ Firebase initialized in main.dart
✓ google-services.json in correct location
✓ Firebase dependencies in pubspec.yaml
✓ Internet permission in AndroidManifest.xml
```

---

## Rolling Back

### If Critical Issue Found

1. **Google Play**: Create new release with previous .aab file
2. **iOS**: Cannot directly rollback - submit expedited fix
3. **Web**: `firebase hosting:rollback` or redeploy previous version
4. **Firebase Rules**: Restore from Rules history in console

---

## Support

### Firebase
- Console: https://console.firebase.google.com
- Support: https://firebase.google.com/support
- Status: https://status.firebase.google.com

### App Stores
- Play Console: https://play.google.com/console
- App Store Connect: https://appstoreconnect.apple.com

### Documentation
- Firebase Setup: [FIREBASE_SETUP.md](./FIREBASE_SETUP.md)
- Firestore Rules: [FIRESTORE_RULES.md](./FIRESTORE_RULES.md)
- Storage Rules: [STORAGE_RULES.md](./STORAGE_RULES.md)

---

## Checklist Summary

### Pre-Deployment
- [ ] Production Firebase project created
- [ ] All Firebase services enabled
- [ ] Security rules deployed and tested
- [ ] First admin user created
- [ ] App configuration updated
- [ ] Version number updated

### Deployment
- [ ] Android signed and uploaded to Play Store
- [ ] iOS archived and uploaded to App Store Connect
- [ ] Web deployed to Firebase Hosting
- [ ] Custom domain configured (if applicable)

### Post-Deployment
- [ ] All features tested in production
- [ ] Monitoring configured
- [ ] Alerts set up
- [ ] Backup strategy in place
- [ ] Documentation updated
- [ ] Team trained on support procedures

---

**🎉 Congratulations on deploying to production!**

For ongoing maintenance and updates, refer to this guide and the monitoring section.

---

**Last Updated**: 2026-02-02  
**Version**: 1.0  
**For**: GUD Express with Firebase Integration
