# iOS Provisioning Profile Management Guide

A comprehensive guide to understanding, creating, and managing provisioning profiles for GUD Express iOS app.

## Table of Contents
1. [What are Provisioning Profiles?](#what-are-provisioning-profiles)
2. [Types of Provisioning Profiles](#types-of-provisioning-profiles)
3. [Creating Provisioning Profiles](#creating-provisioning-profiles)
4. [Managing Provisioning Profiles](#managing-provisioning-profiles)
5. [Troubleshooting](#troubleshooting)
6. [Best Practices](#best-practices)

---

## What are Provisioning Profiles?

Provisioning profiles are files that link:
- Your **development certificates** (who you are)
- Your **app's bundle ID** (what app)
- Your **device identifiers** (where it can run)

Think of it as a "permission slip" that allows your app to run on devices.

### Components

```
Provisioning Profile = Certificate + App ID + Device IDs + Entitlements
```

- **Certificate**: Proves your identity as a developer
- **App ID**: Identifies your app (`com.gudexpress.gud_app`)
- **Device IDs**: UDIDs of devices allowed to run the app
- **Entitlements**: Capabilities like push notifications, iCloud, etc.

---

## Types of Provisioning Profiles

### 1. Development Profile
- **Purpose**: Testing on physical devices during development
- **Distribution**: Can't be shared publicly
- **Device Limit**: Up to 100 devices
- **Duration**: 1 year (renewable)
- **Cost**: Free with Apple Developer account

**When to use:**
- Local development and testing
- Debugging on your devices
- Internal testing with team members

### 2. Ad Hoc Profile
- **Purpose**: Testing outside of development team
- **Distribution**: Can be shared with testers
- **Device Limit**: Up to 100 devices
- **Duration**: 1 year (renewable)
- **Cost**: Free with paid Apple Developer account

**When to use:**
- Beta testing with external testers
- Distributing test builds to clients
- Testing before App Store submission

### 3. App Store Profile
- **Purpose**: Submitting app to App Store
- **Distribution**: Through App Store only
- **Device Limit**: Unlimited (via App Store)
- **Duration**: 1 year (renewable)
- **Cost**: Requires paid Apple Developer account ($99/year)

**When to use:**
- Submitting to App Store Connect
- TestFlight distribution
- Production releases

### 4. Enterprise Profile
- **Purpose**: Internal enterprise distribution
- **Distribution**: Outside App Store (enterprise only)
- **Device Limit**: Unlimited
- **Duration**: 1 year (renewable)
- **Cost**: Requires Apple Developer Enterprise Program ($299/year)

**When to use:**
- Internal company app distribution
- Not applicable for public apps

---

## Creating Provisioning Profiles

### Prerequisites

Before creating profiles, you need:

1. ✅ **Apple Developer Account** (free or paid)
2. ✅ **Certificate** (Development or Distribution)
3. ✅ **Registered App ID** (`com.gudexpress.gud_app`)
4. ✅ **Device UDIDs** (for Development/Ad Hoc only)

### Method 1: Using Xcode (Automatic - Recommended for Development)

#### Step 1: Open Project
```bash
cd ios
open Runner.xcworkspace
```

#### Step 2: Configure Signing
1. Select **Runner** target in project navigator
2. Go to **Signing & Capabilities** tab
3. Check **✓ Automatically manage signing**
4. Select your **Team** from dropdown

#### Step 3: Xcode Creates Profile
- Xcode automatically:
  - Creates/downloads provisioning profile
  - Installs it on your Mac
  - Keeps it updated

**Pros:**
- ✅ Easiest method
- ✅ Automatic profile management
- ✅ No manual steps required

**Cons:**
- ❌ Less control over profile
- ❌ Not suitable for CI/CD

### Method 2: Using Apple Developer Portal (Manual - Recommended for CI/CD)

#### Step 1: Create Certificate

**For Development:**
1. Open **Keychain Access** on Mac
2. **Keychain Access** → **Certificate Assistant** → **Request a Certificate from a Certificate Authority**
3. Enter email and name
4. Select **Saved to disk**
5. Save the Certificate Signing Request (CSR)

**In Developer Portal:**
1. Go to [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/certificates)
2. Click **+** to add new certificate
3. Select **iOS App Development** (or **iOS Distribution** for App Store)
4. Upload your CSR file
5. Download the certificate (.cer file)
6. Double-click to install in Keychain

#### Step 2: Register App ID

1. Go to [Identifiers](https://developer.apple.com/account/resources/identifiers)
2. Click **+** to add new
3. Select **App IDs** → **App**
4. Fill in details:
   - **Description**: GUD Express
   - **Bundle ID**: Explicit - `com.gudexpress.gud_app`
5. Enable required capabilities:
   - ✅ Push Notifications
   - ✅ Background Modes
   - ✅ Sign in with Apple (if needed)
6. Click **Continue** and **Register**

#### Step 3: Register Devices (Development/Ad Hoc only)

**Find Device UDID:**
```bash
# Method 1: Using Xcode
# Window → Devices and Simulators → Select device → Identifier

# Method 2: Using system_profiler (macOS)
system_profiler SPUSBDataType | grep "Serial Number" -B 2

# Method 3: Using idevice_id (if installed)
idevice_id -l
```

**Register in Portal:**
1. Go to [Devices](https://developer.apple.com/account/resources/devices)
2. Click **+** to add new device
3. Enter:
   - **Device Name**: e.g., "John's iPhone 14"
   - **Device ID (UDID)**: Paste the UDID
4. Click **Continue** and **Register**

#### Step 4: Create Provisioning Profile

**For Development Profile:**
1. Go to [Profiles](https://developer.apple.com/account/resources/profiles)
2. Click **+** to create new
3. Select **iOS App Development**
4. Select App ID: `com.gudexpress.gud_app`
5. Select certificate(s) to include
6. Select devices to include
7. Name: `GUD Express Development`
8. Download the `.mobileprovision` file

**For App Store Profile:**
1. Select **App Store** under Distribution
2. Select App ID: `com.gudexpress.gud_app`
3. Select distribution certificate
4. Name: `GUD Express App Store`
5. Download the `.mobileprovision` file

#### Step 5: Install Profile

**Option A: Double-click**
- Simply double-click the `.mobileprovision` file

**Option B: Manual installation**
```bash
# Copy to provisioning profiles directory
cp GUD_Express_Development.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
```

**Option C: Xcode**
1. Open Xcode → **Preferences** → **Accounts**
2. Select your Apple ID
3. Click **Download Manual Profiles**

---

## Managing Provisioning Profiles

### View Installed Profiles

**Using Finder:**
```bash
open ~/Library/MobileDevice/Provisioning\ Profiles/
```

**Using Terminal:**
```bash
ls -la ~/Library/MobileDevice/Provisioning\ Profiles/
```

**Using Xcode:**
1. **Xcode** → **Preferences** → **Accounts**
2. Select Apple ID → **Manage Certificates**
3. View associated profiles

### View Profile Details

```bash
# Decode and view profile contents
security cms -D -i ~/Library/MobileDevice/Provisioning\ Profiles/PROFILE_UUID.mobileprovision
```

Look for:
- **Name**: Profile name
- **UUID**: Unique identifier
- **TeamIdentifier**: Your Team ID
- **AppIDName**: App identifier
- **ExpirationDate**: When it expires
- **ProvisionedDevices**: List of device UDIDs (if applicable)

### Update Profiles

**When to update:**
- ✅ Profile expired
- ✅ Added new devices
- ✅ Changed capabilities
- ✅ Renewed certificate

**How to update:**

**Automatic (Xcode):**
1. Open project in Xcode
2. Xcode will prompt to update automatically
3. Or: **Xcode** → **Preferences** → **Accounts** → **Download Manual Profiles**

**Manual (Developer Portal):**
1. Go to [Profiles](https://developer.apple.com/account/resources/profiles)
2. Select the profile
3. Click **Edit**
4. Update devices/certificates as needed
5. Click **Generate**
6. Download and install new profile

### Delete Profiles

**Remove from Mac:**
```bash
# Remove all profiles
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*

# Remove specific profile
rm ~/Library/MobileDevice/Provisioning\ Profiles/PROFILE_UUID.mobileprovision
```

**Remove from Developer Portal:**
1. Go to [Profiles](https://developer.apple.com/account/resources/profiles)
2. Select profile
3. Click **Delete** or **Edit** → **Delete**

---

## Troubleshooting

### Common Issues

#### 1. "No Provisioning Profile Found"

**Error:** `No profiles for 'com.gudexpress.gud_app' were found`

**Solutions:**

**A. Using Xcode (Automatic):**
```
1. Open ios/Runner.xcworkspace
2. Select Runner target → Signing & Capabilities
3. Enable "Automatically manage signing"
4. Select your Team
5. Xcode will create profile automatically
```

**B. Manual Download:**
```
1. Go to Apple Developer Portal
2. Download appropriate profile
3. Double-click to install
4. Rebuild project
```

#### 2. "Profile Doesn't Include Signing Certificate"

**Error:** `Profile doesn't include the selected signing certificate`

**Solution:**
```
1. Go to Apple Developer Portal → Profiles
2. Edit the profile
3. Select your certificate
4. Regenerate and download
5. Install new profile
```

#### 3. "Profile Has Expired"

**Error:** `The provisioning profile has expired`

**Solution:**
```bash
# Check expiration
security cms -D -i profile.mobileprovision | grep ExpirationDate

# Renew in Developer Portal:
1. Go to Profiles section
2. Select expired profile
3. Click Edit → Generate
4. Download and install new profile
```

#### 4. "Device Not Included in Profile"

**Error:** `This device is not included in the provisioning profile`

**Solution:**
```
1. Find device UDID (Window → Devices in Xcode)
2. Go to Developer Portal → Devices
3. Register the device
4. Edit provisioning profile
5. Add the device
6. Regenerate and download profile
```

#### 5. "Bundle ID Doesn't Match"

**Error:** `The app ID doesn't match the bundle identifier`

**Solution:**
```
1. Check bundle ID in Xcode: Runner target → General → Identity
2. Verify it's: com.gudexpress.gud_app
3. If different, update in Xcode
4. Or create new profile with correct bundle ID
```

### Debugging Commands

```bash
# List all profiles
ls -la ~/Library/MobileDevice/Provisioning\ Profiles/

# Check profile details
security cms -D -i profile.mobileprovision

# Check certificates
security find-identity -v -p codesigning

# Check keychain
security list-keychains

# Check default keychain
security default-keychain
```

---

## Best Practices

### For Development

1. ✅ **Use Automatic Signing**
   - Easiest for local development
   - Xcode manages everything
   - Less manual work

2. ✅ **Register All Team Devices**
   - Add all development devices upfront
   - Avoid repeated profile updates

3. ✅ **Keep Xcode Updated**
   - Latest Xcode handles profiles better
   - Better automatic signing support

### For CI/CD

1. ✅ **Use Manual Signing**
   - More control in CI/CD
   - Consistent across builds
   - See [IOS_BUILD_AND_DEPLOY_GUIDE.md](IOS_BUILD_AND_DEPLOY_GUIDE.md)

2. ✅ **Store as Base64**
   - Encode profiles for GitHub Secrets
   - Keep them secure
   - Never commit to repository

3. ✅ **Use App Store Connect API**
   - Better than app-specific passwords
   - No 2FA prompts in CI/CD
   - More reliable automation

### General

1. ✅ **Monitor Expiration**
   - Profiles expire after 1 year
   - Set reminders to renew
   - Update before expiration

2. ✅ **Document Team IDs**
   - Keep Team ID documented
   - Store securely for team access

3. ✅ **Backup Profiles**
   - Keep copies of profiles
   - Document configuration
   - Easier recovery if needed

4. ✅ **Separate Profiles**
   - Different profiles for dev/prod
   - Easier to manage
   - Better security

5. ✅ **Regular Cleanup**
   - Remove old/unused profiles
   - Reduces confusion
   - Better organization

---

## Quick Reference

### Profile Types Summary

| Type | Purpose | Device Limit | Duration | Cost |
|------|---------|--------------|----------|------|
| Development | Local testing | 100 | 1 year | Free |
| Ad Hoc | Beta testing | 100 | 1 year | $99/year |
| App Store | Production | Unlimited | 1 year | $99/year |
| Enterprise | Internal | Unlimited | 1 year | $299/year |

### File Locations

```
# Provisioning profiles
~/Library/MobileDevice/Provisioning Profiles/

# Certificates (Keychain)
Login Keychain → My Certificates

# Xcode Derived Data
~/Library/Developer/Xcode/DerivedData/
```

### Useful Commands

```bash
# View profiles
open ~/Library/MobileDevice/Provisioning\ Profiles/

# Check profile
security cms -D -i profile.mobileprovision

# Check certificates
security find-identity -v -p codesigning

# Get device UDID
system_profiler SPUSBDataType | grep "Serial Number" -B 2
```

---

## Additional Resources

### Documentation
- [Apple Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
- [App Distribution Guide](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)
- [Entitlements Documentation](https://developer.apple.com/documentation/bundleresources/entitlements)

### Tools
- [Apple Developer Portal](https://developer.apple.com/account)
- [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources)
- [Transporter App](https://apps.apple.com/app/transporter/id1450874784)

### Related Guides
- [IOS_LOCAL_BUILD_GUIDE.md](IOS_LOCAL_BUILD_GUIDE.md) - Local build instructions
- [IOS_BUILD_AND_DEPLOY_GUIDE.md](IOS_BUILD_AND_DEPLOY_GUIDE.md) - CI/CD setup
- [IOS_BUILD_QUICK_START.md](IOS_BUILD_QUICK_START.md) - Quick reference

---

**Last Updated**: 2024
**Version**: 1.0
**Maintained by**: GUD Express Team
