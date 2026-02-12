# Admin-Driver Integration Guide

## Overview

This guide provides comprehensive documentation for the integration between admin and driver features in the GUD application. It covers load assignment, status tracking, performance monitoring, and troubleshooting common issues.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Load Assignment Flow](#load-assignment-flow)
3. [Driver Performance Tracking](#driver-performance-tracking)
4. [Real-time Communication](#real-time-communication)
5. [Validation and Security](#validation-and-security)
6. [Troubleshooting](#troubleshooting)
7. [Developer Onboarding](#developer-onboarding)
8. [API Reference](#api-reference)

---

## Architecture Overview

### Core Components

```
Admin Dashboard (Flutter)
    ↓
FirestoreService (Dart)
    ↓
Firestore Database
    ↓
Real-time Listeners
    ↓
Driver App (Flutter)
```

### Key Services

1. **FirestoreService** (`lib/services/firestore_service.dart`)
   - Central hub for all admin-driver communication
   - Manages CRUD operations for loads, drivers, and statistics
   - Implements real-time listeners for instant updates

2. **AuthService** (`lib/services/auth_service.dart`)
   - Handles role-based access control (admin vs driver)
   - Manages Firebase Authentication integration

3. **NotificationService** (`lib/services/notification_service.dart`)
   - Push notifications for load assignments (FCM)
   - Local notifications support

4. **SyncService** (`lib/services/sync_service.dart`)
   - Offline-first architecture
   - Periodic sync every 5 minutes
   - Conflict resolution

### Data Models

- **LoadModel** (`lib/models/load.dart`) - Load/shipment tracking
- **Driver** (`lib/models/driver.dart`) - Driver profiles and performance
- **AppUser** (`lib/models/app_user.dart`) - User roles and authentication

---

## Load Assignment Flow

### 1. Admin Creates Load

**File**: `lib/screens/admin/create_load_screen.dart`

```dart
// Admin fills out form with:
// - Load number (validated for uniqueness)
// - Driver selection (validated for existence and active status)
// - Pickup/delivery addresses
// - Rate and optional miles
// - Notes

await _firestoreService.createLoad(
  loadNumber: 'LOAD-001',
  driverId: driverUid,  // Firebase Auth UID
  driverName: 'John Doe',
  pickupAddress: '123 Main St',
  deliveryAddress: '456 Oak Ave',
  rate: 2500.0,
  createdBy: adminUid,
);
```

**Validations Performed**:
- ✅ Duplicate load number check
- ✅ Driver exists and is active
- ✅ Driver workload check (warns if 5+ active loads)
- ✅ Required fields validation
- ✅ Rate is non-negative

**Database Operation**:
```javascript
// Firestore document created in 'loads' collection
{
  loadNumber: "LOAD-001",
  driverId: "abc123",        // Driver's Firebase Auth UID
  driverName: "John Doe",    // Denormalized for performance
  pickupAddress: "123 Main St",
  deliveryAddress: "456 Oak Ave",
  rate: 2500.0,
  status: "assigned",        // Initial status
  createdBy: "admin456",     // Admin's UID
  createdAt: ServerTimestamp
}
```

### 2. Driver Receives Load

**File**: `lib/screens/driver/driver_home.dart`

```dart
// Real-time Firestore query
Stream<List<LoadModel>> streamDriverLoads(String driverId) {
  return _db
    .collection('loads')
    .where('driverId', isEqualTo: driverId)  // Filter by driver's UID
    .orderBy('createdAt', descending: true)
    .snapshots();
}
```

**Required Firestore Index**:
```json
{
  "collectionGroup": "loads",
  "fields": [
    { "fieldPath": "driverId", "order": "ASCENDING" },
    { "fieldPath": "createdAt", "order": "DESCENDING" }
  ]
}
```

### 3. Driver Updates Status

**Status Progression**:
```
assigned → in_transit → delivered → completed
```

**Methods**:
- `startTrip(loadId)` - Status: assigned → in_transit
- `endTrip(loadId, miles)` - Status: in_transit → delivered
- `updateLoadStatus(loadId, status)` - Generic status update

**Example**:
```dart
// Driver starts trip
await _firestoreService.startTrip(loadId);
// Updates: status = 'in_transit', tripStartAt = ServerTimestamp

// Driver completes delivery
await _firestoreService.endTrip(loadId, 380.5);
// Updates: status = 'delivered', deliveredAt = ServerTimestamp, miles = 380.5
```

### 4. Admin Monitors Progress

**File**: `lib/screens/admin/admin_home.dart`

```dart
// Admin sees all loads in real-time
Stream<List<LoadModel>> streamAllLoads() {
  return _db
    .collection('loads')
    .orderBy('createdAt', descending: true)
    .snapshots();
}
```

**Dashboard Features**:
- Real-time status updates
- Filter by status (assigned, in_transit, delivered)
- Search by load number or driver name
- Performance metrics

---

## Driver Performance Tracking

### Metrics Tracked

1. **Total Earnings**: Sum of rates from delivered loads
2. **Completed Loads**: Count of delivered/completed loads
3. **Active Loads**: Count of non-completed loads
4. **Last Location**: Real-time GPS tracking
5. **Average Rating**: From driver extended service

### Updating Driver Statistics

**Method**: `updateDriverStats()`

```dart
// Called after load delivery
await _firestoreService.updateDriverStats(
  driverId: driverUid,
  earnings: 2500.0,      // Load rate
  completedLoads: 1,     // Increment by 1
);
```

**Database Operation** (Atomic):
```javascript
{
  totalEarnings: FieldValue.increment(2500.0),
  completedLoads: FieldValue.increment(1)
}
```

### Real-time Earnings Dashboard

**File**: `lib/screens/driver/earnings_screen.dart`

```dart
Stream<double> streamDriverEarnings(String driverId) {
  return _db
    .collection('loads')
    .where('driverId', isEqualTo: driverId)
    .where('status', isEqualTo: 'delivered')
    .snapshots()
    .map((snap) => snap.docs.fold(0.0, (sum, doc) => sum + doc['rate']));
}
```

---

## Real-time Communication

### 1. Firestore Real-time Listeners

All admin-driver communication uses Firestore's real-time listeners for instant updates:

- **Admin Dashboard**: Monitors all loads across all drivers
- **Driver Dashboard**: Monitors driver's assigned loads
- **Performance Dashboard**: Tracks driver statistics
- **Earnings Screen**: Real-time earnings updates

### 2. Push Notifications (FCM)

**File**: `lib/services/notification_service.dart`

**Current Implementation**:
- Local notifications ✅
- Push notification setup ✅
- Cloud Functions integration ⚠️ (Not yet implemented)

**Triggers**:
- Load assigned to driver
- Load status changed by driver
- Important admin messages
- Document expiration alerts

**TODO**: Implement Cloud Functions for server-side notifications
```javascript
// functions/index.js
exports.notifyDriverOnLoadAssignment = functions.firestore
  .document('loads/{loadId}')
  .onCreate(async (snap, context) => {
    const load = snap.data();
    // Send FCM notification to driver
    await admin.messaging().sendToDevice(driverToken, notification);
  });
```

### 3. Offline Support

**File**: `lib/services/sync_service.dart`

**Features**:
- Queues operations when offline
- Periodic sync every 5 minutes
- Auto-retry on reconnect
- Conflict resolution

**Usage**:
```dart
// Operations automatically queued if offline
await _firestoreService.updateLoadStatus(loadId, 'in_transit');
// Synced automatically when back online
```

---

## Validation and Security

### Input Validation

**Load Creation Validations**:

1. **Duplicate Load Number Check**:
   ```dart
   final exists = await _firestoreService.loadNumberExists(loadNumber);
   if (exists) throw ArgumentError('Load number already exists');
   ```

2. **Driver Validation**:
   ```dart
   final isValid = await _firestoreService.isDriverValid(driverId);
   if (!isValid) throw ArgumentError('Driver not found or inactive');
   ```

3. **Workload Check**:
   ```dart
   final activeCount = await _firestoreService.getDriverActiveLoadCount(driverId);
   if (activeCount >= 5) {
     // Show warning dialog to admin
   }
   ```

4. **Field Validation**:
   - Load number: non-empty
   - Driver ID: non-empty, valid UID
   - Addresses: non-empty
   - Rate: non-negative number
   - Miles: optional, positive if provided

### Firestore Security Rules

**File**: `firestore.rules`

```javascript
// Loads collection
match /loads/{loadId} {
  // Read access
  allow read: if isAuthenticated() && 
                 (isAdmin() || resource.data.driverId == request.auth.uid);
  
  // Create access
  allow create: if isAdmin();
  
  // Update access
  allow update: if isAuthenticated() && 
                   (isAdmin() || 
                    (resource.data.driverId == request.auth.uid && 
                     request.auth.uid != null));
  
  // Delete access
  allow delete: if isAdmin();
}
```

**Key Points**:
- Drivers can only see loads with `driverId == their UID`
- Drivers can update status of their own loads only
- Only admins can create and delete loads
- All operations require authentication

### Required Firestore Indexes

**File**: `firestore.indexes.json`

```json
[
  {
    "collectionGroup": "loads",
    "fields": [
      { "fieldPath": "driverId", "order": "ASCENDING" },
      { "fieldPath": "createdAt", "order": "DESCENDING" }
    ]
  },
  {
    "collectionGroup": "loads",
    "fields": [
      { "fieldPath": "driverId", "order": "ASCENDING" },
      { "fieldPath": "status", "order": "ASCENDING" },
      { "fieldPath": "createdAt", "order": "DESCENDING" }
    ]
  }
]
```

**Deploy Indexes**:
```bash
firebase deploy --only firestore:indexes
```

---

## Troubleshooting

### Issue 1: Driver Can't See Assigned Loads

**Symptoms**:
- Admin created load with driver assigned
- Driver dashboard shows "No loads assigned yet"

**Debugging Steps**:

1. **Check Driver ID Match**:
   ```dart
   print('Driver UID: ${FirebaseAuth.instance.currentUser?.uid}');
   // Must match load.driverId exactly
   ```

2. **Verify Load in Firestore**:
   - Open Firebase Console > Firestore
   - Navigate to `loads` collection
   - Find load document
   - Check `driverId` field matches driver's Firebase Auth UID

3. **Check Firestore Rules**:
   ```bash
   firebase firestore:rules
   ```
   - Verify driver has read access to loads

4. **Check Indexes**:
   - Firebase Console > Firestore > Indexes
   - Verify `driverId + createdAt` index exists and is enabled
   - Wait 2-5 minutes if index is building

5. **Check Console Logs**:
   ```
   Look for:
   🔍 Starting to stream loads for driver: [driverId]
   📊 Received X load documents
   ⚠️  No loads found - check driverId and Firestore
   ```

**Common Fixes**:
- Ensure `driverId` is set to Firebase Auth UID (not email or name)
- Deploy missing indexes: `firebase deploy --only firestore:indexes`
- Wait for index to build (2-5 minutes)
- Check Firestore security rules allow driver read access

### Issue 2: Duplicate Load Numbers

**Symptoms**:
- Multiple loads with same load number
- Confusion in tracking and reporting

**Prevention**:
- Use `loadNumberExists()` before creating load (now implemented)
- Consider using `generateLoadNumber()` for auto-increment

**Fix Existing Duplicates**:
```dart
// Query for duplicates
final snapshot = await _db.collection('loads').get();
final loadNumbers = <String, int>{};
for (var doc in snapshot.docs) {
  final number = doc.data()['loadNumber'];
  loadNumbers[number] = (loadNumbers[number] ?? 0) + 1;
}
// Handle duplicates manually or with script
```

### Issue 3: Status Filter Not Working

**Symptoms**:
- Clicking "In Transit" filter shows no results
- Status filtering inconsistent

**Common Causes**:
1. **Hyphen vs Underscore**: Using `in-transit` instead of `in_transit`
2. **Missing Index**: Composite index not deployed
3. **Case Sensitivity**: Status values are case-sensitive

**Validation in Code**:
```dart
// Valid status values (note underscores)
static const validLoadStatuses = [
  'assigned',
  'in_transit',    // NOT 'in-transit'
  'delivered',
  'completed',
  'picked_up',     // Legacy, still supported
];
```

**Fix**:
- Always use underscores: `in_transit`, not `in-transit`
- Deploy composite index: `driverId + status + createdAt`
- Use constants from `FirestoreService.validLoadStatuses`

### Issue 4: Permission Denied Errors

**Symptoms**:
- "PERMISSION_DENIED" in console
- Operations fail silently

**Debugging**:

1. **Check Authentication**:
   ```dart
   final user = FirebaseAuth.instance.currentUser;
   if (user == null) print('User not authenticated!');
   ```

2. **Check User Role**:
   ```dart
   final role = await _firestoreService.getUserRole(user.uid);
   print('User role: $role');  // Should be 'admin' or 'driver'
   ```

3. **Verify Firestore Rules**:
   - Check if user document exists in `users` collection
   - Verify `role` field is set correctly
   - Test rules in Firebase Console > Firestore > Rules playground

4. **Check Load Ownership**:
   ```dart
   final load = await _firestoreService.getLoad(loadId);
   print('Load driver: ${load.driverId}');
   print('Current user: ${user.uid}');
   // Must match for driver operations
   ```

**Common Fixes**:
- Ensure user is authenticated before operations
- Verify user role is set in `users/{uid}` document
- Check `driverId` matches current user's UID for driver operations
- Redeploy Firestore rules: `firebase deploy --only firestore:rules`

### Issue 5: Real-time Updates Not Working

**Symptoms**:
- Changes not appearing immediately
- Dashboard requires manual refresh

**Checks**:

1. **Stream Subscription Active**:
   ```dart
   // Use StreamBuilder, not FutureBuilder
   StreamBuilder<List<LoadModel>>(
     stream: _firestoreService.streamDriverLoads(driverId),
     builder: (context, snapshot) { ... }
   )
   ```

2. **Firestore Offline Persistence**:
   ```dart
   // Check if offline persistence enabled
   await FirebaseFirestore.instance.settings = Settings(
     persistenceEnabled: true,
   );
   ```

3. **Network Connectivity**:
   - Check device internet connection
   - Check Firestore connection in Firebase Console

4. **Stream Lifecycle**:
   - Ensure widget doesn't dispose stream prematurely
   - Check for memory leaks or multiple subscriptions

---

## Developer Onboarding

### Prerequisites

1. **Flutter SDK**: Version 3.0+
2. **Firebase Project**: Configured with Firestore and Auth
3. **IDE**: VS Code or Android Studio with Flutter extensions
4. **Git**: For version control

### Setup Steps

1. **Clone Repository**:
   ```bash
   git clone https://github.com/your-org/gud.git
   cd gud
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**:
   - Copy `.env.example` to `.env`
   - Add Firebase configuration
   - Download `google-services.json` (Android)
   - Download `GoogleService-Info.plist` (iOS)

4. **Deploy Firestore Configuration**:
   ```bash
   firebase deploy --only firestore:rules
   firebase deploy --only firestore:indexes
   ```

5. **Create Test Users**:
   ```bash
   # Use Firebase Console to create:
   # - Admin user: admin@test.com
   # - Driver user: driver@test.com
   # Set role in users collection
   ```

6. **Run App**:
   ```bash
   flutter run
   ```

### Key Files to Understand

**Services** (Business Logic):
- `lib/services/firestore_service.dart` - Database operations
- `lib/services/auth_service.dart` - Authentication
- `lib/services/sync_service.dart` - Offline support

**Screens** (UI):
- `lib/screens/admin/create_load_screen.dart` - Load creation
- `lib/screens/admin/admin_home.dart` - Admin dashboard
- `lib/screens/driver/driver_home.dart` - Driver dashboard
- `lib/screens/driver/load_detail_screen.dart` - Load details

**Models** (Data Structures):
- `lib/models/load.dart` - Load model
- `lib/models/driver.dart` - Driver model
- `lib/models/app_user.dart` - User model

### Code Style Guidelines

1. **Comments**: Use inline documentation for public methods
2. **Logging**: Use emoji prefixes for easy log filtering:
   - 🔧 Setup/initialization
   - 📊 Data operations
   - ✅ Success
   - ❌ Error
   - ⚠️ Warning
   - 🔍 Debug

3. **Error Handling**:
   ```dart
   try {
     // operation
   } on FirebaseException catch (e) {
     print('❌ Firebase error: ${e.code}');
     rethrow;
   } catch (e) {
     print('❌ Unexpected error: $e');
     rethrow;
   }
   ```

4. **Validation**: Always validate inputs before database operations

### Testing

**Run Unit Tests**:
```bash
flutter test test/unit/
```

**Run Widget Tests**:
```bash
flutter test test/widget/
```

**Run Integration Tests**:
```bash
flutter test integration_test/
```

---

## API Reference

### FirestoreService Methods

#### Load Management

**createLoad()**
```dart
Future<String> createLoad({
  required String loadNumber,
  required String driverId,
  required String driverName,
  required String pickupAddress,
  required String deliveryAddress,
  required double rate,
  double? miles,
  String? notes,
  required String createdBy,
})
```
Creates new load assignment with validation.

**loadNumberExists()**
```dart
Future<bool> loadNumberExists(String loadNumber)
```
Checks if load number is already in use.

**isDriverValid()**
```dart
Future<bool> isDriverValid(String driverId)
```
Validates driver exists and is active.

**getDriverActiveLoadCount()**
```dart
Future<int> getDriverActiveLoadCount(String driverId)
```
Returns count of active (non-completed) loads for driver.

**streamDriverLoads()**
```dart
Stream<List<LoadModel>> streamDriverLoads(String driverId)
```
Real-time stream of loads for specific driver.

**streamDriverLoadsByStatus()**
```dart
Stream<List<LoadModel>> streamDriverLoadsByStatus({
  required String driverId,
  required String status,
})
```
Real-time stream of driver's loads filtered by status.

**streamAllLoads()**
```dart
Stream<List<LoadModel>> streamAllLoads()
```
Real-time stream of all loads (admin view).

**updateLoadStatus()**
```dart
Future<void> updateLoadStatus({
  required String loadId,
  required String status,
  DateTime? pickedUpAt,
  DateTime? tripStartAt,
  DateTime? deliveredAt,
})
```
Updates load status and timestamps.

**startTrip()**
```dart
Future<void> startTrip(String loadId)
```
Marks load as in_transit with timestamp.

**endTrip()**
```dart
Future<void> endTrip(String loadId, double miles)
```
Marks load as delivered with miles and timestamp.

#### Driver Management

**createDriver()**
```dart
Future<void> createDriver({
  required String driverId,
  required String name,
  required String phone,
  required String email,
  required String truckNumber,
})
```
Creates driver profile.

**updateDriverStats()**
```dart
Future<void> updateDriverStats({
  required String driverId,
  required double earnings,
  required int completedLoads,
})
```
Updates driver statistics atomically.

**streamDriverEarnings()**
```dart
Stream<double> streamDriverEarnings(String driverId)
```
Real-time stream of driver earnings.

**getDriverCompletedLoads()**
```dart
Future<int> getDriverCompletedLoads(String driverId)
```
Returns count of completed loads.

---

## Best Practices

### 1. Always Use Firebase Auth UIDs

❌ **Don't**:
```dart
driverId: driver.email  // Wrong!
driverId: driver.name   // Wrong!
```

✅ **Do**:
```dart
driverId: FirebaseAuth.instance.currentUser?.uid  // Correct!
```

### 2. Validate Before Database Operations

✅ **Do**:
```dart
// Check for duplicates
if (await loadNumberExists(loadNumber)) {
  throw ArgumentError('Duplicate load number');
}

// Validate driver
if (!await isDriverValid(driverId)) {
  throw ArgumentError('Invalid driver');
}

// Then create
await createLoad(...);
```

### 3. Use Real-time Streams

✅ **Do**:
```dart
StreamBuilder<List<LoadModel>>(
  stream: _firestoreService.streamDriverLoads(driverId),
  builder: (context, snapshot) { ... }
)
```

❌ **Don't** (unless you need one-time data):
```dart
FutureBuilder<List<LoadModel>>(
  future: _firestoreService.getDriverLoads(driverId),
  builder: (context, snapshot) { ... }
)
```

### 4. Handle Errors Gracefully

✅ **Do**:
```dart
try {
  await _firestoreService.createLoad(...);
  NavigationService.showSuccess('Load created successfully');
} on ArgumentError catch (e) {
  NavigationService.showError(e.message);
} on FirebaseException catch (e) {
  NavigationService.showError('Database error: ${e.message}');
} catch (e) {
  NavigationService.showError('Unexpected error: $e');
}
```

### 5. Use Proper Status Values

✅ **Do**:
```dart
status: 'in_transit'  // Underscore
status: 'picked_up'   // Underscore
```

❌ **Don't**:
```dart
status: 'in-transit'  // Hyphen - will not work!
status: 'picked-up'   // Hyphen - will not work!
```

---

## Support and Resources

### Documentation
- [Firebase Firestore Docs](https://firebase.google.com/docs/firestore)
- [Flutter Firebase Docs](https://firebase.flutter.dev/)
- Project README.md
- TROUBLESHOOTING.md

### Related Guides
- DRIVER_LOAD_ASSIGNMENT_FIX.md
- DRIVER_LOAD_VISIBILITY_FIX_SUMMARY.md
- FIRESTORE_RULES.md
- FIRESTORE_INDEX_SETUP.md

### Getting Help
1. Check console logs for error messages
2. Review this guide's troubleshooting section
3. Check Firebase Console for:
   - Authentication issues
   - Firestore rules
   - Index status
4. Review Firestore security rules
5. Test in Firebase Rules Playground

---

**Last Updated**: 2026-02-12  
**Version**: 1.0.0  
**Maintainer**: Development Team
