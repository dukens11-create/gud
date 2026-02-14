# iOS Setup for GUD Express

## Quick Start

### Just Testing? Build for Simulator (No Code Signing Required)
If you just want to test the app in the iOS simulator, you don't need to configure code signing:

```bash
# Build and run on iOS simulator
flutter run -d "iPhone 14 Pro"

# Or build specifically for simulator
flutter build ios --simulator
```

**Note:** Simulator builds don't require an Apple Developer account or code signing setup.

### Building for Real Devices? Continue Below

## Prerequisites
- macOS with Xcode 14.0 or later
- CocoaPods installed (`sudo gem install cocoapods`)
- Active Apple Developer account (free or paid)
- Firebase project with iOS app configured

## Setup Steps

### 1. Firebase Configuration
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project (or create a new one)
3. Add an iOS app to your Firebase project
4. Use bundle identifier: `com.gud.express`
5. Download `GoogleService-Info.plist`
6. Replace the placeholder file at `ios/Runner/GoogleService-Info.plist` with your downloaded file

### 2. Install Dependencies
```bash
cd ios
pod install
cd ..
```

### 3. Configure Code Signing for Real Devices

⚠️ **Required for building to real iOS devices, not needed for simulator**

The project uses automatic code signing, but you need to configure your Development Team first.

#### Getting the "DEVELOPMENT_TEAM" Build Error?

If you see an error like:
```
Building a deployable iOS app requires a selected Development Team with a 
Provisioning Profile. Please ensure that a Development Team is selected
```

This means you need to configure your development team. Choose one of the methods below:

#### Method 1: Using Xcode (Recommended for Local Development)

1. **Open the project in Xcode:**
   ```bash
   cd ios && open Runner.xcworkspace  # Open workspace, NOT .xcodeproj
   ```

2. **Sign in with your Apple ID** (if not already signed in):
   - Go to **Xcode → Settings → Accounts**
   - Click **+** to add your Apple ID
   - Sign in with your credentials

3. **Configure signing in the project:**
   - Select **Runner** in the left sidebar
   - Click the **Signing & Capabilities** tab
   - Ensure **"Automatically manage signing"** is checked ✓
   - Select your team from the **Team** dropdown
   - Xcode will automatically create provisioning profiles

4. **Build the app:**
   ```bash
   cd .. && flutter build ios
   ```

#### Method 2: Using Environment Variable (Recommended for CI/CD)

1. **Find your Team ID:**
   - Go to https://developer.apple.com/account
   - Navigate to **Membership** section
   - Copy your Team ID (10-character alphanumeric string like `ABCD1234EF`)

2. **Set the environment variable:**
   ```bash
   export DEVELOPMENT_TEAM="YOUR_TEAM_ID_HERE"
   ```

3. **Make it permanent** (optional, for local development):
   ```bash
   # Add to your shell config file (~/.zshrc or ~/.bashrc)
   echo 'export DEVELOPMENT_TEAM="YOUR_TEAM_ID_HERE"' >> ~/.zshrc
   source ~/.zshrc
   ```

4. **Build the app:**
   ```bash
   flutter build ios
   ```

#### Method 3: Using Configuration Script

Run the provided script that guides you through the setup:

```bash
./scripts/configure_team.sh
```

This script will:
- Prompt you for your Team ID
- Set up the environment variable
- Provide next steps for Xcode configuration

#### CI/CD Setup

For GitHub Actions or other CI/CD systems, set `DEVELOPMENT_TEAM` as a secret environment variable:

```yaml
env:
  DEVELOPMENT_TEAM: ${{ secrets.APPLE_TEAM_ID }}
```

**For detailed instructions, see:**
- **[CODE_SIGNING_SETUP.md](CODE_SIGNING_SETUP.md)** - Complete code signing guide
- **[../IOS_CODE_SIGNING_QUICK_SETUP.md](../IOS_CODE_SIGNING_QUICK_SETUP.md)** - Quick 5-minute setup
- **[../IOS_LOCAL_BUILD_GUIDE.md](../IOS_LOCAL_BUILD_GUIDE.md)** - Comprehensive build guide

### 4. Enable Capabilities
In Xcode, under "Signing & Capabilities", add:
- **Push Notifications**: For receiving FCM messages
- **Background Modes**: Enable "Location updates", "Background fetch", "Remote notifications"
- **Sign in with Apple**: (Optional) For Apple Sign-In support

### 5. Build and Run
```bash
flutter run -d ios
# or
flutter build ios
```

## Push Notifications Setup

### APNs Authentication Key (Recommended)
1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to Certificates, Identifiers & Profiles > Keys
3. Create a new key and enable "Apple Push Notifications service (APNs)"
4. Download the .p8 key file
5. In Firebase Console, go to Project Settings > Cloud Messaging > Apple app configuration
6. Upload your APNs Auth Key (.p8 file) with Key ID and Team ID
7. This key never expires and works for all apps in your team

### APNs Certificate (Legacy Alternative)
If you prefer using certificates instead of auth keys:
1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to Certificates, Identifiers & Profiles > Certificates
3. Create an APNs certificate for your app
4. Download the certificate and export as .p12
5. Upload to Firebase Console under Project Settings > Cloud Messaging

## Troubleshooting

### Build Error: "Development Team Required"
```
Building a deployable iOS app requires a selected Development Team with a 
Provisioning Profile. Please ensure that a Development Team is selected
```

**Solution:** You need to configure your development team. See [Configure Code Signing](#3-configure-code-signing-for-real-devices) above.

**Quick fixes:**
1. **Use simulator instead** (no code signing needed): `flutter run -d "iPhone 14 Pro"`
2. **Set via Xcode**: Open `ios/Runner.xcworkspace` → Runner target → Signing & Capabilities → Select Team
3. **Set via environment**: `export DEVELOPMENT_TEAM="YOUR_TEAM_ID"`
4. **Use script**: `./scripts/configure_team.sh`

### Pod Install Fails
```bash
cd ios
pod repo update
pod install --repo-update
cd ..
```

### Signing Issues
**Error messages like:**
- "No signing certificate"
- "Failed to create provisioning profile"
- "DEVELOPMENT_TEAM is empty"

**Solutions:**
1. **For simulator testing**: Use `flutter build ios --simulator` (no signing needed)
2. **For local development**: 
   - Open Xcode → Settings → Accounts → Add your Apple ID
   - Open `ios/Runner.xcworkspace` → Select team in Signing & Capabilities
3. **For CI/CD**: Set `DEVELOPMENT_TEAM` environment variable with your Team ID
4. **Run diagnostics**: `./scripts/check_code_signing.sh`
5. **Guided setup**: `./scripts/configure_team.sh`

**Key points:**
- Bundle identifier: `com.gudexpress.gud_app`
- Automatic signing is already enabled in the project
- You just need to select your team (Xcode) or set DEVELOPMENT_TEAM (CI/CD)
- **Detailed troubleshooting:** [CODE_SIGNING_SETUP.md](CODE_SIGNING_SETUP.md#troubleshooting)

### Firebase Not Working
- Verify `GoogleService-Info.plist` is properly configured
- Check that the file is included in the Xcode project
- Rebuild the app after changing Firebase configuration

### Location Not Working
- Check that location permissions are properly added to Info.plist
- Request location permissions in your Dart code before using location features
- Test on a real device (location doesn't work well in simulator)

## CI/CD Configuration

### Setting up Code Signing for CI/CD Pipelines

For automated builds in CI/CD environments (GitHub Actions, Codemagic, Bitrise, etc.), configure the `DEVELOPMENT_TEAM` environment variable:

#### GitHub Actions Example

Add your Team ID as a repository secret, then use it in your workflow:

```yaml
name: iOS Build
on: [push]

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        
      - name: Install dependencies
        run: |
          cd ios
          pod install
          cd ..
          
      - name: Build iOS app
        env:
          DEVELOPMENT_TEAM: ${{ secrets.APPLE_TEAM_ID }}
        run: flutter build ios --release
```

#### Codemagic Configuration

In `codemagic.yaml`:

```yaml
workflows:
  ios-workflow:
    environment:
      vars:
        DEVELOPMENT_TEAM: YOUR_TEAM_ID
    scripts:
      - flutter build ios --release
```

#### Other CI Systems

Set `DEVELOPMENT_TEAM` as an environment variable in your CI configuration:
- **Bitrise**: Add in Workflow → Env Vars
- **CircleCI**: Add in Project Settings → Environment Variables
- **GitLab CI**: Add in Settings → CI/CD → Variables

**Note:** For production releases, you'll also need to configure provisioning profiles and certificates. See [CODE_SIGNING_SETUP.md](CODE_SIGNING_SETUP.md) for complete CI/CD setup.

## Building for Release

### App Store
```bash
flutter build ios --release
```

Then open `ios/Runner.xcworkspace` in Xcode and:
1. Select "Any iOS Device" as the build target
2. Product > Archive
3. Upload to App Store Connect

### TestFlight
After archiving, use Xcode's Organizer to upload to TestFlight for beta testing.

## Important Notes
- Always test on real iOS devices, not just simulator
- Location tracking requires real device
- Push notifications require real device
- Camera/photo library require real device
- **Minimum iOS version:** 14.0 (deployment target)
- **Bundle identifier:** `com.gudexpress.gud_app`
- **Signing:** Automatic code signing is enabled (just select your team)

## Summary of Code Signing Approaches

| Scenario | Method | Code Signing Required? |
|----------|--------|----------------------|
| Testing in simulator | `flutter run -d "iPhone 14 Pro"` | ❌ No |
| Local development (device) | Open Xcode → Select team | ✅ Yes |
| Local development (CLI) | Set `export DEVELOPMENT_TEAM=...` | ✅ Yes |
| CI/CD automated builds | Set `DEVELOPMENT_TEAM` env var | ✅ Yes |
| App Store release | Xcode Archive + Upload | ✅ Yes |

**Need help?** Run `./scripts/configure_team.sh` for guided setup or see [CODE_SIGNING_SETUP.md](CODE_SIGNING_SETUP.md) for detailed documentation.
