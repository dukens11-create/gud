# iOS Code Signing Setup Guide

This guide explains how to configure code signing for the GUD Express iOS app for both local development and CI/CD environments.

## Overview

The Xcode project is now configured for **automatic code signing**, which means Xcode will automatically manage certificates and provisioning profiles for you. However, you still need to configure your Development Team.

## Prerequisites

- macOS with Xcode installed (version 14.0 or later recommended)
- An Apple ID (free or paid Apple Developer account)
- Access to the GUD Express repository

## Local Development Setup

### Step 1: Sign in to Xcode with Your Apple ID

1. Open Xcode
2. Go to **Xcode → Settings** (or **Xcode → Preferences** on older versions)
3. Click the **Accounts** tab
4. Click the **+** button to add an account
5. Select **Apple ID** and click **Continue**
6. Sign in with your Apple ID credentials
7. Once signed in, you should see your account in the list

### Step 2: Find Your Team ID

**Option A: From Xcode Settings**
1. In Xcode → Settings → Accounts
2. Select your Apple ID
3. Your Team ID will be shown in the list of teams
   - For a free Apple ID: Usually shows as "Your Name (Personal Team)"
   - For a paid Developer Program: Shows your organization name with Team ID

**Option B: From Apple Developer Portal**
1. Go to https://developer.apple.com/account
2. Sign in with your Apple ID
3. Navigate to **Membership** in the sidebar
4. Your Team ID is displayed there (10-character alphanumeric string, e.g., `ABCDE12345`)

### Step 3: Configure Your Development Team

**Method 1: Using the Configuration Script (Recommended)**

Run the provided script from the project root:

```bash
./scripts/configure_team.sh
```

This script will:
- Prompt you for your Team ID
- Update the project configuration
- Guide you through the remaining Xcode steps

**Method 2: Manual Configuration in Xcode**

1. Open the workspace (not the .xcodeproj file):
   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. In the Xcode project navigator (left sidebar):
   - Click on **Runner** (the blue project icon at the top)

3. Select the **Runner** target from the list

4. Click on the **Signing & Capabilities** tab

5. Make sure **Automatically manage signing** is checked ✓

6. From the **Team** dropdown, select your team:
   - For free Apple ID: Select your Personal Team
   - For paid Developer Program: Select your organization

7. Verify the signing configuration:
   - **Signing Certificate**: Should show "Apple Development"
   - **Provisioning Profile**: Should show "Xcode Managed Profile" or "iOS Team Provisioning Profile"
   - **Status**: Should show no errors (green checkmark or no warning icon)

### Step 4: Set the DEVELOPMENT_TEAM Environment Variable (Optional)

For convenience, you can set an environment variable so you don't have to configure the team each time:

**For bash (~/.bash_profile or ~/.bashrc):**
```bash
export DEVELOPMENT_TEAM="ABCDE12345"  # Replace with your Team ID
```

**For zsh (~/.zshrc):**
```zsh
export DEVELOPMENT_TEAM="ABCDE12345"  # Replace with your Team ID
```

After adding, reload your shell:
```bash
source ~/.zshrc  # or source ~/.bash_profile
```

### Step 5: Build and Test

**Build for iOS Simulator (no code signing required):**
```bash
flutter build ios --simulator
# or
./scripts/build_ios_simulator.sh
```

**Build for Physical Device (requires code signing):**
```bash
flutter build ios --release
# or
./scripts/build_ios_device.sh
```

If the build succeeds, your code signing is correctly configured! 🎉

## CI/CD Setup

For CI/CD environments like GitHub Actions, Codemagic, or other platforms, you need to configure code signing differently.

### Required Secrets/Environment Variables

Configure these secrets in your CI/CD platform:

| Variable Name | Description | How to Get |
|--------------|-------------|------------|
| `DEVELOPMENT_TEAM` | Your Apple Developer Team ID | From Apple Developer Portal → Membership |
| `IOS_CERTIFICATE_BASE64` | Distribution certificate (p12 file) in base64 | Export from Keychain Access, then encode |
| `IOS_CERTIFICATE_PASSWORD` | Password for the certificate | Set when exporting certificate |
| `IOS_PROVISIONING_PROFILE_BASE64` | Provisioning profile in base64 | Download from Apple Developer Portal, then encode |

### Setting Up GitHub Actions

The project includes a GitHub Actions workflow at `.github/workflows/build-ios.yml`. To use it:

1. **Export your distribution certificate:**
   ```bash
   # In Keychain Access, export your "Apple Distribution" certificate as a .p12 file
   # When exporting, set a password
   ```

2. **Encode certificate to base64:**
   ```bash
   base64 -i YourCertificate.p12 -o certificate.txt
   ```

3. **Download and encode provisioning profile:**
   ```bash
   # Download from https://developer.apple.com/account/resources/profiles
   base64 -i YourProfile.mobileprovision -o profile.txt
   ```

4. **Add secrets to GitHub:**
   - Go to your repository on GitHub
   - Navigate to **Settings → Secrets and variables → Actions**
   - Click **New repository secret**
   - Add each of the following:
     - `DEVELOPMENT_TEAM`: Your Team ID (e.g., `ABCDE12345`)
     - `IOS_CERTIFICATE_BASE64`: Contents of `certificate.txt`
     - `IOS_CERTIFICATE_PASSWORD`: The password you set when exporting
     - `IOS_PROVISIONING_PROFILE_BASE64`: Contents of `profile.txt`

5. **Trigger the workflow:**
   - Go to **Actions** tab in your repository
   - Select **Build iOS** workflow
   - Click **Run workflow**

### Setting Up Codemagic

The project includes a `codemagic.yaml` configuration. To use it:

1. **Connect your repository to Codemagic**
   - Go to https://codemagic.io
   - Add your repository

2. **Configure code signing in Codemagic:**
   - Go to your app settings
   - Navigate to **Code signing identities**
   - Upload your certificate and provisioning profile
   - Or use Codemagic's automatic code signing

3. **Set environment variables:**
   - In app settings → Environment variables
   - Add `DEVELOPMENT_TEAM` with your Team ID

4. **Start a build:**
   - Codemagic will automatically use the configured code signing

## Troubleshooting

### Error: "Signing for 'Runner' requires a development team"

**Solution:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the Runner target
3. Go to Signing & Capabilities
4. Select your team from the Team dropdown
5. Make sure "Automatically manage signing" is checked

### Error: "No signing certificate found"

**Solution:**
1. Open Xcode → Settings → Accounts
2. Select your Apple ID
3. Click **Manage Certificates**
4. Click **+** → **Apple Development**
5. Close and try building again

### Error: "Provisioning profile doesn't include signing certificate"

**Solution:**
1. In Xcode, uncheck "Automatically manage signing"
2. Check it again
3. Wait a few seconds for Xcode to refresh
4. Build again

### Error: "Failed to register bundle identifier"

**Solution:**
1. The bundle identifier `com.gudexpress.gud_app` might already be registered to another team
2. Option 1: Use a different bundle identifier (update in both Xcode and `Info.plist`)
3. Option 2: Contact the team owner to add you as a member

### Build works in Xcode but fails with Flutter CLI

**Solution:**
1. Make sure you've set the `DEVELOPMENT_TEAM` environment variable:
   ```bash
   export DEVELOPMENT_TEAM="ABCDE12345"
   ```
2. Try building with the script:
   ```bash
   ./scripts/build_ios_device.sh
   ```

### CI/CD builds fail with signing errors

**Solution:**
1. Verify all secrets are correctly set in your CI/CD platform
2. Ensure certificates haven't expired (check in Apple Developer Portal)
3. Ensure provisioning profile includes the app's bundle identifier
4. Check that the base64 encoding is correct (no extra spaces or newlines)

## Free vs Paid Apple Developer Account

### Free Apple ID (Personal Team)
- ✅ Can develop and test on your own devices
- ✅ Can use iOS Simulator
- ✅ Can use automatic signing
- ✅ Up to 3 devices per type
- ❌ Certificates expire after 7 days (need to rebuild weekly)
- ❌ Cannot publish to App Store
- ❌ Cannot use TestFlight
- ❌ Limited capabilities (no push notifications, etc.)

### Paid Apple Developer Program ($99/year)
- ✅ Can register unlimited devices
- ✅ Certificates valid for 1 year
- ✅ Can publish to App Store
- ✅ Can use TestFlight for beta testing
- ✅ Access to all capabilities (push notifications, etc.)
- ✅ Access to advanced features and APIs

## Additional Resources

- **Official Apple Documentation**: [Code Signing Guide](https://developer.apple.com/support/code-signing/)
- **Flutter iOS Deployment**: [Flutter Docs](https://docs.flutter.dev/deployment/ios)
- **Xcode Help**: [Signing Your App](https://help.apple.com/xcode/mac/current/#/dev60b6fbbc7)
- **Repository Guides**:
  - `IOS_CODE_SIGNING_QUICK_SETUP.md` - Quick 5-10 minute setup guide
  - `IOS_LOCAL_BUILD_GUIDE.md` - Comprehensive local build guide
  - `IOS_BUILD_QUICK_START.md` - CI/CD workflow quick start

## Environment Variables Reference

The project supports the following environment variables for flexible code signing configuration:

| Variable | Purpose | Used By | Example |
|----------|---------|---------|---------|
| `DEVELOPMENT_TEAM` | Your Apple Developer Team ID | Xcode, Flutter build | `ABCDE12345` |
| `CODE_SIGN_IDENTITY` | Certificate identity to use | Xcode (advanced) | `Apple Development` |
| `PROVISIONING_PROFILE_SPECIFIER` | Specific profile to use | Xcode (manual signing) | `iOS Team Provisioning Profile` |

### Using Environment Variables

You can override the default automatic signing behavior by setting environment variables before building:

```bash
# Set your team ID
export DEVELOPMENT_TEAM="ABCDE12345"

# Build with Flutter
flutter build ios --release

# Or use the build script
./scripts/build_ios_device.sh
```

For CI/CD, these variables are automatically read from your platform's secret management system.

## Security Best Practices

1. **Never commit certificates or provisioning profiles to version control**
2. **Never commit private keys or passwords to source code**
3. **Use environment variables or CI/CD secrets for sensitive data**
4. **Rotate certificates periodically (at least annually)**
5. **Limit access to code signing materials to authorized team members only**
6. **Use encrypted storage for certificate backups**

## Getting Help

If you're still experiencing issues:

1. Check the **Troubleshooting** section above
2. Review Apple's official documentation
3. Check the Xcode console for detailed error messages
4. Consult the Flutter community:
   - [Flutter Discord](https://discord.gg/flutter)
   - [Flutter Dev Google Group](https://groups.google.com/g/flutter-dev)
   - [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter+ios)

---

**Last Updated**: February 2026  
**Bundle Identifier**: `com.gudexpress.gud_app`  
**Minimum iOS Version**: 14.0  
**Project Configuration**: Automatic Code Signing Enabled
