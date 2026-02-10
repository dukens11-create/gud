# Troubleshooting Guide: Keystore Setup

This guide covers common issues when setting up the Android keystore in Codemagic.

---

## Error: "No keystores with reference 'gud-release-key' were found"

### Symptoms
Build fails with error message:
```
No keystores with reference 'gud-release-key' were found from code signing identities.
```

### Root Cause
The keystore has not been uploaded to Codemagic, or the reference name doesn't match.

### Solutions

#### Solution 1: Verify Keystore Upload
1. Login to Codemagic
2. Navigate to: `Apps → gud → Settings → Code signing identities → Android`
3. Check if keystore is listed
4. If not listed → Upload keystore (see [CODEMAGIC_KEYSTORE_SETUP.md](CODEMAGIC_KEYSTORE_SETUP.md))

#### Solution 2: Verify Reference Name
The reference name **MUST** be exactly: `gud-release-key`

**Common mistakes:**
- ❌ `keystore` (missing prefix)
- ❌ `Gud-release-key` (wrong capitalization)
- ❌ `gud_keystore` (underscore instead of dash)
- ❌ `gud-release-key ` (trailing space)
- ✅ `gud-release-key` (correct!)

**How to fix:**
1. Go to Android code signing settings
2. Find the uploaded keystore
3. Click "Edit" or "Remove" and re-upload
4. Ensure reference name is exactly: `gud-release-key`

#### Solution 3: Check You're in App Settings, Not Team Settings
**Wrong location (don't use):**
```
Team settings → Code signing identities
```

**Correct location:**
```
Apps → gud → Settings → Code signing identities → Android
```

Always use app-specific settings!

---

## Can't Find Code Signing Settings in Codemagic

### Symptoms
Unable to locate "Code signing identities" section in Codemagic UI.

### Navigation Help

**Method 1: Step-by-step**
1. Login to [https://codemagic.io/](https://codemagic.io/)
2. Click on **"gud"** app from the apps list
3. Look for **"Settings"** in:
   - Left sidebar (vertical menu)
   - Top navigation bar
   - Or a gear icon ⚙️
4. In Settings, find **"Code signing identities"**
5. Click on **"Android"** tab

**Method 2: Direct Path**
```
Codemagic Dashboard
    → Applications (or "Apps")
    → gud (click the card/tile)
    → Settings (left menu or top bar)
    → Code signing identities (in settings list)
    → Android (tab at top)
```

**Method 3: URL Pattern**
If available, the URL should look like:
```
https://codemagic.io/app/{app-id}/settings/code-signing/android
```

### Still Can't Find It?

**Check your account permissions:**
- You need **Admin** or **Developer** role
- **Viewer** role cannot access code signing settings
- Contact repository owner to upgrade permissions

**Check app configuration:**
- App must be properly connected to repository
- App must have Android platform enabled
- Try refreshing the page or clearing browser cache

---

## Environment Variables Not Set

### Symptoms
Build fails with errors like:
```
key.properties not found
storePassword is null
```

### Root Cause
Environment variables are not being injected by Codemagic.

### Solutions

#### Solution 1: Verify `codemagic.yaml` Configuration
Check that `codemagic.yaml` contains:
```yaml
android_signing:
  - gud-release-key
```

This line tells Codemagic to inject environment variables for the keystore.

#### Solution 2: Verify Environment Variables in Script
The script should create `key.properties` like this:
```bash
echo "storePassword=$CM_KEYSTORE_PASSWORD" > android/key.properties
echo "keyPassword=$CM_KEY_PASSWORD" >> android/key.properties
echo "keyAlias=$CM_KEY_ALIAS" >> android/key.properties
echo "storeFile=$CM_KEYSTORE_PATH" >> android/key.properties
```

#### Solution 3: Check Build Logs
In Codemagic build logs, look for:
```
✅ Using keystore: gud-release-key
✅ Environment variables set
```

If missing, keystore wasn't found with that reference name.

---

## Reference Name Doesn't Match

### Symptoms
- Keystore uploaded but build still fails
- Build says "No keystores found"
- Environment variables not set

### Root Cause
Reference name in Codemagic doesn't match the name in `codemagic.yaml`.

### Solution
**What's in `codemagic.yaml`:**
```yaml
android_signing:
  - gud-release-key  ← This exact name
```

**What's in Codemagic UI:**
```
Reference name: gud-release-key  ← Must match exactly
```

**How to fix:**
1. Go to Android code signing settings
2. Check the reference name of your uploaded keystore
3. If it doesn't match, edit or delete and re-upload
4. Ensure reference name is: `gud-release-key`

---

## Build Still Failing After Keystore Setup

### Symptoms
Keystore uploaded correctly, but build still fails.

### Diagnostic Steps

#### Step 1: Check Build Logs
Look for specific error messages in Codemagic build logs:

**Good signs (keystore working):**
```
✅ Using keystore: gud-release-key
✅ Key properties set up successfully
🔧 Building Android App Bundle...
```

**Bad signs (keystore issues):**
```
❌ No keystores found
❌ storePassword is null
❌ Keystore file not found
```

#### Step 2: Verify Keystore Details
Common issues:
- **Wrong password**: Keystore password is incorrect
- **Wrong key alias**: Key alias doesn't match
- **Corrupted keystore**: Re-generate and re-upload

#### Step 3: Check Android Build Configuration
File: `android/app/build.gradle`

Should contain:
```gradle
signingConfigs {
    release {
        def keystoreProperties = new Properties()
        def keystorePropertiesFile = rootProject.file('key.properties')
        if (keystorePropertiesFile.exists()) {
            keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
        }
        
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile file(keystoreProperties['storeFile'])
        storePassword keystoreProperties['storePassword']
    }
}
```

#### Step 4: Manually Test Keystore Locally
Test if keystore is valid:
```bash
keytool -list -v -keystore gud-release-key.jks -alias gud_key
```

Enter the password when prompted. If successful, keystore is valid.

---

## Passwords Lost or Forgotten

### Symptoms
- Can't remember keystore password
- Need to update app but lost credentials

### Solutions

#### If in Development Phase
Generate a new keystore and start over:
```bash
./generate_keystore.sh
```

Re-upload to Codemagic with reference name `gud-release-key`.

**Note:** This creates a new keystore with different signature.

#### If Already Published to Google Play
**Bad news:** You **CANNOT** recover lost passwords.

**Options:**
1. **Change signing key** (Google Play supports this):
   - Generate new keystore
   - Upload to Google Play Console
   - Follow Google's key upgrade process
   - See: [Google Play - Update signing key](https://support.google.com/googleplay/android-developer/answer/9842756)

2. **Contact Google Play Support** (if no backup):
   - They may be able to help in specific cases
   - No guarantees

**Prevention:**
- Always backup keystores securely
- Use password manager
- Store in multiple secure locations

---

## Can't Find Settings Menu in Codemagic

### Symptoms
- Logged into Codemagic but can't find Settings
- UI looks different than described

### Solutions

#### Solution 1: Check App Selection
Make sure you've clicked on the **"gud"** app:
1. From dashboard, click the "gud" app card
2. You should now be inside the app's page
3. Settings will be available in left menu or top bar

#### Solution 2: Check Permissions
- Need admin/developer access to see Settings
- Contact repository owner if you only have viewer access

#### Solution 3: Try Different Browser
- Clear browser cache
- Try incognito/private mode
- Try different browser (Chrome, Firefox, Safari)

#### Solution 4: Codemagic UI Changed
If UI has changed significantly:
1. Look for gear icon ⚙️ (usually means Settings)
2. Check for "Configuration" or "Setup" instead of "Settings"
3. See latest Codemagic documentation: [https://docs.codemagic.io/](https://docs.codemagic.io/)

---

## Keystore File Upload Fails

### Symptoms
- Upload button doesn't work
- File upload errors
- "Invalid keystore" message

### Solutions

#### Solution 1: Check File Format
- Must be `.jks` or `.keystore` file
- Not a zip file
- Not a certificate file (.pem, .cert)
- Valid Java keystore format

#### Solution 2: Check File Size
- Must be under Codemagic's size limit (usually 2-5 MB)
- If too large, keystore may be corrupted

#### Solution 3: Re-generate Keystore
```bash
./generate_keystore.sh
```

#### Solution 4: Browser Issues
- Try different browser
- Disable browser extensions
- Check browser console for errors (F12)

---

## Build Succeeds But AAB Not Signed

### Symptoms
- Build completes without errors
- AAB file generated
- But AAB is not properly signed

### Solutions

#### Solution 1: Verify Signing Configuration
Check `android/app/build.gradle`:
```gradle
buildTypes {
    release {
        signingConfig signingConfigs.release  ← Must be present
        // other settings...
    }
}
```

#### Solution 2: Check Build Command
In `codemagic.yaml`, verify:
```bash
flutter build appbundle --release
```

Not:
```bash
flutter build appbundle --release --no-sign  ← Wrong!
```

#### Solution 3: Verify AAB Signature
Download AAB and check signature:
```bash
jarsigner -verify -verbose -certs app-release.aab
```

Should show:
```
jar verified.
```

---

## Multiple Apps Using Same Keystore

### Symptoms
Need to use same keystore for multiple apps.

### Solution

**Option 1: Team-level keystore (if available)**
Upload keystore to team settings instead of app settings.

**Option 2: Same reference name in multiple apps**
Upload the same keystore to each app with the same reference name.

**Option 3: Different reference names**
Use different reference names and update each app's `codemagic.yaml`:
```yaml
# App 1
android_signing:
  - app1_keystore

# App 2
android_signing:
  - app2_keystore
```

---

## Environment Variables in Logs

### Symptoms
Want to debug environment variables but can't see them.

### Solution

**⚠️ NEVER log passwords or keystore paths!**

But you can check if variables are set:
```bash
# In codemagic.yaml script
if [ -z "$CM_KEYSTORE_PASSWORD" ]; then
    echo "❌ CM_KEYSTORE_PASSWORD not set"
    exit 1
else
    echo "✅ CM_KEYSTORE_PASSWORD is set"
fi
```

Same for:
- `$CM_KEY_PASSWORD`
- `$CM_KEY_ALIAS`
- `$CM_KEYSTORE_PATH`

---

## Additional Resources

### Official Documentation
- [Codemagic Android Code Signing](https://docs.codemagic.io/yaml-code-signing/signing-android/)
- [Flutter Android Deployment](https://docs.flutter.dev/deployment/android)
- [Google Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)

### Related Guides
- [CODEMAGIC_KEYSTORE_SETUP.md](CODEMAGIC_KEYSTORE_SETUP.md) - Detailed setup instructions
- [QUICK_FIX_CHECKLIST.md](QUICK_FIX_CHECKLIST.md) - Quick checklist
- [AAB_BUILD_GUIDE.md](AAB_BUILD_GUIDE.md) - Android deployment guide

---

## Still Need Help?

If you've tried everything and still have issues:

1. **Check Codemagic build logs** for specific error messages
2. **Search Codemagic documentation** for your specific error
3. **Contact Codemagic support**: [https://codemagic.io/contact/](https://codemagic.io/contact/)
4. **Check repository issues**: Look for similar problems in GitHub issues

---

## Common Error Messages Reference

| Error Message | Likely Cause | Solution |
|---------------|--------------|----------|
| No keystores with reference 'gud-release-key' found | Keystore not uploaded or wrong reference name | Upload keystore with exact name `gud-release-key` |
| storePassword is null | Environment variables not set | Verify `android_signing` in codemagic.yaml |
| Keystore file not found | Wrong keystore path | Check `$CM_KEYSTORE_PATH` is used |
| Invalid keystore format | Corrupted or wrong file | Re-generate keystore |
| Wrong password | Incorrect password in Codemagic | Re-enter correct password |
| Key alias not found | Wrong alias name | Check alias matches keystore |
| Keystore was tampered with | Corrupted keystore | Use backup or generate new |

---

**Last Updated:** 2026-02-09  
**Related to:** Codemagic Android code signing setup
