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

This section provides detailed visual guidance for configuring code signing in Xcode.

### Step 1: Select the Runner Target

**Visual Guide:**

1. **Open Xcode** and ensure you've opened `Runner.xcworkspace` (not `.xcodeproj`)
   
2. **Project Navigator (Left Sidebar)**:
   - Look for the left sidebar with a folder icon at the top
   - You'll see a blue "Runner" icon at the very top
   - Click on this blue Runner icon
   
3. **Main Editor Area (Center)**:
   - After clicking Runner in the sidebar, the main area shows project settings
   - You'll see two sections: PROJECT and TARGETS
   - Under TARGETS, click on "Runner" (should have an app icon)
   - You should now see several tabs: General, Signing & Capabilities, Resource Tags, Info, Build Settings, Build Phases, Build Rules
   
4. **Signing & Capabilities Tab**:
   - Click the "Signing & Capabilities" tab (second tab)
   - This tab has two main sections:
     - **Signing (Debug)** - for development builds
     - **Signing (Release)** - for production builds

**What You Should See:**
- Top of the screen: Tabs starting with "General", "Signing & Capabilities"...
- Main area: "Signing & Capabilities" header with Debug/Release configuration selector
- A checkbox labeled "Automatically manage signing"
- A "Team" dropdown menu
- Status indicators for Signing Certificate and Provisioning Profile

---

### Step 2: Enable Automatic Signing

**Visual Guide:**

1. **Locate the Checkbox**:
   - In the Signing (Debug) section, find the checkbox labeled "Automatically manage signing"
   - It's near the top of the signing configuration

2. **Enable Automatic Signing**:
   - Click the checkbox to enable it (check mark should appear: ✓)
   - Xcode may prompt you to select a team if not already configured

3. **Select Your Team**:
   - Below the checkbox, find the "Team" dropdown menu
   - Click the dropdown to see available teams
   - **What you'll see in the dropdown**:
     - Your Personal Team (if using free Apple ID): Shows as "Your Name (Personal Team)"
     - Developer Program Team (if enrolled): Shows as "Organization Name" or your name with Team ID
     - "Add an Account..." option at the bottom
   
4. **If No Team Appears**:
   - Select "Add an Account..." from the dropdown
   - This opens Xcode Preferences → Accounts
   - See [Logging into Xcode with Your Apple ID](#logging-into-xcode-with-your-apple-id) section below

**Important Notes:**
- The "Team" dropdown only appears when "Automatically manage signing" is enabled
- Different teams may have different capabilities and restrictions
- Personal Teams have limitations (3 device limit, 7-day certificate validity)

---

### Step 3: Verify Signing Status

**Visual Guide:**

Once you've selected a team, Xcode automatically configures code signing. Look for these indicators:

1. **Success Indicators** (What you want to see):
   
   **Signing (Debug) section:**
   - ✅ Green checkmark or no error icon
   - **Signing Certificate**: Shows "Apple Development" with your name
     - Example: "Apple Development: john@example.com (ABC123XYZ)"
   - **Provisioning Profile**: Shows "iOS Team Provisioning Profile: com.gudexpress.app"
     - Or: "Xcode Managed Profile"
   - **Bundle Identifier**: Shows "com.gudexpress.app" (or your custom ID)
   
   **Signing (Release) section:**
   - Should show similar information
   - May show "Apple Development" or "Apple Distribution" depending on configuration

2. **Warning/Error Indicators** (What requires attention):
   
   ⚠️ **Yellow Triangle Warning**:
   - Usually appears with a message like "Provisioning profile doesn't include signing certificate"
   - **Fix**: Wait a few seconds for Xcode to download/create profiles automatically
   - If persists, try unchecking and rechecking "Automatically manage signing"
   
   ❌ **Red Error Icon**:
   - Common messages:
     - "No signing certificate found"
     - "Failed to register bundle identifier"
     - "No profiles for 'bundle.id' were found"
   - **Fix**: See [Troubleshooting](#troubleshooting) section for specific error solutions
   
   📱 **"Signing for 'Runner' requires a development team"**:
   - Means no team is selected
   - **Fix**: Select a team from the dropdown

3. **Visual Differences Between Automatic and Manual Signing**:
   
   **Automatic Signing** (Checkbox enabled):
   - Xcode manages everything
   - "Team" dropdown is active
   - Provisioning Profile shows "Xcode Managed Profile"
   - You cannot manually select profiles
   
   **Manual Signing** (Checkbox disabled):
   - You control certificate and profile selection
   - Additional dropdowns appear:
     - "Provisioning Profile" dropdown (Debug)
     - "Provisioning Profile" dropdown (Release)
   - You must manually download and select profiles
   - More complex but offers more control

**Recommendation**: Use Automatic Signing for local development. Manual signing is typically only needed for CI/CD systems.

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

This section provides solutions to common iOS code signing issues. If you don't find your issue here, see [Additional Resources](#additional-resources) for more help.

---

### Problem: "No Signing Certificate Found"

**Symptoms:**
- Cannot select a certificate in Signing & Capabilities
- Error: "No signing certificate found"

**Solution:**
1. Go to **Xcode → Preferences → Accounts**
2. Select your Apple ID
3. Click **Manage Certificates...**
4. Click the **+** button and select **Apple Development**
5. Close the dialog and try building again

**Alternative Solution:**
```bash
# Regenerate certificates via command line
cd ios
rm -rf ~/Library/Developer/Xcode/DerivedData
xcodebuild -workspace Runner.xcworkspace -scheme Runner clean
```

---

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

**Symptoms:**
- `flutter build ios` fails but building in Xcode succeeds
- Command-line build shows signing errors

**Solution:**
```bash
# Clean Flutter build cache
flutter clean

# Clean iOS build folder and caches
cd ios
rm -rf Pods Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData

# Reinstall dependencies
cd ..
flutter pub get
cd ios
pod install

# Try building again
cd ..
flutter build ios
```

**Additional Tips:**
- Ensure you're using the same development team in both Xcode and command-line builds
- Check that provisioning profiles are properly installed
- Try building in Xcode first to ensure code signing is working

### Problem: "Team Not Found in Keychain" or "No Profiles Found"

**Symptoms:**
- Error about missing provisioning profile
- "No profiles for 'com.gudexpress.app' were found"

**Solution 1 - Automatic Signing (Recommended):**
1. In Xcode, go to Signing & Capabilities
2. Check "Automatically manage signing"
3. Select your team from dropdown
4. Xcode will download/create profiles automatically

**Solution 2 - Manual Profile Download:**
1. Go to https://developer.apple.com/account
2. Navigate to Certificates, Identifiers & Profiles
3. Download the provisioning profile for your app
4. Double-click to install it
5. In Xcode, select it under Signing & Capabilities

### Problem: "Signing for 'Runner' requires a development team"

**Symptoms:**
- Build fails with message about requiring development team
- No team is selected in Xcode

**Quick Fix:**
```bash
# Run the configure script
./scripts/configure_team.sh
```

**Manual Fix:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target
3. Go to Signing & Capabilities
4. Select a team from the Team dropdown
5. Enable automatic signing if not already enabled

### Problem: Multiple Matching Certificates/Profiles

**Symptoms:**
- Multiple certificates with same name
- "Ambiguous certificate" warning
- Build chooses wrong certificate

**Solution:**
1. In Xcode, go to Preferences → Accounts
2. Select your Apple ID → Manage Certificates
3. Delete old/expired certificates (keep only one valid Apple Development)
4. In Finder, go to `~/Library/MobileDevice/Provisioning Profiles/`
5. Delete all `.mobileprovision` files
6. In Xcode, Signing & Capabilities, uncheck/recheck automatic signing
7. Xcode will download fresh profiles

### Problem: "The app ID cannot be registered to your development team"

**Symptoms:**
- Bundle ID error when enabling automatic signing
- "App ID is not available" message

**Solution:**
The Bundle ID is already registered to another team or account.

**Option 1 - Change Bundle ID (Recommended for Testing):**
1. In Xcode, select Runner target → General tab
2. Change Bundle Identifier to something unique:
   - `com.yourname.gudexpress`
   - `com.yourcompany.gud`
3. Save and try signing again

**Option 2 - Use Correct Team:**
1. Ensure you're logged into the Apple ID that owns the Bundle ID
2. Select the correct team in Signing & Capabilities

### Problem: Build Fails with "Exit Code 65"

**Symptoms:**
- Build fails with generic "exit code 65"
- No clear error message

**Solution:**
```bash
# Clean everything
flutter clean
cd ios
rm -rf Pods/ Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData
pod cache clean --all

# Reinstall
cd ..
flutter pub get
cd ios
pod install --repo-update

# Build with verbose output
cd ..
flutter build ios --verbose
```

**Check for:**
- Outdated CocoaPods dependencies
- Conflicting Xcode versions
- Insufficient disk space

### Problem: "Trust This Computer" Dialog Loops

**Symptoms:**
- Device keeps asking to "Trust This Computer"
- Cannot deploy to device

**Solution:**
1. Disconnect device
2. On device: Settings → General → Reset → Reset Location & Privacy
3. Restart both Mac and iOS device
4. Reconnect device and trust computer


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

#### 1. Fastlane Match
- Stores certificates in encrypted Git repository
- Team members share same certificates
- Automatic syncing and renewal

**Setup:**
```bash
# Install fastlane
sudo gem install fastlane

# Initialize match
cd ios
fastlane match init

# Generate certificates (first time)
fastlane match development
fastlane match appstore

# In CI, sync certificates
fastlane match development readonly:true
```

**Pros:**
- ✅ Team-wide certificate sharing
- ✅ Automatic certificate renewal
- ✅ Version controlled (encrypted)
- ✅ Works with CI/CD systems

**Cons:**
- ⚠️ Requires separate Git repository
- ⚠️ All team members must use same certificates

#### 2. Manual Certificate Distribution
- Administrator creates certificates
- Securely distributes to team and CI
- Requires periodic manual updates

**Best for:**
- Small teams
- Infrequent releases
- Tight security requirements

#### 3. Cloud Build Services

##### Codemagic
Streamlined Flutter CI/CD with managed iOS signing.

**Setup Steps:**
1. Connect your repository to Codemagic
2. In app settings, navigate to **Code signing identities**
3. Upload your certificate (.p12) and password
4. Upload provisioning profile (.mobileprovision)
5. Codemagic automatically handles keychain setup

**Configuration (codemagic.yaml):**
```yaml
workflows:
  ios-workflow:
    environment:
      groups:
        - ios_signing
      vars:
        BUNDLE_ID: "com.gudexpress.app"
    scripts:
      - name: Install dependencies
        script: flutter pub get
      - name: Build iOS
        script: |
          flutter build ipa --release \
            --export-options-plist=ios/ExportOptions.plist
    artifacts:
      - build/ios/ipa/*.ipa
```

**Pros:**
- ✅ Managed code signing
- ✅ Flutter-optimized
- ✅ Automatic TestFlight upload
- ✅ Easy team onboarding

**Docs:** https://docs.codemagic.io/flutter-code-signing/ios-code-signing/

##### GitHub Actions
Self-hosted CI/CD with full control.

**Our Implementation:**
- See `.github/workflows/build-ios.yml` in this repository
- Automated builds on tags and releases
- Uses repository secrets for signing materials
- Optional TestFlight deployment

**Key Workflow Steps:**
```yaml
- name: Setup code signing
  run: |
    # Decode and install certificate
    echo "${{ secrets.IOS_CERTIFICATE_BASE64 }}" | base64 --decode > cert.p12
    
    # Create keychain
    security create-keychain -p "${{ secrets.KEYCHAIN_PASSWORD }}" build.keychain
    security default-keychain -s build.keychain
    security unlock-keychain -p "${{ secrets.KEYCHAIN_PASSWORD }}" build.keychain
    security set-keychain-settings -t 3600 -u build.keychain
    
    # Import certificate
    security import cert.p12 -k build.keychain -P "${{ secrets.IOS_CERTIFICATE_PASSWORD }}" -T /usr/bin/codesign
    security set-key-partition-list -S apple-tool:,apple: -s -k "${{ secrets.KEYCHAIN_PASSWORD }}" build.keychain
    
    # Install provisioning profile
    mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
    echo "${{ secrets.IOS_PROVISION_PROFILE_BASE64 }}" | base64 --decode > profile.mobileprovision
    UUID=$(grep -aA1 UUID profile.mobileprovision | grep -o '[0-9a-f-]\{36\}')
    cp profile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/${UUID}.mobileprovision
```

**Pros:**
- ✅ Free for public repos
- ✅ Full customization
- ✅ Integrated with GitHub
- ✅ Supports macOS runners

**Cons:**
- ⚠️ Requires manual certificate management
- ⚠️ More complex setup

**Docs:** https://docs.github.com/en/actions

##### Bitrise
Mobile-focused CI/CD with pre-built steps.

**Setup:**
1. Add your app to Bitrise
2. In **Workflow Editor → Code Signing**:
   - Upload iOS certificate
   - Upload provisioning profile
   - Set certificate password
3. Bitrise handles installation automatically

**Workflow (bitrise.yml):**
```yaml
workflows:
  primary:
    steps:
    - certificate-and-profile-installer@1:
        inputs:
        - certificate_url: $BITRISE_CERTIFICATE_URL
        - certificate_passphrase: $BITRISE_CERTIFICATE_PASSPHRASE
        - provisioning_profile_url: $BITRISE_PROVISION_URL
    - flutter-build@0:
        inputs:
        - platform: ios
        - ios_output_type: ipa
```

**Pros:**
- ✅ Mobile-focused
- ✅ Pre-built Flutter steps
- ✅ Visual workflow editor
- ✅ Automatic signing setup

**Docs:** https://devcenter.bitrise.io/

---

### Platform-Specific CI/CD Tips

#### GitHub Actions
**Common Issues:**
- **Keychain timeout**: Set `security set-keychain-settings -t 3600` to extend timeout
- **Certificate not found**: Ensure `security set-key-partition-list` is run after import
- **Profile UUID**: Extract UUID from profile and rename file to `${UUID}.mobileprovision`

**Best Practices:**
```yaml
- name: Cleanup
  if: always()
  run: |
    security delete-keychain build.keychain
    rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*
```

#### Codemagic
**Common Issues:**
- **Reference not found**: Ensure code signing identity reference name matches in both UI and `codemagic.yaml`
- **Team ID mismatch**: Verify Team ID in ExportOptions.plist matches uploaded certificate

**Best Practices:**
- Use environment variable groups for team sharing
- Enable automatic build versioning
- Set up Slack/email notifications for build status

#### Fastlane
**Common Issues:**
- **Match encryption password**: Store in environment variable `MATCH_PASSWORD`
- **Git SSH keys**: Use HTTPS for match repository in CI environments
- **Certificate renewal**: Run `fastlane match nuke development` to reset certificates

**Best Practices:**
```ruby
# Fastfile
lane :build do
  match(type: "appstore", readonly: true)
  gym(scheme: "Runner", export_method: "app-store")
end
```

---2. **Manual Certificate Distribution**
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
