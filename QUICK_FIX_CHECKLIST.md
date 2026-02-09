# Quick Fix Checklist: Keystore Setup

Use this checklist to quickly fix the build error:
```
No keystores with reference 'gud_keystore' were found
```

---

## ⚡ Quick Fix Steps

### ☐ Step 1: Generate Keystore
Run the provided script to generate a keystore:
```bash
./generate_keystore.sh
```

Or manually:
```bash
keytool -genkey -v -keystore gud_keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias gud_key
```

**Save these securely:**
- Keystore password: `_______________`
- Key password: `_______________`
- Key alias: `gud_key`

---

### ☐ Step 2: Login to Codemagic
Go to: [https://codemagic.io/](https://codemagic.io/)

---

### ☐ Step 3: Open "gud" App
From dashboard → Click **"gud"** app card

---

### ☐ Step 4: Navigate to Settings
In left sidebar or top menu → Click **"Settings"**

---

### ☐ Step 5: Find Code Signing Identities
Settings page → Click **"Code signing identities"**

---

### ☐ Step 6: Go to Android Tab
Click **"Android"** tab

---

### ☐ Step 7: Upload Keystore
1. Click **"Add keystore"** button
2. Fill in the form:
   - **Keystore file**: Select `gud_keystore.jks`
   - **Reference name**: Type exactly `gud_keystore` ⚠️ CRITICAL
   - **Keystore password**: Enter password from Step 1
   - **Key alias**: Enter `gud_key`
   - **Key password**: Enter password from Step 1
3. Click **"Save"**

**Reference name MUST be exactly:** `gud_keystore`

---

### ☐ Step 8: Verify Upload
Confirm keystore appears in list:
- Reference name: `gud_keystore` ✓
- Status: Active/Green checkmark ✓

---

### ☐ Step 9: Trigger New Build
1. Return to app overview
2. Click **"Start new build"**
3. Select **"android-aab"** workflow
4. Click **"Start build"**

---

### ☐ Step 10: Verify Build Succeeds
Monitor build logs:
- ✅ "Key properties set up successfully"
- ✅ "Building Android App Bundle"
- ✅ "AAB build successful"
- ✅ Build status: Passed

---

## 🎯 Expected Result

**Before fix:**
```
❌ Error: No keystores with reference 'gud_keystore' were found
```

**After fix:**
```
✅ Using keystore: gud_keystore
✅ AAB build successful
✅ Artifact: app-release.aab
```

---

## 📊 Progress Tracker

Fill in after each step:

| Step | Status | Notes |
|------|--------|-------|
| 1. Generate keystore | ☐ | |
| 2. Login to Codemagic | ☐ | |
| 3. Open "gud" app | ☐ | |
| 4. Navigate to Settings | ☐ | |
| 5. Find Code signing | ☐ | |
| 6. Android tab | ☐ | |
| 7. Upload keystore | ☐ | |
| 8. Verify upload | ☐ | |
| 9. Trigger build | ☐ | |
| 10. Verify success | ☐ | |

---

## ⚠️ Common Mistakes to Avoid

1. ❌ Wrong reference name (e.g., `keystore` instead of `gud_keystore`)
2. ❌ Uploading to team settings instead of app settings
3. ❌ Typo in reference name (case-sensitive!)
4. ❌ Forgetting to save passwords
5. ❌ Using iOS tab instead of Android tab

---

## 🔗 Detailed Guides

Need more help? See:
- [CODEMAGIC_KEYSTORE_SETUP.md](CODEMAGIC_KEYSTORE_SETUP.md) - Detailed setup guide with screenshots descriptions
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions

---

## 🆘 Still Having Issues?

If build still fails after following all steps:
1. Check reference name is exactly: `gud_keystore`
2. Verify all passwords are correct
3. Check build logs for specific error
4. See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

## ✅ Success Indicators

You'll know it worked when:
- ✅ Build completes without keystore errors
- ✅ AAB file is generated in artifacts
- ✅ Build logs show "AAB build successful"
- ✅ Can download signed AAB from Codemagic
