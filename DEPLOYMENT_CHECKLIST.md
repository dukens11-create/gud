# Production Deployment Checklist

This checklist ensures all production features are properly configured and tested before deployment.

## Pre-Deployment Setup

### 1. Install Dependencies ⚠️ REQUIRES FLUTTER SDK
```bash
flutter pub get
flutter pub upgrade
```

**Status**: ⏳ Pending (requires Flutter SDK on local machine)

### 2. Code Quality Checks ⚠️ REQUIRES FLUTTER SDK

#### Run Flutter Analyzer
```bash
flutter analyze
```

#### Run Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Specific test files
flutter test test/services/remote_config_service_test.dart
flutter test test/services/notification_service_test.dart
```

#### Check Code Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

**Status**: ⏳ Pending (requires Flutter SDK on local machine)

---

## Firebase Configuration

### 3. Remote Config Setup

#### Configure Parameters in Firebase Console:
1. Navigate to: Firebase Console → Remote Config
2. Add the following parameters:

**Feature Flags**:
- `enable_biometric_auth`: Boolean (default: true)
- `enable_geofencing`: Boolean (default: true)
- `enable_offline_mode`: Boolean (default: true)
- `enable_analytics`: Boolean (default: true)
- `enable_crashlytics`: Boolean (default: true)
- `enable_push_notifications`: Boolean (default: true)

**Location Settings**:
- `location_update_interval_minutes`: Number (default: 5)
- `location_accuracy_threshold_meters`: Number (default: 50)
- `enable_background_location`: Boolean (default: true)

**Geofence Settings**:
- `geofence_radius_meters`: Number (default: 200)
- `geofence_monitoring_interval_seconds`: Number (default: 30)
- `geofence_loitering_delay_ms`: Number (default: 60000)

**App Control**:
- `maintenance_mode`: Boolean (default: false)
- `maintenance_message`: String (default: "The app is currently under maintenance...")
- `force_update_required`: Boolean (default: false)
- `minimum_app_version`: String (default: "2.0.0")

**Business Logic**:
- `max_loads_per_driver`: Number (default: 5)
- `pod_upload_required`: Boolean (default: true)
- `auto_calculate_earnings`: Boolean (default: true)

3. Click "Publish changes"

**Status**: ⏳ TODO

---

### 4. Cloud Functions Deployment

#### Install Dependencies:
```bash
cd functions
npm install
```

#### Test Locally (Optional):
```bash
# Start Firebase emulators
firebase emulators:start --only functions,firestore

# In another terminal, test functions
firebase functions:shell
```

#### Deploy to Production:
```bash
# Deploy all functions
firebase deploy --only functions

# Or deploy specific functions
firebase deploy --only functions:notifyLoadStatusChange
firebase deploy --only functions:notifyNewLoad
firebase deploy --only functions:calculateEarnings
firebase deploy --only functions:validateLoad
firebase deploy --only functions:cleanupOldLocationData
firebase deploy --only functions:sendOverdueLoadReminders
```

#### Verify Deployment:
1. Check Firebase Console → Functions
2. Verify all 6 functions are deployed
3. Check function logs for any errors
4. Test each function manually

**Status**: ⏳ TODO

---

### 5. Firestore Indexes Deployment

```bash
firebase deploy --only firestore:indexes
```

#### Verify Indexes:
1. Go to Firebase Console → Firestore Database → Indexes
2. Wait for all indexes to build (this may take time for large datasets)
3. Verify composite indexes for:
   - loads (status + deliveryDate)
   - loads (driverId + status)
   - loads (status + createdAt)
   - locationHistory (timestamp)
   - geofenceEvents (loadId + timestamp)
   - geofences (loadId + active)
   - earnings (driverId + date)

**Status**: ⏳ TODO

---

### 6. Crashlytics Setup

#### Enable Crashlytics:
1. Firebase Console → Crashlytics
2. Click "Enable Crashlytics"
3. Follow setup wizard

#### Upload Debug Symbols (iOS):
```bash
# iOS debug symbols are automatically uploaded during build
flutter build ios --release
```

#### Verify:
1. Trigger a test crash (development only)
2. Check Firebase Console → Crashlytics
3. Verify crash appears within 5 minutes

**Status**: ⏳ TODO

---

### 7. FCM Configuration

#### Android FCM Setup:
1. ✅ Already configured in `android/app/google-services.json`
2. ✅ Already configured in `android/app/src/main/AndroidManifest.xml`

#### iOS FCM Setup:
1. ✅ Already configured in `ios/Runner/GoogleService-Info.plist`
2. ✅ Already configured in `ios/Runner/Info.plist`

#### APNs Certificate (iOS):
1. Go to Apple Developer Portal
2. Create APNs certificate
3. Upload to Firebase Console → Project Settings → Cloud Messaging → iOS app configuration

#### Test FCM:
1. Firebase Console → Cloud Messaging
2. Send test notification
3. Verify receipt on test device (foreground, background, terminated)

**Status**: ⏳ TODO (APNs certificate for iOS)

---

## Platform Configuration

### 8. Android Build Configuration

#### Update build.gradle:
Verify `android/app/build.gradle` has correct configuration:
- minSdkVersion: 21 or higher
- targetSdkVersion: 33 or higher
- Proguard rules if using release build

#### Generate Signing Key:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

#### Configure key.properties:
Create `android/key.properties`:
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<path to keystore>
```

**Status**: ⏳ TODO

---

### 9. iOS Build Configuration

#### Update Info.plist:
✅ Already configured with all required permissions

#### Update Xcode Project:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Update Bundle Identifier
3. Configure Signing & Capabilities:
   - ✅ Background Modes (location, fetch, remote-notification)
   - ✅ Push Notifications
   - Add App Groups (if needed)

#### Upload to App Store Connect:
```bash
flutter build ios --release
```
Then use Xcode to archive and upload.

**Status**: ⏳ TODO

---

## Testing

### 10. Feature Testing

#### Background Location Tracking:
- [ ] Install on real device (not simulator)
- [ ] Start location tracking
- [ ] Close app completely
- [ ] Wait 5+ minutes
- [ ] Check Firestore for location updates
- [ ] Verify foreground service notification (Android)
- [ ] Check battery usage

#### Geofence Monitoring:
- [ ] Create test load with pickup/delivery geofences
- [ ] Assign to test driver
- [ ] Approach location (500m)
- [ ] Verify "approaching" notification
- [ ] Arrive at location (100m)
- [ ] Verify "arrived" notification
- [ ] Verify load status auto-updated
- [ ] Check Firestore geofence events

#### Cloud Functions:
- [ ] Create new load → verify all drivers notified
- [ ] Change load status → verify notifications sent
- [ ] Mark load as delivered → verify earnings calculated
- [ ] Create invalid load → verify validation failure
- [ ] Check scheduled functions run at correct times
- [ ] Review function logs for errors

#### Remote Config:
- [ ] App loads config on startup
- [ ] Change config in Firebase Console
- [ ] Force refresh in app
- [ ] Verify new values applied
- [ ] Test maintenance mode
- [ ] Test feature flags

#### Crashlytics:
- [ ] Trigger test crash (debug build only)
- [ ] Log non-fatal error
- [ ] Add breadcrumbs
- [ ] Verify all appear in Firebase Console
- [ ] Check user identification
- [ ] Verify custom keys attached

#### Push Notifications:
- [ ] Send test notification (app foreground)
- [ ] Send test notification (app background)
- [ ] Send test notification (app terminated)
- [ ] Tap notification → verify deep link works
- [ ] Test on both Android and iOS
- [ ] Verify notification channels (Android)

#### Email Verification:
- [ ] Create new user account
- [ ] Verify email sent immediately
- [ ] Check auto-refresh every 3 seconds
- [ ] Click verification link in email
- [ ] Verify app grants access
- [ ] Test resend with cooldown
- [ ] Try accessing protected route without verification

#### Search/Filter UI:
- [ ] Search by load number
- [ ] Search by driver name
- [ ] Search by location
- [ ] Filter by status (each option)
- [ ] Select date range
- [ ] Sort by date (asc/desc)
- [ ] Sort by amount (asc/desc)
- [ ] Sort by driver (asc/desc)
- [ ] Sort by status (asc/desc)
- [ ] Clear all filters
- [ ] Verify empty states show correct messages

**Status**: ⏳ TODO

---

### 11. Performance Testing

#### App Performance:
```bash
flutter run --profile
# Use DevTools for performance profiling
flutter pub global activate devtools
flutter pub global run devtools
```

#### Load Testing:
- [ ] Test with 100+ loads
- [ ] Test with 10+ active geofences
- [ ] Test with background location tracking active
- [ ] Monitor memory usage
- [ ] Monitor battery usage
- [ ] Check for memory leaks

**Status**: ⏳ TODO

---

### 12. Security Testing

#### Permissions:
- [ ] Verify location permission requests are clear
- [ ] Test "deny" permission scenarios
- [ ] Verify background location permission flow
- [ ] Test notification permission flow

#### Data Security:
- [ ] Review Firestore security rules
- [ ] Review Storage security rules
- [ ] Test unauthorized access attempts
- [ ] Verify user data isolation
- [ ] Check sensitive data encryption

**Status**: ⏳ TODO

---

## Build & Release

### 13. Build Release Versions ⚠️ REQUIRES FLUTTER SDK

#### Android:
```bash
# Build App Bundle (recommended for Play Store)
flutter build appbundle --release

# Or build APK
flutter build apk --release --split-per-abi
```

**Output**:
- App Bundle: `build/app/outputs/bundle/release/app-release.aab`
- APKs: `build/app/outputs/flutter-apk/`

#### iOS:
```bash
# Build for iOS
flutter build ios --release

# Then use Xcode to archive and upload
```

**Status**: ⏳ TODO

---

### 14. Store Listings

#### Google Play Store:
- [ ] Upload app bundle
- [ ] Complete store listing
- [ ] Add screenshots (multiple device sizes)
- [ ] Write app description
- [ ] Set pricing and distribution
- [ ] Submit for review

#### Apple App Store:
- [ ] Upload via Xcode or Application Loader
- [ ] Complete App Store listing
- [ ] Add screenshots (multiple device sizes)
- [ ] Write app description
- [ ] Set pricing and availability
- [ ] Submit for review

**Status**: ⏳ TODO

---

## Post-Deployment

### 15. Monitoring Setup

#### Firebase Console:
- [ ] Set up Crashlytics alerts
- [ ] Configure Cloud Functions alerts
- [ ] Set up performance monitoring alerts
- [ ] Configure Analytics dashboards

#### App Store Analytics:
- [ ] Monitor download numbers
- [ ] Track ratings and reviews
- [ ] Monitor crash rates
- [ ] Check user engagement metrics

**Status**: ⏳ TODO

---

### 16. User Communication

#### Documentation:
- [ ] Update user documentation
- [ ] Create release notes
- [ ] Update help center
- [ ] Create tutorial videos (if applicable)

#### Notifications:
- [ ] Notify existing users of update
- [ ] Announce new features
- [ ] Provide migration guides (if needed)

**Status**: ⏳ TODO

---

## Rollback Plan

### 17. Rollback Procedures

#### App Version Rollback:
1. Re-release previous version in app stores
2. Use Remote Config to disable new features
3. Update `minimum_app_version` in Remote Config

#### Cloud Functions Rollback:
```bash
# Rollback to previous version
firebase functions:delete functionName
firebase deploy --only functions:functionName@previousVersion
```

#### Firestore Indexes Rollback:
1. Remove problematic indexes from `firestore.indexes.json`
2. Deploy: `firebase deploy --only firestore:indexes`

**Status**: 📝 Document procedures

---

## Final Checklist

### Before Going Live:
- [ ] All tests passing
- [ ] All Firebase services configured
- [ ] All Cloud Functions deployed
- [ ] Remote Config parameters set
- [ ] Crashlytics enabled
- [ ] FCM tested on both platforms
- [ ] Security rules reviewed
- [ ] Performance acceptable
- [ ] Store listings complete
- [ ] Monitoring configured
- [ ] Rollback plan documented
- [ ] User documentation updated

### Launch Day:
- [ ] Submit to app stores
- [ ] Monitor Crashlytics for issues
- [ ] Monitor Cloud Functions logs
- [ ] Check user feedback
- [ ] Monitor server costs
- [ ] Prepare hotfix if needed

### Week 1 Post-Launch:
- [ ] Review crash reports
- [ ] Analyze user feedback
- [ ] Monitor Cloud Functions usage
- [ ] Check feature adoption rates
- [ ] Plan hotfix release if needed
- [ ] Update documentation based on feedback

---

## Support Resources

### Firebase Support:
- Console: https://console.firebase.google.com
- Documentation: https://firebase.google.com/docs
- Status: https://status.firebase.google.com
- Support: https://firebase.google.com/support

### Flutter Support:
- Documentation: https://flutter.dev/docs
- Issues: https://github.com/flutter/flutter/issues
- Discord: https://discord.gg/flutter

### Emergency Contacts:
- Firebase Support Team: [Add contact]
- Development Team Lead: [Add contact]
- DevOps Team: [Add contact]

---

**Prepared**: February 6, 2026  
**Version**: 2.1.0+2  
**Status**: 🚀 Ready for Deployment

**Notes**: 
- Items marked ⚠️ require Flutter SDK on local machine
- Items marked ⏳ require manual action before deployment
- Complete all TODO items before production deployment
