# Codemagic Keystore Setup Guide

## Overview
This guide provides step-by-step instructions for setting up the Android keystore in Codemagic to fix the build error:
```
No keystores with reference 'gud-release-key' were found from code signing identities.
```

## Prerequisites
- Access to Codemagic account with the "gud" app configured
- A valid Android keystore file (or generate one using our script)

---

## Method A: Generate Keystore Locally and Upload

### Step 1: Generate Keystore
Use the provided script or manual command:

```bash
# Using the provided script (recommended)
./generate_keystore.sh

# Or manually:
keytool -genkey -v -keystore gud-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias gud_key
```

**Important**: Save the following securely:
- Keystore password
- Key password
- Key alias (default: `gud_key`)

### Step 2: Login to Codemagic
1. Go to [https://codemagic.io/](https://codemagic.io/)
2. Sign in with your account credentials

### Step 3: Navigate to the "gud" App
1. From the Codemagic dashboard, you'll see a list of your applications
2. Click on the **"gud"** application card/tile
3. This will open the app overview page

### Step 4: Open App Settings
1. Look for the **"Settings"** option in the left sidebar or top navigation
2. Click on **"Settings"**
3. You should now see various configuration options

### Step 5: Navigate to Code Signing Identities
1. In the Settings page, look for **"Code signing identities"** section
2. Click on **"Code signing identities"**
3. You'll see tabs for different platforms

### Step 6: Go to Android Code Signing
1. Click on the **"Android"** tab
2. You should see options to manage Android keystores

**What this section looks like:**
```
Settings → Code signing identities → Android
┌─────────────────────────────────────────┐
│ Android code signing                    │
│                                         │
│ [Add keystore]                          │
│                                         │
│ Keystores:                              │
│   (List of uploaded keystores)          │
└─────────────────────────────────────────┘
```

### Step 7: Upload Keystore with Correct Reference Name

**⚠️ CRITICAL: The reference name MUST be exactly: `gud-release-key`**

1. Click **"Add keystore"** or **"Upload keystore"** button
2. Fill in the form:
   - **Keystore file**: Click "Choose file" and select `gud-release-key.jks`
   - **Reference name**: Enter **exactly** `gud-release-key` (case-sensitive)
   - **Keystore password**: Enter your keystore password
   - **Key alias**: Enter your key alias (default: `gud_key`)
   - **Key password**: Enter your key password

3. Click **"Save"** or **"Upload"**

**Form should look like:**
```
Add Android keystore
┌─────────────────────────────────────────┐
│ Keystore file:     [Choose file]        │
│ Reference name:    gud-release-key  ◄───┼── MUST BE EXACTLY THIS
│ Keystore password: ••••••••••••         │
│ Key alias:         gud_key               │
│ Key password:      ••••••••••••         │
│                                         │
│          [Cancel]  [Save]               │
└─────────────────────────────────────────┘
```

### Step 8: Verify Upload
1. After saving, you should see the keystore listed under "Android code signing"
2. The reference name should show as: `gud-release-key`
3. Status should be "Active" or have a green checkmark

### Step 9: Trigger New Build
1. Go back to the app overview
2. Click **"Start new build"** or push a new commit
3. Select the **"android-aab"** workflow
4. Monitor the build logs to confirm success

---

## Method B: Let Codemagic Auto-Generate Keystore

### Step 1: Navigate to Android Code Signing
Follow Steps 2-6 from Method A to reach:
```
Settings → Code signing identities → Android
```

### Step 2: Generate New Keystore
1. Click **"Generate keystore"** button (if available)
2. Fill in the form:
   - **Reference name**: Enter **exactly** `gud-release-key`
   - **Key alias**: Enter `gud_key` (or your preferred alias)
   - **Organization details**: Fill in as needed
   - **Validity**: Default (10000 days) is fine

3. Click **"Generate"**

**⚠️ CRITICAL: Save the generated credentials!**
- Codemagic will generate passwords for you
- Download and securely store the keystore file
- **You cannot recover these if lost!**

### Step 3: Verify and Build
1. Confirm the keystore appears with reference name `gud-release-key`
2. Trigger a new build
3. Monitor for success

---

## Visual Navigation Guide

### Finding Settings
```
Codemagic Dashboard
    ↓
Your apps list
    ↓
Click "gud" app
    ↓
[Overview] [Builds] [Settings] ← Click here
    ↓
Settings page
    ↓
[General] [Repository] [Code signing identities] ← Click here
    ↓
[iOS] [Android] [macOS] ← Click Android tab
    ↓
Android code signing management
```

### Alternative Navigation Paths
**Path 1 (Recommended):**
`Apps → gud → Settings → Code signing identities → Android`

**Path 2 (Team Settings - Don't use):**
`Team → Code signing identities` ← This is for team-wide keystores

**Always use app-specific settings, not team settings!**

---

## Important Notes

### Reference Name Requirements
- **MUST** be exactly: `gud-release-key`
- Case-sensitive
- No spaces or special characters
- Must match the value in `codemagic.yaml`:
  ```yaml
  android_signing:
    - gud-release-key
  ```

### Environment Variables
When you upload the keystore with reference name `gud-release-key`, Codemagic automatically creates these environment variables:
- `$CM_KEYSTORE_PASSWORD` - Your keystore password
- `$CM_KEY_PASSWORD` - Your key password
- `$CM_KEY_ALIAS` - Your key alias
- `$CM_KEYSTORE_PATH` - Path to keystore file during build

These are used in the build script (`codemagic.yaml`) to create `key.properties`.

### Security Best Practices
1. **Never commit keystores to Git** - Already in `.gitignore`
2. **Keep backup of keystore** - Store in secure location
3. **Document passwords** - Use password manager
4. **Different keystores for dev/prod** - Use different reference names if needed

---

## Verification Checklist

After setup, verify:
- ✅ Keystore uploaded to Codemagic
- ✅ Reference name is exactly `gud-release-key`
- ✅ All passwords entered correctly
- ✅ Keystore shows as "Active"
- ✅ Build triggered successfully
- ✅ Build logs show keystore found
- ✅ AAB file generated successfully

---

## What Happens During Build

When you trigger the `android-aab` workflow:

1. **Codemagic reads configuration**
   ```yaml
   android_signing:
     - gud-release-key  # Looks for this reference name
   ```

2. **Injects environment variables**
   - Finds keystore with reference `gud-release-key`
   - Sets `CM_KEYSTORE_*` environment variables

3. **Creates key.properties**
   ```bash
   echo "storePassword=$CM_KEYSTORE_PASSWORD" > android/key.properties
   echo "keyPassword=$CM_KEY_PASSWORD" >> android/key.properties
   echo "keyAlias=$CM_KEY_ALIAS" >> android/key.properties
   echo "storeFile=$CM_KEYSTORE_PATH" >> android/key.properties
   ```

4. **Flutter build uses keystore**
   - Reads `android/key.properties`
   - Signs AAB with keystore

5. **Signed AAB generated**
   - Ready for Google Play Store upload

---

## Next Steps

After successful setup:
1. ✅ Build should complete without keystore errors
2. Download the signed AAB from build artifacts
3. Upload to Google Play Console
4. See [AAB_BUILD_GUIDE.md](AAB_BUILD_GUIDE.md) for deployment instructions

---

## Need Help?

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.

For Codemagic-specific help:
- [Codemagic Android Code Signing Docs](https://docs.codemagic.io/yaml-code-signing/signing-android/)
- [Codemagic Support](https://codemagic.io/contact/)
