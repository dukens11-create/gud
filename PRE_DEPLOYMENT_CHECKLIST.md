# GUD Express - Pre-Deployment Checklist

Use this checklist before deploying to production or submitting to app stores.

## 🔥 Firebase Setup

### Firebase Project Configuration
- [ ] Firebase project created for production environment
- [ ] Separate Firebase project for development/staging (recommended)
- [ ] Firebase billing account configured (required for Cloud Functions)
- [ ] Firebase project ownership verified

### Firebase Authentication
- [ ] Email/Password authentication enabled
- [ ] Google Sign-In configured (Web client ID added to Firebase)
- [ ] Apple Sign In configured (iOS only - Service ID configured)
- [ ] Authentication domain allowlisted
- [ ] Email verification templates customized
- [ ] Password reset templates customized

### Cloud Firestore
- [ ] Firestore database created (Native mode)
- [ ] Firestore security rules deployed (`firebase deploy --only firestore:rules`)
- [ ] Firestore composite indexes deployed (`firebase deploy --only firestore:indexes`)
- [ ] Collections structure matches app requirements (users, loads, deliveries, expenses, etc.)
- [ ] Test data removed from production database
- [ ] Firestore backups configured

### Cloud Storage
- [ ] Firebase Storage bucket created
- [ ] Storage security rules deployed (`firebase deploy --only storage`)
- [ ] Storage CORS configuration set (if needed)
- [ ] Storage bucket location verified
- [ ] File size limits appropriate for POD images

### Cloud Functions
- [ ] Cloud Functions deployed (`cd functions && npm run deploy`)
- [ ] All 6 functions deployed successfully:
  - [ ] `notifyLoadStatusChange`
  - [ ] `notifyNewLoad`
  - [ ] `calculateEarnings`
  - [ ] `validateLoad`
  - [ ] `cleanupOldLocationData`
  - [ ] `sendOverdueLoadReminders`
- [ ] Function logs checked for errors (`firebase functions:log`)
- [ ] Function timeout and memory settings appropriate
- [ ] Scheduled functions timezone verified

### Firebase Cloud Messaging (FCM)
- [ ] FCM enabled in Firebase Console
- [ ] APNs authentication key uploaded (iOS)
- [ ] Server key obtained for backend (if applicable)
- [ ] Push notification certificates valid

### Firebase Remote Config
- [ ] Remote Config parameters configured (see docs/REMOTE_CONFIG_SETUP.md)
- [ ] All 23 feature flags and settings configured
- [ ] Default values match production requirements
- [ ] Remote Config published

### Firebase Crashlytics
- [ ] Crashlytics enabled in Firebase Console
- [ ] dSYM files uploaded for iOS (for symbolication)
- [ ] ProGuard mapping files uploaded for Android

### Firebase Analytics
- [ ] Google Analytics enabled
- [ ] Analytics events configured
- [ ] Conversion events marked (if needed)
- [ ] Audience definitions created
- [ ] Data retention settings configured

### Firebase Performance Monitoring
- [ ] Performance Monitoring enabled
- [ ] Performance targets set
- [ ] Custom traces configured (if any)

## 📱 Android Configuration

### Build Configuration
- [ ] `android/app/google-services.json` contains PRODUCTION Firebase config (not template)
- [ ] `android/key.properties` file created from template
- [ ] Android signing keystore generated:
  ```bash
  keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
  ```
- [ ] Keystore stored securely (NOT in version control)
- [ ] `android/key.properties` points to correct keystore file
- [ ] Keystore passwords documented in secure password manager
- [ ] ProGuard rules reviewed and tested
- [ ] `android/app/build.gradle` version code incremented
- [ ] `android/app/build.gradle` version name updated
- [ ] Application ID correct: `com.gudexpress.gud_app`

### Release Build Testing
- [ ] Release APK builds successfully:
  ```bash
  flutter build apk --release
  ```
- [ ] Release AAB builds successfully:
  ```bash
  flutter build appbundle --release
  ```
- [ ] Release build tested on physical device
- [ ] No debug logs or debug features in release build
- [ ] App launches without crashes
- [ ] All core features work in release mode

### Google Play Store Setup
- [ ] Google Play Console account created
- [ ] App created in Play Console
- [ ] App privacy policy URL configured
- [ ] Terms of service URL configured
- [ ] Store listing completed (title, description, screenshots)
- [ ] Content rating questionnaire completed
- [ ] Target audience selected
- [ ] Data safety section completed
- [ ] Internal testing track created (optional)
- [ ] Closed testing track created (recommended)

## 🍎 iOS Configuration

### Build Configuration
- [ ] `ios/Runner/GoogleService-Info.plist` contains PRODUCTION Firebase config (not template)
- [ ] iOS bundle identifier correct: `com.gud.express`
- [ ] Apple Developer account enrolled ($99/year)
- [ ] App ID created in Apple Developer Console
- [ ] Push Notifications capability enabled in App ID
- [ ] Background Modes capability enabled (Location, Remote notifications)
- [ ] App Groups configured (if needed)
- [ ] Provisioning profiles created and downloaded:
  - [ ] Development profile
  - [ ] Distribution profile
- [ ] Signing certificates created:
  - [ ] iOS Development certificate
  - [ ] iOS Distribution certificate
- [ ] `ios/ExportOptions.plist` configured with correct Team ID
- [ ] `ios/Runner.xcodeproj` version incremented
- [ ] `ios/Runner.xcodeproj` build number incremented

### Permission Descriptions
- [ ] All permission descriptions in `Info.plist` reviewed:
  - [ ] `NSLocationWhenInUseUsageDescription`
  - [ ] `NSLocationAlwaysUsageDescription`
  - [ ] `NSLocationAlwaysAndWhenInUseUsageDescription`
  - [ ] `NSCameraUsageDescription`
  - [ ] `NSPhotoLibraryUsageDescription`
  - [ ] `NSPhotoLibraryAddUsageDescription`

### Release Build Testing
- [ ] Release build for iOS successful:
  ```bash
  flutter build ios --release
  ```
- [ ] Archive created in Xcode
- [ ] IPA exported successfully
- [ ] App tested on physical iOS device
- [ ] All features work correctly
- [ ] No crashes or performance issues

### App Store Connect Setup
- [ ] App Store Connect account access verified
- [ ] App created in App Store Connect
- [ ] App information completed
- [ ] App privacy details submitted
- [ ] Pricing and availability configured
- [ ] Screenshots prepared for all required device sizes:
  - [ ] 6.5" Display (iPhone 14 Pro Max, etc.)
  - [ ] 5.5" Display (iPhone 8 Plus, etc.)
  - [ ] iPad Pro 12.9" (if supporting iPad)
- [ ] App preview videos prepared (optional but recommended)
- [ ] App Store promotional text written
- [ ] Keywords optimized (100 character limit)
- [ ] Support URL configured
- [ ] Marketing URL configured (optional)

## 🔐 Security & Privacy

### API Keys Security
- [ ] All API keys restricted by platform (Android package name, iOS bundle ID)
- [ ] Google Maps API key has appropriate restrictions
- [ ] Firebase API keys configured correctly
- [ ] No API keys hardcoded in source code
- [ ] All secrets stored in environment variables or secure storage
- [ ] `.env` file NOT committed to version control
- [ ] `.gitignore` properly configured to exclude:
  - [ ] `.env`
  - [ ] `google-services.json`
  - [ ] `GoogleService-Info.plist`
  - [ ] `key.properties`
  - [ ] `*.jks`
  - [ ] `*.keystore`

### Privacy Compliance
- [ ] Privacy Policy accessible and up-to-date
- [ ] Terms of Service accessible and up-to-date
- [ ] Data Deletion Policy accessible
- [ ] GDPR compliance verified (if applicable)
- [ ] CCPA compliance verified (if applicable)
- [ ] User data collection documented
- [ ] User consent mechanisms implemented
- [ ] Data retention policies defined
- [ ] User data export functionality implemented
- [ ] User data deletion functionality implemented

### Firebase Security Rules
- [ ] Firestore security rules thoroughly tested
- [ ] Storage security rules thoroughly tested
- [ ] Rules deny unauthorized access
- [ ] Rules properly validate data types and constraints
- [ ] Test suite for security rules created and passing

## 🔧 Environment Configuration

### Environment Variables
- [ ] `.env.production` file created from template
- [ ] All required production values filled in:
  - [ ] `FIREBASE_API_KEY`
  - [ ] `FIREBASE_APP_ID`
  - [ ] `FIREBASE_MESSAGING_SENDER_ID`
  - [ ] `FIREBASE_PROJECT_ID`
  - [ ] `FIREBASE_STORAGE_BUCKET`
  - [ ] `FIREBASE_AUTH_DOMAIN`
  - [ ] `GOOGLE_MAPS_API_KEY`
  - [ ] `APPLE_SERVICE_ID` (iOS)
  - [ ] `ENVIRONMENT=production`
- [ ] Environment validation passes in production mode
- [ ] No development/test credentials in production build

## 📦 App Assets

### App Icons
- [ ] Android app icons generated for all densities (mipmap folders)
- [ ] iOS app icons generated for all required sizes
- [ ] App icons meet platform guidelines:
  - [ ] No transparency
  - [ ] Square aspect ratio
  - [ ] High resolution
- [ ] Adaptive icon configured (Android)

### Splash Screens
- [ ] Launch screen configured (iOS)
- [ ] Splash screen configured (Android)
- [ ] Brand colors consistent
- [ ] Splash screens optimized for performance

### Store Assets
- [ ] App screenshots prepared (see docs/STORE_ASSETS_CHECKLIST.md)
- [ ] Feature graphic prepared (Android - 1024x500px)
- [ ] App icon prepared for stores (512x512px)
- [ ] Promotional videos prepared (optional)

## 🧪 Testing

### Manual Testing
- [ ] All user flows tested end-to-end:
  - [ ] User registration
  - [ ] Login/logout
  - [ ] Load management (create, assign, update, complete)
  - [ ] Driver location tracking
  - [ ] Proof of delivery upload
  - [ ] Expense tracking
  - [ ] Statistics and reports
  - [ ] Push notifications
  - [ ] Background location tracking
  - [ ] Geofencing triggers
- [ ] App tested on multiple devices:
  - [ ] Android (different OS versions and manufacturers)
  - [ ] iOS (different models and iOS versions)
- [ ] App tested in different network conditions:
  - [ ] WiFi
  - [ ] Mobile data (4G/5G)
  - [ ] Poor connection
  - [ ] Offline mode
- [ ] App tested in different scenarios:
  - [ ] Fresh install
  - [ ] Update from previous version
  - [ ] After app reinstall
  - [ ] Low battery mode
  - [ ] Background mode

### Automated Testing
- [ ] Unit tests passing:
  ```bash
  flutter test
  ```
- [ ] Integration tests passing (if available)
- [ ] Widget tests passing (if available)
- [ ] No critical issues in Flutter analyze:
  ```bash
  flutter analyze
  ```

### Performance Testing
- [ ] App startup time acceptable (< 3 seconds)
- [ ] Screen transitions smooth (60fps)
- [ ] Image loading optimized
- [ ] Battery consumption acceptable during location tracking
- [ ] Memory usage within limits
- [ ] No memory leaks detected
- [ ] App size reasonable (< 50MB for Android, < 100MB for iOS)

### Push Notifications Testing
- [ ] Push notifications received on Android
- [ ] Push notifications received on iOS
- [ ] Notification deep links work correctly
- [ ] Background notifications work
- [ ] Foreground notifications work
- [ ] Notification permissions requested appropriately

### Location & Geofencing Testing
- [ ] Location permissions requested appropriately
- [ ] Background location tracking works correctly
- [ ] Geofences created successfully
- [ ] Geofence entry events triggered
- [ ] Geofence exit events triggered
- [ ] Location data synced to Firestore
- [ ] Location accuracy acceptable
- [ ] Battery drain from location tracking reasonable

## 📊 Monitoring & Analytics

### Crashlytics Setup
- [ ] Crashlytics dashboard accessible
- [ ] Test crash logged successfully
- [ ] Crash reporting working in production
- [ ] Crash alerts configured
- [ ] Team members have access to Crashlytics dashboard

### Analytics Setup
- [ ] Firebase Analytics dashboard accessible
- [ ] Custom events logging correctly
- [ ] Screen view tracking working
- [ ] User properties set correctly
- [ ] Conversion events tracked

### Performance Monitoring
- [ ] Performance dashboard accessible
- [ ] Key metrics being tracked:
  - [ ] App startup time
  - [ ] Screen rendering time
  - [ ] Network request duration
- [ ] Performance alerts configured

### Cloud Functions Monitoring
- [ ] Cloud Functions dashboard accessible
- [ ] Function execution logs viewable:
  ```bash
  firebase functions:log
  ```
- [ ] Function error alerts configured
- [ ] Function quota monitoring set up

## 🚀 CI/CD Pipeline

### GitHub Actions Setup
- [ ] GitHub repository configured
- [ ] Android build workflow configured (`.github/workflows/android-build.yml`)
- [ ] iOS build workflow configured (optional)
- [ ] Firebase deployment workflow configured
- [ ] Workflows trigger correctly on:
  - [ ] Push to main branch
  - [ ] Pull requests
  - [ ] Version tags (for releases)

### GitHub Secrets Configuration
Required secrets for CI/CD:
- [ ] `FIREBASE_TOKEN` (for Firebase CLI deployment)
- [ ] `ANDROID_KEYSTORE_BASE64` (Base64-encoded keystore file)
- [ ] `ANDROID_KEY_PROPERTIES` (Key properties file content)
- [ ] `IOS_CERTIFICATE_BASE64` (iOS signing certificate)
- [ ] `IOS_PROVISIONING_PROFILE` (iOS provisioning profile)
- [ ] `GOOGLE_SERVICES_JSON` (Firebase config for Android)
- [ ] `GOOGLE_SERVICE_INFO_PLIST` (Firebase config for iOS)
- [ ] Production environment variables (if needed)

### Workflow Testing
- [ ] Android build workflow runs successfully
- [ ] APK artifact uploaded correctly
- [ ] AAB artifact uploaded correctly
- [ ] Firebase deployment workflow runs successfully
- [ ] Functions deployed via CI/CD
- [ ] Rules deployed via CI/CD

## 📝 Documentation

### Code Documentation
- [ ] README.md up to date
- [ ] CHANGELOG.md updated with latest changes
- [ ] API documentation complete (if applicable)
- [ ] Code comments added for complex logic
- [ ] Architecture documentation reviewed

### Deployment Documentation
- [ ] DEPLOYMENT.md reviewed and accurate
- [ ] Firebase setup guide reviewed (FIREBASE_SETUP.md)
- [ ] Remote Config setup guide reviewed (docs/REMOTE_CONFIG_SETUP.md)
- [ ] App Store submission guide reviewed (docs/APP_STORE_SUBMISSION_GUIDE.md)

### User Documentation
- [ ] User guide created or updated
- [ ] FAQ document created
- [ ] Troubleshooting guide available
- [ ] Support contact information provided

## 📋 Version Management

### Version Numbers
- [ ] Version number incremented in `pubspec.yaml`
- [ ] Version code incremented in `android/app/build.gradle`
- [ ] Version number incremented in Xcode project
- [ ] CHANGELOG.md updated with version changes
- [ ] Git tag created for release:
  ```bash
  git tag -a v2.1.0 -m "Release version 2.1.0"
  git push origin v2.1.0
  ```

### Release Notes
- [ ] Release notes written for this version
- [ ] Key features documented
- [ ] Bug fixes documented
- [ ] Known issues documented
- [ ] Upgrade notes provided (if applicable)

## 🎯 Final Checks

### Pre-Submission
- [ ] App thoroughly tested on real devices (not just emulators)
- [ ] All placeholder content removed
- [ ] Test/debug code removed
- [ ] Logging verbosity reduced for production
- [ ] App complies with platform guidelines:
  - [ ] [Google Play Policies](https://play.google.com/about/developer-content-policy/)
  - [ ] [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [ ] App content appropriate for target audience
- [ ] All third-party SDKs and libraries licensed correctly
- [ ] Copyright notices included
- [ ] Attributions for open source libraries included

### Submission Checklist
- [ ] All items above completed
- [ ] Team reviewed and approved for release
- [ ] Stakeholders notified of pending release
- [ ] Support team prepared for launch
- [ ] Marketing materials ready (if applicable)
- [ ] Beta testing completed (recommended)
- [ ] Emergency rollback plan documented

## 🆘 Emergency Contacts

Document key contacts for production issues:
- [ ] Firebase Support: [Firebase Support](https://firebase.google.com/support)
- [ ] Google Play Support: Play Console Help
- [ ] App Store Support: App Store Connect Help
- [ ] Team Lead: [Name/Email]
- [ ] DevOps: [Name/Email]
- [ ] On-Call Engineer: [Name/Phone]

## ✅ Sign-Off

Before proceeding to app store submission:

- **Prepared by:** _________________ Date: _______
- **Technical Review:** _________________ Date: _______
- **QA Approval:** _________________ Date: _______
- **Management Approval:** _________________ Date: _______

---

## Additional Resources

- [DEPLOYMENT.md](../DEPLOYMENT.md) - Detailed deployment instructions
- [docs/REMOTE_CONFIG_SETUP.md](../docs/REMOTE_CONFIG_SETUP.md) - Remote Config configuration
- [docs/APP_STORE_SUBMISSION_GUIDE.md](../docs/APP_STORE_SUBMISSION_GUIDE.md) - Store submission guide
- [FIREBASE_SETUP.md](../FIREBASE_SETUP.md) - Firebase setup guide
- [docs/monitoring.md](../docs/monitoring.md) - Production monitoring guide

**Remember:** Take your time with each checklist item. Rushing through deployment can lead to costly mistakes and app rejections. When in doubt, test again!
