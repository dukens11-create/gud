# GUD Express - Deployment Guide (Demo Version)

Complete guide to building and deploying the GUD Express demo app.

## 🚀 Deployment Options

### Option 1: Direct APK Distribution (Testing)
### Option 2: Google Play Store (Production)
### Option 3: Apple App Store (Production)
### Option 4: Render.com Deployment (Web)

---

## 🌐 Option 4: Render.com Deployment (Web)

Render is a modern cloud platform that provides free hosting for static sites with automatic deployments from GitHub.

### Quick Setup

1. **Sign up for Render:** https://render.com/
2. **Connect GitHub:** In Render dashboard, connect your GitHub account
3. **Create Static Site:**
   - Click "New +" → "Static Site"
   - Select `dukens11-create/gud` repository
   - Build Command: `./render-build.sh`
   - Publish Directory: `build/web`
   - Click "Create Static Site"

4. **Wait for build:** First build takes ~5-10 minutes
5. **Access your app:** https://gud-express.onrender.com

### Features
- ✅ Free SSL certificates (HTTPS)
- ✅ CDN-backed hosting
- ✅ Automatic deployments from GitHub
- ✅ Custom domain support
- ✅ Environment variables support
- ✅ Preview deployments for PRs

See [Render Deployment Guide](docs/RENDER_DEPLOYMENT.md) for complete instructions.

---

## 📱 Option 1: Direct APK Distribution (Testing)

Perfect for testing and demonstration purposes.

### Prerequisites

1. **Flutter SDK** installed (version 3.0.0+)
2. **Android Studio** or Android SDK
3. **Java Development Kit (JDK)** 17

### Step-by-Step Build

#### A. Build the Android APK

```bash
# Navigate to project root
cd /path/to/gud

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release
```

**Output location:** `build/app/outputs/flutter-apk/app-release.apk`

#### B. Build App Bundle (for Play Store)

```bash
flutter build appbundle --release
```

**Output location:** `build/app/outputs/bundle/release/app-release.aab`

#### C. Distribute the APK

**Method 1: Direct Installation**
1. Copy `app-release.apk` to device
2. Enable "Install from Unknown Sources"
3. Tap APK file to install

**Method 2: Email/Cloud**
1. Upload APK to cloud storage (Google Drive, Dropbox, etc.)
2. Share download link with testers
3. Recipients download and install

**Method 3: GitHub Releases**
1. Create a new release on GitHub
2. Upload the APK as a release asset
3. Share the release link

---

## 🏪 Option 2: Google Play Store (Production)

```bash
# Get your Firebase App ID from Firebase Console
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_FIREBASE_ANDROID_APP_ID \
  --groups testers \
  --release-notes "GUD Express v1.0.0 - Initial release"
```

---

## 🤖 Automated CI/CD with GitHub Actions

We've set up two GitHub Actions workflows:

### 1. **Automatic Build on Push** (`.github/workflows/android-build.yml`)

**Triggers:**
- Every push to `main` branch
- Every pull request
- Manual trigger

**Actions:**
- ✅ Builds Android APK
- ✅ Builds App Bundle (AAB)
- ✅ Runs tests
- ✅ Uploads artifacts

**Usage:** Just push code, GitHub will build automatically!

### 2. **Firebase App Distribution** (`.github/workflows/firebase-app-distribution.yml`)

**Triggers:**
- When you create a version tag (e.g., `v1.0.0`)
- Manual trigger

**Setup Required:**

1. **Get Firebase App ID**
   - Go to Firebase Console → Project Settings
   - Under "Your apps" → Android app
   - Copy the App ID (format: `1:123456789:android:abc123...`)

2. **Create Firebase Service Account**
   ```bash
   # In your local terminal
   firebase login
   firebase projects:list
   
   # Get service account credentials
   # Go to: https://console.firebase.google.com/project/YOUR_PROJECT/settings/serviceaccounts/adminsdk
   # Click "Generate new private key"
   # Download the JSON file
   ```

3. **Add GitHub Secrets**
   - Go to your repo: `https://github.com/dukens11-create/gud/settings/secrets/actions`
   - Click **New repository secret**
   - Add two secrets:
     - Name: `FIREBASE_APP_ID`
       Value: Your Firebase Android App ID
     - Name: `FIREBASE_SERVICE_ACCOUNT`
       Value: Entire contents of the service account JSON file

4. **Deploy by Creating a Tag**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

This will automatically build and distribute to Firebase!

---

## 🏪 Option 2: Google Play Store Deployment

For public release on Google Play Store.

### Prerequisites

1. **Google Play Developer Account** ($25 one-time fee)
   - Register at: https://play.google.com/console/signup

2. **App Signing Key** (for production)

### Step 1: Generate Upload Key

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

**Save your passwords!**

### Step 2: Configure Gradle for Signing

Create `android/key.properties`:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/path/to/upload-keystore.jks
```

Update `android/app/build.gradle`:

```gradle
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
            // ... other settings
        }
    }
}
```

### Step 3: Build App Bundle

```bash
flutter build appbundle --release
```

**Output:** `build/app/outputs/bundle/release/app-release.aab`

### Step 4: Upload to Play Console

1. Go to [Play Console](https://play.google.com/console)
2. Click **Create app**
3. Fill in app details:
   - App name: **GUD Express**
   - Default language: English (US)
   - App type: App
   - Free or Paid: Choose
4. Complete the setup questionnaire
5. Go to **Production** → **Create new release**
6. Upload `app-release.aab`
7. Fill in release details
8. Complete store listing:
   - Title: GUD Express
   - Short description
   - Full description
   - App icon (512x512 PNG)
   - Screenshots (at least 2)
   - Feature graphic (1024x500)
9. Submit for review

**Review time:** 1-7 days

---

## 🍎 Option 3: Apple App Store (iOS)

### Prerequisites

1. **Apple Developer Account** ($99/year)
2. **macOS with Xcode**
3. **Provisioning Profiles**

### Step 1: Configure iOS App

```bash
# Open iOS project in Xcode
open ios/Runner.xcworkspace
```

In Xcode:
1. Select **Runner** → **Signing & Capabilities**
2. Set your Team
3. Set Bundle Identifier: `com.gudexpress.gud_app`

### Step 2: Build iOS App

```bash
flutter build ios --release
```

### Step 3: Create Archive in Xcode

1. In Xcode: **Product** → **Archive**
2. Wait for build to complete
3. Click **Distribute App**
4. Choose **App Store Connect**
5. Upload

### Step 4: App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Create new app
3. Fill in metadata
4. Submit for review

---

## 📊 Version Management

Update version in `pubspec.yaml`:

```yaml
version: 1.0.0+1
#        ^^^^^ ^^ 
#        name  build number
```

**Increment:**
- Build number (+1) for minor fixes
- Version name for feature releases

---

## 🔥 Quick Deploy Commands

### Test Build (Firebase App Distribution)
```bash
flutter build apk --release
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_FIREBASE_APP_ID --groups testers
```

### Production Build (Play Store)
```bash
flutter build appbundle --release --obfuscate --split-debug-info=./debug-info
```

### Check Build
```bash
flutter doctor -v
flutter analyze
flutter test
```

---

## 🛡️ Security Checklist

Before deploying:

- [ ] Remove debug/test code
- [ ] Firebase Security Rules configured (see FIREBASE_RULES.md)
- [ ] API keys secured (not hardcoded)
- [ ] `google-services.json` configured for production
- [ ] Code obfuscation enabled for release builds
- [ ] Sensitive data encrypted
- [ ] Privacy policy URL added
- [ ] Terms of service prepared

---

## 📞 Support

For deployment issues:
- Check [Flutter deployment docs](https://docs.flutter.dev/deployment)
- Firebase support: https://firebase.google.com/support
- Create an issue in this repo

---

## 🎉 Congratulations!

Your GUD Express app is now deployed! 🚛

**Next Steps:**
1. Test thoroughly with beta testers
2. Gather feedback
3. Fix bugs
4. Release to production
5. Monitor Firebase Analytics
6. Iterate and improve

Happy Shipping! 🎯
