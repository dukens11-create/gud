# iOS Build and Deploy Guide

Complete guide for building GUD Express iOS app and deploying to App Store Connect using GitHub Actions.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Apple Developer Account Setup](#apple-developer-account-setup)
3. [App Store Connect Setup](#app-store-connect-setup)
4. [Certificate and Provisioning Profile Setup](#certificate-and-provisioning-profile-setup)
5. [GitHub Secrets Configuration](#github-secrets-configuration)
6. [Workflow Usage](#workflow-usage)
7. [Alternative Upload Methods](#alternative-upload-methods)
8. [Troubleshooting](#troubleshooting)
9. [Advanced Configuration](#advanced-configuration)

---

## Prerequisites

### Required Accounts
- **Apple Developer Account** ($99/year individual or $299/year organization)
- **GitHub Account** with repository access
- **macOS Computer** (for initial setup only)

### Required Software (Local Setup)
- Xcode 14+ (from Mac App Store)
- Xcode Command Line Tools: `xcode-select --install`
- CocoaPods: `sudo gem install cocoapods`
- Flutter SDK (for testing locally)

---

## Apple Developer Account Setup

### 1. Register Your Apple Developer Account
1. Go to [Apple Developer Program](https://developer.apple.com/programs/)
2. Sign up with your Apple ID
3. Complete payment ($99/year)
4. Wait for approval (usually 24-48 hours)

### 2. Find Your Team ID
1. Go to [Apple Developer Console](https://developer.apple.com/account)
2. Navigate to **Membership** section
3. Note your **Team ID** (10-character string like `ABCDE12345`)

### 3. Two-Factor Authentication
- Ensure 2FA is enabled on your Apple ID
- This is required for App Store Connect access

---

## App Store Connect Setup

### 1. Create Your App in App Store Connect
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+ (New App)**
3. Fill in the required information:
   - **Platform**: iOS
   - **Name**: GUD Express
   - **Primary Language**: English (US)
   - **Bundle ID**: Select `com.gudexpress.gud_app`
   - **SKU**: `gud-express-app` (unique identifier)
   - **User Access**: Full Access

### 2. Create App Store Connect API Key (Recommended)

This method is preferred as it avoids 2FA prompts during CI/CD.

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **Users and Access** → **Keys** (under Integrations)
3. Click **Generate API Key** or **+ (Add)**
4. Configure the key:
   - **Name**: `GitHub Actions CI`
   - **Access**: `Admin` or `App Manager`
5. Click **Generate**
6. **Download the API Key** (`.p8` file) - **You can only download this once!**
7. Note the following values:
   - **Issuer ID** (UUID at top of page)
   - **Key ID** (10-character string)

**⚠️ IMPORTANT**: Save the `.p8` file securely. You cannot download it again!

### 3. Alternative: App-Specific Password Method

If you prefer not to use API keys:

1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in with your Apple ID
3. Navigate to **Security** → **App-Specific Passwords**
4. Click **Generate Password**
5. Name it: `GitHub Actions iOS Deploy`
6. Save the generated password securely

---

## Certificate and Provisioning Profile Setup

### Method 1: Using Xcode (Recommended for Beginners)

1. Open your project in Xcode:
   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. Select the **Runner** target
3. Go to **Signing & Capabilities** tab
4. Configure code signing:
   - **Team**: Select your development team
   - **Bundle Identifier**: `com.gudexpress.gud_app`
   - **Signing Certificate**: `iOS Distribution`
   - **Provisioning Profile**: Xcode will create automatically

5. Export certificate:
   - Open **Keychain Access** app
   - Navigate to **My Certificates**
   - Find your **iOS Distribution** certificate
   - Right-click → **Export**
   - Save as: `distribution_certificate.p12`
   - Set a **password** (you'll need this for GitHub Secrets)

6. Export provisioning profile:
   ```bash
   # Profiles are stored in:
   ~/Library/MobileDevice/Provisioning\ Profiles/
   
   # Find your App Store profile
   ls -l ~/Library/MobileDevice/Provisioning\ Profiles/
   
   # Copy the .mobileprovision file
   cp ~/Library/MobileDevice/Provisioning\ Profiles/YOUR_UUID.mobileprovision ~/Desktop/App_Store.mobileprovision
   ```

### Method 2: Manual Creation via Apple Developer Portal

#### Create Distribution Certificate

1. Generate Certificate Signing Request (CSR):
   ```bash
   # On your Mac, open Keychain Access
   # Keychain Access → Certificate Assistant → Request a Certificate from a Certificate Authority
   ```
   - **User Email Address**: Your email
   - **Common Name**: Your name or organization
   - **Request is**: Saved to disk
   - Click **Continue** and save `CertificateSigningRequest.certSigningRequest`

2. Create certificate in Apple Developer Portal:
   - Go to [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/certificates)
   - Click **+** to create new certificate
   - Select **iOS Distribution**
   - Upload your CSR file
   - Download the certificate (`.cer` file)

3. Install certificate:
   - Double-click the downloaded `.cer` file to install in Keychain
   - Export as `.p12` from Keychain Access (see Method 1 step 5)

#### Create App Store Provisioning Profile

1. Register App ID (if not done):
   - Go to [Identifiers](https://developer.apple.com/account/resources/identifiers)
   - Click **+** to add new
   - Select **App IDs** → **App**
   - **Description**: GUD Express
   - **Bundle ID**: Explicit: `com.gudexpress.gud_app`
   - **Capabilities**: Enable required capabilities (Push Notifications, etc.)

2. Create Provisioning Profile:
   - Go to [Profiles](https://developer.apple.com/account/resources/profiles)
   - Click **+** to create new
   - Select **App Store** under Distribution
   - **App ID**: Select `com.gudexpress.gud_app`
   - **Certificate**: Select your iOS Distribution certificate
   - **Profile Name**: `GUD Express App Store`
   - Download the `.mobileprovision` file

---

## GitHub Secrets Configuration

### 1. Encode Files to Base64

You need to convert your certificates and keys to base64 format:

```bash
# Certificate (required)
base64 -i distribution_certificate.p12 -o certificate.txt

# Provisioning Profile (required)
base64 -i App_Store.mobileprovision -o profile.txt

# App Store Connect API Key (required)
base64 -i AuthKey_XXXXXXXXXX.p8 -o api_key.txt
```

For Windows users (using PowerShell):
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("distribution_certificate.p12")) | Out-File certificate.txt
[Convert]::ToBase64String([IO.File]::ReadAllBytes("App_Store.mobileprovision")) | Out-File profile.txt
[Convert]::ToBase64String([IO.File]::ReadAllBytes("AuthKey_XXXXXXXXXX.p8")) | Out-File api_key.txt
```

### 2. Add Secrets to GitHub Repository

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secrets:

#### Required Secrets

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `IOS_CERTIFICATE_BASE64` | Distribution certificate (p12) encoded as base64 | Content of `certificate.txt` |
| `IOS_CERTIFICATE_PASSWORD` | Password used when exporting the p12 certificate | `MySecurePassword123` |
| `IOS_PROVISIONING_PROFILE_BASE64` | App Store provisioning profile encoded as base64 | Content of `profile.txt` |
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect API Key ID | `ABCDE12345` |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect Issuer ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `APP_STORE_CONNECT_API_KEY_BASE64` | App Store Connect API key (p8) encoded as base64 | Content of `api_key.txt` |
| `TEAM_ID` | Apple Developer Team ID | `ABCDE12345` |

#### Optional Secrets (Alternative Method)

| Secret Name | Description | When to Use |
|-------------|-------------|-------------|
| `APPLE_ID` | Your Apple ID email | If not using API key |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password | If not using API key |
| `ITC_TEAM_ID` | iTunes Connect Team ID | If member of multiple teams |
| `KEYCHAIN_PASSWORD` | Custom keychain password | Optional (defaults to `temppass`) |

### 3. Verify Secrets

After adding secrets, verify they're correctly formatted:
- Secrets should be plain text (base64 string or plain password)
- No extra spaces or newlines
- Base64 strings are typically very long (hundreds of characters)

---

## Workflow Usage

### Automatic Triggers

The workflow automatically runs on:

1. **Version Tags**: When you push a tag matching `v*`
   ```bash
   git tag v2.1.0
   git push origin v2.1.0
   ```

2. **Releases**: When you create or publish a GitHub release

### Manual Trigger

1. Go to your repository on GitHub
2. Click **Actions** tab
3. Select **Build iOS** workflow
4. Click **Run workflow**
5. Choose options:
   - **Branch**: Select branch to build from
   - **Upload to TestFlight**: Choose `true` or `false`
6. Click **Run workflow**

### Workflow Steps

The workflow performs the following:

1. ✅ Checkout code
2. ✅ Set up Flutter (stable channel)
3. ✅ Cache dependencies (Flutter & CocoaPods)
4. ✅ Install CocoaPods dependencies
5. ✅ Set up Ruby and Fastlane
6. ✅ Create temporary keychain
7. ✅ Import signing certificate
8. ✅ Install provisioning profile
9. ✅ Configure App Store Connect API
10. ✅ Build IPA with Flutter
11. ✅ Upload to TestFlight (if enabled)
12. ✅ Upload IPA as artifact
13. ✅ Clean up certificates and keychain

### Download Build Artifacts

1. Go to **Actions** tab
2. Click on the completed workflow run
3. Scroll to **Artifacts** section
4. Download **ios-ipa** artifact
5. Extract and find your `gud_app.ipa`

### TestFlight Distribution

After successful upload:

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **My Apps** → **GUD Express**
3. Click **TestFlight** tab
4. Your build will appear after processing (10-30 minutes)
5. Add internal/external testers
6. Submit for Beta App Review (for external testers)

---

## Alternative Upload Methods

### Method 1: Using Fastlane Locally

If you want to test locally:

```bash
# Install dependencies
cd ios
bundle install

# Build IPA
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

# Upload to TestFlight
cd ios
bundle exec fastlane upload_testflight
```

### Method 2: Using xcrun altool (Command Line)

Direct upload without Fastlane:

```bash
# Build IPA
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

# Upload to App Store Connect
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/gud_app.ipa \
  --apiKey YOUR_API_KEY_ID \
  --apiIssuer YOUR_ISSUER_ID
```

### Method 3: Using Transporter App

For manual upload with GUI:

1. Build IPA using Flutter:
   ```bash
   flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
   ```

2. Download [Transporter](https://apps.apple.com/us/app/transporter/id1450874784) from Mac App Store

3. Open Transporter and sign in with Apple ID

4. Drag and drop your `.ipa` file

5. Click **Deliver** to upload

### Method 4: Using Xcode Organizer

Traditional Xcode upload:

1. Build in Xcode:
   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. Select **Generic iOS Device** or **Any iOS Device**

3. **Product** → **Archive**

4. When archive completes, Xcode Organizer opens

5. Select your archive → **Distribute App**

6. Choose **App Store Connect** → **Upload**

7. Follow prompts to complete upload

---

## Troubleshooting

### Common Issues and Solutions

#### 1. Code Signing Errors

**Error**: `No signing certificate "iOS Distribution" found`

**Solution**:
- Verify certificate is correctly encoded in `IOS_CERTIFICATE_BASE64`
- Check certificate password in `IOS_CERTIFICATE_PASSWORD`
- Ensure certificate hasn't expired in Apple Developer Portal
- Verify certificate type is "iOS Distribution", not "Development"

**Verify certificate locally**:
```bash
# Decode and check certificate
echo "$IOS_CERTIFICATE_BASE64" | base64 --decode > test_cert.p12
security find-certificate -a -p -c "iPhone Distribution" | openssl x509 -text -noout
```

#### 2. Provisioning Profile Issues

**Error**: `No provisioning profile found`

**Solution**:
- Verify profile is correctly encoded in `IOS_PROVISIONING_PROFILE_BASE64`
- Check bundle ID matches: `com.gudexpress.gud_app`
- Ensure provisioning profile hasn't expired
- Verify provisioning profile includes your distribution certificate
- Make sure profile type is "App Store", not "Development" or "Ad Hoc"

**Verify profile locally**:
```bash
# Decode and inspect profile
echo "$IOS_PROVISIONING_PROFILE_BASE64" | base64 --decode > test.mobileprovision
security cms -D -i test.mobileprovision
```

#### 3. Upload to App Store Connect Fails

**Error**: `Upload failed` or `Authentication failed`

**Solutions**:

**For API Key method**:
- Verify `APP_STORE_CONNECT_API_KEY_ID` is correct (10-char string)
- Verify `APP_STORE_CONNECT_ISSUER_ID` is correct (UUID)
- Check API key base64 encoding is correct
- Ensure API key has "Admin" or "App Manager" role
- Verify the API key hasn't been revoked

**For Apple ID method**:
- Verify `APPLE_ID` is correct email address
- Check `APPLE_APP_SPECIFIC_PASSWORD` is correct
- Generate new app-specific password if needed
- Ensure 2FA is enabled on Apple ID

**Test API key locally**:
```bash
# Decode API key
echo "$APP_STORE_CONNECT_API_KEY_BASE64" | base64 --decode > AuthKey.p8

# Test with xcrun
xcrun altool --list-apps \
  --apiKey YOUR_API_KEY_ID \
  --apiIssuer YOUR_ISSUER_ID
```

#### 4. Build Fails During Compilation

**Error**: Build errors in Xcode or Flutter

**Solutions**:
- Run `flutter clean` and try again
- Delete `ios/Pods` and `Podfile.lock`, then run `pod install`
- Update CocoaPods: `cd ios && pod repo update`
- Check Flutter version compatibility: `flutter doctor`
- Verify `ios/Runner.xcworkspace` opens in Xcode without errors
- Check for breaking changes in dependencies

#### 5. Missing Entitlements

**Error**: `Missing required entitlements`

**Solution**:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** target → **Signing & Capabilities**
3. Add required capabilities (Push Notifications, etc.)
4. Commit changes to `Runner.entitlements`

#### 6. Bundle ID Mismatch

**Error**: `Bundle ID doesn't match provisioning profile`

**Solution**:
- Verify bundle ID in `ios/Runner.xcodeproj/project.pbxproj` is `com.gudexpress.gud_app`
- Check `ExportOptions.plist` has correct bundle ID
- Ensure provisioning profile was created for correct bundle ID

#### 7. Version/Build Number Issues

**Error**: `Build number already exists`

**Solution**:
- Increment build number in `pubspec.yaml` (e.g., `2.1.0+3`)
- Or use dynamic build numbers:
  ```bash
  flutter build ipa --build-number=${{ github.run_number }}
  ```

#### 8. Flutter Build Issues

**Error**: `Flutter command not found` or build fails

**Solutions**:
- Verify Flutter is properly set up: `flutter doctor -v`
- Clear Flutter cache: `flutter clean`
- Get dependencies: `flutter pub get`
- Check `pubspec.yaml` for dependency conflicts

#### 9. Keychain Issues

**Error**: `User interaction not allowed` or `Keychain locked`

**Solution**:
- Verify keychain setup in workflow is correct
- Check `KEYCHAIN_PASSWORD` secret if customized
- Ensure `security unlock-keychain` command runs before code signing

#### 10. Pod Install Fails

**Error**: CocoaPods installation fails

**Solutions**:
```bash
# Update CocoaPods
cd ios
rm -rf Pods Podfile.lock
pod repo update
pod install --repo-update

# If still fails, try
pod deintegrate
pod install
```

### Debugging Tips

#### Enable Verbose Logging

Add to workflow:
```yaml
- name: Build IPA (verbose)
  run: |
    flutter build ipa --release \
      --export-options-plist=ios/ExportOptions.plist \
      --verbose
```

#### Check Certificate Validity

```bash
# Check certificate expiry
security find-identity -v -p codesigning
openssl pkcs12 -in certificate.p12 -noout -info
```

#### Inspect Provisioning Profile

```bash
# Decode and view profile details
security cms -D -i profile.mobileprovision
```

#### Test Build Locally

Before using CI/CD, test locally:
```bash
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

### Get Help

If you're still stuck:

1. **Check GitHub Actions logs**: Detailed error messages in the failed step
2. **Apple Developer Forums**: [developer.apple.com/forums](https://developer.apple.com/forums)
3. **Flutter Discord**: [discord.gg/flutter](https://discord.gg/flutter)
4. **Stack Overflow**: Tag with `flutter`, `ios`, `github-actions`

---

## Advanced Configuration

### Using Fastlane Match

For better certificate management across teams:

1. Install Fastlane Match:
   ```bash
   cd ios
   bundle exec fastlane match init
   ```

2. Choose storage (git, S3, Google Cloud)

3. Generate certificates:
   ```bash
   bundle exec fastlane match appstore
   ```

4. Update workflow to use Match

### Custom Build Variants

For different environments (dev, staging, prod):

1. Create schemes in Xcode
2. Create multiple `ExportOptions.plist` files
3. Update workflow to build different variants

### Screenshot Automation

Generate screenshots automatically:

1. Set up Snapshot (part of Fastlane)
2. Create UI tests for screenshots
3. Run in workflow:
   ```bash
   cd ios
   bundle exec fastlane screenshots
   ```

### Slack/Discord Notifications

Add to workflow:
```yaml
- name: Notify Slack
  if: success()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: '✅ iOS build successful!'
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### Build Number from Git

Auto-increment build number:
```yaml
- name: Set build number
  run: |
    BUILD_NUMBER=${{ github.run_number }}
    flutter build ipa --build-number=$BUILD_NUMBER
```

### Parallel Jobs

Split build and upload into separate jobs:
```yaml
jobs:
  build:
    # Build IPA
  
  upload:
    needs: build
    # Upload to TestFlight
```

### Cache Optimization

Improve build speed with better caching:
```yaml
- name: Cache Flutter
  uses: actions/cache@v4
  with:
    path: |
      ~/.pub-cache
      ${{ runner.tool_cache }}/flutter
    key: flutter-${{ runner.os }}-${{ hashFiles('pubspec.lock') }}
```

### Metadata Management

Automate App Store metadata updates:

1. Initialize metadata:
   ```bash
   cd ios
   bundle exec fastlane deliver init
   ```

2. Edit metadata files in `ios/fastlane/metadata/`

3. Update workflow to deploy metadata:
   ```bash
   bundle exec fastlane metadata
   ```

---

## Security Best Practices

### Certificate Security
- ✅ **NEVER** commit certificates or provisioning profiles to git
- ✅ Always use GitHub Secrets for sensitive data
- ✅ Use base64 encoding for binary files
- ✅ Create temporary keychain for builds
- ✅ Clean up certificates after each build
- ✅ Rotate certificates before expiry
- ✅ Use App Store Connect API keys instead of Apple ID passwords

### Access Control
- ✅ Limit who has access to GitHub Secrets
- ✅ Use separate API keys for different environments
- ✅ Regularly audit API key usage in App Store Connect
- ✅ Revoke old API keys when no longer needed

### Workflow Security
- ✅ Use specific action versions (not `@latest`)
- ✅ Restrict workflow permissions to minimum required
- ✅ Review workflow logs for sensitive data leaks
- ✅ Use environment-specific secrets for different stages

---

## Version Management

### Automatic Version Updates

Current version in `pubspec.yaml`:
```yaml
version: 2.1.0+2
```

### Update Version for Release

```bash
# Update version in pubspec.yaml
# Format: MAJOR.MINOR.PATCH+BUILD_NUMBER
# Example: 2.2.0+3

# Commit and tag
git add pubspec.yaml
git commit -m "Bump version to 2.2.0"
git tag v2.2.0
git push origin main --tags
```

### Build Number Strategy

**Option 1**: Manual increment in `pubspec.yaml`
```yaml
version: 2.1.0+3  # Increment last number
```

**Option 2**: Use CI run number (add to workflow)
```yaml
- name: Update build number
  run: |
    VERSION=$(grep 'version:' pubspec.yaml | cut -d' ' -f2 | cut -d'+' -f1)
    BUILD_NUMBER=${{ github.run_number }}
    sed -i '' "s/version: .*/version: $VERSION+$BUILD_NUMBER/" pubspec.yaml
```

**Option 3**: Use timestamp
```bash
BUILD_NUMBER=$(date +%s)
flutter build ipa --build-number=$BUILD_NUMBER
```

---

## Checklist Before First Build

- [ ] Apple Developer Account is active
- [ ] App created in App Store Connect
- [ ] Bundle ID matches: `com.gudexpress.gud_app`
- [ ] Distribution certificate created and exported
- [ ] App Store provisioning profile created and downloaded
- [ ] App Store Connect API key created and downloaded
- [ ] All files encoded to base64
- [ ] All secrets added to GitHub repository
- [ ] ExportOptions.plist updated with correct Team ID
- [ ] Workflow file is in `.github/workflows/build-ios.yml`
- [ ] Fastlane files created in `ios/fastlane/`
- [ ] Gemfile created in `ios/`
- [ ] Local test build successful
- [ ] Git repository is up to date

---

## Next Steps After Successful Build

1. **TestFlight Testing**
   - Add internal testers
   - Run beta testing phase
   - Collect feedback

2. **App Store Submission**
   - Complete App Store listing
   - Add screenshots and descriptions
   - Set pricing and availability
   - Submit for review

3. **Monitoring**
   - Set up crash reporting (Firebase Crashlytics)
   - Monitor build logs in GitHub Actions
   - Track TestFlight feedback

4. **Continuous Improvement**
   - Automate changelog generation
   - Add automated tests before build
   - Set up staging/production environments
   - Implement feature flags

---

## Additional Resources

### Documentation
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Fastlane Documentation](https://docs.fastlane.tools/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

### Tools
- [Transporter App](https://apps.apple.com/us/app/transporter/id1450874784)
- [Apple Configurator](https://apps.apple.com/app/apple-configurator-2/id1037126344)
- [RocketSim](https://www.rocketsim.app/) - iOS Simulator enhancer

### Tutorials
- [Code Signing Explained](https://codesigning.guide/)
- [Fastlane Getting Started](https://docs.fastlane.tools/getting-started/ios/setup/)
- [App Store Guidelines](https://developer.apple.com/app-store/review/guidelines/)

---

## Support

For issues specific to this workflow:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review GitHub Actions workflow logs
3. Verify all secrets are correctly configured
4. Test build locally before using CI/CD

For Apple-specific issues:
- [Apple Developer Support](https://developer.apple.com/support/)
- [App Store Connect Support](https://developer.apple.com/contact/app-store/)

---

**Last Updated**: 2024
**Workflow Version**: 1.0
**Maintained by**: GUD Express Team
