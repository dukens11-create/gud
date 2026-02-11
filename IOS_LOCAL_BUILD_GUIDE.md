# iOS Local Build Guide

Complete guide for building GUD Express iOS app locally on your Mac for development and testing.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Building for Simulator](#building-for-simulator)
4. [Building for Physical Device](#building-for-physical-device)
5. [Code Signing Setup](#code-signing-setup)
6. [Troubleshooting](#troubleshooting)
7. [Quick Reference](#quick-reference)

---

## Prerequisites

### Required Software
- **macOS** 12.0 (Monterey) or later
- **Xcode** 14.0 or later (from Mac App Store)
- **Flutter SDK** 3.0.0 or later
- **CocoaPods** (install with: `sudo gem install cocoapods`)

### Required Accounts (for device builds only)
- **Apple Developer Account** (Free or Paid)
  - Free account: Limited to 3 devices, 7-day certificates
  - Paid account ($99/year): Unlimited devices, 1-year certificates

### Verify Installation
```bash
# Check Flutter
flutter doctor -v

# Check Xcode
xcode-select --print-path

# Check CocoaPods
pod --version
```

---

## Initial Setup

### 1. Clone the Repository
```bash
git clone https://github.com/dukens11-create/gud.git
cd gud
```

### 2. Install Dependencies
```bash
# Install Flutter dependencies
flutter pub get

# Install iOS dependencies
cd ios
pod install
cd ..
```

### 3. Configure Firebase (Required)
1. Download `GoogleService-Info.plist` from your Firebase project
2. Place it in `ios/Runner/` directory
3. **DO NOT** commit this file to git (it's in .gitignore)

---

## Building for Simulator

Simulator builds **DO NOT** require code signing or provisioning profiles.

### Using Build Script (Recommended)

#### Linux/macOS:
```bash
./scripts/build_ios_simulator.sh
```

#### Windows (with Mac access):
```cmd
scripts\build_ios_simulator.bat
```

### Manual Build Steps

1. **Clean and prepare:**
   ```bash
   flutter clean
   flutter pub get
   cd ios && pod install && cd ..
   ```

2. **Build for simulator:**
   ```bash
   flutter build ios --simulator --debug
   ```

3. **Run on simulator:**
   ```bash
   # List available simulators
   flutter devices
   
   # Run on specific simulator
   flutter run -d <simulator-id>
   
   # Or let Flutter choose
   flutter run
   ```

### Opening Simulator Manually
```bash
# Open Xcode's Simulator app
open -a Simulator

# Or from Xcode: Xcode → Open Developer Tool → Simulator
```

### Simulator Shortcuts
- **iPhone 14 Pro Max**: Best for testing large screens
- **iPhone SE (3rd gen)**: Best for testing small screens
- **iPad Pro**: Best for tablet testing

---

## Building for Physical Device

Device builds **REQUIRE** code signing and provisioning profiles.

### Quick Start (Automated Script)

#### For Debug Build:
```bash
./scripts/build_ios_device.sh
```

#### For Release Build:
```bash
./scripts/build_ios_device.sh --release
```

#### For IPA Export:
```bash
./scripts/build_ios_device.sh --export-ipa
```

### Manual Build Steps

1. **Configure code signing** (see [Code Signing Setup](#code-signing-setup))

2. **Connect your device:**
   - Connect iPhone/iPad via USB
   - Unlock the device
   - Trust the computer (if first time)

3. **Clean and prepare:**
   ```bash
   flutter clean
   flutter pub get
   cd ios && pod install && cd ..
   ```

4. **Build and run:**
   ```bash
   # List connected devices
   flutter devices
   
   # Run on device
   flutter run -d <device-id>
   ```

### Using Xcode (Alternative)

1. **Open workspace:**
   ```bash
   cd ios
   open Runner.xcworkspace
   ```
   
   ⚠️ **Important**: Always open `.xcworkspace`, NOT `.xcodeproj`

2. **Select device:**
   - At the top of Xcode, select your connected device

3. **Select scheme:**
   - Select "Runner" scheme

4. **Build and run:**
   - Press `Cmd + R` or click the Play button

---

## Code Signing Setup

### Option 1: Using Configuration Script (Recommended)

Run the automated configuration script:
```bash
./scripts/configure_team.sh
```

The script will:
1. Prompt for your Apple Developer Team ID
2. Update Xcode project with Team ID
3. Update ExportOptions.plist
4. Create backups of modified files

### Option 2: Manual Configuration in Xcode

1. **Open project:**
   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. **Select Runner target:**
   - In the project navigator (left panel)
   - Click on "Runner" (blue icon at top)

3. **Go to Signing & Capabilities:**
   - Click on "Signing & Capabilities" tab

4. **Configure signing:**
   - ✅ Check "Automatically manage signing"
   - Select your **Team** from dropdown
   - Bundle Identifier should be: `com.gudexpress.gud_app`

5. **Verify:**
   - Xcode will automatically:
     - Create/download provisioning profile
     - Install signing certificate
     - Show "Signing & Capabilities" status

### Finding Your Team ID

**Method 1: Apple Developer Portal**
1. Go to [Apple Developer](https://developer.apple.com/account)
2. Sign in with your Apple ID
3. Navigate to **Membership**
4. Your Team ID is listed (10-character string, e.g., `ABCDE12345`)

**Method 2: Xcode**
1. Open Xcode
2. Go to **Preferences** → **Accounts**
3. Select your Apple ID
4. Click **Manage Certificates**
5. Team ID is shown next to team name

### Code Signing Modes

#### Automatic Signing (Recommended for Development)
- ✅ Xcode manages certificates and profiles
- ✅ Easiest for development
- ✅ Works with free Apple ID
- ❌ Not suitable for CI/CD

#### Manual Signing (For CI/CD)
- ✅ Full control over certificates
- ✅ Required for CI/CD pipelines
- ❌ More complex setup
- See [IOS_BUILD_AND_DEPLOY_GUIDE.md](IOS_BUILD_AND_DEPLOY_GUIDE.md)

---

## Troubleshooting

### Common Issues

#### 1. "No Development Team Selected"

**Error:** `Signing for "Runner" requires a development team.`

**Solution:**
```bash
# Option A: Use configuration script
./scripts/configure_team.sh

# Option B: Configure in Xcode
# 1. Open ios/Runner.xcworkspace
# 2. Select Runner target → Signing & Capabilities
# 3. Select your Team
```

#### 2. "Unable to Install Provisioning Profile"

**Error:** `Failed to install or create provisioning profile`

**Solutions:**
1. **Check team selection:**
   - Ensure team is selected in Xcode

2. **Reset provisioning:**
   ```bash
   # Delete derived data
   rm -rf ~/Library/Developer/Xcode/DerivedData
   
   # Clean build
   cd ios
   pod deintegrate
   pod install
   cd ..
   flutter clean
   ```

3. **Manual profile download:**
   - Go to [Apple Developer Portal](https://developer.apple.com/account/resources/profiles)
   - Download development profile for `com.gudexpress.gud_app`
   - Install by double-clicking

#### 3. "Pod Install Fails"

**Error:** CocoaPods installation errors

**Solutions:**
```bash
# Update CocoaPods
sudo gem install cocoapods

# Update repos
cd ios
pod repo update

# Reinstall
pod deintegrate
pod install

# If still fails, try clean install
rm -rf Pods Podfile.lock
pod install --repo-update
```

#### 4. "Device Not Found"

**Error:** Device not appearing in Flutter devices

**Solutions:**
1. **Check USB connection:**
   - Unplug and replug device
   - Use Apple original cable if possible

2. **Trust computer:**
   - Unlock device
   - Tap "Trust" when prompted

3. **Enable Developer Mode (iOS 16+):**
   - Settings → Privacy & Security → Developer Mode → Enable

4. **Check device status:**
   ```bash
   flutter devices -v
   ```

#### 5. "Certificate Issues"

**Error:** Various certificate-related errors

**Solutions:**
1. **Check certificate validity:**
   - Open **Keychain Access** app
   - Check "login" keychain
   - Look for "iPhone Developer" certificate
   - Ensure it's not expired

2. **Install certificate:**
   - Download from Apple Developer Portal
   - Double-click to install in Keychain

3. **Reset certificates:**
   - Xcode → Preferences → Accounts
   - Select Apple ID → Manage Certificates
   - Click "+" and create new certificate

#### 6. "Build Number Already Exists"

**Error:** When uploading to TestFlight/App Store

**Solution:**
```yaml
# Edit pubspec.yaml
# Increment the build number (number after +)
version: 2.1.0+3  # Increment to +4, +5, etc.
```

#### 7. "GoogleService-Info.plist Not Found"

**Error:** Firebase configuration missing

**Solution:**
1. Download from Firebase Console
2. Place in `ios/Runner/` directory
3. Ensure it's added to Xcode project:
   - Open `ios/Runner.xcworkspace`
   - Drag file into project if not already there

#### 8. "Xcode Command Line Tools Not Found"

**Error:** `xcode-select: error: tool 'xcodebuild' requires Xcode`

**Solution:**
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Set Xcode path
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer

# Verify
xcodebuild -version
```

### Debugging Tips

#### Enable Verbose Logging
```bash
flutter run -v
flutter build ios -v
```

#### Check Xcode Build Logs
1. Open `ios/Runner.xcworkspace` in Xcode
2. Product → Build
3. View logs in Report Navigator (Cmd + 9)

#### Clean Everything
```bash
# Nuclear option - clean everything
flutter clean
rm -rf ios/Pods ios/Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData
cd ios && pod install && cd ..
flutter pub get
```

---

## Quick Reference

### Essential Commands

```bash
# Build for simulator
flutter build ios --simulator --debug

# Build for device (debug)
flutter build ios --debug

# Build for device (release)
flutter build ios --release

# Run on device/simulator
flutter run -d <device-id>

# List devices
flutter devices

# Clean build
flutter clean

# Install pods
cd ios && pod install && cd ..

# Open in Xcode
cd ios && open Runner.xcworkspace
```

### Keyboard Shortcuts (Xcode)

| Shortcut | Action |
|----------|--------|
| `Cmd + R` | Build and run |
| `Cmd + B` | Build only |
| `Cmd + .` | Stop running |
| `Cmd + K` | Clear console |
| `Cmd + Shift + K` | Clean build folder |
| `Cmd + 0` | Show/hide navigator |
| `Cmd + 9` | Show report navigator |

### File Locations

| File | Purpose |
|------|---------|
| `ios/Runner.xcworkspace` | Xcode workspace (always use this) |
| `ios/Runner.xcodeproj` | Xcode project (don't open directly) |
| `ios/Podfile` | CocoaPods dependencies |
| `ios/ExportOptions.plist` | IPA export configuration |
| `ios/Runner/Info.plist` | iOS app configuration |
| `ios/Runner/GoogleService-Info.plist` | Firebase configuration |

### Important URLs

- [Apple Developer](https://developer.apple.com)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [Xcode Documentation](https://developer.apple.com/xcode/)

---

## Workflows

### Simulator Development Workflow

```
┌─────────────────────────────────┐
│ 1. Make code changes            │
└───────────┬─────────────────────┘
            ↓
┌─────────────────────────────────┐
│ 2. flutter run (auto-rebuild)   │
└───────────┬─────────────────────┘
            ↓
┌─────────────────────────────────┐
│ 3. Test in simulator            │
└───────────┬─────────────────────┘
            ↓
┌─────────────────────────────────┐
│ 4. Repeat until satisfied       │
└─────────────────────────────────┘
```

### Device Development Workflow

```
┌─────────────────────────────────┐
│ 1. Configure code signing       │
│    (one-time setup)             │
└───────────┬─────────────────────┘
            ↓
┌─────────────────────────────────┐
│ 2. Connect device via USB       │
└───────────┬─────────────────────┘
            ↓
┌─────────────────────────────────┐
│ 3. flutter run -d <device>      │
└───────────┬─────────────────────┘
            ↓
┌─────────────────────────────────┐
│ 4. Test on physical device      │
└───────────┬─────────────────────┘
            ↓
┌─────────────────────────────────┐
│ 5. Debug issues (if any)        │
└─────────────────────────────────┘
```

### Release Build Workflow

```
┌─────────────────────────────────┐
│ 1. Update version in pubspec    │
└───────────┬─────────────────────┘
            ↓
┌─────────────────────────────────┐
│ 2. Test thoroughly              │
└───────────┬─────────────────────┘
            ↓
┌─────────────────────────────────┐
│ 3. Build IPA:                   │
│    ./scripts/build_ios_device.sh│
│    --export-ipa                 │
└───────────┬─────────────────────┘
            ↓
┌─────────────────────────────────┐
│ 4. Upload to TestFlight         │
│    (see IOS_BUILD_AND_DEPLOY)   │
└─────────────────────────────────┘
```

---

## Additional Resources

### Documentation
- [Main iOS Build & Deploy Guide](IOS_BUILD_AND_DEPLOY_GUIDE.md) - Complete CI/CD guide
- [iOS Quick Start](IOS_BUILD_QUICK_START.md) - CI/CD quick reference
- [Project README](../README.md) - General project information

### Tools
- [Xcode](https://apps.apple.com/us/app/xcode/id497799835) - IDE for iOS development
- [SF Symbols](https://developer.apple.com/sf-symbols/) - Apple's icon library
- [Transporter](https://apps.apple.com/us/app/transporter/id1450874784) - Upload to App Store

### Support
- [Flutter Discord](https://discord.gg/flutter)
- [Apple Developer Forums](https://developer.apple.com/forums)
- [Stack Overflow - Flutter](https://stackoverflow.com/questions/tagged/flutter)

---

**Last Updated**: 2024
**Version**: 1.0
**Maintained by**: GUD Express Team
