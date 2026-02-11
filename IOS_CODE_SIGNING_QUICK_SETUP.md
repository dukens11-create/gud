# iOS Code Signing Quick Setup

Quick guide to set up code signing for GUD Express iOS app in 5-10 minutes.

## What You'll Need

- ✅ macOS with Xcode installed
- ✅ Apple ID (free or paid developer account)
- ✅ GUD Express project cloned locally

## Step-by-Step Setup

### 1. Find Your Team ID (2 minutes)

**Option A: Apple Developer Portal**
1. Go to https://developer.apple.com/account
2. Sign in with your Apple ID
3. Click **Membership** in sidebar
4. Copy your **Team ID** (10 characters, e.g., `ABCDE12345`)

**Option B: Xcode**
1. Open Xcode → **Preferences** (Cmd + ,)
2. Click **Accounts** tab
3. Sign in with Apple ID if not already signed in
4. Select your account
5. Team ID is shown in the teams list

---

### 2. Configure Team in Project (1 minute)

**Option A: Using Script (Easiest)**
```bash
cd /path/to/gud
./scripts/configure_team.sh
# Follow the prompts and enter your Team ID
```

**Option B: Manual in Xcode**
```bash
cd /path/to/gud/ios
open Runner.xcworkspace
```

Then in Xcode:
1. Select **Runner** project in navigator (left panel)
2. Select **Runner** target
3. Click **Signing & Capabilities** tab
4. Check **✓ Automatically manage signing**
5. Select your **Team** from dropdown

---

### 3. Build and Test (2 minutes)

**For Simulator (No signing needed):**
```bash
./scripts/build_ios_simulator.sh
```

**For Physical Device:**
```bash
# Connect your iPhone/iPad via USB
./scripts/build_ios_device.sh
```

---

## Verification

### Check if Setup is Correct

1. **Open workspace:**
   ```bash
   cd ios && open Runner.xcworkspace
   ```

2. **Check Signing & Capabilities:**
   - Runner target → Signing & Capabilities
   - Should show: "✓ Signing Certificate: Apple Development"
   - Should show: "✓ Provisioning Profile: Xcode Managed Profile"

3. **Test build:**
   ```bash
   flutter build ios --debug
   ```

If it builds without errors, you're all set! 🎉

---

## Troubleshooting

### Issue: "No Team Found"

**Solution:**
1. Xcode → Preferences → Accounts
2. Click **+** to add Apple ID
3. Sign in with your Apple ID
4. Close and reopen project

### Issue: "Signing Certificate Not Found"

**Solution:**
1. Xcode → Preferences → Accounts
2. Select Apple ID → **Manage Certificates**
3. Click **+** → **Apple Development**
4. Close and rebuild

### Issue: "Device Not Registered"

**Solution:**
1. Connect device via USB
2. Xcode → Window → Devices and Simulators
3. Select your device
4. Xcode will automatically register it

---

## Free vs Paid Account Differences

### Free Apple ID
- ✅ Can develop and test on devices
- ✅ Can use simulator
- ✅ Up to 3 devices
- ❌ 7-day certificate validity (need to rebuild weekly)
- ❌ Can't publish to App Store

### Paid Developer Account ($99/year)
- ✅ Unlimited devices
- ✅ 1-year certificate validity
- ✅ Can publish to App Store
- ✅ TestFlight distribution
- ✅ Advanced features (push notifications, etc.)

---

## Quick Commands

```bash
# Configure team
./scripts/configure_team.sh

# Build for simulator
./scripts/build_ios_simulator.sh

# Build for device (debug)
./scripts/build_ios_device.sh

# Build for device (release)
./scripts/build_ios_device.sh --release

# Export IPA
./scripts/build_ios_device.sh --export-ipa

# Run on device
flutter run -d <device-id>

# List devices
flutter devices
```

---

## Next Steps

After successful setup:

1. **Local Development:**
   - See [IOS_LOCAL_BUILD_GUIDE.md](IOS_LOCAL_BUILD_GUIDE.md)

2. **Understanding Provisioning:**
   - See [IOS_PROVISIONING_GUIDE.md](IOS_PROVISIONING_GUIDE.md)

3. **CI/CD Setup:**
   - See [IOS_BUILD_AND_DEPLOY_GUIDE.md](IOS_BUILD_AND_DEPLOY_GUIDE.md)

---

## Summary Checklist

- [ ] Found Team ID from Apple Developer Portal or Xcode
- [ ] Configured team using script or Xcode
- [ ] Verified signing in Xcode (green checkmarks)
- [ ] Successfully built for simulator or device
- [ ] Device registered (if building for device)

Once all checkmarks are complete, you're ready to develop! 🚀

---

**Need Help?**
- Check [IOS_LOCAL_BUILD_GUIDE.md](IOS_LOCAL_BUILD_GUIDE.md) Troubleshooting section
- Apple Developer Forums: https://developer.apple.com/forums
- Flutter Discord: https://discord.gg/flutter

---

**Last Updated**: 2024
**Version**: 1.0
**Setup Time**: ~5-10 minutes
