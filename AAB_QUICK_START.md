# Quick Start: Building AAB for GUD Express

This is a quick reference for building the Android App Bundle. For detailed instructions, see [AAB_BUILD_GUIDE.md](AAB_BUILD_GUIDE.md).

## Prerequisites Checklist

- [ ] Flutter SDK 3.0.0+ installed
- [ ] Android SDK installed (API 21-36)
- [ ] Java JDK 17+ installed
- [ ] Keystore generated
- [ ] `android/key.properties` configured

## Quick Build (3 Steps)

### 1. Setup (First Time Only)

```bash
# Generate keystore
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Create key.properties
cp android/key.properties.template android/key.properties
# Edit key.properties with your values
```

### 2. Build AAB

**Linux/macOS:**
```bash
./scripts/build_aab.sh
```

**Windows:**
```cmd
scripts\build_aab.bat
```

### 3. Upload

Output location: `build/app/outputs/bundle/release/app-release.aab`

Upload to: [Google Play Console](https://play.google.com/console)

## Manual Build

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

## Test Before Upload

```bash
# Download bundletool
wget https://github.com/google/bundletool/releases/download/1.15.6/bundletool-all-1.15.6.jar

# Generate APKs
java -jar bundletool-all-1.15.6.jar build-apks \
  --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=app.apks \
  --ks=~/upload-keystore.jks \
  --ks-key-alias=upload

# Install on device
java -jar bundletool-all-1.15.6.jar install-apks --apks=app.apks
```

## Version Update

Update TWO files:

**1. pubspec.yaml:**
```yaml
version: 2.2.0+3  # New version
```

**2. android/app/build.gradle:**
```gradle
versionCode 3         # Increment
versionName "2.2.0"   # Match pubspec
```

## Common Issues

### "key.properties not found"
```bash
cp android/key.properties.template android/key.properties
# Edit with your actual values
```

### "Keystore not found"
Check path in `android/key.properties` - use absolute path.

### Build fails
```bash
flutter clean
rm -rf build/
flutter pub get
./scripts/build_aab.sh
```

## CI/CD

### GitHub Actions
Automatic builds on push to main. Check the Actions tab.

### Codemagic
Configure in [codemagic.io](https://codemagic.io) with environment variables:
- `CM_KEYSTORE_PASSWORD`
- `CM_KEY_PASSWORD`
- `CM_KEY_ALIAS`
- `CM_KEYSTORE_PATH`

## Build Artifacts

| Location | Description |
|----------|-------------|
| `build/app/outputs/bundle/release/app-release.aab` | Release AAB for Play Store |
| `build/app/outputs/flutter-apk/app-release.apk` | Release APK (if built) |

## What Gets Optimized

✅ Code minified and obfuscated (ProGuard/R8)  
✅ Resources shrunk (unused removed)  
✅ Split APKs by ABI (armeabi-v7a, arm64-v8a, x86_64)  
✅ Split by language and density  
✅ Smaller download sizes (30-40% reduction)

## Security Notes

⚠️ **NEVER commit:**
- `android/key.properties`
- `*.keystore` or `*.jks` files
- Any passwords or credentials

✅ **Always backup:**
- Your keystore file (in a secure location)
- Your keystore passwords (in a password manager)

## Documentation

- **Detailed Guide:** [AAB_BUILD_GUIDE.md](AAB_BUILD_GUIDE.md) (486 lines)
- **Implementation Summary:** [AAB_SETUP_SUMMARY.md](AAB_SETUP_SUMMARY.md) (327 lines)
- **Script Documentation:** [scripts/README.md](scripts/README.md)
- **Deployment Guide:** [DEPLOYMENT.md](DEPLOYMENT.md)

## Support

1. Check troubleshooting in [AAB_BUILD_GUIDE.md](AAB_BUILD_GUIDE.md#troubleshooting)
2. Review [AAB_SETUP_SUMMARY.md](AAB_SETUP_SUMMARY.md)
3. Contact development team

---

**App Version:** 2.1.0+2  
**Last Updated:** February 2026
