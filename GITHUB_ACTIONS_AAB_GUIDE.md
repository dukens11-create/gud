# GitHub Actions AAB Build Guide for GUD Express

This guide provides complete instructions for setting up and using the GitHub Actions workflow to automatically build signed Android App Bundle (AAB) files for the GUD Express Flutter app.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Generate Android Keystore](#generate-android-keystore)
4. [Encode Keystore to Base64](#encode-keystore-to-base64)
5. [Add Secrets to GitHub Repository](#add-secrets-to-github-repository)
6. [Trigger the Workflow](#trigger-the-workflow)
7. [Download the AAB Artifact](#download-the-aab-artifact)
8. [Upload to Google Play Console](#upload-to-google-play-console)
9. [Troubleshooting](#troubleshooting)
10. [Security Best Practices](#security-best-practices)

---

## Overview

The GitHub Actions workflow (`.github/workflows/build-aab.yml`) automatically builds a signed Android App Bundle (AAB) for production deployment. The workflow:

- ✅ Runs on Ubuntu with Java 17 and Flutter stable
- ✅ Caches dependencies for faster builds
- ✅ Decodes your keystore from GitHub Secrets
- ✅ Creates signing configuration from secrets
- ✅ Builds a signed, production-ready AAB
- ✅ Uploads the AAB as a downloadable artifact
- ✅ Follows security best practices
- ✅ Cleans up sensitive files after build

**Triggers:**
- Manual dispatch (from GitHub Actions UI)
- Git tags matching pattern `v*` (e.g., `v2.1.0`)
- GitHub releases (published or created)

---

## Prerequisites

Before setting up the workflow, ensure you have:

- **GitHub repository access**: Write access to add secrets
- **JDK 17+**: To generate keystore (if you don't have one)
- **Base64 encoding tool**: Available on Linux/Mac by default, Windows users can use Git Bash or WSL
- **Keystore file**: Either existing or newly generated (instructions below)

---

## Generate Android Keystore

If you don't already have a keystore, generate one using the following steps:

### Step 1: Open Terminal/Command Prompt

Open your terminal (Linux/Mac) or Command Prompt/PowerShell (Windows).

### Step 2: Generate Keystore

Run the following command:

```bash
keytool -genkey -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### Step 3: Enter Keystore Information

You'll be prompted to enter:

1. **Keystore password**: Choose a strong password (e.g., 16+ characters)
   - Remember this password! You'll need it as `KEYSTORE_PASSWORD`
2. **Key password**: Can be the same as keystore password
   - This will be your `KEY_PASSWORD`
3. **Name, Organization, etc.**: Enter your details or press Enter to skip

### Step 4: Verify Keystore Creation

You should now have a file named `upload-keystore.jks` in your current directory.

```bash
# Verify the keystore file exists
ls -lh upload-keystore.jks

# List keystore contents
keytool -list -v -keystore upload-keystore.jks
```

### Important Notes

- 🔒 **Keep your keystore file secure!** Store it in a safe location.
- ⚠️ **Never commit it to git!** It's already in `.gitignore`.
- 📝 **Document your passwords securely** (use a password manager).
- 🔑 **Losing your keystore means you cannot update your app** on Google Play Store.

### Key Alias

By default, the key alias is `upload`. If you used a different alias, note it down for later.

---

## Encode Keystore to Base64

GitHub Secrets stores text values, so we need to encode the binary keystore file to base64.

### On Linux/Mac

```bash
# Navigate to the directory containing your keystore
cd /path/to/keystore

# Encode to base64 (single line)
base64 -i upload-keystore.jks | tr -d '\n' > keystore_base64.txt

# Verify the file was created
cat keystore_base64.txt
```

### On Windows (PowerShell)

```powershell
# Navigate to the directory containing your keystore
cd C:\path\to\keystore

# Encode to base64
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Out-File -Encoding ASCII keystore_base64.txt

# Verify the file was created
Get-Content keystore_base64.txt
```

### On Windows (Git Bash or WSL)

```bash
# Navigate to the directory containing your keystore
cd /c/path/to/keystore

# Encode to base64 (single line)
base64 -w 0 upload-keystore.jks > keystore_base64.txt

# Verify the file was created
cat keystore_base64.txt
```

### Verify Base64 Encoding

The `keystore_base64.txt` file should contain a long string of characters (base64 encoded data). This is what you'll add to GitHub Secrets.

**Example output (truncated):**
```
/u3+7QAAAAIAAAABAAAAAQAGdXBsb2FkAAABjY2X8+0AAAUBMIIEfTAOBgorBgEE...
```

---

## Add Secrets to GitHub Repository

GitHub Secrets securely store sensitive information needed for the build process.

### Step 1: Navigate to Repository Settings

1. Go to your GitHub repository: `https://github.com/dukens11-create/gud`
2. Click on **Settings** tab
3. In the left sidebar, expand **Secrets and variables**
4. Click on **Actions**

### Step 2: Add Required Secrets

You need to add **4 secrets**. Click **"New repository secret"** for each:

#### 1. KEYSTORE_BASE64

- **Name**: `KEYSTORE_BASE64`
- **Value**: Copy the entire contents of `keystore_base64.txt`
  ```bash
  # Copy to clipboard (Mac)
  cat keystore_base64.txt | pbcopy
  
  # Copy to clipboard (Linux with xclip)
  cat keystore_base64.txt | xclip -selection clipboard
  
  # On Windows, just open the file and copy
  ```
- Click **Add secret**

#### 2. KEYSTORE_PASSWORD

- **Name**: `KEYSTORE_PASSWORD`
- **Value**: The password you used when creating the keystore (from Step 3 of keystore generation)
- Click **Add secret**

#### 3. KEY_PASSWORD

- **Name**: `KEY_PASSWORD`
- **Value**: The key password you used (often same as `KEYSTORE_PASSWORD`)
- Click **Add secret**

#### 4. KEY_ALIAS

- **Name**: `KEY_ALIAS`
- **Value**: The alias you used when creating the keystore (default: `upload`)
- Click **Add secret**

### Step 3: Verify Secrets

After adding all secrets, you should see 4 secrets listed:
- ✅ KEYSTORE_BASE64
- ✅ KEYSTORE_PASSWORD
- ✅ KEY_PASSWORD
- ✅ KEY_ALIAS

**Note**: GitHub doesn't show secret values after creation for security reasons.

---

## Trigger the Workflow

There are three ways to trigger the AAB build workflow:

### Method 1: Manual Dispatch (Recommended for Testing)

1. Go to **Actions** tab in your repository
2. Click on **"Build Android App Bundle (AAB)"** workflow
3. Click **"Run workflow"** button (on the right)
4. Select the branch (usually `main`)
5. Optionally choose Flutter version (default: `stable`)
6. Click **"Run workflow"** green button

### Method 2: Create a Git Tag

Tags matching pattern `v*` automatically trigger the workflow:

```bash
# Create and push a version tag
git tag v2.1.0
git push origin v2.1.0

# Or create an annotated tag with message
git tag -a v2.1.0 -m "Release version 2.1.0"
git push origin v2.1.0
```

### Method 3: Create a GitHub Release

1. Go to **Releases** in your repository
2. Click **"Draft a new release"**
3. Choose or create a tag (e.g., `v2.1.0`)
4. Fill in release title and description
5. Click **"Publish release"**

The workflow will automatically trigger when the release is published.

---

## Download the AAB Artifact

After the workflow completes successfully:

### Step 1: Navigate to Workflow Run

1. Go to **Actions** tab in your repository
2. Click on the completed workflow run
3. You should see a green checkmark ✅ if successful

### Step 2: Download Artifact

1. Scroll down to the **Artifacts** section at the bottom of the page
2. You'll see an artifact named like: `gud-express-aab-2.1.0+2`
3. Click on the artifact name to download it as a ZIP file

### Step 3: Extract AAB

1. Unzip the downloaded file
2. Inside you'll find `app-release.aab`
3. This is your signed, production-ready Android App Bundle!

### Artifact Details

- **Retention**: Artifacts are kept for 90 days
- **Size**: Typically 20-50 MB (compressed)
- **Format**: ZIP file containing the AAB

---

## Upload to Google Play Console

Now that you have the signed AAB, you can upload it to Google Play:

### Step 1: Access Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Sign in with your Google account
3. Select your app (GUD Express)

### Step 2: Create a New Release

1. Navigate to **Production** (or **Internal testing** for testing)
2. Click **"Create new release"**
3. In the **App bundles** section, click **"Upload"**
4. Select your `app-release.aab` file

### Step 3: Complete Release Details

1. **Release name**: e.g., "2.1.0" (from pubspec.yaml)
2. **Release notes**: Describe what's new in this version
   - Add release notes for all supported languages
   - Include bug fixes, new features, improvements
3. Review the release details
4. Click **"Review release"**

### Step 4: Roll Out Release

1. Review all information carefully
2. Click **"Start rollout to Production"** (or appropriate track)
3. Confirm the rollout

### Release Timeline

- **Internal testing**: Available within minutes
- **Closed/Open testing**: Available within a few hours
- **Production**: Review typically takes 1-3 days

---

## Troubleshooting

### Common Issues and Solutions

#### ❌ Build Fails: "KEYSTORE_BASE64 secret is not set"

**Problem**: The required secrets are not configured.

**Solution**: 
1. Follow [Add Secrets to GitHub Repository](#add-secrets-to-github-repository)
2. Ensure all 4 secrets are added correctly
3. Wait a few minutes for secrets to propagate
4. Re-run the workflow

#### ❌ Build Fails: "Keystore tampered with or password incorrect"

**Problem**: Incorrect keystore password or corrupted keystore encoding.

**Solution**:
1. Verify `KEYSTORE_PASSWORD` matches your actual keystore password
2. Re-encode keystore to base64 (ensure no line breaks)
3. Update `KEYSTORE_BASE64` secret with new encoding
4. Re-run the workflow

#### ❌ Build Fails: "Unknown keystore format"

**Problem**: Base64 encoding includes line breaks or is corrupted.

**Solution**:
1. Re-encode keystore using `-w 0` flag (Linux) or `tr -d '\n'` (Mac)
2. Ensure the encoded string is one continuous line
3. Update `KEYSTORE_BASE64` secret
4. Re-run the workflow

#### ❌ Workflow Doesn't Trigger on Tag

**Problem**: Tag doesn't match the pattern or workflow is disabled.

**Solution**:
1. Ensure tag starts with `v` (e.g., `v2.1.0`, not `2.1.0`)
2. Check if Actions are enabled in repository settings
3. Verify workflow file is in `.github/workflows/` directory
4. Check branch protection rules don't block the workflow

#### ❌ Cannot Download Artifact

**Problem**: Artifact expired or browser issues.

**Solution**:
1. Artifacts expire after 90 days - re-run workflow if needed
2. Try a different browser or clear cache
3. Check if you have permission to access the repository
4. Try downloading via GitHub CLI:
   ```bash
   gh run download <run-id> --name gud-express-aab-<version>
   ```

#### ❌ Flutter Analyze Warnings

**Problem**: Code quality issues detected.

**Solution**:
1. The workflow continues despite analyze warnings (continue-on-error: true)
2. Review warnings locally: `flutter analyze`
3. Fix critical issues before production release
4. Consider fixing warnings for better code quality

#### ❌ Build Takes Too Long

**Problem**: Workflow exceeds timeout or takes too long.

**Solution**:
1. Current timeout is 45 minutes (should be sufficient)
2. Check if dependencies are being cached properly
3. Consider increasing timeout in workflow file if needed
4. Review build logs for bottlenecks

### Getting Help

If you encounter issues not covered here:

1. **Check workflow logs**: Click on failed step for detailed logs
2. **Review Flutter doctor**: Run `flutter doctor -v` locally
3. **Test local build**: Try `flutter build appbundle --release` locally
4. **GitHub Actions docs**: [docs.github.com/actions](https://docs.github.com/actions)
5. **Flutter docs**: [docs.flutter.dev](https://docs.flutter.dev)

---

## Security Best Practices

This workflow follows industry-standard security practices:

### ✅ Secrets Management

- **GitHub Secrets**: Encrypted at rest and in transit
- **Never logged**: Secrets are automatically redacted in logs
- **Scoped access**: Only accessible to authorized workflows
- **No hardcoding**: Passwords and keys never in source code

### ✅ Keystore Handling

- **Base64 encoding**: Safe transmission of binary files
- **Temporary storage**: Keystore decoded only during build
- **Automatic cleanup**: Sensitive files deleted after build
- **Never committed**: `.gitignore` prevents accidental commits

### ✅ Workflow Security

- **Repository check**: Workflow only runs in main repository
- **Minimal permissions**: Uses least privilege principle
- **Artifact encryption**: Uploaded artifacts are encrypted
- **Limited retention**: Artifacts expire after 90 days

### ✅ Code Security

- **Flutter analyze**: Checks for code issues
- **Dependency caching**: Reduces external network calls
- **Timeout protection**: 45-minute timeout prevents runaway builds
- **Audit logs**: GitHub logs all workflow runs

### 🔒 Additional Recommendations

1. **Enable branch protection**: Require reviews before merging
2. **Use 2FA**: Enable two-factor authentication on GitHub
3. **Rotate secrets**: Periodically update keystore passwords
4. **Review logs**: Monitor workflow runs for anomalies
5. **Backup keystore**: Store keystore securely offsite
6. **Document access**: Keep record of who has keystore access
7. **Use release signing**: Never share debug keystore
8. **Audit dependencies**: Regularly check for vulnerabilities

### 🚨 What NOT to Do

- ❌ Never commit keystore files to git
- ❌ Never share keystore passwords in plain text
- ❌ Never email keystore files
- ❌ Never store keystore in public locations
- ❌ Never use the same keystore for development and production
- ❌ Never disable secret scanning in repository settings
- ❌ Never share GitHub personal access tokens

---

## Workflow File Reference

The workflow is defined in `.github/workflows/build-aab.yml`:

### Key Features

```yaml
# Triggers
- workflow_dispatch      # Manual trigger
- tags: v*              # Version tags
- release: published    # GitHub releases

# Environment
- runs-on: ubuntu-latest
- java-version: 17
- flutter-version: stable

# Secrets Required
- KEYSTORE_BASE64       # Base64-encoded keystore
- KEYSTORE_PASSWORD     # Keystore password
- KEY_PASSWORD          # Key password
- KEY_ALIAS            # Key alias (default: upload)

# Build Steps
1. Checkout code
2. Set up Java 17
3. Set up Flutter
4. Cache dependencies
5. Get Flutter dependencies
6. Decode keystore from base64
7. Create key.properties
8. Build AAB (flutter build appbundle --release)
9. Upload artifact
10. Clean up sensitive files
```

### Customization

You can customize the workflow by editing `.github/workflows/build-aab.yml`:

- **Flutter version**: Change `flutter-version` input default
- **Timeout**: Adjust `timeout-minutes` value
- **Retention**: Modify `retention-days` for artifacts
- **Cache keys**: Update cache keys for better performance
- **Build flags**: Add custom flags to `flutter build appbundle`

---

## Version Management

### Updating App Version

Before building a new AAB for release:

1. **Update `pubspec.yaml`**:
   ```yaml
   version: 2.2.0+3  # Format: version+buildNumber
   ```

2. **Update `android/app/build.gradle`**:
   ```gradle
   defaultConfig {
       versionCode 3          // Increment for each release
       versionName "2.2.0"    // Match pubspec.yaml
   }
   ```

3. **Commit changes**:
   ```bash
   git add pubspec.yaml android/app/build.gradle
   git commit -m "Bump version to 2.2.0"
   git push
   ```

4. **Create tag**:
   ```bash
   git tag v2.2.0
   git push origin v2.2.0
   ```

### Version Naming Convention

Follow semantic versioning:
- **Major** (2.x.x): Breaking changes
- **Minor** (x.2.x): New features, backward compatible
- **Patch** (x.x.1): Bug fixes

Build number should increment for every Play Store upload, regardless of version number.

---

## Quick Reference Card

### One-Time Setup (First Time Only)

```bash
# 1. Generate keystore
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 2. Encode to base64
base64 -i upload-keystore.jks | tr -d '\n' > keystore_base64.txt

# 3. Add 4 secrets to GitHub:
#    - KEYSTORE_BASE64 (contents of keystore_base64.txt)
#    - KEYSTORE_PASSWORD (your keystore password)
#    - KEY_PASSWORD (your key password)
#    - KEY_ALIAS (default: upload)
```

### Regular Release Process

```bash
# 1. Update version in pubspec.yaml and build.gradle
# 2. Commit and push changes
git add .
git commit -m "Bump version to 2.x.x"
git push

# 3. Create and push tag
git tag v2.x.x
git push origin v2.x.x

# 4. Download AAB from Actions tab
# 5. Upload to Google Play Console
```

### Emergency Rollback

If you need to rollback a release:
1. In Play Console, create a new release with previous AAB
2. Or use "Halt rollout" if issues detected early
3. Fix issues and create new version with patch

---

## FAQ

### Q: Can I use this for debug builds?

A: This workflow is designed for release builds only. For debug builds, use `flutter build apk --debug` locally.

### Q: How long do artifacts stay available?

A: Artifacts are retained for 90 days. After that, you'll need to re-run the workflow.

### Q: Can I build multiple versions simultaneously?

A: Yes, each workflow run is independent. You can trigger multiple runs with different tags.

### Q: What if I lose my keystore?

A: If you lose your keystore, you cannot update the existing app on Play Store. You'll need to publish as a new app with a new package name. **Always backup your keystore securely!**

### Q: Can I use a different Java version?

A: Flutter 3.24.0 requires Java 17. Using other versions may cause build failures.

### Q: How do I test the AAB before releasing?

A: Use Google Play's Internal Testing track to test with real users before production release.

### Q: Can I modify the workflow?

A: Yes! The workflow file is version controlled. Make changes in a branch, test, then merge to main.

### Q: Does this work for iOS?

A: No, this workflow is Android-specific. iOS requires different signing and build processes.

### Q: How much does this cost?

A: GitHub Actions provides free minutes for public repositories. Private repositories have monthly quotas. Check GitHub pricing for details.

### Q: Can I see previous AAB builds?

A: Yes, each workflow run keeps its artifacts for 90 days. Navigate to Actions → specific run → Artifacts.

---

## Additional Resources

- **Flutter Documentation**: [docs.flutter.dev](https://docs.flutter.dev)
- **Android App Bundle**: [developer.android.com/guide/app-bundle](https://developer.android.com/guide/app-bundle)
- **GitHub Actions**: [docs.github.com/actions](https://docs.github.com/actions)
- **Google Play Console**: [play.google.com/console](https://play.google.com/console)
- **Keystore Security**: [developer.android.com/studio/publish/app-signing](https://developer.android.com/studio/publish/app-signing)

---

## Support

If you need help:
1. Check [Troubleshooting](#troubleshooting) section
2. Review workflow logs in Actions tab
3. Test build locally: `flutter build appbundle --release`
4. Check existing AAB guides: `AAB_BUILD_GUIDE.md`, `AAB_QUICK_START.md`

---

**Last Updated**: 2026-02-09  
**Workflow Version**: 1.0  
**Compatible with**: Flutter 3.24.0+, Android SDK 21-36
