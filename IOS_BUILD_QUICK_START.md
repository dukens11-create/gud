# iOS Build Workflow - Quick Start

This is a quick reference for using the iOS CI/CD workflow. For complete setup instructions, see [IOS_BUILD_AND_DEPLOY_GUIDE.md](IOS_BUILD_AND_DEPLOY_GUIDE.md).

## Prerequisites

Before using the workflow, you must have:

1. ✅ Apple Developer Account (active)
2. ✅ App created in App Store Connect
3. ✅ All GitHub Secrets configured (see below)
4. ✅ Certificates and provisioning profiles set up

## Required GitHub Secrets

Add these secrets in: **Settings → Secrets and variables → Actions**

| Secret Name | Description |
|-------------|-------------|
| `IOS_CERTIFICATE_BASE64` | Distribution certificate (p12) in base64 |
| `IOS_CERTIFICATE_PASSWORD` | Certificate password |
| `IOS_PROVISIONING_PROFILE_BASE64` | App Store provisioning profile in base64 |
| `APP_STORE_CONNECT_API_KEY_ID` | API Key ID (10 chars) |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID (UUID) |
| `APP_STORE_CONNECT_API_KEY_BASE64` | API key (.p8) in base64 |
| `TEAM_ID` | Apple Developer Team ID |

### Optional Secrets

| Secret Name | Description | When Needed |
|-------------|-------------|-------------|
| `APPLE_ID` | Apple ID email | Alternative to API key |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password | Alternative to API key |
| `ITC_TEAM_ID` | iTunes Connect Team ID | Multiple teams |

## How to Trigger the Workflow

### Method 1: Manual Trigger (Recommended for Testing)

1. Go to your repository on GitHub
2. Click **Actions** tab
3. Select **Build iOS** workflow
4. Click **Run workflow** button
5. Choose options:
   - Branch: `main` (or your branch)
   - Upload to TestFlight: `false` (for testing) or `true` (for release)
6. Click **Run workflow**

### Method 2: Tag Push (Automatic Release)

```bash
# Create and push a version tag
git tag v2.1.0
git push origin v2.1.0
```

The workflow will automatically:
- Build the IPA
- Upload to TestFlight (if configured)
- Create downloadable artifacts

### Method 3: GitHub Release

1. Go to **Releases** in your repository
2. Click **Draft a new release**
3. Create a tag: `v2.1.0`
4. Add release notes
5. Click **Publish release**

The workflow triggers automatically on release creation.

## Monitoring the Build

1. Go to **Actions** tab in your repository
2. Click on the running workflow
3. Watch the progress in real-time
4. Expand each step to see detailed logs

### Expected Build Time

- ⏱️ Total time: 15-25 minutes
- Flutter setup: 2-3 minutes
- CocoaPods install: 3-5 minutes
- IPA build: 8-12 minutes
- Upload to TestFlight: 2-3 minutes

## Download Build Artifacts

After successful build:

1. Go to the completed workflow run
2. Scroll to **Artifacts** section at the bottom
3. Click **ios-ipa** to download
4. Extract the ZIP file to get your `gud_app.ipa`

## TestFlight Distribution

After upload to TestFlight:

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select **My Apps** → **GUD Express**
3. Click **TestFlight** tab
4. Wait for processing (10-30 minutes)
5. Add testers when ready
6. Distribute to testers

## Common Commands

### Encode files to Base64

```bash
# Certificate
base64 -i distribution_certificate.p12 -o certificate.txt

# Provisioning Profile
base64 -i App_Store.mobileprovision -o profile.txt

# API Key
base64 -i AuthKey_XXXXXXXXXX.p8 -o api_key.txt
```

### Test Build Locally

```bash
# Before using CI/CD, test locally
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

### Update Version

```bash
# Edit pubspec.yaml
# Change: version: 2.1.0+2
# To: version: 2.2.0+3

# Commit and tag
git add pubspec.yaml
git commit -m "Bump version to 2.2.0"
git tag v2.2.0
git push origin main --tags
```

## Troubleshooting Quick Fixes

### Build Fails: Certificate Error
- ✅ Verify `IOS_CERTIFICATE_BASE64` is correct
- ✅ Check `IOS_CERTIFICATE_PASSWORD` matches
- ✅ Ensure certificate hasn't expired

### Build Fails: Provisioning Profile Error
- ✅ Verify `IOS_PROVISIONING_PROFILE_BASE64` is correct
- ✅ Check bundle ID matches: `com.gudexpress.gud_app`
- ✅ Ensure profile hasn't expired

### Upload Fails: Authentication Error
- ✅ Verify API Key ID and Issuer ID are correct
- ✅ Check API key base64 encoding
- ✅ Ensure API key has proper permissions

### Build Fails: Pod Install
```bash
# Run locally to debug
cd ios
pod repo update
pod install
```

## Next Steps

1. **First Build**: Run manually with TestFlight upload disabled
2. **Verify**: Download artifact and test IPA locally
3. **TestFlight**: Run with TestFlight upload enabled
4. **Automate**: Create tags for automatic builds

## Getting Help

- **Complete Guide**: [IOS_BUILD_AND_DEPLOY_GUIDE.md](IOS_BUILD_AND_DEPLOY_GUIDE.md)
- **Troubleshooting**: See the comprehensive guide
- **GitHub Actions Logs**: Check detailed logs in Actions tab

## Workflow Files

- **Workflow**: `.github/workflows/build-ios.yml`
- **Fastfile**: `ios/fastlane/Fastfile`
- **Appfile**: `ios/fastlane/Appfile`
- **Gemfile**: `ios/Gemfile`
- **Export Options**: `ios/ExportOptions.plist`

## Version Info

- **App Version**: 2.1.0+2 (from `pubspec.yaml`)
- **Bundle ID**: `com.gudexpress.gud_app`
- **App Name**: GUD Express
- **Platform**: iOS 12.0+

---

**Quick Start Complete!** For detailed setup, see [IOS_BUILD_AND_DEPLOY_GUIDE.md](IOS_BUILD_AND_DEPLOY_GUIDE.md)
