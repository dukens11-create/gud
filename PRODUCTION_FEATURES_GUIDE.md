# Production-Ready Features Guide

This document provides a comprehensive guide to all the production-ready logistics features that have been scaffolded in the GUD Express app.

## Table of Contents

1. [Background GPS Tracking](#background-gps-tracking)
2. [Push Notifications](#push-notifications)
3. [Live Map Dashboard](#live-map-dashboard)
4. [Geofencing](#geofencing)
5. [Crash Reporting & Analytics](#crash-reporting--analytics)
6. [Advanced Authentication](#advanced-authentication)
7. [Enhanced Driver Management](#enhanced-driver-management)
8. [Security & Production Readiness](#security--production-readiness)

---

## Background GPS Tracking

### Overview
Continuous GPS tracking for drivers that works even when the app is in the background.

### Implementation Status
✅ Service scaffolded with starter code  
⏳ Requires flutter_background_geolocation integration for production  
⏳ Foreground service notification needed for Android

### Setup Steps

1. **Enable background location permissions:**

   **Android:** Already added to `AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
   <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
   <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>
   ```

   **iOS:** Already added to `Info.plist`:
   ```xml
   <key>NSLocationAlwaysUsageDescription</key>
   <key>UIBackgroundModes</key>
   <array>
     <string>location</string>
   </array>
   ```

2. **Configure the service in your app:**

   ```dart
   import 'package:gud_app/services/background_location_service.dart';

   // In driver dashboard
   final locationService = BackgroundLocationService();
   
   // Start tracking when driver goes on duty
   await locationService.startTracking(
     driverId,
     intervalMinutes: 5, // Update every 5 minutes
   );
   
   // Stop tracking when driver goes off duty
   locationService.stopTracking();
   ```

3. **For production use, integrate flutter_background_geolocation:**
   - Uncomment the TODO sections in `background_location_service.dart`
   - Add license key from transistorsoft.com
   - Configure settings for optimal battery/accuracy balance

### Testing
- Test on physical device (background location doesn't work in simulators)
- Check Firestore `drivers/{driverId}/lastLocation` for updates
- Monitor battery usage over extended periods

### TODO Items
- [ ] Implement flutter_background_geolocation for production reliability
- [ ] Add foreground service notification for Android (legal requirement)
- [ ] Implement offline queue for failed location updates
- [ ] Add battery optimization handling
- [ ] Implement location accuracy filtering

---

## Push Notifications

### Overview
Firebase Cloud Messaging (FCM) integration for real-time notifications about loads, status changes, and deliveries.

### Implementation Status
✅ Service scaffolded with comprehensive notification handling  
⏳ Requires FCM server configuration  
⏳ Cloud Functions needed for server-side sending

### Setup Steps

1. **Firebase Console Configuration:**
   - Go to Firebase Console > Cloud Messaging
   - Upload APNs certificate for iOS (for production)
   - Note down Server Key (for backend)

2. **Initialize in your app:**

   ```dart
   import 'package:gud_app/services/notification_service.dart';

   // In main.dart after Firebase initialization
   final notificationService = NotificationService();
   await notificationService.initialize();
   
   // Save FCM token when user logs in
   await notificationService.saveFCMToken(userId, role);
   ```

3. **Subscribe to topics:**

   ```dart
   // Subscribe to role-based notifications
   await notificationService.subscribeToTopic('drivers');
   await notificationService.subscribeToTopic('admins');
   ```

4. **Create Cloud Functions for sending notifications:**

   Create `functions/index.js`:
   ```javascript
   const functions = require('firebase-functions');
   const admin = require('firebase-admin');
   admin.initializeApp();

   // Send notification when load is assigned
   exports.sendLoadAssignmentNotification = functions.firestore
     .document('loads/{loadId}')
     .onUpdate(async (change, context) => {
       const newData = change.after.data();
       const oldData = change.before.data();
       
       // Check if driver was newly assigned
       if (!oldData.driverId && newData.driverId) {
         const driverDoc = await admin.firestore()
           .collection('users')
           .doc(newData.driverId)
           .get();
         
         const fcmToken = driverDoc.data().fcmToken;
         if (!fcmToken) return;
         
         const message = {
           notification: {
             title: 'New Load Assignment',
             body: `You've been assigned load ${newData.loadNumber}`,
           },
           data: {
             type: 'load_assignment',
             loadId: context.params.loadId,
           },
           token: fcmToken,
         };
         
         await admin.messaging().send(message);
       }
     });
   ```

### Notification Types
- **Load Assignment:** When admin assigns load to driver
- **Status Updates:** When driver or admin changes load status
- **POD Events:** When POD is uploaded or requires attention
- **Announcements:** General messages from admin
- **Reminders:** Automated reminders for pending tasks

### Testing
1. Use Firebase Console > Cloud Messaging to send test notifications
2. Test foreground, background, and terminated app states
3. Verify notification tap navigation works correctly

### TODO Items
- [ ] Implement Android notification channels (load_assignments, status_updates, etc.)
- [ ] Add notification action buttons (Accept, View, Dismiss)
- [ ] Implement rich notifications with images
- [ ] Add notification badges for unread count
- [ ] Create Cloud Functions for automated notifications
- [ ] Add notification scheduling for reminders

---

## Live Map Dashboard

### Overview
Real-time Google Maps view showing all active driver locations with interactive markers and info cards.

### Implementation Status
✅ Admin map screen scaffolded  
⏳ Requires Google Maps API keys  
⏳ Needs marker clustering for scalability

### Setup Steps

1. **Enable Google Maps APIs:**
   - Go to Google Cloud Console
   - Enable: Maps SDK for Android, Maps SDK for iOS, Geocoding API
   - Create API keys for Android and iOS

2. **Configure Android:**

   Add to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <application>
     <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_ANDROID_API_KEY_HERE"/>
   </application>
   ```

3. **Configure iOS:**

   Add to `ios/Runner/AppDelegate.swift`:
   ```swift
   import GoogleMaps

   override func application(
     _ application: UIApplication,
     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
   ) -> Bool {
     GMSServices.provideAPIKey("YOUR_IOS_API_KEY_HERE")
     GeneratedPluginRegistrant.register(with: self)
     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
   }
   ```

4. **Add map screen to admin navigation:**

   ```dart
   // In admin_home_screen.dart
   IconButton(
     icon: Icon(Icons.map),
     onPressed: () {
       Navigator.push(
         context,
         MaterialPageRoute(
           builder: (_) => AdminMapDashboardScreen(),
         ),
       );
     },
   )
   ```

### Features
- Real-time driver location markers
- Color-coded by status (green=available, blue=on duty, orange=in transit)
- Tap markers to see driver info card
- Auto-refresh as drivers move
- Active driver count display

### Testing
- Add multiple drivers with location data in Firestore
- Start background tracking for test drivers
- Verify markers update in real-time
- Test marker tap and info card display

### TODO Items
- [ ] Add map controls (traffic, satellite view toggles)
- [ ] Implement marker clustering for many drivers
- [ ] Add driver route history/breadcrumbs
- [ ] Display geofence zones on map
- [ ] Calculate and show distances/ETAs
- [ ] Add driver filtering and search
- [ ] Implement heat map for driver density

---

## Geofencing

### Overview
Automatic location-based triggers when drivers enter/exit pickup and delivery zones.

### Implementation Status
✅ Service scaffolded with geofence logic  
⏳ Requires geofence_service integration for production  
⏳ Needs automatic load status updates

### Setup Steps

1. **Create geofences when load is created:**

   ```dart
   import 'package:gud_app/services/geofence_service.dart';

   final geofenceService = GeofenceService();
   
   // When creating a load, create geofences
   final pickupGeofenceId = await geofenceService.createPickupGeofence(
     loadId: loadId,
     latitude: pickupLat,
     longitude: pickupLng,
     radius: 200.0, // meters
   );
   
   final deliveryGeofenceId = await geofenceService.createDeliveryGeofence(
     loadId: loadId,
     latitude: deliveryLat,
     longitude: deliveryLng,
     radius: 200.0,
   );
   ```

2. **Start monitoring when driver accepts load:**

   ```dart
   // In driver dashboard
   await geofenceService.startMonitoring(driverId);
   ```

3. **Stop monitoring when driver completes load:**

   ```dart
   geofenceService.stopMonitoring();
   await geofenceService.removeLoadGeofences(loadId);
   ```

### Automatic Actions
When driver enters geofence:
- ✅ Log geofence entry event to Firestore
- ⏳ Update load status automatically (at_pickup, at_delivery)
- ⏳ Send push notification to driver
- ⏳ Notify admin of arrival

### Geofence Data Structure
```javascript
// Firestore: geofences/{geofenceId}
{
  "id": "pickup_LOAD123",
  "loadId": "LOAD123",
  "type": "pickup" | "delivery",
  "latitude": 40.7128,
  "longitude": -74.0060,
  "radius": 200,
  "active": true,
  "createdAt": timestamp
}

// Firestore: geofenceEvents/{eventId}
{
  "geofenceId": "pickup_LOAD123",
  "loadId": "LOAD123",
  "driverId": "driver123",
  "type": "enter" | "exit",
  "geofenceType": "pickup" | "delivery",
  "latitude": 40.7128,
  "longitude": -74.0060,
  "timestamp": timestamp
}
```

### Testing
- Create test loads with known locations
- Manually change driver location in Firestore
- Verify geofence events are logged
- Check that appropriate actions trigger

### TODO Items
- [ ] Integrate geofence_service package for production
- [ ] Implement automatic load status updates on geofence entry
- [ ] Add push notifications for geofence events
- [ ] Implement smart radius sizing (urban vs rural)
- [ ] Add geofence analytics dashboard
- [ ] Support compound geofences for large facilities

---

## Crash Reporting & Analytics

### Overview
Comprehensive error tracking with Firebase Crashlytics and user analytics with Firebase Analytics.

### Implementation Status
✅ Service fully scaffolded  
⏳ Requires initialization in main.dart  
⏳ Needs custom event tracking throughout app

### Setup Steps

1. **Enable Crashlytics in Firebase Console:**
   - Go to Firebase Console > Crashlytics
   - Click "Enable Crashlytics"
   - Upload debug symbols for better stack traces

2. **Initialize in main.dart:**

   ```dart
   import 'package:gud_app/services/crash_reporting_service.dart';

   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     
     await Firebase.initializeApp();
     
     // Initialize crash reporting
     final crashService = CrashReportingService();
     await crashService.initialize();
     
     runApp(const GUDApp());
   }
   ```

3. **Set user context after login:**

   ```dart
   await crashService.setUserIdentifier(
     userId,
     email: userEmail,
     role: userRole,
   );
   
   await crashService.setUserProperties(
     userId: userId,
     role: userRole,
     truckNumber: truckNumber,
   );
   ```

4. **Log errors throughout the app:**

   ```dart
   try {
     // Risky operation
     await someOperation();
   } catch (e, stackTrace) {
     await crashService.logError(
       e,
       stackTrace,
       reason: 'Failed to upload POD',
       context: {
         'loadId': loadId,
         'userId': userId,
       },
     );
     
     // Show error to user
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(content: Text('Error: $e')),
     );
   }
   ```

5. **Log analytics events:**

   ```dart
   // Screen views
   await crashService.logScreenView('admin_dashboard');
   
   // Load events
   await crashService.logLoadCreated(loadId, rate);
   await crashService.logLoadStatusChange(loadId, 'assigned', 'in_transit');
   
   // POD events
   await crashService.logPODUploaded(loadId, podId);
   
   // Custom events
   await crashService.logCustomEvent('driver_location_shared', {
     'accuracy': accuracy,
     'source': 'manual',
   });
   ```

### Key Analytics Events
- `login` - User authentication
- `load_created` - New load creation
- `load_status_changed` - Status transitions
- `pod_uploaded` - POD submission
- `location_updated` - GPS tracking
- `notification_received` / `notification_opened`
- Custom events for business metrics

### Crashlytics Features
- Automatic crash detection
- Non-fatal error logging
- User context (ID, email, role)
- Custom keys for debugging
- Stack traces with source mapping

### Testing
1. Force a test crash: `crashService.forceCrash()` (debug mode only)
2. Log test errors and check Firebase Console > Crashlytics
3. Verify analytics events appear in Firebase Console > Analytics

### TODO Items
- [ ] Add performance monitoring for slow screens
- [ ] Implement custom metrics for business KPIs
- [ ] Add A/B testing with Remote Config
- [ ] Create analytics dashboard visualizations
- [ ] Implement user feedback collection
- [ ] Add session recording integration

---

## Advanced Authentication

### Overview
Extended authentication options including social login (Google, Apple) and two-factor authentication.

### Implementation Status
✅ Dependencies added  
⏳ Requires implementation of OAuth flows  
⏳ Needs UI for social login buttons  
⏳ 2FA implementation needed

### Setup Steps

1. **Google Sign-In Setup:**

   **Firebase Console:**
   - Go to Authentication > Sign-in method
   - Enable Google sign-in provider
   - Add SHA-1/SHA-256 fingerprints for Android

   **Android Configuration:**
   ```bash
   # Get SHA-1 for debug
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
   Add to Firebase Console > Project Settings > SHA certificates

   **Implementation:**
   ```dart
   import 'package:google_sign_in/google_sign_in.dart';
   import 'package:firebase_auth/firebase_auth.dart';

   Future<UserCredential?> signInWithGoogle() async {
     try {
       final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
       if (googleUser == null) return null;

       final GoogleSignInAuthentication googleAuth = 
           await googleUser.authentication;

       final credential = GoogleAuthProvider.credential(
         accessToken: googleAuth.accessToken,
         idToken: googleAuth.idToken,
       );

       return await FirebaseAuth.instance.signInWithCredential(credential);
     } catch (e) {
       print('Google sign-in error: $e');
       return null;
     }
   }
   ```

2. **Apple Sign-In Setup (iOS only):**

   **Requirements:**
   - Apple Developer account with Sign in with Apple capability
   - Configure in Firebase Console > Authentication > Sign-in method

   **Implementation:**
   ```dart
   import 'package:sign_in_with_apple/sign_in_with_apple.dart';

   Future<UserCredential?> signInWithApple() async {
     try {
       final appleCredential = await SignInWithApple.getAppleIDCredential(
         scopes: [
           AppleIDAuthorizationScopes.email,
           AppleIDAuthorizationScopes.fullName,
         ],
       );

       final oAuthCredential = OAuthProvider("apple.com").credential(
         idToken: appleCredential.identityToken,
         accessToken: appleCredential.authorizationCode,
       );

       return await FirebaseAuth.instance.signInWithCredential(oAuthCredential);
     } catch (e) {
       print('Apple sign-in error: $e');
       return null;
     }
   }
   ```

3. **Two-Factor Authentication:**

   ```dart
   // Enable phone authentication in Firebase Console first
   
   // Step 1: Send verification code
   Future<void> sendVerificationCode(String phoneNumber) async {
     await FirebaseAuth.instance.verifyPhoneNumber(
       phoneNumber: phoneNumber,
       verificationCompleted: (PhoneAuthCredential credential) async {
         // Auto-verification (Android only)
         await FirebaseAuth.instance.signInWithCredential(credential);
       },
       verificationFailed: (FirebaseAuthException e) {
         print('Verification failed: ${e.message}');
       },
       codeSent: (String verificationId, int? resendToken) {
         // Save verificationId for later use
         _verificationId = verificationId;
       },
       codeAutoRetrievalTimeout: (String verificationId) {
         _verificationId = verificationId;
       },
       timeout: Duration(seconds: 60),
     );
   }

   // Step 2: Verify code
   Future<void> verifyCode(String smsCode) async {
     final credential = PhoneAuthProvider.credential(
       verificationId: _verificationId!,
       smsCode: smsCode,
     );
     
     // Link to existing user or sign in
     await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);
   }
   ```

4. **Update Login Screen UI:**

   ```dart
   // Add to login_screen.dart
   Column(
     children: [
       // Existing email/password login
       
       Divider(),
       Text('Or sign in with'),
       
       Row(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           IconButton(
             icon: Image.asset('assets/google_logo.png'),
             onPressed: signInWithGoogle,
           ),
           if (Platform.isIOS)
             IconButton(
               icon: Icon(Icons.apple),
               onPressed: signInWithApple,
             ),
         ],
       ),
     ],
   )
   ```

### TODO Items
- [ ] Implement Google Sign-In flow with UI
- [ ] Implement Apple Sign-In flow (iOS only)
- [ ] Add phone number verification for 2FA
- [ ] Create 2FA enrollment screen
- [ ] Add biometric authentication (Face ID/Touch ID/Fingerprint)
- [ ] Implement password reset flow
- [ ] Add email verification requirement
- [ ] Create account linking for multiple providers

---

## Enhanced Driver Management

### Overview
Extended driver and truck management with documents, certifications, inspections, and enhanced status tracking.

### Implementation Status
⏳ Data model extension needed  
⏳ Document upload screens to be created  
⏳ Status management UI needed

### Data Model Extensions

1. **Extended Driver Model:**

   ```dart
   class DriverExtended {
     final String id;
     final String name;
     final String phone;
     final String truckNumber;
     final String status; // available, on_duty, off_duty, inactive
     
     // New fields
     final String? licenseNumber;
     final DateTime? licenseExpiry;
     final String? cdlClass; // A, B, C
     final List<String> endorsements; // H, N, P, S, T, X
     
     // Documents
     final DriverDocument? license;
     final DriverDocument? medicalCard;
     final DriverDocument? insurance;
     final List<DriverDocument> certifications;
     
     // Truck inspection
     final TruckInspection? lastInspection;
     final DateTime? nextInspectionDue;
     
     // Performance metrics
     final double averageRating;
     final int completedLoads;
     final double totalMiles;
     final int onTimeDeliveryRate; // percentage
   }

   class DriverDocument {
     final String id;
     final String type; // license, medical_card, insurance, certification
     final String url;
     final DateTime uploadedAt;
     final DateTime expiryDate;
     final String status; // valid, expiring_soon, expired
   }

   class TruckInspection {
     final String id;
     final String truckNumber;
     final DateTime inspectionDate;
     final String inspector;
     final bool passed;
     final List<String> issues;
     final String? notes;
   }
   ```

2. **Firestore Structure:**

   ```javascript
   // drivers/{driverId}
   {
     // Existing fields...
     
     // License info
     "licenseNumber": "DL123456",
     "licenseExpiry": timestamp,
     "cdlClass": "A",
     "endorsements": ["H", "N"],
     
     // Performance
     "averageRating": 4.8,
     "completedLoads": 245,
     "totalMiles": 125000,
     "onTimeDeliveryRate": 98,
     
     // Status timestamps
     "statusUpdatedAt": timestamp,
     "lastActiveAt": timestamp
   }

   // drivers/{driverId}/documents/{docId}
   {
     "type": "license",
     "url": "gs://...",
     "uploadedAt": timestamp,
     "expiryDate": timestamp,
     "status": "valid",
     "verifiedBy": "adminId",
     "verifiedAt": timestamp
   }

   // drivers/{driverId}/inspections/{inspectionId}
   {
     "truckNumber": "TRK-001",
     "inspectionDate": timestamp,
     "inspector": "John Doe",
     "passed": true,
     "issues": ["Low tire pressure - corrected"],
     "notes": "All systems operational",
     "nextDue": timestamp
   }
   ```

### Implementation Steps

1. **Document Upload Screen:**

   ```dart
   class DriverDocumentUploadScreen extends StatefulWidget {
     final String driverId;
     final DocumentType type;
     
     // TODO: Implement document picker
     // TODO: Add expiry date selector
     // TODO: Upload to Firebase Storage
     // TODO: Save metadata to Firestore
   }
   ```

2. **Status Management:**

   ```dart
   enum DriverStatus {
     available,    // Ready for assignment
     on_duty,      // Actively working on a load
     off_duty,     // Not working
     inactive,     // Account disabled
   }

   Future<void> updateDriverStatus(String driverId, DriverStatus status) async {
     await FirebaseFirestore.instance
         .collection('drivers')
         .doc(driverId)
         .update({
       'status': status.name,
       'statusUpdatedAt': FieldValue.serverTimestamp(),
     });
   }
   ```

3. **Document Expiration Monitoring:**

   ```dart
   // Cloud Function to check document expiration
   exports.checkDocumentExpiration = functions.pubsub
     .schedule('every 24 hours')
     .onRun(async (context) => {
       const driversSnapshot = await admin.firestore()
         .collection('drivers')
         .get();
       
       for (const driverDoc of driversSnapshot.docs) {
         const docsSnapshot = await driverDoc.ref
           .collection('documents')
           .get();
         
         for (const doc of docsSnapshot.docs) {
           const data = doc.data();
           const expiryDate = data.expiryDate.toDate();
           const daysUntilExpiry = Math.floor(
             (expiryDate - new Date()) / (1000 * 60 * 60 * 24)
           );
           
           if (daysUntilExpiry <= 30 && data.status !== 'expiring_soon') {
             // Update status
             await doc.ref.update({ status: 'expiring_soon' });
             
             // Send notification
             // TODO: Send push notification to driver
             // TODO: Send email notification to admin
           }
         }
       }
     });
   ```

### TODO Items
- [ ] Create extended driver data model
- [ ] Build document upload UI
- [ ] Implement document verification workflow
- [ ] Add truck inspection form and tracking
- [ ] Create document expiration monitoring
- [ ] Build driver performance dashboard
- [ ] Add driver rating system
- [ ] Implement driver onboarding checklist
- [ ] Create compliance reporting

---

## Security & Production Readiness

### Overview
Enhanced security measures for production deployment including Firebase App Check, stricter Firestore rules, and security best practices.

### Implementation Status
✅ Dependencies added  
⏳ App Check configuration needed  
⏳ Security rules enhancement required  
⏳ Security audit needed

### Firebase App Check Setup

1. **Enable App Check in Firebase Console:**
   - Go to Firebase Console > App Check
   - Register your app with Play Integrity API (Android) or App Attest (iOS)

2. **Configure Android:**

   ```kotlin
   // android/app/src/main/kotlin/.../MainActivity.kt
   import com.google.firebase.appcheck.FirebaseAppCheck
   import com.google.firebase.appcheck.playintegrity.PlayIntegrityAppCheckProviderFactory

   override fun onCreate(savedInstanceState: Bundle?) {
       super.onCreate(savedInstanceState)
       
       FirebaseAppCheck.getInstance().installAppCheckProviderFactory(
           PlayIntegrityAppCheckProviderFactory.getInstance()
       )
   }
   ```

3. **Configure iOS:**

   ```swift
   // ios/Runner/AppDelegate.swift
   import FirebaseAppCheck

   override func application(
     _ application: UIApplication,
     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
   ) -> Bool {
     let providerFactory = AppAttestProviderFactory()
     AppCheck.setAppCheckProviderFactory(providerFactory)
     
     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
   }
   ```

4. **Initialize in Flutter:**

   ```dart
   import 'package:firebase_app_check/firebase_app_check.dart';

   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp();
     
     // Activate App Check
     await FirebaseAppCheck.instance.activate(
       webRecaptchaSiteKey: 'YOUR_RECAPTCHA_SITE_KEY',
       androidProvider: AndroidProvider.playIntegrity,
       appleProvider: AppleProvider.appAttest,
     );
     
     runApp(const GUDApp());
   }
   ```

### Enhanced Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    function isDriver() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'driver';
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Rate limiting helper (basic)
    function rateLimited() {
      return request.time > resource.data.lastUpdate + duration.create(0, 1); // 1 second
    }
    
    // Data validation helpers
    function validEmail(email) {
      return email.matches('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$');
    }
    
    function validPhoneNumber(phone) {
      return phone.matches('^\\+?[1-9]\\d{1,14}$');
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated() && (isOwner(userId) || isAdmin());
      allow create: if isAdmin() && validEmail(request.resource.data.email);
      allow update: if isAdmin() || (isOwner(userId) && onlyUpdatingAllowedFields());
      allow delete: if isAdmin();
      
      function onlyUpdatingAllowedFields() {
        return request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['phone', 'fcmToken', 'fcmTokenUpdated', 'platform']);
      }
    }
    
    // Drivers collection
    match /drivers/{driverId} {
      allow read: if isAuthenticated();
      allow create: if isAdmin();
      allow update: if isAdmin() || (isDriver() && isOwner(driverId) && onlyUpdatingLocation());
      allow delete: if isAdmin();
      
      function onlyUpdatingLocation() {
        return request.resource.data.diff(resource.data).affectedKeys()
          .hasOnly(['lastLocation', 'lastLocationUpdate']) && rateLimited();
      }
      
      // Driver documents subcollection
      match /documents/{docId} {
        allow read: if isAuthenticated() && (isOwner(driverId) || isAdmin());
        allow write: if isAdmin() || (isDriver() && isOwner(driverId));
      }
      
      // Driver inspections subcollection
      match /inspections/{inspectionId} {
        allow read: if isAuthenticated() && (isOwner(driverId) || isAdmin());
        allow write: if isAdmin();
      }
    }
    
    // Loads collection
    match /loads/{loadId} {
      allow read: if isAuthenticated() && 
                     (isAdmin() || resource.data.driverId == request.auth.uid);
      allow create: if isAdmin();
      allow update: if isAdmin() || (isDriver() && canUpdateLoad());
      allow delete: if isAdmin();
      
      function canUpdateLoad() {
        let allowedFields = ['status', 'tripStartTime', 'tripEndTime'];
        let changedFields = request.resource.data.diff(resource.data).affectedKeys();
        return resource.data.driverId == request.auth.uid && 
               changedFields.hasOnly(allowedFields);
      }
      
      // POD subcollection
      match /pods/{podId} {
        allow read: if isAuthenticated();
        allow create: if isAuthenticated() && 
                         (isAdmin() || get(/databases/$(database)/documents/loads/$(loadId)).data.driverId == request.auth.uid);
        allow update: if isAdmin();
        allow delete: if isAdmin();
      }
    }
    
    // Geofences collection
    match /geofences/{geofenceId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    // Geofence events collection
    match /geofenceEvents/{eventId} {
      allow read: if isAuthenticated() && (isAdmin() || resource.data.driverId == request.auth.uid);
      allow create: if isAuthenticated();
      allow update, delete: if false; // Events are immutable
    }
    
    // Location history (optional)
    match /drivers/{driverId}/locationHistory/{locationId} {
      allow read: if isAuthenticated() && (isAdmin() || isOwner(driverId));
      allow create: if isDriver() && isOwner(driverId);
      allow update, delete: if false; // History is immutable
    }
  }
}
```

### Storage Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
             firestore.get(/databases/(default)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    function validImageSize() {
      return request.resource.size < 10 * 1024 * 1024; // 10MB
    }
    
    function validImageType() {
      return request.resource.contentType.matches('image/.*');
    }
    
    // POD images
    match /pods/{loadId}/{fileName} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && validImageSize() && validImageType();
    }
    
    // Driver documents
    match /drivers/{driverId}/documents/{fileName} {
      allow read: if isAuthenticated() && (request.auth.uid == driverId || isAdmin());
      allow write: if isAuthenticated() && (request.auth.uid == driverId || isAdmin()) && 
                      validImageSize();
    }
  }
}
```

### Security Best Practices

1. **Input Validation:**
   ```dart
   // Always validate user input
   String? validateEmail(String? value) {
     if (value == null || value.isEmpty) {
       return 'Email is required';
     }
     final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
     if (!emailRegex.hasMatch(value)) {
       return 'Invalid email format';
     }
     return null;
   }
   ```

2. **Secure Data Storage:**
   ```dart
   import 'package:flutter_secure_storage/flutter_secure_storage.dart';

   final secureStorage = FlutterSecureStorage();
   
   // Store sensitive data
   await secureStorage.write(key: 'auth_token', value: token);
   
   // Retrieve sensitive data
   final token = await secureStorage.read(key: 'auth_token');
   ```

3. **API Key Protection:**
   - Never commit API keys to version control
   - Use environment variables or secure key management
   - Restrict API key usage by IP/app signature in cloud console

4. **SSL Pinning (Advanced):**
   ```dart
   // TODO: Implement SSL pinning for API calls
   // Use dio package with certificate pinning
   ```

### Production Checklist

- [ ] Enable Firebase App Check for all platforms
- [ ] Review and test Firestore security rules thoroughly
- [ ] Review and test Storage security rules
- [ ] Set up SSL pinning for API calls
- [ ] Implement rate limiting
- [ ] Add input validation on all forms
- [ ] Use secure storage for sensitive data
- [ ] Remove all debug logging in production
- [ ] Enable ProGuard/R8 for Android (code obfuscation)
- [ ] Configure iOS App Transport Security
- [ ] Set up Firebase security monitoring and alerts
- [ ] Perform security audit and penetration testing
- [ ] Document incident response procedures
- [ ] Set up automated security scanning in CI/CD
- [ ] Review third-party dependencies for vulnerabilities

### TODO Items
- [ ] Complete Firebase App Check integration
- [ ] Implement enhanced Firestore rules with rate limiting
- [ ] Add input validation throughout app
- [ ] Set up secure storage for sensitive data
- [ ] Implement SSL pinning
- [ ] Add security logging and monitoring
- [ ] Perform security audit
- [ ] Create incident response plan
- [ ] Set up automated security testing

---

## Testing Strategy

See [TESTING_GUIDE.md](./TESTING_GUIDE.md) for comprehensive testing documentation.

---

## Support and Troubleshooting

### Common Issues

**Background location not working:**
- Ensure permissions granted in device settings
- Check that foreground service notification is shown (Android)
- Verify background modes enabled (iOS)

**Push notifications not received:**
- Check FCM token is saved in Firestore
- Verify notification permissions granted
- Check Firebase Console for delivery reports

**Map not displaying:**
- Verify Google Maps API keys are configured
- Check that APIs are enabled in Cloud Console
- Ensure billing is enabled for Google Cloud project

**Geofences not triggering:**
- Verify location permissions granted
- Check geofence radius is appropriate
- Monitor geofenceEvents collection for entries

### Getting Help

- Review individual service files for detailed TODOs
- Check Firebase Console for configuration issues
- Review Cloud Functions logs for server-side errors
- Check device logs for app-specific errors

---

## Next Steps

1. Complete TODO items marked as high priority
2. Implement Cloud Functions for automated notifications
3. Add comprehensive testing coverage
4. Perform security audit before production
5. Set up monitoring and alerting
6. Create user documentation and training materials

---

**Version:** 1.0.0  
**Last Updated:** 2026-02-06  
**Status:** Feature scaffolding complete, implementation in progress
