# Keystore Setup Guide for Codemagic CI/CD

This guide provides detailed instructions for setting up Android keystores and iOS code signing in Codemagic to resolve the **"No keystores with reference 'gud_keystore' were found"** error.

## Table of Contents
1. [Android Keystore Setup](#android-keystore-setup)
2. [Uploading Keystore to Codemagic](#uploading-keystore-to-codemagic)
3. [iOS Code Signing Setup](#ios-code-signing-setup)
4. [Environment Variables Configuration](#environment-variables-configuration)
5. [Troubleshooting](#troubleshooting)
6. [Security Best Practices](#security-best-practices)

---

## Android Keystore Setup

### Option 1: Generate Keystore Locally (Recommended)

#### Step 1: Generate the Keystore

Run the following command on your local machine:

**Linux/macOS:**
```bash
keytool -genkey -v -keystore gud_keystore.jks \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias gud_key
```

**Windows:**
```cmd
keytool -genkey -v -keystore gud_keystore.jks ^
  -storetype JKS ^
  -keyalg RSA ^
  -keysize 2048 ^
  -validity 10000 ^
  -alias gud_key
```

#### Step 2: Answer the Prompts

You will be prompted for the following information:

1. **Keystore password**: Create a strong password (e.g., minimum 12 characters with mixed case, numbers, and symbols)
   - **IMPORTANT:** Record this password securely - you'll need it for Codemagic setup

2. **Key password**: Can be the same as keystore password or different
   - **IMPORTANT:** Record this password securely

3. **Distinguished Name fields**:
   - **First and last name**: Your or your organization's name (e.g., "GUD Express Inc")
   - **Organizational unit**: Your department (e.g., "Engineering" or "Development")
   - **Organization**: Your company name (e.g., "GUD Express")
   - **City or Locality**: Your city (e.g., "San Francisco")
   - **State or Province**: Your state (e.g., "California")
   - **Two-letter country code**: Your country code (e.g., "US")

4. **Confirmation**: Type "yes" to confirm the information is correct

#### Example Session:
```
Enter keystore password: MySecure@Password123
Re-enter new password: MySecure@Password123
What is your first and last name?
  [Unknown]:  GUD Express Inc
What is the name of your organizational unit?
  [Unknown]:  Engineering
What is the name of your organization?
  [Unknown]:  GUD Express
What is the name of your City or Locality?
  [Unknown]:  San Francisco
What is the name of your State or Province?
  [Unknown]:  California
What is the two-letter country code for this unit?
  [Unknown]:  US
Is CN=GUD Express Inc, OU=Engineering, O=GUD Express, L=San Francisco, ST=California, C=US correct?
  [no]:  yes

Generating 2,048 bit RSA key pair and self-signed certificate (SHA256withRSA) with a validity of 10,000 days
        for: CN=GUD Express Inc, OU=Engineering, O=GUD Express, L=San Francisco, ST=California, C=US
Enter key password for <gud_key>
        (RETURN if same as keystore password): [Press ENTER or enter different password]
[Storing gud_keystore.jks]
```

#### Step 3: Verify the Keystore

Verify your keystore was created successfully:

```bash
# List keystore contents
keytool -list -v -keystore gud_keystore.jks -alias gud_key

# You should see:
# - Alias name: gud_key
# - Creation date
# - Entry type: PrivateKeyEntry
# - Certificate chain length: 1
```

**Expected output snippet:**
```
Alias name: gud_key
Creation date: [Date]
Entry type: PrivateKeyEntry
Certificate chain length: 1
Certificate[1]:
Owner: CN=GUD Express Inc, OU=Engineering, O=GUD Express, L=San Francisco, ST=California, C=US
Issuer: CN=GUD Express Inc, OU=Engineering, O=GUD Express, L=San Francisco, ST=California, C=US
Valid from: [Start Date] until: [End Date]
```

#### Step 4: Secure Your Keystore

**⚠️ CRITICAL SECURITY STEPS:**

1. **Store the keystore file securely** (outside your project directory)
2. **Create secure backups** in multiple locations (encrypted cloud storage, secure physical storage)
3. **Record the following in a password manager**:
   - Keystore password
   - Key password
   - Key alias: `gud_key`
   - Keystore file name: `gud_keystore.jks`
   - Location of backups
   - Creation date

4. **NEVER commit the keystore to version control**

**⚠️ WARNING:** If you lose your keystore, you will NOT be able to update your app on Google Play Store. You would have to publish a completely new app with a different package name.

---

### Option 2: Let Codemagic Generate the Keystore

Codemagic can automatically generate a keystore for you. This is easier but gives you less control.

#### Pros:
- ✅ Quick and easy setup
- ✅ Codemagic manages the keystore securely
- ✅ No risk of losing the file locally

#### Cons:
- ❌ Less control over keystore properties
- ❌ Tied to Codemagic platform
- ❌ Must download from Codemagic if you want to build locally

#### Steps:
1. Go to Codemagic dashboard
2. Navigate to your app settings
3. Go to **Code signing identities** section
4. Click **Android** tab
5. Click **Generate keystore**
6. Codemagic will create a keystore automatically
7. Give it the reference name: `gud_keystore`
8. Set the key alias: `gud_key`
9. Download and backup the generated keystore file

---

## Uploading Keystore to Codemagic

This section resolves the **"No keystores with reference 'gud_keystore' were found"** error.

### Step-by-Step Upload Process

#### 1. Access Codemagic Dashboard

1. Go to [Codemagic](https://codemagic.io/apps)
2. Sign in with your account
3. Select your **gud** app/repository
4. Click on the app to open its settings

#### 2. Navigate to Code Signing

1. In the app settings, find the left sidebar
2. Click on **Code signing identities**
3. Click on the **Android** tab

#### 3. Upload Your Keystore

1. In the Android code signing section, look for **Upload keystore**
2. Click **Choose file** or drag and drop your `gud_keystore.jks` file
3. Fill in the following fields:

   **Keystore reference name:** `gud_keystore`
   - ⚠️ **MUST be exactly:** `gud_keystore` (this matches the reference in `codemagic.yaml`)
   - This is case-sensitive and must match exactly

   **Keystore password:** [Enter your keystore password]
   - The password you created in Step 2 of keystore generation

   **Key alias:** `gud_key`
   - ⚠️ **MUST be exactly:** `gud_key` (this is what we used when generating the keystore)

   **Key password:** [Enter your key password]
   - The key-specific password (may be same as keystore password)

4. Click **Add keystore** to upload

#### 4. Verify Upload

After uploading, you should see:
- ✅ Keystore name: `gud_keystore`
- ✅ Key alias: `gud_key`
- ✅ Upload date
- ✅ Status: Active/Available

**Screenshot verification:**
The uploaded keystore should appear in the list with:
```
Reference name: gud_keystore
Alias: gud_key
Uploaded: [Date]
[Delete button] [Download button]
```

---

## iOS Code Signing Setup

### Prerequisites

1. **Apple Developer Account** ($99/year)
   - Enroll at [developer.apple.com](https://developer.apple.com)
   - Complete payment and verification

2. **macOS computer with Xcode** (for certificate generation)
   - Or use Codemagic's automatic provisioning

3. **Bundle ID registered** in Apple Developer Portal
   - Example: `com.gudexpress.gud_app`

### Option 1: Automatic Code Signing (Recommended)

Codemagic can automatically manage certificates and provisioning profiles for you.

#### Step 1: Add App Store Connect API Key

1. **Generate API Key in App Store Connect:**
   - Go to [App Store Connect](https://appstoreconnect.apple.com)
   - Navigate to **Users and Access** → **Keys**
   - Click the **+** button to create a new key
   - Give it a name: "Codemagic iOS Builds"
   - Select access level: **Developer** or **App Manager**
   - Click **Generate**
   - **Download the API key** (you can only download it once!)
   - Record the **Issuer ID** and **Key ID**

2. **Upload to Codemagic:**
   - In Codemagic dashboard, go to your app settings
   - Navigate to **Code signing identities** → **iOS**
   - Click **Add API key**
   - Upload the downloaded `.p8` key file
   - Enter **Issuer ID** (from App Store Connect)
   - Enter **Key ID** (from App Store Connect)
   - Click **Save**

#### Step 2: Configure Automatic Provisioning in codemagic.yaml

The automatic provisioning is already configured in `codemagic.yaml`:

```yaml
ios-workflow:
  environment:
    ios_signing:
      distribution_type: app_store  # or: ad_hoc, development
      bundle_identifier: com.gudexpress.gud_app
```

Codemagic will automatically:
- ✅ Create certificates if needed
- ✅ Generate provisioning profiles
- ✅ Sign your app
- ✅ Manage certificate renewals

### Option 2: Manual Code Signing

If you prefer manual control over certificates and provisioning profiles:

#### Step 1: Create Certificates

**Development Certificate:**
1. On macOS, open **Keychain Access**
2. **Keychain Access** → **Certificate Assistant** → **Request a Certificate from a Certificate Authority**
3. Enter your email and name, select "Saved to disk"
4. Go to [Apple Developer Portal](https://developer.apple.com) → **Certificates, IDs & Profiles**
5. Click **+** to add certificate
6. Select **Apple Development**
7. Upload the certificate request file
8. Download the certificate and double-click to install in Keychain

**Distribution Certificate:**
1. Follow same steps as above
2. Select **Apple Distribution** instead
3. Download and install

#### Step 2: Create App ID

1. Go to **Certificates, IDs & Profiles** → **Identifiers**
2. Click **+** button
3. Select **App IDs** → Continue
4. Enter:
   - **Description:** GUD Express
   - **Bundle ID:** `com.gudexpress.gud_app` (explicit)
   - **Capabilities:** Enable required capabilities (Push Notifications, Sign in with Apple, etc.)
5. Click **Register**

#### Step 3: Register Devices (for Development/Ad Hoc)

1. Go to **Devices** → Click **+**
2. Enter device name and UDID
3. Register all test devices

#### Step 4: Create Provisioning Profiles

**Development Profile:**
1. Go to **Profiles** → Click **+**
2. Select **iOS App Development**
3. Select your App ID
4. Select Development Certificate(s)
5. Select test devices
6. Name it: "GUD Express Development"
7. Download the profile

**Distribution Profile (App Store):**
1. Click **+** → **App Store**
2. Select your App ID
3. Select Distribution Certificate
4. Name it: "GUD Express Distribution"
5. Download the profile

#### Step 5: Upload to Codemagic

1. In Codemagic → **Code signing identities** → **iOS**
2. Upload **Certificate** (.p12 file):
   - Export from Keychain: Right-click certificate → Export
   - Enter export password
   - Upload to Codemagic with password

3. Upload **Provisioning Profile** (.mobileprovision file):
   - Drag and drop the downloaded profile
   - Verify bundle ID matches

---

## Environment Variables Configuration

### Required Environment Variables

Configure these in Codemagic dashboard under **Environment variables**:

#### Android Signing Variables

These are automatically populated when you upload the keystore, but you can verify:

| Variable Name | Description | Example |
|--------------|-------------|---------|
| `CM_KEYSTORE_PASSWORD` | Keystore password | Your secure password |
| `CM_KEY_PASSWORD` | Key-specific password | Your secure password |
| `CM_KEY_ALIAS` | Key alias name | `gud_key` |
| `CM_KEYSTORE_PATH` | Path to keystore | Auto-populated by Codemagic |

#### iOS Signing Variables

| Variable Name | Description | Example |
|--------------|-------------|---------|
| `APP_STORE_CONNECT_ISSUER_ID` | API Key Issuer ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `APP_STORE_CONNECT_KEY_IDENTIFIER` | API Key ID | `XXXXXXXXXX` |
| `APP_STORE_CONNECT_PRIVATE_KEY` | API Key content | Content of .p8 file |

#### Additional Configuration Variables

| Variable Name | Description | Example |
|--------------|-------------|---------|
| `GRADLE_OPTS` | Gradle JVM options | `-Xmx6144m -XX:MaxMetaspaceSize=1024m` |
| `FLUTTER_VERSION` | Flutter version | `stable` or `3.24.0` |

### Setting Environment Variables

#### Method 1: Via Codemagic UI

1. Go to your app settings in Codemagic
2. Navigate to **Environment variables**
3. Click **Add variable**
4. Enter variable name and value
5. Toggle **Secure** for sensitive values (passwords, keys)
6. Select which workflows can access the variable
7. Click **Add**

#### Method 2: Via Application/Team Settings

For variables shared across multiple apps:
1. Go to **Teams** → **Team settings**
2. Navigate to **Global variables**
3. Add variables that all team apps can access

---

## Troubleshooting

### "No keystores with reference 'gud_keystore' were found"

This is the main error this guide resolves. Follow these steps:

#### Checklist:

1. **✅ Verify keystore is uploaded to Codemagic:**
   - Go to Codemagic → App Settings → Code signing identities → Android
   - Confirm you see `gud_keystore` in the list
   - If not, upload the keystore following the [upload instructions](#uploading-keystore-to-codemagic)

2. **✅ Check reference name is exactly `gud_keystore`:**
   - In Codemagic, the reference name must be **exactly**: `gud_keystore`
   - No extra spaces, different capitalization, or typos
   - Must match what's in `codemagic.yaml` line 75

3. **✅ Verify key alias is `gud_key`:**
   - When uploading keystore, ensure key alias field shows: `gud_key`
   - This must match the alias used when generating the keystore

4. **✅ Check the workflow configuration:**
   - Open `codemagic.yaml`
   - Find the `android-aab` workflow
   - Verify it has:
     ```yaml
     environment:
       android_signing:
         - gud_keystore
     ```

5. **✅ Ensure workflow is using the keystore:**
   - The build must be for `android-aab` workflow (not `android-apk`)
   - APK builds don't require keystore signing
   - AAB builds for Play Store require signing

6. **✅ Check environment variables:**
   - Go to Codemagic → Environment variables
   - Verify these exist (auto-created when keystore is uploaded):
     - `CM_KEYSTORE_PASSWORD`
     - `CM_KEY_PASSWORD`
     - `CM_KEY_ALIAS`
     - `CM_KEYSTORE_PATH`

#### If still failing:

1. **Delete and re-upload the keystore:**
   - Remove the existing keystore from Codemagic
   - Upload again, being very careful with the reference name
   - Ensure it's exactly: `gud_keystore`

2. **Generate a new keystore:**
   - If you suspect the keystore file is corrupted
   - Generate a new one following [Option 1](#option-1-generate-keystore-locally-recommended)
   - **⚠️ WARNING:** New keystore means new app listing on Play Store if already published

3. **Check build logs:**
   - In Codemagic, open the failed build
   - Scroll to the "Set up key.properties" step
   - Look for error messages about missing keystore
   - Verify environment variables are being populated

4. **Contact Codemagic support:**
   - If issue persists, contact [Codemagic support](https://codemagic.io/support)
   - Provide build logs and screenshots

### iOS Code Signing Errors

#### "No signing certificate matching"

**Solution:**
1. Verify certificate is uploaded to Codemagic
2. Check certificate hasn't expired
3. Ensure certificate matches the provisioning profile
4. Try automatic provisioning instead of manual

#### "Provisioning profile doesn't match bundle identifier"

**Solution:**
1. Verify bundle ID in provisioning profile: `com.gudexpress.gud_app`
2. Check bundle ID in `Info.plist` matches
3. Regenerate provisioning profile if needed

#### "Certificate expired"

**Solution:**
1. Generate new certificate in Apple Developer Portal
2. Create new provisioning profile with new certificate
3. Upload both to Codemagic
4. Rebuild

### Build Failures

#### "Gradle build failed"

**Solution:**
```bash
# Locally test the build
flutter clean
flutter pub get
flutter build appbundle --release

# Check for errors
# Common issues:
# - Missing google-services.json
# - Wrong Gradle version
# - Dependency conflicts
```

#### "Flutter version mismatch"

**Solution:**
1. Check `codemagic.yaml` Flutter version
2. Update to match your local Flutter version
3. Or use `stable` for latest stable release

#### "Out of memory during build"

**Solution:**
1. Increase `GRADLE_OPTS` in environment variables:
   ```
   GRADLE_OPTS=-Xmx8192m -XX:MaxMetaspaceSize=2048m
   ```
2. Or in `codemagic.yaml`:
   ```yaml
   environment:
     vars:
       GRADLE_OPTS: "-Xmx8192m -XX:MaxMetaspaceSize=2048m"
   ```

---

## Security Best Practices

### Keystore Security

1. **✅ Never commit keystores to version control**
   - Add to `.gitignore`:
     ```gitignore
     *.jks
     *.keystore
     key.properties
     ```

2. **✅ Use strong passwords**
   - Minimum 12 characters
   - Mix of uppercase, lowercase, numbers, symbols
   - Don't use dictionary words or personal information

3. **✅ Store passwords securely**
   - Use a password manager (1Password, LastPass, Bitwarden)
   - Never store in plain text files
   - Never share via email or unencrypted channels

4. **✅ Maintain multiple secure backups**
   - Encrypted cloud storage (Google Drive, Dropbox with encryption)
   - Secure physical storage (USB drive in safe)
   - Company vault/secure storage system

5. **✅ Limit access**
   - Only authorized personnel should have keystore access
   - Use Codemagic team permissions to control access
   - Audit access regularly

6. **✅ Document everything**
   - Record keystore creation date
   - Document who has access
   - Keep backup locations documented
   - Set calendar reminders for certificate renewals

### iOS Certificate Security

1. **✅ Protect private keys**
   - Certificate private keys must remain secure
   - Export with strong password
   - Delete from shared machines

2. **✅ Use App Store Connect API keys**
   - More secure than personal credentials
   - Can be revoked if compromised
   - Scoped to specific permissions

3. **✅ Rotate API keys periodically**
   - Recommended: Every 6-12 months
   - Immediately if key is suspected to be compromised

### Codemagic Security

1. **✅ Enable 2FA on Codemagic account**
   - Add extra security layer
   - Protect against unauthorized access

2. **✅ Use secure environment variables**
   - Mark sensitive values as "Secure" in Codemagic
   - They'll be hidden in logs and UI

3. **✅ Audit build logs**
   - Regularly review build logs for suspicious activity
   - Ensure secrets aren't being logged

4. **✅ Review team access**
   - Limit Codemagic team member permissions
   - Remove access for former team members promptly

---

## Validation Steps

After completing the setup, verify everything works:

### Android Validation

1. **Trigger a build in Codemagic:**
   - Push to `main` branch
   - Or manually trigger `android-aab` workflow

2. **Check build logs:**
   - Look for "Set up key.properties" step
   - Should see:
     ```
     storePassword=***
     keyPassword=***
     keyAlias=gud_key
     storeFile=/path/to/keystore
     ```

3. **Verify AAB is signed:**
   - Build should complete successfully
   - Download the AAB artifact
   - Verify with bundletool:
     ```bash
     java -jar bundletool.jar validate --bundle=app-release.aab
     ```

4. **Test upload to Play Console:**
   - Try uploading AAB to Internal Testing track
   - Should be accepted without signing errors

### iOS Validation

1. **Trigger iOS build:**
   - Push to `main` branch
   - Or manually trigger `ios-workflow`

2. **Check signing logs:**
   - Look for "Code signing" step
   - Should show certificate and profile being used

3. **Verify IPA is signed:**
   - Download IPA artifact
   - Check signing:
     ```bash
     codesign -vv -d build/ios/ipa/*.ipa
     ```

4. **Test upload to TestFlight:**
   - IPA should be accepted by App Store Connect
   - No code signing errors

---

## Quick Reference

### Key Names and Aliases

| Item | Value |
|------|-------|
| Keystore reference name | `gud_keystore` |
| Key alias | `gud_key` |
| Bundle ID (iOS) | `com.gudexpress.gud_app` |
| Package name (Android) | `com.gudexpress.gud_app` |

### Important Files

| File | Location | Purpose |
|------|----------|---------|
| `codemagic.yaml` | Root directory | CI/CD configuration |
| `gud_keystore.jks` | Secure location (NOT in repo) | Android signing keystore |
| `key.properties` | `android/` (NOT in repo) | Local keystore config |
| `.p8` key file | Secure location | App Store Connect API key |

### Important Links

- [Codemagic Dashboard](https://codemagic.io/apps)
- [Apple Developer Portal](https://developer.apple.com)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Google Play Console](https://play.google.com/console)
- [Codemagic Documentation](https://docs.codemagic.io/)
- [Flutter Build Documentation](https://docs.flutter.dev/deployment)

---

## Getting Help

### Internal Resources
- Review [AAB_BUILD_GUIDE.md](AAB_BUILD_GUIDE.md) for detailed Android build instructions
- Check [IOS_BUILD_AND_DEPLOY_GUIDE.md](IOS_BUILD_AND_DEPLOY_GUIDE.md) for iOS details
- See [DEPLOYMENT.md](DEPLOYMENT.md) for overall deployment process

### External Support
- **Codemagic Support:** [https://codemagic.io/support](https://codemagic.io/support)
- **Codemagic Slack:** [https://codemagicio.slack.com](https://codemagicio.slack.com)
- **Documentation:** [https://docs.codemagic.io](https://docs.codemagic.io)

### Common Issues
- For keystore upload errors, see [Troubleshooting](#troubleshooting)
- For iOS signing issues, see [iOS Code Signing Errors](#ios-code-signing-errors)
- For build failures, see [Build Failures](#build-failures)

---

**Last Updated:** February 2026  
**Document Version:** 1.0  
**Applies to:** GUD Express App v2.1.0+2
