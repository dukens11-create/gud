# iOS Firebase Configuration Setup Guide

## Overview

This guide provides step-by-step instructions for properly configuring Firebase for iOS in the GUD Express app. The iOS app **requires a valid Firebase configuration** to function correctly. Using placeholder values will cause authentication, database, and storage features to fail.

## ⚠️ Critical Notice

The current `ios/Runner/GoogleService-Info.plist` file contains **placeholder values** that will prevent the app from working on iOS devices:

```xml
<key>CLIENT_ID</key>
<string>750390855294-placeholder.apps.googleusercontent.com</string>
<key>REVERSED_CLIENT_ID</key>
<string>com.googleusercontent.apps.750390855294-placeholder</string>
<key>GOOGLE_APP_ID</key>
<string>1:750390855294:ios:placeholder</string>
```

**You must replace this file with the correct configuration from Firebase Console before building for iOS devices.**

## Prerequisites

- Active Firebase project (Project: `gud-express`)
- Access to [Firebase Console](https://console.firebase.google.com/project/gud-express)
- Xcode installed (for iOS development)
- Flutter SDK configured

## Step-by-Step Setup

### Step 1: Access Firebase Console

1. Navigate to the [Firebase Console](https://console.firebase.google.com/)
2. Select the **gud-express** project
3. Click on the **gear icon** (⚙️) next to "Project Overview"
4. Select **Project settings**

### Step 2: Register iOS App (If Not Already Registered)

If the iOS app hasn't been registered yet:

1. In Project Settings, scroll down to **Your apps** section
2. Click the **iOS icon** (🍎) to add an iOS app
3. Enter the following information:
   - **iOS bundle ID**: `com.gudexpress.gud_app`
   - **App nickname** (optional): `GUD Express iOS`
   - **App Store ID** (optional): Leave blank for now
4. Click **Register app**

### Step 3: Download GoogleService-Info.plist

1. After registering (or if already registered), you'll see the download option
2. Click **Download GoogleService-Info.plist**
3. Save the file to a secure location on your computer

**Important**: This file contains sensitive configuration data. Keep it secure and never commit it to public repositories.

### Step 4: Verify Configuration File

Before replacing the placeholder file, verify that your downloaded `GoogleService-Info.plist` contains:

```xml
<key>CLIENT_ID</key>
<string>750390855294-[actual-hash].apps.googleusercontent.com</string>
<key>REVERSED_CLIENT_ID</key>
<string>com.googleusercontent.apps.750390855294-[actual-hash]</string>
<key>GOOGLE_APP_ID</key>
<string>1:750390855294:ios:[actual-app-id]</string>
<key>API_KEY</key>
<string>AIzaSyAaXuqdrgjL20QCjs66DbDhc2D3IzjLtf4</string>
<key>PROJECT_ID</key>
<string>gud-express</string>
<key>BUNDLE_ID</key>
<string>com.gudexpress.gud_app</string>
```

**Key verification points**:
- ✅ `CLIENT_ID` should NOT contain "placeholder"
- ✅ `REVERSED_CLIENT_ID` should NOT contain "placeholder"
- ✅ `GOOGLE_APP_ID` should NOT contain "placeholder"
- ✅ `PROJECT_ID` should be `gud-express`
- ✅ `BUNDLE_ID` should be `com.gudexpress.gud_app`

### Step 5: Replace Placeholder File

1. Navigate to your project directory:
   ```bash
   cd /path/to/gud
   ```

2. **Backup the existing placeholder** (optional):
   ```bash
   cp ios/Runner/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist.backup
   ```

3. **Replace with the downloaded file**:
   ```bash
   cp /path/to/downloaded/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist
   ```

   Or manually:
   - Delete `ios/Runner/GoogleService-Info.plist`
   - Copy your downloaded file to `ios/Runner/GoogleService-Info.plist`

### Step 6: Validate Configuration

Run the validation script to ensure your configuration is correct:

```bash
./scripts/validate_firebase_ios.sh
```

Expected output for a valid configuration:
```
✅ iOS Firebase Configuration Validation

✅ GoogleService-Info.plist exists
✅ No placeholder values found
✅ Required keys present:
   - CLIENT_ID
   - REVERSED_CLIENT_ID
   - GOOGLE_APP_ID
   - API_KEY
   - PROJECT_ID
   - BUNDLE_ID

✅ All checks passed! iOS Firebase configuration is valid.
```

If validation fails, the script will provide specific error messages to help you fix the issues.

### Step 7: Clean and Rebuild

After replacing the configuration file:

```bash
# Clean previous builds
flutter clean

# Install iOS dependencies
cd ios
pod install
cd ..

# Get Flutter dependencies
flutter pub get

# Build for iOS
flutter build ios --release
```

### Step 8: Test on iOS Device/Simulator

1. **Run on Simulator**:
   ```bash
   flutter run
   # Select iOS simulator when prompted
   ```

2. **Run on Physical Device**:
   ```bash
   flutter run -d [your-device-id]
   ```

3. **Test Firebase Features**:
   - Authentication (login/register)
   - Database operations (loads, drivers)
   - File uploads (POD images)
   - Push notifications

## Xcode Integration

If you're building directly in Xcode:

1. Open the workspace:
   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. Verify `GoogleService-Info.plist` is included:
   - In Xcode's Project Navigator (left sidebar)
   - Under `Runner` → `Runner` folder
   - You should see `GoogleService-Info.plist`
   - Right-click → "Show in Finder" to verify it's the correct file

3. Build and run from Xcode

## Common Issues and Solutions

### Issue: "Firebase not configured" error at runtime

**Symptom**: App crashes or shows Firebase initialization errors.

**Solution**:
1. Verify `GoogleService-Info.plist` is in `ios/Runner/`
2. Run validation script: `./scripts/validate_firebase_ios.sh`
3. Clean and rebuild: `flutter clean && cd ios && pod install && cd .. && flutter pub get`

### Issue: Validation script reports placeholder values

**Symptom**: Script output shows `❌ Placeholder values found`

**Solution**:
1. Download the correct file from Firebase Console (Step 3)
2. Verify you're using the iOS app configuration (not Android)
3. Replace the file completely (Step 5)
4. Re-run validation

### Issue: Authentication not working

**Symptom**: Login/signup fails with configuration errors.

**Solution**:
1. Verify `CLIENT_ID` and `REVERSED_CLIENT_ID` are correct (not placeholders)
2. Check Firebase Console → Authentication → Settings → Authorized domains
3. Ensure your Bundle ID matches: `com.gudexpress.gud_app`
4. Check URL schemes in Xcode:
   - Select Runner target → Info tab
   - Expand "URL Types"
   - Verify `REVERSED_CLIENT_ID` is listed

### Issue: File not found in Xcode

**Symptom**: Build errors about missing GoogleService-Info.plist

**Solution**:
1. Ensure file is in correct location: `ios/Runner/GoogleService-Info.plist`
2. In Xcode, right-click `Runner` folder → "Add Files to Runner"
3. Select `GoogleService-Info.plist`
4. Ensure "Copy items if needed" is checked
5. Ensure "Runner" target is selected

### Issue: CI/CD build failures

**Symptom**: GitHub Actions or Codemagic builds fail with Firebase errors

**Solution**:
1. The validation script runs automatically in CI
2. Ensure the correct file is committed to the repository
3. **Security Note**: For private repositories, you can commit the file
4. For public repositories, use environment variables or secrets
5. See [CI/CD Configuration](#cicd-integration) section

## Security Best Practices

### For Development

1. ✅ **Keep the file secure**: `GoogleService-Info.plist` contains API keys
2. ✅ **Use separate projects**: Development and production Firebase projects
3. ✅ **Restrict API keys**: Configure API key restrictions in Firebase Console
4. ✅ **Review regularly**: Check Firebase Console for unusual activity

### For Production

1. ✅ **Use production Firebase project**: Never use dev credentials in production
2. ✅ **Configure Bundle ID properly**: Production bundle ID must match
3. ✅ **Enable App Attest**: For enhanced security (iOS 14+)
4. ✅ **Monitor usage**: Set up Firebase alerts and monitoring

### For Private Repositories

- ✅ Safe to commit `GoogleService-Info.plist` to private repos
- ✅ Ensure `.gitignore` doesn't exclude this file
- ✅ Team members can pull and use immediately

### For Public Repositories

- ❌ **DO NOT** commit actual credentials
- ✅ Keep `GoogleService-Info.plist.template` as a reference
- ✅ Use environment variables in CI/CD
- ✅ Document setup process for contributors

## CI/CD Integration

### GitHub Actions

The iOS build workflows automatically validate Firebase configuration:

```yaml
- name: Validate iOS Firebase Configuration
  run: ./scripts/validate_firebase_ios.sh
```

If validation fails, the build will stop with a clear error message.

### Codemagic

Add to `codemagic.yaml`:

```yaml
scripts:
  - name: Validate Firebase iOS Config
    script: |
      ./scripts/validate_firebase_ios.sh
```

### Manually Adding Validation

To any CI/CD pipeline:

```bash
# Before building
./scripts/validate_firebase_ios.sh

# Build will only proceed if validation passes
flutter build ios --release
```

## Template File Reference

The repository includes `ios/Runner/GoogleService-Info.plist.template` as a reference. This template:

- Shows the structure of the configuration file
- Uses placeholder values (not functional)
- Helps contributors understand what values to replace
- Should NOT be used for actual builds

## Verification Checklist

Before deploying or submitting to App Store:

- [ ] Downloaded `GoogleService-Info.plist` from Firebase Console
- [ ] Verified file contains no "placeholder" text
- [ ] Placed file at `ios/Runner/GoogleService-Info.plist`
- [ ] Ran validation script successfully
- [ ] Tested authentication on iOS device/simulator
- [ ] Tested database operations (CRUD)
- [ ] Tested file uploads
- [ ] Verified Bundle ID matches: `com.gudexpress.gud_app`
- [ ] Tested on both simulator and physical device
- [ ] Verified Firebase features work in production build

## Quick Reference

| Item | Value |
|------|-------|
| **Firebase Project** | gud-express |
| **Project Number** | 750390855294 |
| **Bundle ID** | com.gudexpress.gud_app |
| **File Location** | `ios/Runner/GoogleService-Info.plist` |
| **Validation Script** | `./scripts/validate_firebase_ios.sh` |
| **Firebase Console** | https://console.firebase.google.com/project/gud-express |

## Additional Resources

- [Firebase iOS Setup Documentation](https://firebase.google.com/docs/ios/setup)
- [FlutterFire iOS Configuration](https://firebase.flutter.dev/docs/installation/ios)
- [Main Firebase Setup Guide](../FIREBASE_SETUP.md)
- [iOS Build Guide](../IOS_BUILD_AND_DEPLOY_GUIDE.md)
- [Troubleshooting Guide](../TROUBLESHOOTING.md)

## Getting Help

If you encounter issues not covered in this guide:

1. Check the [Troubleshooting Guide](../TROUBLESHOOTING.md)
2. Review [Firebase Documentation](https://firebase.google.com/docs/ios)
3. Open an issue on GitHub with:
   - Description of the problem
   - Steps to reproduce
   - Output from validation script
   - iOS version and device info

---

**Remember**: The iOS app will NOT work with placeholder values. Always use the actual configuration from Firebase Console.
