# App Signing Guide

## Android App Signing

### Generate Upload Keystore

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

**Answer prompts:**
- Enter keystore password: [SECURE_PASSWORD]
- Re-enter password: [SECURE_PASSWORD]
- What is your first and last name? GUD Express Inc.
- What is the name of your organizational unit? Engineering
- What is the name of your organization? GUD Express
- What is the name of your City or Locality? [CITY]
- What is the name of your State or Province? [STATE]
- What is the two-letter country code? US
- Enter key password: [KEY_PASSWORD]

### Configure Gradle

**Create android/key.properties:**
```properties
storePassword=[STORE_PASSWORD]
keyPassword=[KEY_PASSWORD]
keyAlias=upload
storeFile=/path/to/upload-keystore.jks
```

**Update android/app/build.gradle:**
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### Build Signed APK/AAB

```bash
# Build App Bundle (recommended)
flutter build appbundle --release

# Build APK
flutter build apk --release --split-per-abi

# Output locations:
# build/app/outputs/bundle/release/app-release.aab
# build/app/outputs/apk/release/
```

### Google Play App Signing

1. Go to Google Play Console
2. Navigate to: Release > Setup > App signing
3. Opt in to Google Play App Signing
4. Upload your keystore or let Google generate one
5. Download certificate for future updates

## iOS App Signing

### Prerequisites

- Apple Developer Account ($99/year)
- macOS with Xcode
- Valid provisioning profiles

### Create Certificates

**1. Development Certificate:**
- Xcode > Preferences > Accounts
- Select team > Manage Certificates
- Click "+" > Apple Development

**2. Distribution Certificate:**
- Click "+" > Apple Distribution
- Or create via Apple Developer Portal

### Create App ID

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Certificates, IDs & Profiles > Identifiers
3. Click "+" to add new App ID
4. Select "App IDs"
5. Enter:
   - Description: GUD Express
   - Bundle ID: com.gudexpress.gud_app
   - Capabilities: Push Notifications, Sign in with Apple, etc.
6. Register

### Create Provisioning Profiles

**Development Profile:**
1. Certificates, IDs & Profiles > Profiles
2. Click "+" > iOS App Development
3. Select App ID
4. Select Certificates
5. Select Devices
6. Name: GUD Express Development
7. Generate and download

**Distribution Profile:**
1. Click "+" > App Store
2. Select App ID
3. Select Distribution Certificate
4. Name: GUD Express Distribution
5. Generate and download

### Configure Xcode

```bash
# Open iOS project
open ios/Runner.xcworkspace

# In Xcode:
# 1. Select Runner project
# 2. Select Runner target
# 3. Signing & Capabilities tab
# 4. Select Team
# 5. Enable "Automatically manage signing"
```

### Build & Archive

```bash
# Clean build
flutter clean

# Build iOS release
flutter build ios --release

# Or use Xcode:
# Product > Archive
# Window > Organizer > Archives
# Click "Distribute App"
```

### Upload to App Store Connect

**Using Xcode:**
1. Product > Archive
2. Organizer > Distribute App
3. Select "App Store Connect"
4. Follow prompts

**Using Transporter:**
1. Export IPA from Xcode
2. Open Transporter app
3. Drag IPA to Transporter
4. Click "Deliver"

## Continuous Integration

### GitHub Actions

**.github/workflows/release.yml:**
```yaml
name: Release Build

on:
  push:
    tags:
      - 'v*'

jobs:
  android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-java@v3
        with:
          java-version: '17'
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      
      - name: Decode keystore
        run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/upload-keystore.jks
      
      - name: Create key.properties
        run: |
          echo "storePassword=${{ secrets.STORE_PASSWORD }}" > android/key.properties
          echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/key.properties
          echo "keyAlias=upload" >> android/key.properties
          echo "storeFile=upload-keystore.jks" >> android/key.properties
      
      - name: Build
        run: flutter build appbundle --release
      
      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.PLAY_STORE_JSON }}
          packageName: com.gudexpress.gud_app
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: internal

  ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - name: Build iOS
        run: flutter build ios --release --no-codesign
      # Add Fastlane configuration for App Store upload
```

### Codemagic

**codemagic.yaml:**
```yaml
workflows:
  release:
    name: Release Build
    max_build_duration: 60
    environment:
      flutter: stable
      xcode: latest
      cocoapods: default
    scripts:
      - name: Build Android
        script: flutter build appbundle --release
      - name: Build iOS
        script: flutter build ipa --release
    artifacts:
      - build/app/outputs/bundle/release/*.aab
      - build/ios/ipa/*.ipa
    publishing:
      google_play:
        credentials: $PLAY_STORE_CREDENTIALS
        track: internal
      app_store_connect:
        api_key: $APP_STORE_API_KEY
        submit_to_testflight: true
```

## Security Best Practices

### Keystore Management

1. **Never commit to version control**
   ```bash
   # Add to .gitignore
   *.jks
   *.keystore
   key.properties
   ```

2. **Secure storage**
   - Use password manager for credentials
   - Store keystore in secure location
   - Regular backups of keystore

3. **Access control**
   - Limit who has keystore access
   - Use CI/CD secrets for automation
   - Rotate keys periodically

### Certificate Management

1. **Backup certificates**
   - Export from Keychain
   - Store in secure location
   - Document expiration dates

2. **Renewal reminders**
   - Set calendar alerts 30 days before expiration
   - Renew certificates promptly
   - Update provisioning profiles

## API Key Rotation

### When to Rotate

- Every 90 days (recommended)
- After team member departure
- If key may have been compromised
- For compliance requirements

### Rotation Process

1. **Generate new keys** in Firebase Console
2. **Update .env files** with new keys
3. **Test thoroughly** in staging
4. **Deploy new build** to production
5. **Revoke old keys** after verification
6. **Document rotation** in change log

## Troubleshooting

### Android Signing Issues

**Error: No valid keystore**
```bash
# Verify keystore
keytool -list -v -keystore upload-keystore.jks
```

**Error: Wrong password**
- Double-check key.properties
- Verify passwords in secrets

### iOS Signing Issues

**Error: Provisioning profile doesn't match**
- Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- Download profiles: Xcode > Preferences > Accounts > Download Manual Profiles

**Error: Certificate expired**
- Renew in Apple Developer Portal
- Download new provisioning profiles

## Version Management

### Version Numbering

Follow Semantic Versioning (SemVer):
```
MAJOR.MINOR.PATCH+BUILD

Example: 2.1.3+42
- 2 = Major version
- 1 = Minor version
- 3 = Patch version
- 42 = Build number
```

### Update Version

**pubspec.yaml:**
```yaml
version: 2.1.3+42
```

**Build:**
```bash
flutter build appbundle --build-number=42 --build-name=2.1.3
```

## Release Checklist

- [ ] Version number updated
- [ ] Changelog updated
- [ ] All tests passing
- [ ] Lint checks clean
- [ ] Security audit completed
- [ ] ProGuard rules verified
- [ ] Environment variables set
- [ ] Keystores backed up
- [ ] Certificates valid
- [ ] Provisioning profiles current
- [ ] Release notes prepared
- [ ] Screenshots updated
- [ ] Beta testing completed
- [ ] Stakeholder approval

## Support

For signing issues:
- **Email:** devops@gudexpress.com
- **Slack:** #gud-devops
- **On-call:** +1-XXX-XXX-XXXX
