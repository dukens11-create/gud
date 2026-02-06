# GUD Express - Complete Deployment Guide

Comprehensive step-by-step guide to deploy GUD Express to production and app stores.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Firebase Setup](#firebase-setup)
3. [Cloud Functions Deployment](#cloud-functions-deployment)
4. [Android Release Build](#android-release-build)
5. [iOS Release Build](#ios-release-build)
6. [Google Play Store Submission](#google-play-store-submission)
7. [Apple App Store Submission](#apple-app-store-submission)
8. [Production Monitoring](#production-monitoring)
9. [CI/CD with GitHub Actions](#cicd-with-github-actions)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software
- **Flutter SDK**: 3.24.0 or later
- **Dart SDK**: Included with Flutter
- **Android Studio**: Latest stable version (for Android builds)
- **Xcode**: 15.0+ (for iOS builds, macOS only)
- **Firebase CLI**: Install with `npm install -g firebase-tools`
- **Node.js**: 18.x or later (for Cloud Functions)
- **Git**: Latest version

### Required Accounts
- **Firebase Account**: With billing enabled (for Cloud Functions)
- **Google Play Console**: $25 one-time registration fee
- **Apple Developer Account**: $99/year subscription (for iOS)
- **GitHub Account**: For CI/CD (optional)

### Verify Installation

```bash
# Check Flutter
flutter doctor -v

# Check Firebase CLI
firebase --version

# Check Node.js
node --version  # Should be 18+

# Check Git
git --version
```

---

## Firebase Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Add project**
3. Enter project name: `gud-express-production`
4. Enable Google Analytics (recommended)
5. Click **Create project**

### Step 2: Enable Firebase Services

#### Authentication
1. Navigate to **Build** → **Authentication**
2. Click **Get started**
3. Enable sign-in methods:
   - ✅ Email/Password
   - ✅ Google (configure OAuth 2.0 Client ID)
   - ✅ Apple (iOS only - configure Service ID)

#### Cloud Firestore
1. Navigate to **Build** → **Firestore Database**
2. Click **Create database**
3. Select **Production mode**
4. Choose location: `us-central` (or closest to your users)
5. Click **Enable**

#### Cloud Storage
1. Navigate to **Build** → **Storage**
2. Click **Get started**
3. Use default security rules
4. Click **Done**

#### Cloud Messaging (FCM)
1. Navigate to **Build** → **Cloud Messaging**
2. Already enabled by default
3. For iOS: Upload APNs Authentication Key
   - Go to Apple Developer Console → Keys
   - Create new key with APNs enabled
   - Download `.p8` file
   - Upload to Firebase under Project Settings → Cloud Messaging

### Step 3: Register Apps in Firebase

#### Android App
1. In Firebase Console, click **Add app** → **Android**
2. Enter package name: `com.gudexpress.gud_app`
3. Enter app nickname: `GUD Express Android`
4. Download `google-services.json`
5. Replace `/android/app/google-services.json` with downloaded file

#### iOS App
1. Click **Add app** → **iOS**
2. Enter bundle ID: `com.gud.express`
3. Enter app nickname: `GUD Express iOS`
4. Download `GoogleService-Info.plist`
5. Replace `/ios/Runner/GoogleService-Info.plist` with downloaded file

### Step 4: Configure Environment Variables

Create `.env` file in project root:

```bash
cp .env.production .env
```

Edit `.env` with your Firebase values:

```env
FIREBASE_API_KEY=YOUR_ACTUAL_API_KEY
FIREBASE_APP_ID=YOUR_ACTUAL_APP_ID
FIREBASE_MESSAGING_SENDER_ID=YOUR_SENDER_ID
FIREBASE_PROJECT_ID=gud-express-production
FIREBASE_STORAGE_BUCKET=gud-express-production.appspot.com
FIREBASE_AUTH_DOMAIN=gud-express-production.firebaseapp.com
GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_KEY
APPLE_SERVICE_ID=YOUR_APPLE_SERVICE_ID
ENVIRONMENT=production
```

**⚠️ NEVER commit `.env` file to version control!**

---

## Cloud Functions Deployment

### Step 1: Enable Billing

Cloud Functions require a billing account (Blaze plan):

1. Go to Firebase Console → **Upgrade**
2. Select **Blaze (Pay as you go)** plan
3. Add payment method
4. Set up budget alerts (recommended)

### Step 2: Login to Firebase CLI

```bash
firebase login
```

### Step 3: Select Your Project

```bash
firebase use gud-express-production
```

Or set up project alias:

```bash
firebase use --add
# Select your project from list
# Enter alias: production
```

### Step 4: Install Function Dependencies

```bash
cd functions
npm install
cd ..
```

### Step 5: Deploy Cloud Functions

Deploy all functions:

```bash
cd functions
npm run deploy
```

Or deploy with Firebase CLI from root:

```bash
firebase deploy --only functions
```

**Expected output:**
```
✔ functions[notifyLoadStatusChange] Successful update operation.
✔ functions[notifyNewLoad] Successful update operation.
✔ functions[calculateEarnings] Successful update operation.
✔ functions[validateLoad] Successful update operation.
✔ functions[cleanupOldLocationData] Successful create operation.
✔ functions[sendOverdueLoadReminders] Successful create operation.
```

### Step 6: Deploy Firestore Indexes

```bash
firebase deploy --only firestore:indexes
```

Or using the npm script:

```bash
cd functions
npm run deploy:indexes
cd ..
```

### Step 7: Deploy Security Rules

```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage
```

### Step 8: Verify Deployment

```bash
# View function logs
firebase functions:log

# List deployed functions
firebase functions:list

# Test a function (optional)
firebase functions:shell
```

---

## Android Release Build

### Step 1: Generate Signing Key

Generate a keystore for signing your app:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

**Answer the prompts:**
- Enter keystore password (save this!)
- Re-enter password
- Enter your name
- Enter organizational unit
- Enter organization name
- Enter city
- Enter state
- Enter country code

**⚠️ IMPORTANT:**
- Save the keystore file securely
- NEVER commit the keystore to Git
- Store passwords in a password manager
- Make backups of the keystore

### Step 2: Configure Signing

Create `android/key.properties` from template:

```bash
cp android/key.properties.template android/key.properties
```

Edit `android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/path/to/upload-keystore.jks
```

**Example paths:**
- Mac/Linux: `/Users/yourname/upload-keystore.jks`
- Windows: `C:\\Users\\YourName\\upload-keystore.jks`
- Relative: `../../upload-keystore.jks`

### Step 3: Update Version Numbers

Edit `pubspec.yaml`:

```yaml
version: 2.1.0+21  # version number+build number
```

Version format: `MAJOR.MINOR.PATCH+BUILD_NUMBER`

This will automatically update:
- Android: `versionName` and `versionCode`
- iOS: `CFBundleShortVersionString` and `CFBundleVersion`

### Step 4: Build Release APK

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release
```

**Output:** `build/app/outputs/flutter-apk/app-release.apk`

### Step 5: Build App Bundle (Recommended for Play Store)

```bash
flutter build appbundle --release
```

**Output:** `build/app/outputs/bundle/release/app-release.aab`

**Why AAB?**
- Smaller download size for users
- Google Play Dynamic Delivery
- Required for apps > 150MB

### Step 6: Test Release Build

Install on a physical device:

```bash
# Install APK
adb install build/app/outputs/flutter-apk/app-release.apk

# Or use flutter
flutter install --release
```

**Test thoroughly:**
- ✅ App launches successfully
- ✅ Login/authentication works
- ✅ All features functional
- ✅ Push notifications work
- ✅ Location tracking works
- ✅ No debug logs visible

---

## iOS Release Build

### Step 1: Configure Signing

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** project in navigator
3. Select **Runner** target
4. Go to **Signing & Capabilities** tab
5. Select your Team
6. Ensure Bundle Identifier is `com.gud.express`
7. Enable **Automatically manage signing** (recommended)

### Step 2: Update Version Numbers

Version is set in `pubspec.yaml` (see Android step above).

Verify in Xcode:
1. Runner project → General tab
2. Check **Version** (should match `pubspec.yaml`)
3. Check **Build** number

### Step 3: Configure Capabilities

Ensure these capabilities are enabled:

1. **Push Notifications**
2. **Background Modes**:
   - ✅ Location updates
   - ✅ Background fetch
   - ✅ Remote notifications
3. **Sign in with Apple** (if using Apple Sign In)

### Step 4: Build Release

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build iOS release
flutter build ios --release
```

### Step 5: Create Archive in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Any iOS Device (arm64)** as destination
3. Go to **Product** → **Archive**
4. Wait for archive to complete
5. Organizer window opens automatically

### Step 6: Export IPA

In Xcode Organizer:

1. Select your archive
2. Click **Distribute App**
3. Select distribution method:
   - **App Store Connect** (for TestFlight/App Store)
   - **Ad Hoc** (for testing on specific devices)
   - **Enterprise** (if you have enterprise account)
4. Follow the wizard:
   - Select your team
   - Choose signing: **Automatically manage signing**
   - Review app.ipa contents
5. Click **Export**
6. Save IPA file

### Step 7: Test on Device

For Ad Hoc distribution:

1. Connect device to Mac
2. Open Xcode → **Window** → **Devices and Simulators**
3. Select your device
4. Click **+** to add IPA
5. Install and test thoroughly

---

## Google Play Store Submission

### Step 1: Create Play Console Account

1. Go to [Google Play Console](https://play.google.com/console)
2. Pay $25 registration fee (one-time)
3. Complete account setup

### Step 2: Create New App

1. Click **Create app**
2. Fill in details:
   - **App name**: GUD Express
   - **Default language**: English (United States)
   - **App or game**: App
   - **Free or paid**: Free
3. Accept declarations
4. Click **Create app**

### Step 3: Complete Store Listing

Navigate to **Store presence** → **Main store listing**:

#### App Details
- **App name**: GUD Express
- **Short description** (80 chars):
  ```
  Professional trucking management with real-time tracking and load management
  ```
- **Full description** (4000 chars):
  ```
  GUD Express is a comprehensive trucking management solution designed for 
  drivers and dispatchers. Track loads in real-time, manage deliveries, 
  capture proof of delivery, and monitor expenses all in one powerful app.

  KEY FEATURES:
  • Real-time GPS tracking and route optimization
  • Load management and assignment
  • Digital proof of delivery with photo capture
  • Expense tracking and reporting
  • Push notifications for load updates
  • Offline mode for rural areas
  • Geofencing for automatic arrival detection
  • Comprehensive analytics and reporting

  [Add more details about your app's features and benefits]
  ```

#### Graphics
Required assets:

1. **App icon** (512 x 512 px, 32-bit PNG)
2. **Feature graphic** (1024 x 500 px, PNG or JPEG)
3. **Phone screenshots** (at least 2, up to 8):
   - 16:9 aspect ratio
   - Minimum dimension: 320px
   - Maximum dimension: 3840px
4. **7-inch tablet screenshots** (optional)
5. **10-inch tablet screenshots** (optional)

**📁 Location**: Prepare assets in `docs/store_listings/android/`

#### Categorization
- **App category**: Business
- **Tags**: Logistics, Tracking, Trucking, Fleet Management

#### Contact Details
- **Email**: support@gudexpress.com
- **Phone**: (optional)
- **Website**: https://gudexpress.com (if available)

#### Privacy Policy
- **URL**: https://your-domain.com/privacy-policy
  (Can host on GitHub Pages - see existing privacy_policy.md)

### Step 4: Complete Content Rating

1. Navigate to **Policy** → **App content**
2. Click **Start questionnaire**
3. Select category: **Utility, Productivity, Communication, or Other**
4. Answer questions honestly
5. Save and get rating

### Step 5: Set Up Pricing & Distribution

Navigate to **Policy** → **Pricing and distribution**:

1. **Countries**: Select all countries (or specific ones)
2. **Pricing**: Free
3. **Contains ads**: No (unless you added ads)
4. **In-app purchases**: No (unless you have IAPs)
5. **Content guidelines**: Check all appropriate boxes
6. **App access**: All functionality available without restrictions

### Step 6: Complete Data Safety

Navigate to **Policy** → **App content** → **Data safety**:

Answer questions about:
- Data collection (location, personal info, etc.)
- Data sharing with third parties
- Data security practices
- Data deletion options

**Example for GUD Express:**
- ✅ Collects location data
- ✅ Collects personal info (name, email)
- ✅ Data encrypted in transit
- ✅ Users can request data deletion
- ❌ No data sharing with third parties (verify this!)

### Step 7: Upload App Bundle

Navigate to **Release** → **Production** → **Create new release**:

1. Click **Upload**
2. Select your AAB file: `build/app/outputs/bundle/release/app-release.aab`
3. Wait for upload and processing
4. Review any warnings or errors

### Step 8: Write Release Notes

Add release notes for this version:

```
Initial release of GUD Express v2.1.0

Features:
• Real-time GPS tracking
• Load management
• Proof of delivery
• Expense tracking
• Push notifications
• Offline support
```

### Step 9: Submit for Review

1. Review all sections (must show green checkmarks)
2. Click **Save**
3. Click **Review release**
4. Click **Start rollout to Production**

**Review process:**
- Usually takes 1-3 days
- May take up to 7 days
- You'll receive email when reviewed

### Step 10: Monitor Release

After approval:
1. App goes live on Play Store
2. Monitor **Release dashboard** for:
   - Install metrics
   - Crash reports
   - User reviews
   - Performance metrics

---

## Apple App Store Submission

### Step 1: Prepare App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Click **My Apps**
3. Click **+** → **New App**

### Step 2: Create App Record

Fill in app information:

- **Platform**: iOS
- **Name**: GUD Express
- **Primary Language**: English (U.S.)
- **Bundle ID**: Select `com.gud.express`
- **SKU**: `gud-express-001` (unique identifier)
- **User Access**: Full Access

### Step 3: Complete App Information

Navigate to your app → **App Information**:

#### General Information
- **Name**: GUD Express
- **Subtitle** (30 chars): Trucking Management Made Easy
- **Category**: 
  - Primary: Business
  - Secondary: Productivity

#### Privacy
- **Privacy Policy URL**: https://your-domain.com/privacy
- **App Privacy**: Configure in App Store Connect

### Step 4: Configure App Privacy

Click **Set Up Your App Privacy**:

Answer questions about:
1. **Data collection**: Location, email, name, etc.
2. **Data usage**: Analytics, app functionality, etc.
3. **Tracking**: No tracking
4. **Data linked to user**: Yes (authentication data)

### Step 5: Prepare Screenshots

Required screenshots for each device size:

#### iPhone 6.7" Display (Pro Max)
- 1290 x 2796 pixels
- At least 3 screenshots required
- Up to 10 screenshots allowed

#### iPhone 5.5" Display (8 Plus)
- 1242 x 2208 pixels
- At least 3 screenshots required

**📁 Location**: Prepare in `docs/store_listings/ios/`

**Tips:**
- Show key features
- Use descriptive captions
- Keep text readable
- Follow Apple's guidelines
- Consider hiring a designer

### Step 6: Write App Store Description

**Description** (4000 chars):
```
GUD Express - Professional Trucking Management

Transform your trucking business with GUD Express, the complete management 
solution for drivers and dispatchers. Stay connected, track deliveries in 
real-time, and streamline your operations.

POWERFUL FEATURES:

🚚 Real-Time GPS Tracking
• Track driver locations live
• Optimize routes automatically
• Share ETAs with customers
• Monitor fleet in real-time

📦 Load Management
• Assign loads to drivers
• Track pickup and delivery
• Update status on the go
• Manage multiple loads simultaneously

📸 Digital Proof of Delivery
• Capture photos instantly
• Add notes and signatures
• Store in cloud securely
• Generate professional PDFs

💰 Expense Tracking
• Log fuel costs
• Track maintenance
• Categorize expenses
• Export reports instantly

🔔 Smart Notifications
• Load assignment alerts
• Status update notifications
• Important reminders
• Real-time updates

📡 Works Offline
• Data syncs automatically
• Functions without internet
• Perfect for rural routes
• Never miss a beat

WHO IT'S FOR:
• Independent truck drivers
• Fleet managers
• Dispatchers
• Trucking companies of all sizes

REQUIREMENTS:
• iOS 13.0 or later
• Location services access
• Camera access (for POD)
• Push notifications

SUPPORT:
Need help? Contact us at support@gudexpress.com

[Add more specific details about your app]
```

**Keywords** (100 chars):
```
trucking,logistics,fleet,tracking,delivery,driver,load,dispatch,route,GPS
```

**Support URL**: https://gudexpress.com/support
**Marketing URL**: https://gudexpress.com (optional)

### Step 7: Create App Version

Navigate to **App Store** → **iOS App** → **+ Version or Platform**:

1. Enter version number: `2.1.0`
2. Click **Create**

### Step 8: Upload Build

#### Using Xcode:
1. Create archive (see iOS build steps above)
2. In Organizer, click **Distribute App**
3. Select **App Store Connect**
4. Click **Upload**
5. Wait for processing (15-30 minutes)

#### Verify Upload:
1. Go to App Store Connect
2. Navigate to **TestFlight** tab
3. Build should appear under **iOS Builds**
4. Wait for **Processing** to complete
5. Status changes to **Ready to Submit**

### Step 9: Configure Build for Release

Back in **App Store** tab:

1. Select your uploaded build
2. Review **Export Compliance**: 
   - Does your app use encryption? Usually "No" for standard HTTPS
3. Click **Save**

### Step 10: Configure Additional Information

#### App Review Information
- **First Name**: Your first name
- **Last Name**: Your last name
- **Phone Number**: Your phone
- **Email**: Your email
- **Demo Account**: Provide test credentials:
  ```
  Username: demo@gudexpress.com
  Password: DemoPassword123!
  Role: Driver (or Admin)
  ```
- **Notes**: 
  ```
  Test account provided above for review purposes.
  Key features to test:
  1. Login with provided credentials
  2. View sample loads on dashboard
  3. Test location tracking (requires location permission)
  4. View proof of delivery features
  
  Note: Some features require multiple users for full testing.
  ```

#### Version Information
- **Copyright**: © 2024 GUD Express. All rights reserved.
- **Age Rating**: 4+
- **Content Rights**: You confirm you own the rights

### Step 11: Submit for Review

1. Review all fields (green checkmarks required)
2. Click **Add for Review**
3. Click **Submit to App Review**
4. Confirm submission

**Review Timeline:**
- Initial review: 24-48 hours
- Re-submissions: Usually faster
- May be selected for longer review (rare)

### Step 12: TestFlight Beta Testing (Recommended)

Before submitting to App Store:

1. Go to **TestFlight** tab
2. Add internal testers (up to 100)
3. Add external testers (unlimited, requires review)
4. Share TestFlight link
5. Gather feedback
6. Fix any issues
7. Then submit to App Store

### Step 13: Monitor Review Status

Check status in App Store Connect:
- **Waiting for Review**: In queue
- **In Review**: Being reviewed (usually takes hours)
- **Pending Developer Release**: Approved! (you control release)
- **Processing for App Store**: Final processing
- **Ready for Sale**: Live!

### Step 14: Post-Launch

After approval:
- App goes live (or at scheduled time)
- Monitor:
  - Crash reports (Xcode → Organizer → Crashes)
  - User reviews
  - Sales and Trends
  - App Analytics

---

## Production Monitoring

### Firebase Crashlytics

#### Access Dashboard
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Quality** → **Crashlytics**

#### Monitor Crashes
- **Crash-free users**: Target 99.5%+
- **Crash trends**: Monitor for spikes
- **Top issues**: Fix high-impact crashes first
- **Velocity alerts**: Set up notifications

#### View Crash Details
```bash
# Via CLI
firebase crashlytics:symbols:upload \
  --app=YOUR_FIREBASE_APP_ID \
  path/to/symbols
```

### Firebase Analytics

#### Access Dashboard
1. Firebase Console → **Analytics** → **Dashboard**
2. View key metrics:
   - Active users (DAU, WAU, MAU)
   - User engagement
   - User retention
   - Revenue (if applicable)

#### Custom Events
Monitor custom events you logged:
- `load_created`
- `load_assigned`
- `load_delivered`
- `pod_uploaded`
- `expense_added`

#### Audiences
Create audiences for:
- Active drivers
- Inactive users (for re-engagement)
- High-value users
- Users with crashes

### Firebase Performance Monitoring

#### Access Dashboard
1. Firebase Console → **Quality** → **Performance**

#### Monitor Metrics
- **App start time**: Target < 3 seconds
- **Screen rendering**: Target 60fps
- **Network requests**: Monitor slow APIs
- **Custom traces**: Track critical operations

### Cloud Functions Monitoring

#### View Function Logs

```bash
# Real-time logs
firebase functions:log

# Filter by function
firebase functions:log --only notifyLoadStatusChange

# Specific time range
firebase functions:log --since 2h
```

#### Monitor Function Health

1. Firebase Console → **Functions**
2. Check for:
   - Invocations
   - Execution time
   - Memory usage
   - Error rate

#### Set Up Alerts

1. Cloud Console → **Monitoring** → **Alerting**
2. Create alert policies for:
   - High error rate (> 5%)
   - Long execution time (> 10s)
   - High invocation count (cost management)

### Cloud Firestore Monitoring

#### Usage Metrics
1. Firebase Console → **Firestore Database** → **Usage**
2. Monitor:
   - Document reads
   - Document writes
   - Document deletes
   - Storage usage

#### Set Usage Alerts
```bash
# Set up budget alerts in Cloud Console
# Billing → Budgets & Alerts
```

### Google Play Console

#### Monitor Android App
1. [Play Console](https://play.google.com/console)
2. Key metrics:
   - **Installs**: Growth trends
   - **Uninstalls**: Watch for spikes
   - **Ratings**: Target 4.0+
   - **Reviews**: Respond to users
   - **Crashes**: ANR rate < 1%

### App Store Connect

#### Monitor iOS App
1. [App Store Connect](https://appstoreconnect.apple.com/)
2. Key metrics:
   - **Downloads**: Track trends
   - **Crashes**: Crash rate < 1%
   - **App Store ratings**: Target 4.0+
   - **Reviews**: Respond promptly

### Setting Up Alerts

#### Firebase Alerts
1. Firebase Console → **Alerts**
2. Configure:
   - Crashlytics: New crash types
   - Performance: Slow traces
   - Analytics: User drops

#### Email Notifications
Set up email notifications for:
- ✅ New crashes
- ✅ Performance regressions
- ✅ Function errors
- ✅ Quota warnings
- ✅ New reviews

#### Slack Integration (Optional)
```bash
# Set up Slack webhook for alerts
# Firebase Console → Project Settings → Integrations → Slack
```

---

## CI/CD with GitHub Actions

### Prerequisites

1. GitHub repository set up
2. Workflows exist: `.github/workflows/android-build.yml`
3. Firebase CLI token for deployments

### Required GitHub Secrets

Navigate to **Settings** → **Secrets and variables** → **Actions**:

#### Firebase Secrets
```
FIREBASE_TOKEN
```
Get token:
```bash
firebase login:ci
# Copy the token displayed
```

#### Android Secrets
```
ANDROID_KEYSTORE_BASE64
ANDROID_KEY_PROPERTIES
GOOGLE_SERVICES_JSON
```

Generate Base64 keystore:
```bash
# macOS/Linux
base64 -i upload-keystore.jks -o keystore.txt

# Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) > keystore.txt

# Add to GitHub Secrets as ANDROID_KEYSTORE_BASE64
```

Create `ANDROID_KEY_PROPERTIES` secret:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/home/runner/work/gud/gud/android/app/upload-keystore.jks
```

Create `GOOGLE_SERVICES_JSON` secret:
```bash
# Copy contents of android/app/google-services.json
# Paste as GitHub secret
```

#### iOS Secrets (if building iOS on CI)
```
IOS_CERTIFICATE_BASE64
IOS_PROVISIONING_PROFILE
GOOGLE_SERVICE_INFO_PLIST
IOS_CERTIFICATE_PASSWORD
```

Generate Base64 certificate:
```bash
base64 -i certificate.p12 -o certificate.txt
```

### Update Workflow to Trigger on Tags

Edit `.github/workflows/android-build.yml`:

```yaml
on:
  push:
    branches:
      - main
    tags:
      - 'v*.*.*'  # Trigger on version tags
  pull_request:
    branches:
      - main
  workflow_dispatch:
```

### Creating Release Builds

```bash
# Tag your release
git tag -a v2.1.0 -m "Release version 2.1.0"

# Push tag to GitHub
git push origin v2.1.0

# GitHub Actions will automatically:
# 1. Build APK
# 2. Build AAB
# 3. Run tests
# 4. Upload artifacts
```

### Download Build Artifacts

1. Go to GitHub → **Actions**
2. Select workflow run
3. Scroll to **Artifacts**
4. Download APK or AAB

### Deploy Functions via CI/CD

Create `.github/workflows/firebase-deploy.yml`:

```yaml
name: Deploy to Firebase

on:
  push:
    branches:
      - main
    paths:
      - 'functions/**'
      - 'firestore.rules'
      - 'firestore.indexes.json'
      - 'storage.rules'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '18'
      
      - name: Install Firebase CLI
        run: npm install -g firebase-tools
      
      - name: Install Functions Dependencies
        run: |
          cd functions
          npm ci
      
      - name: Deploy to Firebase
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
        run: |
          firebase deploy --only functions,firestore:rules,firestore:indexes,storage --token $FIREBASE_TOKEN
```

### Monitoring CI/CD

- Check **Actions** tab for workflow status
- Review logs for failures
- Set up email notifications for failed builds

---

## Troubleshooting

### Common Issues

#### Firebase Deployment Issues

**Problem**: `Permission denied` when deploying functions

**Solution**:
```bash
# Re-login to Firebase
firebase logout
firebase login

# Verify project
firebase projects:list

# Set correct project
firebase use YOUR_PROJECT_ID
```

---

**Problem**: Function deployment timeout

**Solution**:
```bash
# Deploy functions one at a time
firebase deploy --only functions:notifyLoadStatusChange
firebase deploy --only functions:notifyNewLoad
# etc.

# Or increase timeout
firebase deploy --only functions --force
```

---

**Problem**: Cloud Functions require billing

**Solution**:
1. Firebase Console → **Upgrade**
2. Enable Blaze plan
3. Add payment method
4. Set budget alerts

---

#### Android Build Issues

**Problem**: `google-services.json not found`

**Solution**:
```bash
# Verify file exists
ls -la android/app/google-services.json

# Download from Firebase Console
# Project Settings → Your apps → Download google-services.json
# Place in android/app/
```

---

**Problem**: Keystore not found or invalid

**Solution**:
```bash
# Verify keystore path in key.properties
cat android/key.properties

# Test keystore
keytool -list -v -keystore ~/upload-keystore.jks

# If corrupted, generate new keystore (will require new Play Store app)
```

---

**Problem**: Build fails with "Execution failed for task ':app:minifyReleaseWithR8'"

**Solution**:
```bash
# Check ProGuard rules
cat android/app/proguard-rules.pro

# Add rules for any failing libraries
# Clean and rebuild
flutter clean
flutter build apk --release
```

---

#### iOS Build Issues

**Problem**: Code signing error

**Solution**:
1. Open Xcode
2. Select Runner project
3. Signing & Capabilities
4. Ensure correct team selected
5. Toggle "Automatically manage signing"

---

**Problem**: `GoogleService-Info.plist not found`

**Solution**:
```bash
# Download from Firebase Console
# Place in ios/Runner/

# Verify in Xcode
# File should appear in Runner folder
# Build Phases → Copy Bundle Resources
```

---

**Problem**: Push notifications not working on iOS

**Solution**:
1. Verify APNs key uploaded to Firebase
2. Check capabilities in Xcode
3. Request notification permissions in code
4. Test on physical device (not simulator)

---

#### Runtime Issues

**Problem**: App crashes on startup

**Solution**:
```bash
# Check Firebase initialization
# Verify google-services.json / GoogleService-Info.plist

# Check logs
# Android:
adb logcat | grep Flutter

# iOS:
# Xcode → Devices & Simulators → View Device Logs
```

---

**Problem**: Location tracking not working

**Solution**:
1. Check permissions in `Info.plist` (iOS) or `AndroidManifest.xml`
2. Request permissions at runtime
3. Test on physical device
4. Check location services enabled on device

---

**Problem**: Cloud Functions not triggering

**Solution**:
```bash
# Check function logs
firebase functions:log

# Verify functions deployed
firebase functions:list

# Test manually
# Firebase Console → Functions → Test function
```

---

### Getting Help

#### Firebase Support
- [Firebase Documentation](https://firebase.google.com/docs)
- [Firebase Support](https://firebase.google.com/support)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/firebase) - Tag: `firebase`

#### Flutter Support
- [Flutter Documentation](https://flutter.dev/docs)
- [Flutter GitHub](https://github.com/flutter/flutter/issues)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter) - Tag: `flutter`

#### Platform Support
- [Google Play Support](https://support.google.com/googleplay/android-developer)
- [App Store Support](https://developer.apple.com/support/app-store/)

#### Community
- [Flutter Community](https://flutter.dev/community)
- [Firebase Discord](https://discord.gg/firebase)
- [r/FlutterDev](https://reddit.com/r/FlutterDev)

---

## Next Steps

After successful deployment:

1. ✅ Monitor crash reports daily
2. ✅ Respond to user reviews
3. ✅ Track analytics metrics
4. ✅ Plan feature updates
5. ✅ Set up beta testing for new features
6. ✅ Regular security updates
7. ✅ Optimize based on performance data

## Additional Resources

- [PRE_DEPLOYMENT_CHECKLIST.md](PRE_DEPLOYMENT_CHECKLIST.md) - Complete pre-flight checklist
- [docs/REMOTE_CONFIG_SETUP.md](docs/REMOTE_CONFIG_SETUP.md) - Remote Config configuration
- [docs/APP_STORE_SUBMISSION_GUIDE.md](docs/APP_STORE_SUBMISSION_GUIDE.md) - Detailed store guide
- [FIREBASE_SETUP.md](FIREBASE_SETUP.md) - Firebase configuration guide
- [docs/monitoring.md](docs/monitoring.md) - Advanced monitoring guide

---

**🎉 Congratulations!** You're ready to deploy GUD Express to production!

For questions or issues, refer to the troubleshooting section or contact support.
