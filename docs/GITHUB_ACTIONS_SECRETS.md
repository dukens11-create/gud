# GitHub Actions Secrets Configuration

Complete guide for configuring GitHub Actions secrets for CI/CD deployment.

## 🔐 Required Secrets

### Firebase Secrets

#### `FIREBASE_TOKEN`
**Purpose**: Authenticate Firebase CLI for automated deployments

**How to Generate**:
```bash
# Login and generate CI token
firebase login:ci

# Copy the token displayed
# Example: 1//0g1234567890abcdef...
```

**How to Add**:
1. Go to GitHub repository
2. Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `FIREBASE_TOKEN`
5. Value: Paste your token
6. Click "Add secret"

---

### Android Secrets

#### `ANDROID_KEYSTORE_BASE64`
**Purpose**: Store Android signing keystore securely

**How to Generate**:
```bash
# macOS/Linux
base64 -i /path/to/upload-keystore.jks | pbcopy

# Or save to file
base64 -i /path/to/upload-keystore.jks > keystore-base64.txt

# Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\upload-keystore.jks")) | Set-Clipboard

# Or save to file
[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\upload-keystore.jks")) | Out-File keystore-base64.txt
```

**How to Use in Workflow**:
```yaml
- name: Decode Keystore
  run: |
    echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/app/upload-keystore.jks
```

#### `ANDROID_KEY_PROPERTIES`
**Purpose**: Store signing configuration

**Format**:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/home/runner/work/gud/gud/android/app/upload-keystore.jks
```

**How to Use in Workflow**:
```yaml
- name: Create key.properties
  run: |
    echo "${{ secrets.ANDROID_KEY_PROPERTIES }}" > android/key.properties
```

#### `GOOGLE_SERVICES_JSON`
**Purpose**: Firebase configuration for Android

**How to Generate**:
1. Download from Firebase Console
2. Copy entire contents of `google-services.json`
3. Add as GitHub secret

**How to Use in Workflow**:
```yaml
- name: Create google-services.json
  run: |
    echo "${{ secrets.GOOGLE_SERVICES_JSON }}" > android/app/google-services.json
```

---

### iOS Secrets

#### `IOS_CERTIFICATE_BASE64`
**Purpose**: Store iOS signing certificate securely

**How to Generate**:
```bash
# Export certificate from Keychain as .p12 file
# Then convert to base64

# macOS
base64 -i certificate.p12 | pbcopy

# Copy to clipboard or save to file
base64 -i certificate.p12 > certificate-base64.txt
```

**How to Use in Workflow**:
```yaml
- name: Import Certificate
  env:
    CERTIFICATE_BASE64: ${{ secrets.IOS_CERTIFICATE_BASE64 }}
    CERTIFICATE_PASSWORD: ${{ secrets.IOS_CERTIFICATE_PASSWORD }}
  run: |
    echo "$CERTIFICATE_BASE64" | base64 -d > certificate.p12
    
    # Create temporary keychain
    security create-keychain -p "" build.keychain
    security default-keychain -s build.keychain
    security unlock-keychain -p "" build.keychain
    
    # Import certificate
    security import certificate.p12 -k build.keychain -P "$CERTIFICATE_PASSWORD" -T /usr/bin/codesign
    
    security set-key-partition-list -S apple-tool:,apple: -s -k "" build.keychain
```

#### `IOS_CERTIFICATE_PASSWORD`
**Purpose**: Password for iOS certificate .p12 file

**Value**: The password you set when exporting the certificate

#### `IOS_PROVISIONING_PROFILE`
**Purpose**: iOS provisioning profile for distribution

**How to Generate**:
1. Download .mobileprovision file from Apple Developer Console
2. Convert to base64:
```bash
base64 -i profile.mobileprovision | pbcopy
```

**How to Use in Workflow**:
```yaml
- name: Install Provisioning Profile
  run: |
    mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
    echo "${{ secrets.IOS_PROVISIONING_PROFILE }}" | base64 -d > ~/Library/MobileDevice/Provisioning\ Profiles/profile.mobileprovision
```

#### `GOOGLE_SERVICE_INFO_PLIST`
**Purpose**: Firebase configuration for iOS

**How to Generate**:
1. Download from Firebase Console
2. Copy entire contents of `GoogleService-Info.plist`
3. Add as GitHub secret

**How to Use in Workflow**:
```yaml
- name: Create GoogleService-Info.plist
  run: |
    echo "${{ secrets.GOOGLE_SERVICE_INFO_PLIST }}" > ios/Runner/GoogleService-Info.plist
```

---

### Environment Secrets

#### `ENV_PRODUCTION`
**Purpose**: Production environment variables

**Format** (Contents of `.env.production`):
```env
FIREBASE_API_KEY=AIza...
FIREBASE_APP_ID=1:12345...
FIREBASE_MESSAGING_SENDER_ID=12345...
FIREBASE_PROJECT_ID=gud-express-prod
FIREBASE_STORAGE_BUCKET=gud-express-prod.appspot.com
FIREBASE_AUTH_DOMAIN=gud-express-prod.firebaseapp.com
GOOGLE_MAPS_API_KEY=AIza...
APPLE_SERVICE_ID=com.gud.express.service
ENVIRONMENT=production
```

**How to Use in Workflow**:
```yaml
- name: Create .env file
  run: |
    echo "${{ secrets.ENV_PRODUCTION }}" > .env
```

---

## 📋 Complete Secrets Checklist

### Required for All Workflows
- [ ] `FIREBASE_TOKEN`

### Required for Android Builds
- [ ] `ANDROID_KEYSTORE_BASE64`
- [ ] `ANDROID_KEY_PROPERTIES`
- [ ] `GOOGLE_SERVICES_JSON`
- [ ] `ENV_PRODUCTION` (if using env files)

### Required for iOS Builds
- [ ] `IOS_CERTIFICATE_BASE64`
- [ ] `IOS_CERTIFICATE_PASSWORD`
- [ ] `IOS_PROVISIONING_PROFILE`
- [ ] `GOOGLE_SERVICE_INFO_PLIST`
- [ ] `ENV_PRODUCTION` (if using env files)

### Optional Secrets
- [ ] `SLACK_WEBHOOK` (for Slack notifications)
- [ ] `TELEGRAM_BOT_TOKEN` (for Telegram notifications)
- [ ] `PLAY_STORE_SERVICE_ACCOUNT` (for automated Play Store uploads)
- [ ] `APP_STORE_CONNECT_API_KEY` (for automated App Store uploads)

---

## 🔧 Example Workflow with Secrets

### Complete Android Build & Deploy

Create `.github/workflows/android-release.yml`:

```yaml
name: Android Release Build

on:
  push:
    tags:
      - 'v*.*.*'

jobs:
  build:
    name: Build Android Release
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
          cache: true
      
      - name: Decode Android Keystore
        run: |
          echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/app/upload-keystore.jks
      
      - name: Create key.properties
        run: |
          echo "${{ secrets.ANDROID_KEY_PROPERTIES }}" > android/key.properties
      
      - name: Create google-services.json
        run: |
          echo "${{ secrets.GOOGLE_SERVICES_JSON }}" > android/app/google-services.json
      
      - name: Create .env file
        run: |
          echo "${{ secrets.ENV_PRODUCTION }}" > .env
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Build APK
        run: flutter build apk --release
      
      - name: Build App Bundle
        run: flutter build appbundle --release
      
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/app-release.apk
      
      - name: Upload AAB
        uses: actions/upload-artifact@v4
        with:
          name: release-aab
          path: build/app/outputs/bundle/release/app-release.aab
      
      - name: Create Release
        uses: softprops/action-gh-release@v1
        if: startsWith(github.ref, 'refs/tags/')
        with:
          files: |
            build/app/outputs/flutter-apk/app-release.apk
            build/app/outputs/bundle/release/app-release.aab
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## 🔒 Security Best Practices

### Do's ✅

1. **Use GitHub Secrets** for all sensitive data
2. **Rotate secrets regularly** (every 3-6 months)
3. **Use least privilege** - only grant necessary permissions
4. **Enable 2FA** on all accounts (GitHub, Firebase, Apple, Google)
5. **Audit secret access** regularly
6. **Use organization secrets** for shared secrets across repos
7. **Document all secrets** in team documentation
8. **Backup keystores** and certificates securely

### Don'ts ❌

1. **Never commit secrets** to version control
2. **Never print secrets** in workflow logs
3. **Never share secrets** via email or chat
4. **Never use the same password** for multiple services
5. **Never store secrets** in plain text files
6. **Never use production secrets** in development
7. **Don't share keystore passwords** unnecessarily
8. **Don't commit .env files** with real values

---

## 🧪 Testing Secrets Configuration

### Verify Secrets Are Set

```yaml
- name: Check Required Secrets
  run: |
    if [ -z "${{ secrets.FIREBASE_TOKEN }}" ]; then
      echo "❌ FIREBASE_TOKEN is not set"
      exit 1
    fi
    if [ -z "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" ]; then
      echo "❌ ANDROID_KEYSTORE_BASE64 is not set"
      exit 1
    fi
    echo "✅ All required secrets are configured"
```

### Test Keystore Decoding

```yaml
- name: Test Keystore
  run: |
    echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > test.jks
    keytool -list -v -keystore test.jks -storepass "${{ secrets.ANDROID_STORE_PASSWORD }}" | head -20
    rm test.jks
```

---

## 🔄 Secret Rotation

### When to Rotate

- Every 3-6 months (scheduled)
- When team member leaves
- After security incident
- When secret may be exposed
- Best practice: quarterly reviews

### How to Rotate

1. **Generate new secret** (keystore, certificate, token)
2. **Update in GitHub** Secrets
3. **Test in CI/CD** pipeline
4. **Deploy to production**
5. **Revoke old secret**
6. **Document rotation** date

### Example: Rotate Firebase Token

```bash
# Logout current session
firebase logout

# Login and get new token
firebase login:ci

# Update GitHub secret with new token

# Test deployment
firebase deploy --only functions --token NEW_TOKEN

# Verify success
```

---

## 🆘 Troubleshooting

### Secret Not Working

**Check:**
1. Secret name matches exactly (case-sensitive)
2. No extra spaces or newlines
3. Base64 encoding is correct
4. File paths are correct
5. Permissions are set correctly

### Keystore Issues

```bash
# Verify keystore is valid
keytool -list -v -keystore upload-keystore.jks

# Check base64 encoding
base64 -i upload-keystore.jks | base64 -d > test.jks
keytool -list -v -keystore test.jks

# Verify they match
md5 upload-keystore.jks test.jks
```

### Certificate Issues (iOS)

```bash
# Verify certificate
security find-identity -v -p codesigning

# Check provisioning profile
security cms -D -i profile.mobileprovision
```

---

## 📚 Additional Resources

- [GitHub Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [iOS Code Signing](https://developer.apple.com/support/code-signing/)
- [Firebase CI/CD](https://firebase.google.com/docs/cli#cli-ci-systems)

---

## 📞 Support

For issues with secrets configuration:
1. Check GitHub Actions logs
2. Verify secret values are set correctly
3. Test locally with same values
4. Contact DevOps team if issue persists

**Remember**: Never share actual secret values in support requests!
