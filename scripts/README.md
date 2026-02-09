# Build Scripts

This directory contains automated build scripts for creating Android App Bundles (AAB).

## Available Scripts

### `build_aab.sh` (Linux/macOS)
Bash script for building release AAB on Unix-based systems.

**Usage:**
```bash
chmod +x scripts/build_aab.sh
./scripts/build_aab.sh
```

### `build_aab.bat` (Windows)
Batch script for building release AAB on Windows systems.

**Usage:**
```cmd
scripts\build_aab.bat
```

## Prerequisites

Before running these scripts, ensure you have:

1. **key.properties configured** - See [AAB_BUILD_GUIDE.md](../AAB_BUILD_GUIDE.md)
2. **Keystore generated** - See [AAB_BUILD_GUIDE.md](../AAB_BUILD_GUIDE.md#keystore-generation)
3. **Flutter installed** - Run `flutter doctor` to verify
4. **All dependencies installed** - Run `flutter pub get`

## What the Scripts Do

Both scripts perform the following steps:

1. **Validate** - Check that key.properties and keystore exist
2. **Clean** - Remove previous build artifacts (`flutter clean`)
3. **Dependencies** - Install Flutter packages (`flutter pub get`)
4. **Build** - Create the release AAB (`flutter build appbundle --release`)
5. **Verify** - Confirm the AAB was created successfully

## Output

The AAB file will be created at:
```
build/app/outputs/bundle/release/app-release.aab
```

## Troubleshooting

If the script fails, check:
- Flutter is installed and in PATH
- key.properties exists in android/ directory
- Keystore file path in key.properties is correct
- All dependencies are up to date

For detailed troubleshooting, see [AAB_BUILD_GUIDE.md](../AAB_BUILD_GUIDE.md#troubleshooting)
