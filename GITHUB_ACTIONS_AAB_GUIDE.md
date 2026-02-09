# GitHub Actions AAB Build Guide for GUD Express

This guide provides comprehensive instructions for setting up and using the GitHub Actions workflow to automatically build Android App Bundles (AAB) for the GUD Express Flutter app with secure signing.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Keystore Setup](#keystore-setup)
4. [GitHub Secrets Configuration](#github-secrets-configuration)
5. [Workflow Usage](#workflow-usage)
6. [Downloading Artifacts](#downloading-artifacts)
7. [Google Play Console Upload](#google-play-console-upload)
8. [Troubleshooting](#troubleshooting)
9. [Security Best Practices](#security-best-practices)
10. [Advanced Configuration](#advanced-configuration)

---

## 🎯 Overview

The GitHub Actions workflow (`.github/workflows/build-aab.yml`) automates the process of building signed Android App Bundles for the GUD Express app. It includes:

- **Automated Builds**: Triggered on tags, releases, or manually
- **Secure Signing**: Using encrypted GitHub Secrets
- **Artifact Upload**: Automatic upload of AAB and mapping files
- **Release Integration**: Automatic attachment to GitHub releases
- **Caching**: Optimized build times with dependency caching

### Workflow Triggers

The workflow can be triggered in multiple ways:

1. **Manual Trigger**: Via GitHub Actions tab (workflow_dispatch)
2. **Version Tags**: Push tags matching `v*` pattern (e.g., `v2.1.0`)
3. **Release Creation**: When a GitHub release is created or published
4. **Scheduled**: Weekly builds every Monday at 2 AM UTC (optional)

---

## ✅ Prerequisites

Before setting up the workflow, ensure you have:

- **Repository Access**: Admin or write access to the GitHub repository
- **Java Development Kit (JDK)**: Version 17 (for local builds)
- **Android Studio**: For generating keystores (or use command line)
- **Flutter SDK**: Version 3.0.0+ (for local builds)

---

## 🔐 Keystore Setup

A keystore is required to sign your Android app for release. **Keep this secure** - losing it means you cannot update your app on Google Play!

### Step 1: Generate a New Keystore (If You Don't Have One)

```bash
# Navigate to your android/app directory
cd android/app

# Generate a new keystore
keytool -genkey -v -keystore gud_keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias gud_key

# You will be prompted for:
# - Keystore password (save this!)
# - Key password (save this!)
# - Your name and organizational details
```

**Important Notes:**
- Store the keystore file in a secure location (NOT in git)
- Save the passwords in a secure password manager
- The validity period is 10,000 days (~27 years)

### Step 2: Verify Your Keystore

```bash
# List keystore information
keytool -list -v -keystore gud_keystore.jks -alias gud_key

# Check keystore validity
keytool -list -keystore gud_keystore.jks
```

### Step 3: Encode Keystore to Base64

The workflow requires the keystore as a base64-encoded string:

```bash
# Encode the keystore to base64
base64 android/app/gud_keystore.jks > keystore_base64.txt

# On macOS, use:
base64 -i android/app/gud_keystore.jks -o keystore_base64.txt

# On Windows (PowerShell), use:
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\app\gud_keystore.jks")) | Out-File keystore_base64.txt
```

The `keystore_base64.txt` file will contain a long string of characters - this is what you'll add to GitHub Secrets.

**Important**: Delete this file after adding to GitHub Secrets:
```bash
rm keystore_base64.txt
```

---

## 🔑 GitHub Secrets Configuration

GitHub Secrets securely store sensitive information like your keystore and passwords.

### Step 1: Navigate to Repository Settings

1. Go to your GitHub repository: https://github.com/dukens11-create/gud
2. Click **Settings** (top navigation)
3. In the left sidebar, click **Secrets and variables** → **Actions**

### Step 2: Add Required Secrets

Click **New repository secret** for each of the following:

#### 1. KEYSTORE_BASE64
- **Name**: `KEYSTORE_BASE64`
- **Value**: Paste the entire contents of `keystore_base64.txt`
- **Description**: Base64-encoded keystore file

#### 2. KEYSTORE_PASSWORD
- **Name**: `KEYSTORE_PASSWORD`
- **Value**: The keystore password you set when generating the keystore
- **Description**: Password for the keystore file

#### 3. KEY_PASSWORD
- **Name**: `KEY_PASSWORD`
- **Value**: The key password you set when generating the keystore
- **Description**: Password for the signing key

#### 4. KEY_ALIAS
- **Name**: `KEY_ALIAS`
- **Value**: `gud_key` (or whatever alias you used when generating the keystore)
- **Description**: Alias name for the signing key

### Step 3: Verify Secrets

After adding all secrets, you should see:
- ✅ KEYSTORE_BASE64
- ✅ KEYSTORE_PASSWORD
- ✅ KEY_PASSWORD
- ✅ KEY_ALIAS

**Security Note**: Secrets are encrypted and never exposed in logs.

---

## 🚀 Workflow Usage

### Manual Trigger (Recommended for Testing)

1. Go to the **Actions** tab in your GitHub repository
2. Select **Build Android App Bundle (AAB)** from the left sidebar
3. Click **Run workflow** (top right)
4. Select the branch (usually `main`)
5. Configure options:
   - **Build type**: `release` (default) or `debug`
   - **Run tests**: `true` (default) or `false`
6. Click **Run workflow**

### Automatic Trigger via Tags

To automatically build when you create a version tag:

```bash
# Create and push a version tag
git tag v2.1.0
git push origin v2.1.0

# The workflow will automatically start
```

### Automatic Trigger via Release

1. Go to **Releases** in your GitHub repository
2. Click **Draft a new release**
3. Choose or create a tag (e.g., `v2.1.0`)
4. Fill in release details
5. Click **Publish release**
6. The workflow will automatically start and attach the AAB to the release

---

## 📥 Downloading Artifacts

After the workflow completes successfully:

### From Actions Tab

1. Go to **Actions** tab in your repository
2. Click on the completed workflow run
3. Scroll to **Artifacts** section at the bottom
4. Download:
   - `gud-express-aab-{run_number}-v{version}` - The AAB file
   - `gud-express-mapping-{run_number}-v{version}` - ProGuard mapping file (if available)

### From Releases (for tagged builds)

1. Go to **Releases** tab in your repository
2. Find the release you created
3. Download files from **Assets** section:
   - `app-release.aab` - Android App Bundle
   - `mapping.txt` - ProGuard mapping file

**Retention**: Artifacts are kept for 30 days (AAB) and 90 days (mapping files).

---

## 📤 Google Play Console Upload

Once you have downloaded the AAB file, follow these steps to upload it to Google Play Console:

### Step 1: Access Google Play Console

1. Go to https://play.google.com/console
2. Sign in with your Google account
3. Select your app (GUD Express)

### Step 2: Create a New Release

1. Navigate to **Production** (or **Testing** for internal/closed testing)
2. Click **Create new release**
3. Click **Upload** and select your `app-release.aab` file

### Step 3: Upload ProGuard Mapping File

1. After uploading the AAB, click **Upload ProGuard mapping file**
2. Select the `mapping.txt` file downloaded from GitHub Actions
3. This file is essential for crash report deobfuscation

### Step 4: Complete Release Details

1. Add **Release notes** (what's new in this version)
2. Review the release
3. Click **Save** and then **Review release**
4. Click **Start rollout to Production**

### Step 5: Monitor Release

- The review typically takes 1-3 days
- You'll receive an email when the app is published
- Monitor crash reports in Play Console

---

## 🔧 Troubleshooting

### Common Issues and Solutions

#### Issue 1: Keystore Decoding Fails

**Error**: `Error decoding keystore` or `Invalid base64`

**Solution**:
- Ensure the base64 encoding was done correctly
- Check that the entire base64 string was copied to GitHub Secrets
- Try re-encoding the keystore:
  ```bash
  base64 android/app/gud_keystore.jks | tr -d '\n' > keystore_base64.txt
  ```

#### Issue 2: Signing Configuration Not Found

**Error**: `Keystore file not found` or `key.properties not set`

**Solution**:
- Verify all four secrets are set correctly in GitHub
- Check the secret names match exactly (case-sensitive)
- Ensure KEYSTORE_BASE64 contains the encoded keystore

#### Issue 3: Build Fails with Gradle Error

**Error**: `Execution failed for task ':app:signReleaseBundle'`

**Solution**:
- Verify keystore password is correct
- Check that KEY_ALIAS matches the alias in your keystore
- Ensure the keystore is valid and not corrupted

#### Issue 4: AAB File Not Found

**Error**: `AAB file not found after build`

**Solution**:
- Check Flutter version compatibility (use 3.24.0 as specified)
- Ensure `flutter build appbundle` command succeeded
- Review build logs for any errors

#### Issue 5: Mapping File Missing

**Warning**: `Mapping file not generated`

**Solution**:
- This is normal if ProGuard/R8 optimization is disabled
- The mapping file is only generated when `minifyEnabled true`
- Check `android/app/build.gradle` release configuration

#### Issue 6: Tests Failing

**Error**: `flutter test` fails during workflow

**Solution**:
- Set `run_tests: false` when manually triggering the workflow
- Fix test failures in your codebase
- Tests failures are set to `continue-on-error: true` by default

#### Issue 7: Insufficient Permissions

**Error**: `Resource not accessible by integration`

**Solution**:
- Check repository permissions in Settings → Actions → General
- Ensure workflow has `contents: write` permission
- Verify you have admin access to the repository

### Viewing Logs

To view detailed logs:
1. Go to **Actions** tab
2. Click on the failed workflow run
3. Click on the job that failed
4. Expand each step to see detailed logs

---

## 🛡️ Security Best Practices

### Do's ✅

1. **Always Use GitHub Secrets**: Never commit sensitive information to git
2. **Rotate Secrets Regularly**: Update secrets periodically
3. **Limit Access**: Only give repository access to trusted team members
4. **Use Branch Protection**: Require reviews for changes to main branch
5. **Monitor Workflow Runs**: Regularly check for unauthorized workflow runs
6. **Keep Keystore Backup**: Store keystore in a secure offline location
7. **Use Strong Passwords**: Use complex passwords for keystore and keys

### Don'ts ❌

1. **Never Commit Keystore**: Keep `*.jks`, `*.keystore` in `.gitignore`
2. **Never Share Secrets**: Don't share keystore passwords via email/chat
3. **Never Use Debug Signing**: Always use release signing for production
4. **Never Skip Testing**: Run tests before deploying to production
5. **Don't Ignore Warnings**: Address security warnings in build logs

### .gitignore Configuration

Ensure your `.gitignore` includes:
```gitignore
# Android keystore files
*.jks
*.keystore
key.properties
keystore.properties
keystore_base64.txt

# Build outputs
build/
*.aab
*.apk
```

---

## ⚙️ Advanced Configuration

### Customizing Build Numbers

The workflow uses GitHub run number as the build number. To customize:

```yaml
flutter build appbundle --release \
  --build-number=${{ github.run_number }} \
  --build-name=${{ steps.version.outputs.version_name }}
```

### Adding Notification Integrations

#### Slack Notifications

Add this step to the workflow:

```yaml
- name: Notify Slack
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK_URL }}
```

#### Discord Notifications

Add this step to the workflow:

```yaml
- name: Notify Discord
  if: always()
  uses: sarisia/actions-status-discord@v1
  with:
    webhook: ${{ secrets.DISCORD_WEBHOOK }}
```

### Building APK Alongside AAB

To also build APK for testing, add this step:

```yaml
- name: Build Android APK (Optional)
  run: flutter build apk --release --split-per-abi

- name: Upload APK artifacts
  uses: actions/upload-artifact@v4
  with:
    name: gud-express-apk-${{ github.run_number }}
    path: build/app/outputs/flutter-apk/*.apk
    retention-days: 30
```

### Parallel Job Execution

For faster builds, you can run tests and builds in parallel:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      # Test steps

  build-aab:
    needs: test
    runs-on: ubuntu-latest
    steps:
      # Build steps
```

### Environment-Specific Builds

To build for different environments (dev, staging, production):

```yaml
- name: Build AAB for Environment
  run: |
    flutter build appbundle --release \
      --flavor ${{ github.event.inputs.environment }} \
      --dart-define=ENV=${{ github.event.inputs.environment }}
```

---

## 📊 Monitoring and Maintenance

### Build Status Badge

Add this badge to your README.md to show build status:

```markdown
[![Build AAB](https://github.com/dukens11-create/gud/actions/workflows/build-aab.yml/badge.svg)](https://github.com/dukens11-create/gud/actions/workflows/build-aab.yml)
```

### Regular Maintenance Tasks

1. **Update Flutter Version**: Every 3-6 months
   - Update `flutter-version` in the workflow
   - Test locally before updating

2. **Rotate Secrets**: Annually
   - Generate new keystore for major version changes
   - Update GitHub Secrets

3. **Review Dependencies**: Monthly
   - Run `flutter pub outdated`
   - Update dependencies in `pubspec.yaml`

4. **Clean Up Old Artifacts**: Quarterly
   - Delete old workflow runs and artifacts
   - Keep only necessary builds

---

## 📚 Additional Resources

### Official Documentation
- [Flutter Build Modes](https://flutter.dev/docs/testing/build-modes)
- [Android App Bundle](https://developer.android.com/guide/app-bundle)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Google Play Console](https://play.google.com/console)

### Related Files
- `.github/workflows/build-aab.yml` - Main workflow file
- `android/app/build.gradle` - Android build configuration
- `pubspec.yaml` - Flutter project configuration
- `AAB_BUILD_GUIDE.md` - Local AAB build guide

---

## 🆘 Getting Help

If you encounter issues not covered in this guide:

1. **Check Workflow Logs**: Detailed error messages in Actions tab
2. **Review GitHub Issues**: Search for similar issues in the repository
3. **Contact Team**: Reach out to the development team
4. **Open an Issue**: Create a new issue with detailed information

---

## 📝 Version History

- **v2.1.0** - Initial GitHub Actions AAB workflow setup
- Added comprehensive documentation
- Implemented secure signing with GitHub Secrets
- Added artifact upload and release integration

---

**Last Updated**: February 2026

**Maintained By**: GUD Express Development Team
