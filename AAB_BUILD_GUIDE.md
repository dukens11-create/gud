# Android App Bundle (AAB) Build Guide for GUD Express

This guide provides comprehensive instructions for building and deploying the GUD Express Android App Bundle (AAB) to the Google Play Store.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Keystore Generation](#keystore-generation)
3. [Building the AAB](#building-the-aab)
4. [Verifying the Build](#verifying-the-build)
5. [Google Play Console Upload](#google-play-console-upload)
6. [Testing the AAB](#testing-the-aab)
7. [Troubleshooting](#troubleshooting)
8. [Version Management](#version-management)
9. [CI/CD Integration](#cicd-integration)

---

## Prerequisites

Before building the AAB, ensure you have the following installed:

### Required Software
- **Flutter SDK**: 3.0.0 or higher (recommended: 3.24.0)
  ```bash
  flutter --version
  ```
- **Android SDK**: API Level 21-36
- **Java Development Kit (JDK)**: Version 17 or higher
  ```bash
  java -version
  ```
- **Android Studio**: Latest stable version (optional but recommended)

### Environment Setup
```bash
# Verify Flutter installation
flutter doctor -v

# Update Flutter if needed
flutter upgrade

# Install Android toolchain
flutter doctor --android-licenses
```

---

## Keystore Generation

A keystore is required to sign your release builds. **Keep this secure** - losing it means you cannot update your app on Google Play!

### Step 1: Generate the Keystore

Run the following command in your terminal:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

**For Windows:**
```cmd
keytool -genkey -v -keystore %USERPROFILE%\upload-keystore.jks ^
  -keyalg RSA -keysize 2048 -validity 10000 ^
  -alias upload
```

### Step 2: Answer the Prompts

You'll be asked for:
- **Keystore password**: Create a strong password
- **Key password**: Can be the same as keystore password
- **Your name**: Your or your organization's name
- **Organizational unit**: Your department (e.g., Development)
- **Organization**: Your company name (e.g., GUD Express)
- **City/Locality**: Your city
- **State/Province**: Your state
- **Country code**: Two-letter country code (e.g., US)

**IMPORTANT:** Write down these passwords in a secure location!

### Step 3: Create key.properties

1. Copy the template:
   ```bash
   cp android/key.properties.template android/key.properties
   ```

2. Edit `android/key.properties` with your actual values:
   ```properties
   storePassword=YOUR_KEYSTORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=upload
   storeFile=/absolute/path/to/upload-keystore.jks
   ```

**Example:**
```properties
storePassword=MySecurePassword123!
keyPassword=MySecurePassword123!
keyAlias=upload
storeFile=/Users/john/upload-keystore.jks
```

**Windows Example:**
```properties
storePassword=MySecurePassword123!
keyPassword=MySecurePassword123!
keyAlias=upload
storeFile=C:\\Users\\john\\upload-keystore.jks
```

### Step 4: Secure Your Keystore

```bash
# Move keystore to a secure location (outside the project)
mv ~/upload-keystore.jks ~/secure-keys/

# Update key.properties with the new path
# Verify key.properties is in .gitignore
git check-ignore android/key.properties
```

**⚠️ NEVER commit key.properties or your keystore to version control!**

---

## Building the AAB

### Option 1: Using Build Scripts (Recommended)

#### Linux/macOS:
```bash
# Make the script executable (first time only)
chmod +x scripts/build_aab.sh

# Run the build
./scripts/build_aab.sh
```

#### Windows:
```cmd
scripts\build_aab.bat
```

### Option 2: Manual Build

```bash
# Step 1: Clean previous builds
flutter clean

# Step 2: Get dependencies
flutter pub get

# Step 3: Build the AAB
flutter build appbundle --release

# The AAB will be at: build/app/outputs/bundle/release/app-release.aab
```

### Build Options

**Split by ABI (for smaller downloads):**
```bash
flutter build appbundle --release --target-platform android-arm,android-arm64,android-x64
```

**Build with obfuscation (already enabled in release mode):**
```bash
flutter build appbundle --release --obfuscate --split-debug-info=./debug-info
```

---

## Verifying the Build

### Using Bundletool

Bundletool lets you test your AAB locally before uploading to Play Store.

#### Step 1: Download Bundletool
```bash
wget https://github.com/google/bundletool/releases/download/1.15.6/bundletool-all-1.15.6.jar
```

#### Step 2: Generate APK Set from AAB
```bash
java -jar bundletool-all-1.15.6.jar build-apks \
  --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=gud_express.apks \
  --ks=~/upload-keystore.jks \
  --ks-key-alias=upload \
  --ks-pass=pass:YOUR_KEYSTORE_PASSWORD \
  --key-pass=pass:YOUR_KEY_PASSWORD
```

#### Step 3: Install on Device
```bash
# Connect your Android device
adb devices

# Install the APKs
java -jar bundletool-all-1.15.6.jar install-apks \
  --apks=gud_express.apks
```

### Verify AAB Contents

Check the AAB structure:
```bash
java -jar bundletool-all-1.15.6.jar dump manifest \
  --bundle=build/app/outputs/bundle/release/app-release.aab
```

Check AAB size:
```bash
# Linux/macOS
ls -lh build/app/outputs/bundle/release/app-release.aab

# Windows
dir build\app\outputs\bundle\release\app-release.aab
```

**Expected size:** 40-80 MB (varies based on features and assets)

---

## Google Play Console Upload

### Step 1: Access Play Console
1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app or create a new one
3. Navigate to **Release > Production** (or Testing track)

### Step 2: Create a Release
1. Click **Create new release**
2. Upload your AAB file (`app-release.aab`)
3. The system will automatically verify and process the AAB

### Step 3: Fill Release Details

**Release name:** `2.1.0 (2)` - matches version from pubspec.yaml

**Release notes** (example):
```
What's New in 2.1.0:
• Enhanced GPS tracking with improved accuracy
• New expense tracking features
• Performance improvements
• Bug fixes and stability improvements
```

### Step 4: Review and Rollout
1. Review all details
2. Choose rollout percentage (start with 10-20% for safety)
3. Click **Save** and then **Review release**
4. Click **Start rollout to production**

### First Time Setup (New App)

If this is your first release:
1. Complete **Store listing** (screenshots, descriptions)
2. Set up **Content rating**
3. Complete **App content** survey
4. Set **Pricing & distribution**
5. Submit for review (can take 1-7 days)

---

## Testing the AAB

### Internal Testing Track
1. Go to **Release > Testing > Internal testing**
2. Create a new release with your AAB
3. Add testers via email
4. Share the testing link with your team

### Closed Testing (Beta)
1. Go to **Release > Testing > Closed testing**
2. Create a testing track
3. Add AAB to the track
4. Invite users or create email lists

### Open Testing
1. Available to anyone with the link
2. Good for public beta testing
3. Users can opt-in through Play Store

---

## Troubleshooting

### Common Issues

#### 1. "key.properties not found"
```bash
# Solution: Copy and configure key.properties
cp android/key.properties.template android/key.properties
# Edit the file with your actual values
```

#### 2. "Keystore file not found"
```bash
# Solution: Verify the path in key.properties
# Use absolute path, not relative
# For Windows, use double backslashes: C:\\Users\\...
```

#### 3. Build fails with "minifyEnabled" error
```bash
# Solution: Ensure ProGuard rules are correct
# Check: android/app/proguard-rules.pro exists
# Try building without minification first:
flutter build appbundle --release --no-shrink
```

#### 4. "Duplicate class" errors
```bash
# Solution: Clean and rebuild
flutter clean
flutter pub get
flutter build appbundle --release
```

#### 5. Firebase/Google Services errors
```bash
# Ensure google-services.json exists in android/app/
# Verify Firebase project configuration
# Check that google-services plugin is applied in build.gradle
```

#### 6. AAB upload rejected by Play Console
- **Issue:** Version code already exists
  - **Solution:** Increment versionCode in `android/app/build.gradle`
- **Issue:** Signature mismatch
  - **Solution:** Ensure you're using the same keystore as previous releases
- **Issue:** Missing required permissions
  - **Solution:** Check AndroidManifest.xml has all necessary permissions

### Debug Build Issues

Enable verbose logging:
```bash
flutter build appbundle --release --verbose
```

Check Gradle logs:
```bash
cd android
./gradlew bundleRelease --stacktrace
```

---

## Version Management

### Version Naming Convention
- **Format:** `MAJOR.MINOR.PATCH+BUILD`
- **Example:** `2.1.0+2`
  - `2.1.0`: Version name (user-facing)
  - `2`: Version code (internal, must increment)

### Updating Version

Version numbers must be updated in TWO locations:

1. Edit `pubspec.yaml`:
   ```yaml
   version: 2.2.0+3
   ```

2. Edit `android/app/build.gradle`:
   ```gradle
   versionCode 3
   versionName "2.2.0"
   ```

**Important:** Keep these synchronized! The version in `build.gradle` is what Google Play uses.

3. Rebuild the AAB:
   ```bash
   ./scripts/build_aab.sh
   ```

### Version Strategy
- **Patch (2.1.1):** Bug fixes only
- **Minor (2.2.0):** New features, backwards compatible
- **Major (3.0.0):** Breaking changes, major overhaul

---

## CI/CD Integration

### GitHub Actions

The project includes a pre-configured workflow at `.github/workflows/android-build.yml`.

#### Automatic Builds
- Triggered on: Push to `main`, PR, version tags (`v*.*.*`)
- Builds both APK and AAB
- Stores artifacts for 30 days

#### Manual Trigger
```bash
# Go to GitHub Actions tab
# Select "Android Build" workflow
# Click "Run workflow"
```

### Codemagic

The project includes AAB workflow in `codemagic.yaml`.

#### Setup
1. Go to [Codemagic](https://codemagic.io)
2. Connect your repository
3. Add environment variables:
   - `CM_KEYSTORE_PASSWORD`
   - `CM_KEY_PASSWORD`
   - `CM_KEY_ALIAS`
   - `CM_KEYSTORE_PATH`

#### Trigger Build
- Push to `main` or `release/*` branches
- Create a version tag: `v2.1.0`

---

## Best Practices

### Security
- ✅ **NEVER** commit keystore or key.properties
- ✅ Store keystore in a secure, backed-up location
- ✅ Use different keystores for debug and release
- ✅ Limit access to signing credentials
- ✅ Rotate keys periodically (advanced)

### Build Optimization
- ✅ Enable ProGuard/R8 obfuscation (already configured)
- ✅ Use AAB instead of APK for smaller downloads
- ✅ Enable split APKs by ABI
- ✅ Compress images before including in assets
- ✅ Remove unused resources

### Testing
- ✅ Test on multiple devices before release
- ✅ Use Internal Testing track first
- ✅ Gradually roll out (10% → 50% → 100%)
- ✅ Monitor crash reports in Play Console
- ✅ Check ANR (Application Not Responding) rates

### Release Checklist
- [ ] Version numbers updated
- [ ] Changelog prepared
- [ ] All tests passing
- [ ] ProGuard rules verified
- [ ] Keystore accessible
- [ ] AAB built successfully
- [ ] AAB tested with bundletool
- [ ] Screenshots updated (if UI changed)
- [ ] Store listing reviewed
- [ ] Release notes written

---

## Additional Resources

- [Official Flutter Build Documentation](https://docs.flutter.dev/deployment/android)
- [Android App Bundle Documentation](https://developer.android.com/guide/app-bundle)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [Bundletool Documentation](https://developer.android.com/tools/bundletool)
- [ProGuard/R8 Documentation](https://developer.android.com/build/shrink-code)

---

## Support

For issues specific to GUD Express:
- Check the [main documentation](/README.md)
- Review [DEPLOYMENT.md](/DEPLOYMENT.md)
- Contact the development team

**Last Updated:** February 2026  
**App Version:** 2.1.0+2  
**Minimum Flutter Version:** 3.0.0
