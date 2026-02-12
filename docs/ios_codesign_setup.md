# iOS Code Signing Setup Guide

This guide explains how to configure iOS code signing for the GUD Express Flutter app. Code signing is required by Apple to build and deploy iOS apps to real devices.

## ⚠️ Important Security Notice

**DO NOT commit the following to source control:**
- Apple Developer credentials or passwords
- Provisioning profiles (`.mobileprovision` files)
- Private keys (`.p12` or `.p8` files)
- Code signing certificates
- App Store Connect API keys

These are sensitive credentials that must be kept secure and configured individually by each developer and CI/CD system.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Opening the Project in Xcode](#opening-the-project-in-xcode)
3. [Setting Up Your Development Team](#setting-up-your-development-team)
4. [Understanding Bundle IDs](#understanding-bundle-ids)
5. [Logging into Xcode with Your Apple ID](#logging-into-xcode-with-your-apple-id)
6. [Device Registration](#device-registration)
7. [Automatic vs Manual Signing](#automatic-vs-manual-signing)
8. [Troubleshooting](#troubleshooting)
9. [CI/CD Automation](#cicd-automation)

---

## Prerequisites

Before you begin, ensure you have:

- **macOS** with Xcode installed (Xcode 14.0 or later recommended)
- **Flutter SDK** installed and configured
- **Apple ID** - You can use a free Apple ID for testing, but a paid Apple Developer Program membership ($99/year) is required for App Store distribution
- **GUD Express project** cloned to your local machine

### Check Your Setup

```bash
# Verify Xcode is installed
xcode-select --version

# Verify Flutter is installed
flutter doctor

# Navigate to project directory
cd /path/to/gud
```

---

## Opening the Project in Xcode

**Important:** Always open the workspace file, not the project file directly.

### Step 1: Open the Workspace

```bash
cd ios
open Runner.xcworkspace
```

Or from Xcode:
1. Launch Xcode
2. Select **File → Open**
3. Navigate to your project's `ios/` directory
4. Select `Runner.xcworkspace` (not `Runner.xcodeproj`)
5. Click **Open**

### Why Use the Workspace?

The workspace (`.xcworkspace`) includes CocoaPods dependencies and proper configuration. Opening the project file (`.xcodeproj`) directly will result in build errors due to missing dependencies.

---

## Setting Up Your Development Team

### Step 1: Select the Runner Target

1. In Xcode's Project Navigator (left sidebar), click on the **Runner** project (blue icon at the top)
2. In the main editor area, select the **Runner** target under **TARGETS**
3. Click the **Signing & Capabilities** tab at the top

### Step 2: Enable Automatic Signing

1. Check the box for **✓ Automatically manage signing**
2. From the **Team** dropdown, select your Development Team
   - If no team appears, you need to add your Apple ID first (see next section)

### Step 3: Verify Signing Status

Once configured, you should see:
- ✅ **Signing Certificate**: Apple Development
- ✅ **Provisioning Profile**: Xcode Managed Profile

If you see any errors or warnings, refer to the [Troubleshooting](#troubleshooting) section.

---

## Understanding Bundle IDs

### What is a Bundle ID?

A Bundle ID (also called Bundle Identifier) is a unique identifier for your iOS app. It follows reverse-domain notation, such as:
- `com.gudexpress.app`
- `com.yourcompany.gudexpress`

### Why Bundle IDs Must Be Unique

- Apple requires each app to have a globally unique Bundle ID
- Your Bundle ID cannot conflict with apps already registered by other developers
- If building for App Store, you must use a Bundle ID that you control

### Viewing Your Current Bundle ID

In Xcode:
1. Select **Runner** target → **Signing & Capabilities**
2. Look for **Bundle Identifier** field
3. Default: `com.gudexpress.app`

### Changing the Bundle ID (If Needed)

If the default Bundle ID is taken or you need a custom one:

1. In Xcode, go to **Runner** target → **General** tab
2. Under **Identity**, change the **Bundle Identifier** field
3. Use your own domain in reverse notation (e.g., `com.yourcompany.gudexpress`)
4. The Bundle ID must:
   - Be unique across all Apple apps
   - Contain only alphanumeric characters, hyphens, and periods
   - Not start with a number

**Note:** Changing the Bundle ID requires updating it in multiple places. Consider using the default unless necessary.

---

## Logging into Xcode with Your Apple ID

### Step 1: Open Xcode Preferences

1. Open Xcode
2. Go to **Xcode → Preferences** (or press `Cmd + ,`)
3. Click the **Accounts** tab

### Step 2: Add Your Apple ID

1. Click the **+** button in the bottom-left corner
2. Select **Apple ID**
3. Click **Continue**
4. Enter your Apple ID email and password
5. Complete two-factor authentication if prompted
6. Click **Next**

### Step 3: Verify Your Account

Once logged in, you should see:
- Your Apple ID email address
- Associated teams (if you're part of the Apple Developer Program)
- Account type (Personal Team or Developer Team)

### Account Types

#### Free Apple ID (Personal Team)
- Can build and test on your own devices
- Limited to 3 devices
- Certificates valid for 7 days
- Cannot distribute to App Store or TestFlight

#### Apple Developer Program ($99/year)
- Unlimited device registrations
- Certificates valid for 1 year
- Can distribute via App Store and TestFlight
- Access to advanced capabilities

---

## Device Registration

### Registering Your iOS Device

To test on a physical device, it must be registered with your Apple Developer account.

### Step 1: Connect Your Device

1. Connect your iPhone or iPad to your Mac via USB
2. Trust the computer on your device when prompted
3. Enter your device passcode

### Step 2: Register via Xcode

1. In Xcode, go to **Window → Devices and Simulators** (or press `Cmd + Shift + 2`)
2. Select your device from the left sidebar
3. Xcode will automatically register it with your team
4. Wait for the registration to complete (usually a few seconds)

### Verification

Your device should now show:
- Connected status
- Device name and model
- iOS version
- UDID (Unique Device Identifier)

---

## Automatic vs Manual Signing

### Automatic Signing (Recommended)

**Pros:**
- ✅ Easiest to set up
- ✅ Xcode handles certificates and profiles automatically
- ✅ Good for development and testing
- ✅ Automatically renews expiring profiles

**Setup:**
1. Go to **Runner** target → **Signing & Capabilities**
2. Check **✓ Automatically manage signing**
3. Select your Team
4. Xcode handles the rest

### Manual Signing

**Pros:**
- ✅ Full control over certificates and profiles
- ✅ Required for CI/CD systems
- ✅ Can use distribution profiles for App Store builds
- ✅ Better for team environments

**Cons:**
- ⚠️ More complex setup
- ⚠️ Must manually manage certificate expiration
- ⚠️ Requires understanding of provisioning profiles

**Setup:**
1. Uncheck **Automatically manage signing**
2. Select a **Provisioning Profile** from dropdown
3. Ensure your signing certificate is installed in Keychain
4. Select appropriate profiles for Debug and Release configurations

**When to Use Manual Signing:**
- CI/CD pipelines (GitHub Actions, Codemagic, etc.)
- Enterprise distribution
- When you need specific provisioning profiles
- Multi-developer teams sharing profiles

---

## Troubleshooting

### Problem: "No Signing Certificate Found"

**Solution:**
1. Go to **Xcode → Preferences → Accounts**
2. Select your Apple ID
3. Click **Manage Certificates...**
4. Click the **+** button and select **Apple Development**
5. Close the dialog and try building again

### Problem: "No Team Found"

**Symptoms:**
- Team dropdown is empty
- Cannot select a development team

**Solution:**
1. Verify you're logged into Xcode with your Apple ID
2. Go to **Xcode → Preferences → Accounts**
3. Click **+** to add your Apple ID if not present
4. Wait a few seconds for teams to load
5. Restart Xcode if teams still don't appear

### Problem: "Device Not Registered"

**Symptoms:**
- Error when trying to build to device
- "The device is not registered in your account"

**Solution:**
1. Connect device via USB
2. Go to **Window → Devices and Simulators**
3. Select your device
4. Wait for automatic registration
5. If using a free account, ensure you haven't exceeded the 3-device limit

### Problem: "Bundle ID Already in Use"

**Symptoms:**
- "Failed to register bundle identifier"
- "Bundle ID is not available"

**Solution:**
1. Go to **Runner** target → **General** tab
2. Change the **Bundle Identifier** to something unique
3. Use your own domain (e.g., `com.yourcompany.gudexpress`)
4. Try building again

### Problem: "Provisioning Profile Expired"

**Symptoms:**
- "Provisioning profile expired"
- Build fails with signing error

**Solution:**

For **Automatic Signing:**
1. Go to **Signing & Capabilities**
2. Xcode should auto-renew the profile
3. If not, try unchecking and rechecking "Automatically manage signing"

For **Manual Signing:**
1. Download a new provisioning profile from [Apple Developer Portal](https://developer.apple.com/account)
2. Double-click to install
3. Select it in Xcode

### Problem: "Code Signing Entitlements Error"

**Symptoms:**
- "Runner does not support the Wireless Accessory Configuration capability"
- Capability errors

**Solution:**
1. Go to **Signing & Capabilities** tab
2. Remove any capabilities you don't need
3. Ensure your Apple Developer account supports required capabilities
4. For paid features, verify your developer program membership is active

### Problem: Building Works in Xcode but Fails via Flutter Command

**Solution:**
```bash
# Clean Flutter build cache
flutter clean

# Clean iOS build folder
cd ios
rm -rf Pods Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData

# Reinstall dependencies
cd ..
flutter pub get
cd ios
pod install

# Try building again
flutter build ios
```

### Problem: "Untrusted Developer" on Device

**Symptoms:**
- App installs but won't launch
- "Untrusted Developer" warning on device

**Solution:**
1. On your iOS device, go to **Settings → General → VPN & Device Management**
2. Find your developer account under **Developer App**
3. Tap **Trust "Your Name"**
4. Tap **Trust** again to confirm
5. Launch the app again

---

## CI/CD Automation

### Important Considerations for CI/CD

Building iOS apps in automated pipelines (GitHub Actions, GitLab CI, Codemagic, etc.) requires special setup because:

1. **No Interactive Xcode UI**: CI systems cannot use Xcode's interactive signing features
2. **Credentials as Secrets**: All signing assets must be stored as encrypted secrets
3. **Manual Signing Required**: Automatic signing doesn't work in CI environments
4. **Certificate Management**: Certificates and profiles must be installed programmatically

### What CI/CD Systems Need

To build iOS apps, your CI/CD system needs:

1. **Apple Developer Certificates**
   - Distribution certificate (for App Store)
   - Development certificate (for testing)
   - Private key (`.p12` file with password)

2. **Provisioning Profiles**
   - Distribution profile (for App Store)
   - Development profile (for ad-hoc testing)

3. **App Store Connect API Key** (optional, for uploads)
   - Key ID
   - Issuer ID
   - Private key (`.p8` file)

4. **Keychain Setup**
   - CI must create a temporary keychain
   - Install certificates in the keychain
   - Install provisioning profiles

### Setting Up Secrets

**Never commit these to your repository!** Instead:

1. Encode certificates as Base64:
   ```bash
   base64 -i certificate.p12 > certificate_base64.txt
   ```

2. Add to CI secrets (GitHub Actions example):
   - Go to **Repository → Settings → Secrets and variables → Actions**
   - Add secrets:
     - `IOS_CERTIFICATE_BASE64` - Base64-encoded .p12 file
     - `IOS_CERTIFICATE_PASSWORD` - Password for .p12 file
     - `IOS_PROVISION_PROFILE_BASE64` - Base64-encoded .mobileprovision
     - `APPLE_KEY_ID` - App Store Connect API Key ID
     - `APPLE_ISSUER_ID` - App Store Connect Issuer ID
     - `APPLE_KEY_CONTENT` - App Store Connect API private key content

3. In your workflow, decode and install:
   ```yaml
   - name: Install certificates
     run: |
       # Decode certificate
       echo "${{ secrets.IOS_CERTIFICATE_BASE64 }}" | base64 --decode > certificate.p12
       
       # Create keychain
       security create-keychain -p actions build.keychain
       security import certificate.p12 -k build.keychain -P "${{ secrets.IOS_CERTIFICATE_PASSWORD }}"
       
       # Install provisioning profile
       mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
       echo "${{ secrets.IOS_PROVISION_PROFILE_BASE64 }}" | base64 --decode > profile.mobileprovision
       cp profile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
   ```

### Security Best Practices for CI/CD

1. **Use temporary keychains** - Create and delete keychains per build
2. **Rotate API keys regularly** - At least once per year
3. **Use minimal permissions** - API keys should have only necessary access
4. **Enable audit logs** - Monitor certificate and key usage
5. **Clean up after builds** - Delete certificates and profiles from CI agents
6. **Use repository secrets** - Never log secrets in build output
7. **Restrict secret access** - Limit who can view/edit secrets

### Alternative CI/CD Approaches

1. **Fastlane Match**
   - Stores certificates in encrypted Git repository
   - Team members share same certificates
   - Automatic syncing and renewal

2. **Manual Certificate Distribution**
   - Administrator creates certificates
   - Securely distributes to team and CI
   - Requires periodic manual updates

3. **Cloud Build Services**
   - Codemagic, Bitrise, App Center
   - Provide managed signing workflows
   - Often simpler than self-hosted CI

### Recommended Reading

For comprehensive CI/CD setup, see:
- [IOS_BUILD_AND_DEPLOY_GUIDE.md](../IOS_BUILD_AND_DEPLOY_GUIDE.md) - Complete CI/CD guide
- [IOS_BUILD_QUICK_START.md](../IOS_BUILD_QUICK_START.md) - Quick reference
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Fastlane Documentation](https://docs.fastlane.tools/)

---

## Quick Reference

### Essential Commands

```bash
# Open workspace in Xcode
cd ios && open Runner.xcworkspace

# Build for simulator (no signing required)
flutter build ios --simulator

# Build for device (requires signing)
flutter build ios

# Run on connected device
flutter run -d <device-id>

# List available devices
flutter devices

# Clean build
flutter clean
cd ios && rm -rf Pods Podfile.lock && cd .. && flutter pub get && cd ios && pod install
```

### Key File Locations

| File/Directory | Purpose |
|---------------|---------|
| `ios/Runner.xcworkspace` | Xcode workspace (always use this) |
| `ios/Runner.xcodeproj` | Xcode project (don't open directly) |
| `ios/Runner/Info.plist` | App configuration and capabilities |
| `ios/Podfile` | CocoaPods dependencies |
| `~/Library/MobileDevice/Provisioning Profiles/` | Installed provisioning profiles |
| `~/Library/Keychains/` | macOS keychains with certificates |

### Useful Xcode Shortcuts

- `Cmd + B` - Build
- `Cmd + R` - Run
- `Cmd + .` - Stop
- `Cmd + Shift + K` - Clean build folder
- `Cmd + Shift + 2` - Devices and Simulators
- `Cmd + ,` - Preferences

---

## Additional Resources

### Official Documentation
- [Apple Developer Program](https://developer.apple.com/programs/)
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [Xcode Help](https://help.apple.com/xcode/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)

### GUD Express Documentation
- [iOS Code Signing Quick Setup](../IOS_CODE_SIGNING_QUICK_SETUP.md) - 5-minute setup
- [iOS Local Build Guide](../IOS_LOCAL_BUILD_GUIDE.md) - Complete local development
- [iOS Provisioning Guide](../IOS_PROVISIONING_GUIDE.md) - Advanced provisioning

### Community Support
- [Apple Developer Forums](https://developer.apple.com/forums/)
- [Flutter Discord](https://discord.gg/flutter)
- [Stack Overflow - iOS](https://stackoverflow.com/questions/tagged/ios)

---

## Summary Checklist

Before you start developing:

- [ ] Xcode is installed and up to date
- [ ] Logged into Xcode with Apple ID
- [ ] Opened `ios/Runner.xcworkspace` (not .xcodeproj)
- [ ] Selected Development Team in Signing & Capabilities
- [ ] Enabled automatic signing
- [ ] Verified signing shows green checkmarks
- [ ] Device registered (if building for device)
- [ ] Bundle ID is unique and valid
- [ ] Successfully built for simulator or device

Once complete, you're ready to develop and test on iOS! 🚀

---

**Security Reminder:** Never commit certificates, profiles, passwords, or API keys to source control. Always use encrypted secrets for CI/CD systems.

**Last Updated:** February 2024  
**Version:** 1.0
