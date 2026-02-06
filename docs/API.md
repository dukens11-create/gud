# API Documentation

**Version:** 2.0.0  
**Last Updated:** 2026-02-06

---

## Table of Contents

- [Overview](#overview)
- [Authentication API](#authentication-api)
- [Firestore Data Models](#firestore-data-models)
- [Storage API](#storage-api)
- [Cloud Functions](#cloud-functions)
- [Error Codes](#error-codes)
- [Rate Limits](#rate-limits)
- [Example Requests](#example-requests)

---

## Overview

GUD Express uses Firebase as its backend infrastructure, providing:
- **Authentication** - Firebase Authentication for user management
- **Database** - Cloud Firestore for real-time data storage
- **Storage** - Firebase Storage for file uploads
- **Functions** - Cloud Functions for server-side logic
- **Messaging** - Firebase Cloud Messaging for push notifications

### Base URLs

```
Authentication: firebase-auth-api-endpoint
Firestore: https://firestore.googleapis.com/v1/projects/YOUR_PROJECT
Storage: https://firebasestorage.googleapis.com/v0/b/YOUR_BUCKET
Functions: https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net
```

### Authentication

All API requests require authentication. Use Firebase Auth to obtain an ID token:

```dart
final user = FirebaseAuth.instance.currentUser;
final token = await user?.getIdToken();

// Include in requests
headers: {
  'Authorization': 'Bearer $token',
}
```

---

## Authentication API

### Firebase Authentication Methods

#### Email/Password Sign In

```dart
// Method
Future<UserCredential> signInWithEmailAndPassword({
  required String email,
  required String password,
})

// Usage
try {
  final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: 'user@example.com',
    password: 'securePassword123',
  );
  final user = credential.user;
  print('Logged in: ${user?.email}');
} on FirebaseAuthException catch (e) {
  if (e.code == 'user-not-found') {
    print('No user found for that email.');
  } else if (e.code == 'wrong-password') {
    print('Wrong password provided.');
  }
}
```

#### Create Account

```dart
// Method
Future<UserCredential> createUserWithEmailAndPassword({
  required String email,
  required String password,
})

// Usage
final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: 'newuser@example.com',
  password: 'securePassword123',
);
```

#### Password Reset

```dart
// Method
Future<void> sendPasswordResetEmail({
  required String email,
})

// Usage
await FirebaseAuth.instance.sendPasswordResetEmail(
  email: 'user@example.com',
);
```

#### Google Sign-In (Scaffolded)

```dart
// Method
Future<UserCredential> signInWithGoogle()

// Usage
final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
final credential = GoogleAuthProvider.credential(
  accessToken: googleAuth.accessToken,
  idToken: googleAuth.idToken,
);
final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
```

#### Sign Out

```dart
// Method
Future<void> signOut()

// Usage
await FirebaseAuth.instance.signOut();
```

### Auth Error Codes

| Code | Description |
|------|-------------|
| `user-not-found` | No user found with that email |
| `wrong-password` | Incorrect password |
| `email-already-in-use` | Email already registered |
| `invalid-email` | Email format is invalid |
| `weak-password` | Password is too weak |
| `user-disabled` | User account has been disabled |
| `operation-not-allowed` | Sign-in method not enabled |
| `too-many-requests` | Too many failed login attempts |

---

## Firestore Data Models

### Collections Structure

```
/users/{userId}
/drivers/{driverId}
/loads/{loadId}
/pods/{podId}
/expenses/{expenseId}
/statistics/{statisticId}
```

### User Model

**Collection:** `users`  
**Document ID:** Firebase Auth UID

```dart
class AppUser {
  final String uid;
  final String email;
  final String role;              // 'admin' or 'driver'
  final DateTime createdAt;
  final DateTime? lastLogin;
  final Map<String, dynamic>? metadata;
}
```

**Firestore Document:**
```json
{
  "uid": "abc123",
  "email": "user@example.com",
  "role": "admin",
  "createdAt": Timestamp(1234567890, 0),
  "lastLogin": Timestamp(1234567890, 0),
  "metadata": {
    "displayName": "John Doe",
    "phoneNumber": "+1234567890"
  }
}
```

**Queries:**
```dart
// Get user by ID
final userDoc = await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .get();

// Get all admins
final adminsQuery = await FirebaseFirestore.instance
  .collection('users')
  .where('role', isEqualTo: 'admin')
  .get();

// Get users created after date
final recentUsers = await FirebaseFirestore.instance
  .collection('users')
  .where('createdAt', isGreaterThan: Timestamp.fromDate(DateTime(2024, 1, 1)))
  .orderBy('createdAt', descending: true)
  .get();
```

### Driver Model

**Collection:** `drivers`  
**Document ID:** Firebase Auth UID

```dart
class Driver {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? truckNumber;
  final String status;            // 'available', 'on_trip', 'offline'
  final DateTime createdAt;
  final DateTime? lastActive;
  final GeoPoint? currentLocation;
  final Map<String, dynamic>? metadata;
}
```

**Firestore Document:**
```json
{
  "id": "driver123",
  "name": "John Doe",
  "email": "driver@example.com",
  "phone": "+1234567890",
  "truckNumber": "TRUCK-001",
  "status": "available",
  "createdAt": Timestamp(1234567890, 0),
  "lastActive": Timestamp(1234567890, 0),
  "currentLocation": GeoPoint(40.7128, -74.0060),
  "metadata": {
    "licenseNumber": "DL123456",
    "licenseExpiry": "2025-12-31"
  }
}
```

**Queries:**
```dart
// Get all available drivers
final availableDrivers = await FirebaseFirestore.instance
  .collection('drivers')
  .where('status', isEqualTo: 'available')
  .get();

// Get driver by truck number
final driverQuery = await FirebaseFirestore.instance
  .collection('drivers')
  .where('truckNumber', isEqualTo: 'TRUCK-001')
  .limit(1)
  .get();

// Get drivers near location (requires geohashing)
// Implementation: Use geohash library
```

### Load Model

**Collection:** `loads`  
**Document ID:** Auto-generated

```dart
class Load {
  final String id;
  final String loadNumber;
  final String pickupLocation;
  final String deliveryLocation;
  final String status;            // 'pending', 'assigned', 'in_progress', 'delivered', 'cancelled'
  final String? driverId;
  final String? driverName;
  final double rate;
  final DateTime createdAt;
  final DateTime? assignedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? estimatedDeliveryTime;
  final String? notes;
  final Map<String, dynamic>? metadata;
}
```

**Firestore Document:**
```json
{
  "id": "load123",
  "loadNumber": "LOAD-001",
  "pickupLocation": "123 Main St, City A, State 12345",
  "deliveryLocation": "456 Oak Ave, City B, State 67890",
  "status": "delivered",
  "driverId": "driver123",
  "driverName": "John Doe",
  "rate": 500.00,
  "createdAt": Timestamp(1234567890, 0),
  "assignedAt": Timestamp(1234567900, 0),
  "pickedUpAt": Timestamp(1234568000, 0),
  "deliveredAt": Timestamp(1234570000, 0),
  "estimatedDeliveryTime": Timestamp(1234575000, 0),
  "notes": "Fragile items, handle with care",
  "metadata": {
    "customer": "ABC Company",
    "weight": 1000,
    "dimensions": "10x10x10"
  }
}
```

**Queries:**
```dart
// Get all loads for driver
final driverLoads = await FirebaseFirestore.instance
  .collection('loads')
  .where('driverId', isEqualTo: driverId)
  .orderBy('createdAt', descending: true)
  .get();

// Get loads by status
final pendingLoads = await FirebaseFirestore.instance
  .collection('loads')
  .where('status', isEqualTo: 'pending')
  .get();

// Get loads in date range
final loadsInRange = await FirebaseFirestore.instance
  .collection('loads')
  .where('createdAt', isGreaterThanOrEqualTo: startDate)
  .where('createdAt', isLessThanOrEqualTo: endDate)
  .orderBy('createdAt')
  .get();

// Pagination
final firstPage = await FirebaseFirestore.instance
  .collection('loads')
  .orderBy('createdAt', descending: true)
  .limit(20)
  .get();

final lastDoc = firstPage.docs.last;
final nextPage = await FirebaseFirestore.instance
  .collection('loads')
  .orderBy('createdAt', descending: true)
  .startAfterDocument(lastDoc)
  .limit(20)
  .get();
```

### POD (Proof of Delivery) Model

**Collection:** `pods`  
**Document ID:** Auto-generated

```dart
class POD {
  final String id;
  final String loadId;
  final String? imageUrl;
  final String? notes;
  final String? signature;
  final DateTime createdAt;
  final GeoPoint? location;
}
```

**Firestore Document:**
```json
{
  "id": "pod123",
  "loadId": "load123",
  "imageUrl": "https://firebasestorage.googleapis.com/...",
  "notes": "Delivered to front desk",
  "signature": "base64_signature_data",
  "createdAt": Timestamp(1234567890, 0),
  "location": GeoPoint(40.7128, -74.0060)
}
```

**Queries:**
```dart
// Get POD for load
final podQuery = await FirebaseFirestore.instance
  .collection('pods')
  .where('loadId', isEqualTo: loadId)
  .limit(1)
  .get();

// Get all PODs by driver (via loads)
final driverPods = await FirebaseFirestore.instance
  .collection('pods')
  .where('driverId', isEqualTo: driverId)
  .orderBy('createdAt', descending: true)
  .get();
```

### Expense Model

**Collection:** `expenses`  
**Document ID:** Auto-generated

```dart
class Expense {
  final String id;
  final String loadId;
  final String driverId;
  final String category;          // 'fuel', 'tolls', 'maintenance', 'other'
  final double amount;
  final String? description;
  final String? receiptUrl;
  final DateTime createdAt;
  final String status;            // 'pending', 'approved', 'rejected'
}
```

**Firestore Document:**
```json
{
  "id": "expense123",
  "loadId": "load123",
  "driverId": "driver123",
  "category": "fuel",
  "amount": 150.00,
  "description": "Fuel at Shell Station",
  "receiptUrl": "https://firebasestorage.googleapis.com/...",
  "createdAt": Timestamp(1234567890, 0),
  "status": "approved"
}
```

**Queries:**
```dart
// Get expenses for load
final loadExpenses = await FirebaseFirestore.instance
  .collection('expenses')
  .where('loadId', isEqualTo: loadId)
  .get();

// Get driver expenses
final driverExpenses = await FirebaseFirestore.instance
  .collection('expenses')
  .where('driverId', isEqualTo: driverId)
  .orderBy('createdAt', descending: true)
  .get();

// Get pending expenses
final pendingExpenses = await FirebaseFirestore.instance
  .collection('expenses')
  .where('status', isEqualTo: 'pending')
  .get();

// Calculate total expenses
final expensesSnapshot = await FirebaseFirestore.instance
  .collection('expenses')
  .where('loadId', isEqualTo: loadId)
  .get();
  
final total = expensesSnapshot.docs.fold<double>(
  0,
  (sum, doc) => sum + (doc.data()['amount'] as double),
);
```

### Statistics Model

**Collection:** `statistics`  
**Document ID:** `{userId}_{period}` (e.g., `driver123_2024-01`)

```dart
class Statistics {
  final String id;
  final String userId;
  final String period;            // 'daily', 'weekly', 'monthly'
  final int loadsCompleted;
  final double totalEarnings;
  final double totalExpenses;
  final double netEarnings;
  final double avgDeliveryTime;
  final DateTime calculatedAt;
}
```

**Firestore Document:**
```json
{
  "id": "driver123_2024-01",
  "userId": "driver123",
  "period": "monthly",
  "loadsCompleted": 25,
  "totalEarnings": 12500.00,
  "totalExpenses": 2500.00,
  "netEarnings": 10000.00,
  "avgDeliveryTime": 4.5,
  "calculatedAt": Timestamp(1234567890, 0)
}
```

---

## Storage API

### Firebase Storage Structure

```
/pods/{loadId}/{filename}
/drivers/{driverId}/profile.jpg
/drivers/{driverId}/documents/{documentId}
/receipts/{expenseId}/{filename}
```

### Upload File

```dart
// Upload POD photo
Future<String> uploadPODPhoto(String loadId, File imageFile) async {
  final ref = FirebaseStorage.instance
    .ref()
    .child('pods/$loadId/${DateTime.now().millisecondsSinceEpoch}.jpg');
  
  // Compress image
  final compressedImage = await FlutterImageCompress.compressWithFile(
    imageFile.absolute.path,
    minWidth: 1920,
    minHeight: 1080,
    quality: 85,
  );
  
  // Upload
  final uploadTask = ref.putData(compressedImage!);
  final snapshot = await uploadTask;
  
  // Get download URL
  final downloadUrl = await snapshot.ref.getDownloadURL();
  return downloadUrl;
}
```

### Download File

```dart
// Download file URL
final url = await FirebaseStorage.instance
  .ref()
  .child('pods/$loadId/photo.jpg')
  .getDownloadURL();

// Display with CachedNetworkImage
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

### Delete File

```dart
// Delete file
await FirebaseStorage.instance
  .ref()
  .child('pods/$loadId/photo.jpg')
  .delete();
```

### Storage Metadata

```dart
// Get metadata
final metadata = await FirebaseStorage.instance
  .ref()
  .child('pods/$loadId/photo.jpg')
  .getMetadata();

print('Size: ${metadata.size} bytes');
print('Content Type: ${metadata.contentType}');
print('Updated: ${metadata.updated}');
```

---

## Cloud Functions

### Notification Functions (Scaffolded)

#### Send Load Assignment Notification

**Function:** `sendLoadAssignmentNotification`  
**Trigger:** Firestore onCreate in `/loads` collection

```javascript
// Cloud Function (Node.js)
exports.sendLoadAssignmentNotification = functions.firestore
  .document('loads/{loadId}')
  .onCreate(async (snap, context) => {
    const load = snap.data();
    const driverId = load.driverId;
    
    if (!driverId) return;
    
    // Get driver's FCM token
    const driverDoc = await admin.firestore()
      .collection('drivers')
      .doc(driverId)
      .get();
    
    const fcmToken = driverDoc.data().fcmToken;
    
    // Send notification
    const message = {
      token: fcmToken,
      notification: {
        title: 'New Load Assigned',
        body: `Load ${load.loadNumber} has been assigned to you`,
      },
      data: {
        loadId: context.params.loadId,
        type: 'load_assignment',
      },
    };
    
    await admin.messaging().send(message);
  });
```

#### Calculate Driver Statistics

**Function:** `calculateDriverStatistics`  
**Trigger:** Scheduled (daily at midnight)

```javascript
// Cloud Function (Node.js)
exports.calculateDriverStatistics = functions.pubsub
  .schedule('0 0 * * *')
  .timeZone('America/New_York')
  .onRun(async (context) => {
    const drivers = await admin.firestore()
      .collection('drivers')
      .get();
    
    for (const driver of drivers.docs) {
      const driverId = driver.id;
      const startOfMonth = new Date();
      startOfMonth.setDate(1);
      startOfMonth.setHours(0, 0, 0, 0);
      
      // Get completed loads
      const loads = await admin.firestore()
        .collection('loads')
        .where('driverId', '==', driverId)
        .where('status', '==', 'delivered')
        .where('deliveredAt', '>=', startOfMonth)
        .get();
      
      // Calculate statistics
      const loadsCompleted = loads.size;
      const totalEarnings = loads.docs.reduce(
        (sum, doc) => sum + doc.data().rate,
        0
      );
      
      // Save statistics
      await admin.firestore()
        .collection('statistics')
        .doc(`${driverId}_${startOfMonth.toISOString().slice(0, 7)}`)
        .set({
          userId: driverId,
          period: 'monthly',
          loadsCompleted,
          totalEarnings,
          calculatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
  });
```

### Callable Functions

#### Generate Load Number

**Function:** `generateLoadNumber`  
**Type:** Callable

```dart
// Flutter client
final callable = FirebaseFunctions.instance.httpsCallable('generateLoadNumber');
final result = await callable.call({
  'prefix': 'LOAD',
});
final loadNumber = result.data['loadNumber'];
```

```javascript
// Cloud Function
exports.generateLoadNumber = functions.https.onCall(async (data, context) => {
  // Verify authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }
  
  const prefix = data.prefix || 'LOAD';
  
  // Get counter
  const counterRef = admin.firestore().collection('counters').doc('loads');
  const counter = await admin.firestore().runTransaction(async (transaction) => {
    const doc = await transaction.get(counterRef);
    const currentCount = doc.exists ? doc.data().count : 0;
    const newCount = currentCount + 1;
    transaction.set(counterRef, { count: newCount });
    return newCount;
  });
  
  const loadNumber = `${prefix}-${counter.toString().padStart(5, '0')}`;
  return { loadNumber };
});
```

---

## Error Codes

### Firebase Auth Errors

| Code | HTTP Status | Description |
|------|------------|-------------|
| `auth/invalid-email` | 400 | Email format is invalid |
| `auth/user-disabled` | 403 | User account is disabled |
| `auth/user-not-found` | 404 | No user with that email |
| `auth/wrong-password` | 401 | Incorrect password |
| `auth/email-already-in-use` | 409 | Email already registered |
| `auth/weak-password` | 400 | Password is too weak |
| `auth/operation-not-allowed` | 403 | Sign-in method disabled |
| `auth/too-many-requests` | 429 | Too many attempts |

### Firestore Errors

| Code | HTTP Status | Description |
|------|------------|-------------|
| `permission-denied` | 403 | Insufficient permissions |
| `not-found` | 404 | Document not found |
| `already-exists` | 409 | Document already exists |
| `resource-exhausted` | 429 | Quota exceeded |
| `failed-precondition` | 400 | Operation failed precondition |
| `aborted` | 409 | Transaction aborted |
| `out-of-range` | 400 | Invalid field value |
| `unavailable` | 503 | Service temporarily unavailable |

### Storage Errors

| Code | HTTP Status | Description |
|------|------------|-------------|
| `storage/unauthorized` | 403 | User doesn't have permission |
| `storage/canceled` | 499 | User canceled operation |
| `storage/unknown` | 500 | Unknown error occurred |
| `storage/object-not-found` | 404 | File doesn't exist |
| `storage/quota-exceeded` | 429 | Quota exceeded |
| `storage/unauthenticated` | 401 | User not authenticated |
| `storage/retry-limit-exceeded` | 429 | Max retry time exceeded |
| `storage/invalid-checksum` | 400 | File corrupted |

### Custom Error Handling

```dart
class AppException implements Exception {
  final String code;
  final String message;
  final int? httpStatus;
  
  AppException(this.code, this.message, [this.httpStatus]);
  
  @override
  String toString() => '$code: $message';
}

// Usage
try {
  await operation();
} on FirebaseException catch (e) {
  switch (e.code) {
    case 'permission-denied':
      throw AppException(
        'access_denied',
        'You don\'t have permission to access this resource',
        403,
      );
    case 'not-found':
      throw AppException(
        'not_found',
        'The requested resource was not found',
        404,
      );
    default:
      throw AppException(
        'unknown_error',
        'An unexpected error occurred: ${e.message}',
        500,
      );
  }
}
```

---

## Rate Limits

### Firebase Limits

**Firestore:**
- Writes: 10,000/second (per database)
- Reads: 100,000/second (per database)
- Document size: 1MB max
- Collection ID: 1,500 bytes max
- Field name: 1,500 bytes max

**Storage:**
- Upload: 700GB/day (free tier)
- Download: 50GB/day (free tier)
- File size: 5TB max
- Operations: No specific limit

**Authentication:**
- Email/Password: 100 requests/second
- SMS: 10,000 verifications/day (free tier)
- Account creation: No limit

**Cloud Functions:**
- Free tier: 125,000 invocations/month, 40,000 GB-seconds/month
- Timeout: 9 minutes (540 seconds)
- Memory: 256MB default, 8GB max

### Best Practices

1. **Batch Operations**
   ```dart
   final batch = FirebaseFirestore.instance.batch();
   batch.set(docRef1, data1);
   batch.update(docRef2, data2);
   batch.delete(docRef3);
   await batch.commit();
   ```

2. **Pagination**
   ```dart
   Query query = FirebaseFirestore.instance
     .collection('loads')
     .orderBy('createdAt')
     .limit(20);
   ```

3. **Caching**
   ```dart
   // Enable offline persistence
   FirebaseFirestore.instance.settings = Settings(
     persistenceEnabled: true,
     cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
   );
   ```

---

## Example Requests

### Complete CRUD Operations

#### Create Load

```dart
Future<String> createLoad(Load load) async {
  final docRef = await FirebaseFirestore.instance
    .collection('loads')
    .add({
      'loadNumber': load.loadNumber,
      'pickupLocation': load.pickupLocation,
      'deliveryLocation': load.deliveryLocation,
      'status': 'pending',
      'rate': load.rate,
      'createdAt': FieldValue.serverTimestamp(),
    });
  
  return docRef.id;
}
```

#### Read Load

```dart
Future<Load?> getLoad(String loadId) async {
  final doc = await FirebaseFirestore.instance
    .collection('loads')
    .doc(loadId)
    .get();
  
  if (!doc.exists) return null;
  
  return Load.fromFirestore(doc);
}
```

#### Update Load

```dart
Future<void> updateLoadStatus(String loadId, String newStatus) async {
  await FirebaseFirestore.instance
    .collection('loads')
    .doc(loadId)
    .update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
}
```

#### Delete Load

```dart
Future<void> deleteLoad(String loadId) async {
  await FirebaseFirestore.instance
    .collection('loads')
    .doc(loadId)
    .delete();
}
```

### Real-Time Listening

```dart
// Listen to load changes
StreamSubscription<DocumentSnapshot> loadSubscription;

loadSubscription = FirebaseFirestore.instance
  .collection('loads')
  .doc(loadId)
  .snapshots()
  .listen((snapshot) {
    if (snapshot.exists) {
      final load = Load.fromFirestore(snapshot);
      print('Load updated: ${load.status}');
    }
  });

// Cancel subscription
loadSubscription.cancel();
```

### Complex Queries

```dart
// Get active loads for driver with pagination
Future<List<Load>> getActiveDriverLoads(
  String driverId, {
  DocumentSnapshot? startAfter,
  int limit = 20,
}) async {
  Query query = FirebaseFirestore.instance
    .collection('loads')
    .where('driverId', isEqualTo: driverId)
    .where('status', whereIn: ['assigned', 'in_progress'])
    .orderBy('createdAt', descending: true)
    .limit(limit);
  
  if (startAfter != null) {
    query = query.startAfterDocument(startAfter);
  }
  
  final snapshot = await query.get();
  return snapshot.docs.map((doc) => Load.fromFirestore(doc)).toList();
}
```

---

## Additional Resources

### Documentation
- [Firebase Auth Documentation](https://firebase.google.com/docs/auth)
- [Cloud Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Firebase Storage Documentation](https://firebase.google.com/docs/storage)
- [Cloud Functions Documentation](https://firebase.google.com/docs/functions)

### Tools
- [Firebase Console](https://console.firebase.google.com)
- [Firestore Emulator](https://firebase.google.com/docs/emulator-suite)
- [Firebase CLI](https://firebase.google.com/docs/cli)

### Best Practices
- [Firestore Data Model Best Practices](https://firebase.google.com/docs/firestore/best-practices)
- [Security Rules Best Practices](https://firebase.google.com/docs/rules/rules-and-auth)
- [Storage Best Practices](https://firebase.google.com/docs/storage/best-practices)

---

**Last Updated:** 2026-02-06  
**Maintained By:** GUD Express Development Team  
**Related Documents:**
- [FIREBASE_SETUP.md](../FIREBASE_SETUP.md)
- [ARCHITECTURE_DETAILED.md](ARCHITECTURE_DETAILED.md)
- [TESTING.md](../TESTING.md)
