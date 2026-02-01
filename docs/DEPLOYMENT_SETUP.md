# GUD Express - Deployment Setup Guide

This guide provides step-by-step instructions for setting up automated CI/CD pipelines for the GUD Express Flutter application.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Firebase App Distribution Setup](#firebase-app-distribution-setup)
3. [GitHub Secrets Configuration](#github-secrets-configuration)
4. [Creating and Pushing Version Tags](#creating-and-pushing-version-tags)
5. [Manual Deployment Commands](#manual-deployment-commands)
6. [Workflow Overview](#workflow-overview)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before setting up the deployment pipelines, ensure you have:

- ✅ A Firebase project configured for GUD Express
- ✅ Android app registered in Firebase Console
- ✅ `google-services.json` file in `android/app/` directory
- ✅ GitHub repository with admin access
- ✅ Firebase CLI installed locally (for manual deployments)

---

## Firebase App Distribution Setup

### Step 1: Enable Firebase App Distribution

1. Go to the [Firebase Console](https://console.firebase.google.com)
2. Select your GUD Express project
3. In the left sidebar, click **App Distribution** (under Release & Monitor)
4. If prompted, click **Get Started** to enable the service

### Step 2: Get Your Firebase App ID

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Scroll down to **Your apps** section
3. Find your Android app
4. Copy the **App ID** (format: `1:123456789:android:abc123def456...`)
5. Save this - you'll need it for GitHub Secrets

### Step 3: Create a Service Account

1. In Firebase Console, go to **Project Settings** → **Service Accounts**
2. Click **Generate New Private Key**
3. In the dialog that appears, click **Generate Key**
4. A JSON file will be downloaded - **keep this secure!**
5. This file contains your service account credentials

> ⚠️ **Security Warning:** The service account JSON file contains sensitive credentials. Never commit it to your repository or share it publicly.

---

## GitHub Secrets Configuration

GitHub Secrets allow you to securely store sensitive information that your workflows can access.

### Step 1: Access Repository Secrets

1. Go to your GitHub repository: `https://github.com/dukens11-create/gud`
2. Click **Settings** (top menu)
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**

### Step 2: Add FIREBASE_APP_ID Secret

1. Click **New repository secret**
2. Name: `FIREBASE_APP_ID`
3. Secret: Paste your Firebase Android App ID from earlier
4. Click **Add secret**

**Example format:**
```
1:123456789012:android:abc123def456ghi789
```

### Step 3: Add FIREBASE_SERVICE_ACCOUNT Secret

1. Click **New repository secret**
2. Name: `FIREBASE_SERVICE_ACCOUNT`
3. Secret: Paste the **entire contents** of the service account JSON file
4. Click **Add secret**

**The JSON should look like:**
```json
{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@your-project-id.iam.gserviceaccount.com",
  "client_id": "...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "..."
}
```

### Step 4: Verify Secrets

After adding both secrets, you should see them listed:
- ✅ `FIREBASE_APP_ID`
- ✅ `FIREBASE_SERVICE_ACCOUNT`

![GitHub Secrets Screenshot](https://user-images.githubusercontent.com/placeholder-secrets-list.png)

---

## Creating and Pushing Version Tags

Version tags trigger the Firebase deployment workflow automatically.

### Semantic Versioning

Follow [Semantic Versioning](https://semver.org/) for your releases:
- **MAJOR** version: Incompatible API changes
- **MINOR** version: New functionality (backward compatible)
- **PATCH** version: Bug fixes (backward compatible)

Format: `vMAJOR.MINOR.PATCH` (e.g., `v1.0.0`, `v1.2.3`)

### Creating a Version Tag

#### Method 1: Command Line

```bash
# Navigate to your repository
cd /path/to/gud

# Ensure you're on the main branch and up to date
git checkout main
git pull origin main

# Update version in pubspec.yaml
# Edit: version: 1.0.0+1 -> version: 1.1.0+2

# Commit version bump
git add pubspec.yaml
git commit -m "Bump version to 1.1.0"

# Create and push tag
git tag v1.1.0
git push origin main
git push origin v1.1.0
```

#### Method 2: GitHub Web Interface

1. Go to your repository on GitHub
2. Click **Releases** (right sidebar)
3. Click **Draft a new release**
4. Click **Choose a tag**
5. Type your version tag (e.g., `v1.1.0`)
6. Click **Create new tag: v1.1.0 on publish**
7. Fill in:
   - Release title: `GUD Express v1.1.0`
   - Description: Release notes and changes
8. Click **Publish release**

This will automatically trigger the Firebase deployment workflow!

### Viewing Deployment Status

1. Go to **Actions** tab in your GitHub repository
2. Look for the workflow run with your tag name
3. Click on it to see real-time logs
4. Wait for the green checkmark ✅

---

## Manual Deployment Commands

For local testing or manual deployments without using GitHub Actions.

### Prerequisites for Manual Deployment

Install Firebase CLI:
```bash
npm install -g firebase-tools
firebase login
```

### Build and Deploy Manually

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# Deploy to Firebase App Distribution
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_FIREBASE_APP_ID \
  --groups testers \
  --release-notes "Manual deployment - Testing new features"
```

### Build App Bundle (for Play Store)

```bash
# Build release App Bundle
flutter build appbundle --release

# Output location: build/app/outputs/bundle/release/app-release.aab
```

### Quick Test Build

```bash
# Run all checks before deployment
flutter analyze
flutter test
flutter build apk --release --dry-run
```

---

## Workflow Overview

### Android Build Workflow (`.github/workflows/android-build.yml`)

**Triggers:**
- ✅ Push to `main` branch
- ✅ Pull requests to `main`
- ✅ Manual dispatch

**Actions Performed:**
1. Checks out code
2. Sets up Java 17 and Flutter 3.24.0
3. Runs `flutter analyze` (static code analysis)
4. Runs `flutter test` (unit tests)
5. Builds release APK
6. Builds release App Bundle (AAB)
7. Uploads both as artifacts (30-day retention)

**Artifacts Location:**
- Go to **Actions** → Select a workflow run → Scroll to **Artifacts**
- Download `android-apk` or `android-aab`

### Firebase Deploy Workflow (`.github/workflows/firebase-deploy.yml`)

**Triggers:**
- ✅ Version tags matching `v*` (e.g., `v1.0.0`, `v2.1.3`)
- ✅ Manual dispatch

**Actions Performed:**
1. Checks out code
2. Sets up Java 17 and Flutter 3.24.0
3. Gets dependencies
4. Builds release APK
5. Extracts version from tag
6. Deploys to Firebase App Distribution
7. Notifies tester group

**Viewing Deployed Builds:**
1. Go to Firebase Console → App Distribution
2. See your deployed versions
3. Share with testers via groups or individual emails

---

## Troubleshooting

### Common Issues and Solutions

#### 1. **Workflow fails with "Secret not found"**

**Error:**
```
Error: Input required and not supplied: appId
```

**Solution:**
- Verify secrets are added in GitHub Settings → Secrets and variables → Actions
- Check secret names match exactly: `FIREBASE_APP_ID` and `FIREBASE_SERVICE_ACCOUNT`
- Ensure you have admin access to the repository

#### 2. **Build fails with "Java version mismatch"**

**Error:**
```
Could not determine the class-path for class com.android.build.gradle.AppPlugin
```

**Solution:**
- The workflow uses Java 17, which is compatible with Flutter 3.24.0
- Check your local `android/build.gradle` doesn't force a different Java version
- Ensure Android Gradle Plugin is up to date

#### 3. **Flutter tests fail**

**Error:**
```
Test failed. See above for more information.
```

**Solution:**
- Run tests locally first: `flutter test`
- Fix any failing tests before pushing
- If tests are flaky, consider adding retries or skipping in CI temporarily

#### 4. **APK not uploaded to Firebase**

**Error:**
```
Error: Failed to upload APK to Firebase App Distribution
```

**Solutions:**
- Verify `FIREBASE_APP_ID` is correct and matches your Android app in Firebase
- Check service account has **Firebase App Distribution Admin** role
- Ensure App Distribution is enabled in Firebase Console
- Verify the APK was built successfully in previous steps

#### 5. **Tag already exists**

**Error:**
```
fatal: tag 'v1.0.0' already exists
```

**Solution:**
```bash
# Delete local tag
git tag -d v1.0.0

# Delete remote tag
git push origin :refs/tags/v1.0.0

# Create new tag
git tag v1.0.1
git push origin v1.0.1
```

#### 6. **Firebase CLI authentication issues (manual deployment)**

**Error:**
```
Error: Authentication error
```

**Solution:**
```bash
# Log out and log back in
firebase logout
firebase login

# If behind a corporate firewall
firebase login --no-localhost
```

#### 7. **Gradle build fails**

**Error:**
```
Execution failed for task ':app:processReleaseResources'
```

**Solution:**
- Ensure `google-services.json` is present in `android/app/`
- Run `flutter clean && flutter pub get`
- Check `android/app/build.gradle` is correctly configured

#### 8. **Workflow doesn't trigger on tag push**

**Issue:**
Tag pushed but workflow doesn't start

**Solution:**
- Ensure tag format matches pattern `v*` (e.g., `v1.0.0`)
- Check workflow file is on the main branch
- Verify workflows are enabled in repository settings
- Wait a minute - sometimes there's a slight delay

---

## Additional Resources

### Documentation
- [Flutter Deployment Documentation](https://docs.flutter.dev/deployment/android)
- [Firebase App Distribution Docs](https://firebase.google.com/docs/app-distribution)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

### Tools
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
- [Flutter CLI Reference](https://docs.flutter.dev/reference/flutter-cli)

### Support
- For workflow issues: Create an issue in this repository
- For Firebase issues: [Firebase Support](https://firebase.google.com/support)
- For Flutter issues: [Flutter Community](https://flutter.dev/community)

---

## Best Practices

### Version Management
✅ **DO:**
- Update version in `pubspec.yaml` before creating tags
- Use semantic versioning (v1.2.3)
- Write clear release notes
- Test locally before pushing tags

❌ **DON'T:**
- Reuse tag versions
- Push tags without testing
- Skip version updates in pubspec.yaml

### Security
✅ **DO:**
- Keep service account credentials secure
- Use GitHub Secrets for all sensitive data
- Rotate service account keys periodically
- Limit access to deployment secrets

❌ **DON'T:**
- Commit credentials to repository
- Share service account JSON files
- Hardcode API keys in workflows

### Testing
✅ **DO:**
- Run `flutter analyze` before committing
- Fix test failures immediately
- Test builds locally before pushing
- Monitor workflow execution

❌ **DON'T:**
- Ignore workflow failures
- Skip testing
- Deploy without verification

---

## Quick Reference Card

```bash
# Complete deployment flow
git checkout main
git pull origin main

# Edit version in pubspec.yaml (e.g., 1.2.0+3)

git add pubspec.yaml
git commit -m "Bump version to 1.2.0"
git tag v1.2.0
git push origin main
git push origin v1.2.0

# Monitor at: https://github.com/dukens11-create/gud/actions
```

---

## 🎉 Success!

Once set up correctly, your deployment workflow is:

1. **Commit and push** code to `main`
   → Automatic build runs, artifacts uploaded

2. **Create and push version tag**
   → Automatic deployment to Firebase App Distribution

3. **Testers receive notification**
   → Download and test the app

4. **Monitor in Firebase Console**
   → Track installs and feedback

Happy deploying! 🚀
