# GitHub Actions AAB Setup Guide

This guide explains how to set up automated Android App Bundle (AAB) builds using GitHub Actions for the GUD Express app.

## Overview

The automated build workflow:
- ✅ Builds signed AAB files ready for Google Play Store
- ✅ Triggers on manual dispatch, version tags, or releases
- ✅ Securely handles signing keys using GitHub Secrets
- ✅ Caches dependencies for faster builds
- ✅ Automatically cleans up sensitive files after build
- ✅ Uploads AAB as downloadable artifact

## Prerequisites

- A GitHub account with access to the repository
- Java Development Kit (JDK) 8 or later installed locally (for keystore generation)
- Admin or write access to repository settings (to add secrets)

---

## Step 1: Generate Android Keystore

A keystore is required to sign your Android app for production release. You only need to do this once.

### Generate Keystore Command

Open your terminal and run:

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### You'll be prompted for:

1. **Keystore password**: Choose a strong password (you'll need this later)
2. **Key password**: Can be the same as keystore password or different
3. **Name and organization details**: Fill in as appropriate
4. **Confirm information**: Type "yes" when prompted

### Output

This creates a file named `upload-keystore.jks` in your current directory.

⚠️ **IMPORTANT**: Keep this file secure! You'll need it to sign all future versions of your app. Store it in a secure location and back it up.

### Example Session

```bash
$ keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

Enter keystore password: ********
Re-enter new password: ********
What is your first and last name?
  [Unknown]:  GUD Express
What is the name of your organizational unit?
  [Unknown]:  Development
What is the name of your organization?
  [Unknown]:  GUD Express
What is the name of your City or Locality?
  [Unknown]:  San Francisco
What is the name of your State or Province?
  [Unknown]:  CA
What is the two-letter country code for this unit?
  [Unknown]:  US
Is CN=GUD Express, OU=Development, O=GUD Express, L=San Francisco, ST=CA, C=US correct?
  [no]:  yes

Generating 2,048 bit RSA key pair and self-signed certificate (SHA256withRSA) with a validity of 10,000 days
	for: CN=GUD Express, OU=Development, O=GUD Express, L=San Francisco, ST=CA, C=US
Enter key password for <upload>
	(RETURN if same as keystore password): ********
[Storing upload-keystore.jks]
```

---

## Step 2: Encode Keystore to Base64

GitHub Secrets only accept text, so we need to encode the binary keystore file to base64.

### On macOS/Linux:

```bash
base64 -i upload-keystore.jks -o keystore_base64.txt
```

Or use this one-liner to copy directly to clipboard:

```bash
# macOS
base64 -i upload-keystore.jks | pbcopy

# Linux (with xclip installed)
base64 -i upload-keystore.jks | xclip -selection clipboard
```

### On Windows (PowerShell):

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Out-File -Encoding ASCII keystore_base64.txt
```

Or copy to clipboard:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard
```

### Result

You'll have a long text string that looks like:
```
/u3+7QAAAAIAAAABAAAAAQAGdXBsb2FkAAABj...
```

This is your base64-encoded keystore. Keep this safe - you'll add it to GitHub Secrets next.

---

## Step 3: Add Secrets to GitHub Repository

Now we'll add the required secrets to GitHub so the workflow can access them securely.

### Navigate to Repository Settings

1. Go to your GitHub repository: `https://github.com/dukens11-create/gud`
2. Click **Settings** tab
3. In the left sidebar, expand **Secrets and variables**
4. Click **Actions**
5. Click **New repository secret**

### Add These Four Secrets:

#### Secret 1: KEYSTORE_BASE64

- **Name**: `KEYSTORE_BASE64`
- **Value**: Paste the entire base64-encoded string from Step 2
- Click **Add secret**

#### Secret 2: KEYSTORE_PASSWORD

- **Name**: `KEYSTORE_PASSWORD`
- **Value**: The keystore password you set in Step 1
- Click **Add secret**

#### Secret 3: KEY_PASSWORD

- **Name**: `KEY_PASSWORD`
- **Value**: The key password you set in Step 1 (might be same as keystore password)
- Click **Add secret**

#### Secret 4: KEY_ALIAS

- **Name**: `KEY_ALIAS`
- **Value**: `upload` (or whatever alias you used in the keytool command)
- Click **Add secret**

### Verify Secrets

After adding all four secrets, you should see them listed:
- ✅ KEYSTORE_BASE64
- ✅ KEYSTORE_PASSWORD
- ✅ KEY_PASSWORD
- ✅ KEY_ALIAS

⚠️ **Note**: You won't be able to view secret values after creation - this is a security feature.

---

## Step 4: Trigger the Workflow

### Method 1: Manual Trigger (Recommended for Testing)

1. Go to your repository on GitHub
2. Click the **Actions** tab
3. In the left sidebar, click **Build Android App Bundle (AAB)**
4. Click **Run workflow** button (on the right)
5. Select the branch (usually `main`)
6. Click **Run workflow**

### Method 2: Push a Version Tag

```bash
git tag v1.0.0  # Replace with your actual version number
git push origin v1.0.0
```

The workflow will trigger automatically for any tag starting with `v`.

### Method 3: Create a GitHub Release

1. Go to your repository on GitHub
2. Click **Releases** → **Create a new release**
3. Choose or create a tag (e.g., `v1.0.0` - replace with your version)
4. Fill in release details
5. Click **Publish release**

The workflow will trigger automatically.

---

## Step 5: Monitor Build Progress

1. Go to the **Actions** tab in your repository
2. Click on the running workflow
3. You'll see build progress in real-time
4. The build typically takes 5-10 minutes

### Build Steps:

1. ✅ Checkout repository
2. ✅ Set up Java 17
3. ✅ Set up Flutter (stable channel)
4. ✅ Verify Flutter installation
5. ✅ Get Flutter dependencies
6. ✅ Decode keystore from secrets
7. ✅ Create key.properties file
8. ✅ Build release App Bundle
9. ✅ Upload AAB artifact
10. ✅ Clean up sensitive files

---

## Step 6: Download the Built AAB

Once the workflow completes successfully:

1. Scroll to the bottom of the workflow run page
2. Under **Artifacts**, you'll see **app-release-aab**
3. Click to download (it's a zip file)
4. Extract the zip to get `app-release.aab`

### What to Do with the AAB:

The `app-release.aab` file is ready for upload to Google Play Console:

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app
3. Go to **Release** → **Production** (or Testing track)
4. Click **Create new release**
5. Upload the `app-release.aab` file
6. Complete the release process

---

## Troubleshooting

### Error: "KEYSTORE_BASE64 secret is not set"

**Problem**: The workflow can't find the keystore secret.

**Solution**:
- Verify the secret is named exactly `KEYSTORE_BASE64` (case-sensitive)
- Check you added it to **Repository secrets**, not Environment secrets
- Make sure you're running the workflow from the correct branch

### Error: "Required secrets are not set"

**Problem**: One or more signing secrets are missing.

**Solution**:
- Verify all four secrets are added: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`
- Check spelling and case sensitivity

### Error: "Failed to build appbundle"

**Problem**: Build failed during compilation.

**Solutions**:
- Check the build logs for specific error messages
- Ensure your code builds locally: `flutter build appbundle --release`
- Verify dependencies in `pubspec.yaml` are valid
- Check Flutter version compatibility

### Error: "Keystore was tampered with, or password was incorrect"

**Problem**: The keystore password is incorrect or keystore file is corrupted.

**Solutions**:
- Verify `KEYSTORE_PASSWORD` secret matches your keystore password
- Verify `KEY_PASSWORD` secret matches your key password
- Re-encode the keystore to base64 and update the secret
- Ensure the keystore file wasn't corrupted during encoding

### Build Takes Too Long

**Issue**: Build exceeds expected time (>15 minutes).

**Solutions**:
- Check GitHub Actions status: https://www.githubstatus.com/
- The workflow uses caching to speed up subsequent builds
- First build is always slower as it downloads dependencies

### Can't Find Artifact

**Issue**: Workflow completes but no artifact appears.

**Solutions**:
- Check the workflow completed successfully (green checkmark)
- Artifacts are retained for 90 days
- Look at the "Upload AAB artifact" step logs for errors

---

## Security Best Practices

✅ **DO:**
- Keep your keystore file backed up in a secure location
- Use strong, unique passwords for keystore and key
- Store keystore password in a password manager
- Regularly verify that secrets are not exposed in logs
- Use the same keystore for all versions of your app

❌ **DON'T:**
- Never commit keystore files to git
- Never commit `key.properties` to git (it's in `.gitignore`)
- Never share keystore passwords via unsecured channels
- Never include secrets in workflow files (use GitHub Secrets only)
- Never regenerate your keystore unless absolutely necessary

---

## Workflow Features

### Automatic Caching

The workflow caches:
- Gradle dependencies
- Flutter SDK
- Pub packages

This speeds up subsequent builds significantly.

### Automatic Cleanup

After the build completes (success or failure), the workflow automatically removes:
- `android/app/upload-keystore.jks`
- `android/key.properties`

This ensures sensitive files never remain in the runner environment.

### Artifact Retention

Built AAB files are retained for **90 days**. After this period, they're automatically deleted. Download them within this timeframe.

---

## Advanced Configuration

### Changing Flutter Channel

To use a different Flutter channel (e.g., beta):

Edit `.github/workflows/build-aab.yml`:
```yaml
- name: Set up Flutter (stable channel)
  uses: subosito/flutter-action@v2
  with:
    channel: 'beta'  # Change to: stable, beta, or dev
    cache: true
```

### Changing Artifact Retention

To keep artifacts for a different duration:

Edit `.github/workflows/build-aab.yml`:
```yaml
- name: Upload AAB artifact
  uses: actions/upload-artifact@v4
  with:
    name: app-release-aab
    path: build/app/outputs/bundle/release/app-release.aab
    retention-days: 30  # Change to desired number of days (1-90)
```

### Automatic Release Upload

To automatically attach the AAB to GitHub releases, add this step after the upload:

```yaml
- name: Upload to Release
  if: startsWith(github.ref, 'refs/tags/')
  uses: softprops/action-gh-release@v1
  with:
    files: build/app/outputs/bundle/release/app-release.aab
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## Additional Resources

- [Flutter Release Documentation](https://docs.flutter.dev/deployment/android)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Google Play Console](https://play.google.com/console)

---

## Support

If you encounter issues not covered in this guide:

1. Check the [workflow logs](https://github.com/dukens11-create/gud/actions) for detailed error messages
2. Review existing AAB build documentation in the repository
3. Consult Flutter and Android documentation
4. Open an issue in the repository with:
   - Workflow run URL
   - Error messages from logs
   - Steps you've already tried

---

## Summary Checklist

Before running the workflow, ensure:

- [ ] Keystore file generated with `keytool`
- [ ] Keystore encoded to base64
- [ ] All four secrets added to GitHub:
  - [ ] KEYSTORE_BASE64
  - [ ] KEYSTORE_PASSWORD
  - [ ] KEY_PASSWORD
  - [ ] KEY_ALIAS
- [ ] Keystore and passwords backed up securely
- [ ] Ready to trigger workflow manually or via tag/release

Once complete, you can trigger builds anytime without a local development environment!
