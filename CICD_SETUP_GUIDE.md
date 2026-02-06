# CI/CD GitHub Actions Workflows - Setup Guide

This document provides setup instructions and usage guidelines for the GitHub Actions workflows created for Phase 10 CI/CD Enhancement.

## Overview

Five comprehensive GitHub Actions workflows have been created:

1. **test.yml** - Automated testing on every push and PR
2. **build-android.yml** - Android app builds
3. **build-ios.yml** - iOS app builds
4. **deploy.yml** - Multi-platform deployment
5. **code-quality.yml** - Code quality checks on PRs

## Required Secrets

### GitHub Repository Secrets

To enable all workflows, configure these secrets in your GitHub repository (`Settings > Secrets and variables > Actions`):

#### General Secrets
- `CODECOV_TOKEN` - For uploading test coverage reports to Codecov (optional)

#### Android Secrets
- `ANDROID_KEYSTORE_BASE64` - Base64-encoded keystore file for signing
- `ANDROID_KEY_PROPERTIES` - Content of key.properties file with signing details

**Creating Android secrets:**
```bash
# Encode keystore to base64
base64 -i android/app/upload-keystore.jks | pbcopy

# Create key.properties content
cat > key.properties << EOF
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=upload
storeFile=upload-keystore.jks
EOF
```

#### iOS Secrets
- `IOS_CERTIFICATE_BASE64` - Base64-encoded P12 certificate
- `IOS_CERTIFICATE_PASSWORD` - Certificate password
- `IOS_PROVISIONING_PROFILE_BASE64` - Base64-encoded provisioning profile
- `KEYCHAIN_PASSWORD` - Password for temporary keychain (generate a strong random password)

**Creating iOS secrets:**
```bash
# Encode certificate to base64
base64 -i Certificates.p12 | pbcopy

# Encode provisioning profile to base64
base64 -i profile.mobileprovision | pbcopy
```

#### Deployment Secrets
- `FIREBASE_SERVICE_ACCOUNT` - Firebase service account JSON for web deployment
- `FIREBASE_PROJECT_ID` - Your Firebase project ID
- `GOOGLE_PLAY_SERVICE_ACCOUNT` - Google Play service account JSON
- `APP_STORE_CONNECT_API_KEY` - App Store Connect API key
- `APP_STORE_CONNECT_KEY_ID` - App Store Connect key ID
- `APP_STORE_CONNECT_ISSUER_ID` - App Store Connect issuer ID

**Firebase setup:**
```bash
# Create service account in Firebase Console
# Download JSON and copy content to secret
```

**Google Play setup:**
```bash
# Create service account in Google Play Console
# Download JSON and copy content to secret
```

## Workflow Details

### 1. Automated Testing (`test.yml`)

**Triggers:**
- Every push to any branch
- Every pull request

**Features:**
- Tests on multiple Flutter versions (stable, beta)
- Runs `flutter analyze` for code quality
- Runs `flutter test` with coverage
- Uploads coverage to Codecov
- Caches dependencies for faster builds
- Parallel testing on matrix builds

**Usage:**
Automatic - no manual trigger needed. Simply push code or create a PR.

### 2. Android Build (`build-android.yml`)

**Triggers:**
- Push to `main` or `release/**` branches
- Version tags (`v*`)
- Manual trigger via GitHub Actions UI

**Features:**
- Builds both APK and App Bundle (AAB)
- Configures signing from secrets
- Version tagging based on pubspec.yaml and build number
- Uploads artifacts for 30-90 days
- Creates GitHub releases for version tags
- Gradle caching for faster builds

**Manual Trigger:**
1. Go to Actions tab in GitHub
2. Select "Build Android" workflow
3. Click "Run workflow"
4. Choose build type (debug/release)
5. Click "Run workflow"

**Artifacts:**
- APK: `android-apk-{version}-{build_number}`
- App Bundle: `android-bundle-{version}-{build_number}`

### 3. iOS Build (`build-ios.yml`)

**Triggers:**
- Push to `main` or `release/**` branches
- Version tags (`v*`)
- Manual trigger via GitHub Actions UI

**Features:**
- Builds iOS app with code signing
- CocoaPods caching
- Creates IPA file
- Uploads artifacts for 30-90 days
- Creates GitHub releases for version tags
- Secure keychain handling

**Manual Trigger:**
1. Go to Actions tab in GitHub
2. Select "Build iOS" workflow
3. Click "Run workflow"
4. Choose build type (debug/release)
5. Click "Run workflow"

**Artifacts:**
- IPA: `ios-ipa-{version}-{build_number}`
- App Bundle (debug): `ios-app-{version}-{build_number}`

### 4. Deployment (`deploy.yml`)

**Triggers:**
- Manual trigger via GitHub Actions UI
- Push of version tags (`v*.*.*`)

**Features:**
- Multi-platform deployment (web, Android, iOS)
- Environment selection (dev, staging, prod)
- Firebase Hosting for web
- Google Play for Android
- App Store Connect for iOS
- Rollback capability
- Deployment validation

**Manual Trigger:**
1. Go to Actions tab in GitHub
2. Select "Deploy" workflow
3. Click "Run workflow"
4. Select:
   - Environment (dev/staging/prod)
   - Platform (web/android/ios/all)
   - Rollback (true/false)
5. Click "Run workflow"

**Environments:**
The workflow uses GitHub Environments for deployment protection:
- `dev` - Development environment
- `staging` - Staging environment
- `prod` - Production environment
- `{environment}-android` - Android-specific environment
- `{environment}-ios` - iOS-specific environment

**Setting up environments:**
1. Go to Settings > Environments
2. Create environment (e.g., "prod")
3. Add protection rules (required reviewers, wait timer)
4. Configure environment-specific secrets

### 5. Code Quality (`code-quality.yml`)

**Triggers:**
- All pull requests

**Features:**
- Code formatting checks (`flutter format`)
- Static analysis (`flutter analyze` in strict mode)
- Unused code and file detection
- Dependency vulnerability checks
- Code metrics calculation
- TODOs and FIXMEs tracking
- Import organization checks
- Print statement detection
- Automated PR comments with results
- Quality report artifacts

**Usage:**
Automatic - runs on every PR. Reviews the comment posted on your PR for a summary.

**Quality Report:**
Available as artifact: `code-quality-report`

## Best Practices

### Version Management
- Use semantic versioning in `pubspec.yaml`
- Create version tags: `git tag v1.0.0 && git push --tags`
- Build numbers are automatically incremented using GitHub run number

### Branch Strategy
- Use `main` for production-ready code
- Use `release/**` branches for release candidates
- Use feature branches for development
- PRs automatically trigger testing and quality checks

### Secrets Management
- Rotate secrets regularly
- Use different signing keys for debug/release
- Keep production secrets separate from dev/staging
- Never commit secrets to the repository

### Caching
All workflows use caching to speed up builds:
- Flutter SDK cache
- Gradle cache (Android)
- CocoaPods cache (iOS)
- pub dependencies cache

Cache is automatically invalidated when dependencies change.

### Error Handling
- Beta channel tests are allowed to fail (`continue-on-error: true`)
- Quality checks have warnings but may not fail the build
- Deployment requires manual approval for production
- All workflows have timeout limits

## Monitoring and Debugging

### Viewing Workflow Runs
1. Go to the Actions tab in GitHub
2. Select the workflow from the left sidebar
3. Click on a specific run to see details
4. Expand jobs and steps to see logs

### Downloading Artifacts
1. Go to a completed workflow run
2. Scroll to "Artifacts" section at the bottom
3. Click on artifact name to download

### Common Issues

**Issue: Android build fails with signing error**
- Solution: Verify `ANDROID_KEYSTORE_BASE64` and `ANDROID_KEY_PROPERTIES` secrets are correct
- Check keystore password and alias match

**Issue: iOS build fails with code signing**
- Solution: Ensure certificate and provisioning profile are valid
- Verify certificate matches the provisioning profile
- Check that provisioning profile is not expired

**Issue: Tests fail on beta channel**
- Solution: This is expected - beta tests are allowed to fail
- Fix issues if they also appear on stable channel

**Issue: Deployment fails**
- Solution: Check environment secrets are configured
- Verify Firebase/Google Play/App Store credentials
- Review deployment logs for specific errors

## Workflow Maintenance

### Updating Flutter Version
Edit the workflow file and change the `channel` parameter:
```yaml
- name: Set up Flutter
  uses: subosito/flutter-action@v2
  with:
    channel: 'stable'  # Change to 'beta' or specific version
```

### Adding New Test Environments
Add to the matrix in `test.yml`:
```yaml
matrix:
  flutter-version: ['stable', 'beta', '3.16.0']
```

### Modifying Code Quality Rules
Edit `code-quality.yml` to adjust thresholds or add new checks.

### Adjusting Retention Days
Change `retention-days` in artifact upload steps:
```yaml
- name: Upload artifacts
  uses: actions/upload-artifact@v4
  with:
    retention-days: 30  # Adjust as needed
```

## Security Considerations

1. **Secrets Protection**: All sensitive data is stored in GitHub Secrets
2. **Temporary Files**: All keychain and certificate files are cleaned up after use
3. **Base64 Encoding**: Binary files are base64-encoded for secure storage
4. **Environment Protection**: Production deployments can require manual approval
5. **Audit Trail**: All workflow runs are logged and traceable

## Integration with Existing Tools

### Codecov
- Sign up at https://codecov.io
- Add repository and get token
- Add `CODECOV_TOKEN` to GitHub secrets

### Firebase
- Ensure Firebase is initialized in your project
- Create service account with deployment permissions
- Add credentials to secrets

### Google Play
- Set up Google Play Console API access
- Create service account with release permissions
- Add credentials to secrets

### App Store Connect
- Create App Store Connect API key
- Add key information to secrets

## Next Steps

1. **Configure Secrets**: Add all required secrets to your GitHub repository
2. **Test Workflows**: Make a test commit or PR to trigger workflows
3. **Set Up Environments**: Configure GitHub Environments for deployment protection
4. **Review Results**: Check the Actions tab for workflow execution results
5. **Iterate**: Adjust workflows based on your team's needs

## Support

For issues or questions:
1. Check workflow logs in GitHub Actions tab
2. Review this documentation
3. Consult GitHub Actions documentation: https://docs.github.com/actions
4. Review Flutter CI/CD best practices: https://flutter.dev/docs/deployment

## Changelog

### Version 1.0.0 (2024)
- Initial creation of all 5 workflows
- Multi-platform support (Android, iOS, Web)
- Comprehensive testing and quality checks
- Automated deployment with rollback
- Security best practices implemented
