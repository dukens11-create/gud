# API Documentation

Complete API documentation for the GUD Express Trucking Management App, covering Firebase collections, data schemas, storage structure, and authentication flows.

## Table of Contents

- [Overview](#overview)
- [Authentication](#authentication)
- [Firestore Collections](#firestore-collections)
- [Storage Structure](#storage-structure)
- [Security Rules](#security-rules)
- [Data Models](#data-models)
- [API Integration Points](#api-integration-points)
- [Error Handling](#error-handling)

## Overview

GUD Express uses Firebase as its backend infrastructure:

- **Authentication**: Firebase Authentication
- **Database**: Cloud Firestore (NoSQL)
- **Storage**: Firebase Storage
- **Analytics**: Firebase Analytics
- **Messaging**: Firebase Cloud Messaging
- **Crash Reporting**: Firebase Crashlytics

### Base Configuration

```dart
// Firebase initialization
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

FirebaseFirestore firestore = FirebaseFirestore.instance;
FirebaseAuth auth = FirebaseAuth.instance;
FirebaseStorage storage = FirebaseStorage.instance;
```

## Authentication

### Authentication Flow

```
┌─────────┐         ┌──────────────┐         ┌──────────┐
│  User   │────────>│  Firebase    │────────>│ Firestore│
│         │  Login  │     Auth     │  Token  │   User   │
└─────────┘         └──────────────┘         └──────────┘
                           │
                           ├─ Email/Password
                           ├─ Google Sign-In
                           ├─ Apple Sign-In
                           └─ Biometric Auth
```

### Authentication Methods

#### Email/Password Authentication

```dart
// Sign Up
UserCredential credential = await FirebaseAuth.instance
    .createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

// Sign In
UserCredential credential = await FirebaseAuth.instance
    .signInWithEmailAndPassword(
      email: email,
      password: password,
    );

// Sign Out
await FirebaseAuth.instance.signOut();

// Password Reset
await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
```

#### Google Sign-In

```dart
final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
final GoogleSignInAuthentication googleAuth = 
    await googleUser!.authentication;

final credential = GoogleAuthProvider.credential(
  accessToken: googleAuth.accessToken,
  idToken: googleAuth.idToken,
);

await FirebaseAuth.instance.signInWithCredential(credential);
```

#### Biometric Authentication

```dart
final bool canAuthenticate = await LocalAuthentication()
    .canCheckBiometrics;

if (canAuthenticate) {
  final bool didAuthenticate = await LocalAuthentication()
      .authenticate(
        localizedReason: 'Please authenticate to access GUD Express',
      );
}
```

### User Roles

Users have role-based access control:

```dart
// Custom claims in Firebase Auth token
{
  "role": "admin" | "driver",
  "email": "user@example.com",
  "uid": "unique-user-id"
}
```

## Firestore Collections

### Collection Structure

```
/users/{userId}
/drivers/{driverId}
/loads/{loadId}
/pods/{podId}
/expenses/{expenseId}
/invoices/{invoiceId}
/geofences/{geofenceId}
/statistics_snapshots/{snapshotId}
```

### 1. Users Collection

**Path**: `/users/{userId}`

Stores user account information and roles.

#### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| email | String | Yes | User's email address |
| role | String | Yes | User role: "admin" or "driver" |
| name | String | No | Full name |
| phone | String | No | Phone number |
| createdAt | Timestamp | Yes | Account creation timestamp |
| lastLogin | Timestamp | No | Last login timestamp |
| isActive | Boolean | Yes | Account active status |
| profilePhotoUrl | String | No | Profile photo URL |

#### Example Document

```json
{
  "email": "john.doe@gudexpress.com",
  "role": "driver",
  "name": "John Doe",
  "phone": "+1-555-0100",
  "createdAt": "2024-01-01T00:00:00Z",
  "lastLogin": "2024-01-15T08:30:00Z",
  "isActive": true,
  "profilePhotoUrl": "https://storage.googleapis.com/..."
}
```

#### Access Rules

```javascript
// Users can read their own data, admins can read all
allow read: if request.auth.uid == userId || isAdmin();
// Only admins can write
allow write: if isAdmin();
```

### 2. Drivers Collection

**Path**: `/drivers/{driverId}`

Stores driver profiles and statistics.

#### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | String | Yes | Driver's full name |
| phone | String | Yes | Phone number |
| truckNumber | String | Yes | Assigned truck number |
| status | String | Yes | "available", "on_trip", "inactive" |
| totalEarnings | Number | No | Cumulative earnings (default: 0) |
| completedLoads | Number | No | Total loads completed (default: 0) |
| isActive | Boolean | Yes | Active status (default: true) |
| lastLocation | Map | No | {lat, lng, timestamp, accuracy} |
| createdAt | Timestamp | Yes | Profile creation timestamp |

#### Example Document

```json
{
  "name": "John Doe",
  "phone": "+1-555-0100",
  "truckNumber": "TRK-001",
  "status": "on_trip",
  "totalEarnings": 45000.00,
  "completedLoads": 150,
  "isActive": true,
  "lastLocation": {
    "lat": 40.7128,
    "lng": -74.0060,
    "timestamp": "2024-01-15T14:30:00Z",
    "accuracy": 10.5
  },
  "createdAt": "2024-01-01T00:00:00Z"
}
```

#### Access Rules

```javascript
// All authenticated users can read
allow read: if isAuthenticated();
// Only admins can create/update
allow create, update: if isAdmin();
// Prevent deletion
allow delete: if false;
```

### 3. Loads Collection

**Path**: `/loads/{loadId}`

Stores load/shipment information.

#### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| loadNumber | String | Yes | Unique load identifier (e.g., "LD-001") |
| driverId | String | Yes | Assigned driver ID |
| driverName | String | No | Driver's name (denormalized) |
| pickupAddress | String | Yes | Pickup location address |
| deliveryAddress | String | Yes | Delivery location address |
| rate | Number | Yes | Payment rate for load |
| status | String | Yes | "assigned", "picked_up", "in_transit", "delivered" |
| miles | Number | No | Distance in miles (default: 0) |
| notes | String | No | Additional notes |
| createdAt | Timestamp | Yes | Load creation timestamp |
| createdBy | String | Yes | User ID who created the load |
| pickedUpAt | Timestamp | No | Pickup timestamp |
| tripStartAt | Timestamp | No | Trip start timestamp |
| tripEndAt | Timestamp | No | Trip end timestamp |
| deliveredAt | Timestamp | No | Delivery completion timestamp |

#### Example Document

```json
{
  "loadNumber": "LD-001",
  "driverId": "driver-123",
  "driverName": "John Doe",
  "pickupAddress": "123 Main St, New York, NY 10001",
  "deliveryAddress": "456 Oak Ave, Los Angeles, CA 90001",
  "rate": 1500.00,
  "status": "delivered",
  "miles": 2800.5,
  "notes": "Fragile items, handle with care",
  "createdAt": "2024-01-01T08:00:00Z",
  "createdBy": "admin-456",
  "pickedUpAt": "2024-01-01T10:00:00Z",
  "tripStartAt": "2024-01-01T10:15:00Z",
  "tripEndAt": "2024-01-05T16:30:00Z",
  "deliveredAt": "2024-01-05T17:00:00Z"
}
```

#### Access Rules

```javascript
// All authenticated users can read
allow read: if isAuthenticated();
// Only admins can create
allow create: if isAdmin();
// Admins can update, or assigned driver can update their own load
allow update: if isAdmin() || isDriver(resource.data.driverId);
// Only admins can delete
allow delete: if isAdmin();
```

### 4. PODs Collection

**Path**: `/pods/{podId}`

Stores proof of delivery documents and photos.

#### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| loadId | String | Yes | Associated load ID |
| imageUrl | String | Yes | Storage URL for POD image |
| uploadedAt | Timestamp | Yes | Upload timestamp |
| uploadedBy | String | Yes | User ID who uploaded |
| latitude | Number | No | GPS latitude |
| longitude | Number | No | GPS longitude |
| notes | String | No | Additional notes |

#### Example Document

```json
{
  "loadId": "load-123",
  "imageUrl": "gs://bucket/loads/load-123/pods/pod-456.jpg",
  "uploadedAt": "2024-01-05T17:00:00Z",
  "uploadedBy": "driver-123",
  "latitude": 34.0522,
  "longitude": -118.2437,
  "notes": "Delivered to receiving dock"
}
```

#### Access Rules

```javascript
// All authenticated users can read
allow read: if isAuthenticated();
// All authenticated users can create (upload POD)
allow create: if isAuthenticated();
// Admin or uploader can delete
allow delete: if isAdmin() || isDriver(resource.data.uploadedBy);
```

### 5. Expenses Collection

**Path**: `/expenses/{expenseId}`

Stores expense records for drivers and loads.

#### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| amount | Number | Yes | Expense amount |
| category | String | Yes | "fuel", "maintenance", "tolls", "insurance", "other" |
| description | String | Yes | Expense description |
| date | Timestamp | Yes | Expense date |
| driverId | String | No | Associated driver ID |
| loadId | String | No | Associated load ID |
| receiptUrl | String | No | Receipt image URL |
| createdBy | String | Yes | User ID who created expense |
| createdAt | Timestamp | Yes | Creation timestamp |

#### Example Document

```json
{
  "amount": 125.50,
  "category": "fuel",
  "description": "Fuel stop in Nevada",
  "date": "2024-01-03T14:30:00Z",
  "driverId": "driver-123",
  "loadId": "load-123",
  "receiptUrl": "gs://bucket/receipts/driver-123/receipt-789.jpg",
  "createdBy": "driver-123",
  "createdAt": "2024-01-03T14:35:00Z"
}
```

#### Access Rules

```javascript
// Admin can read all, driver can read their own
allow read: if isAdmin() || 
            (isAuthenticated() && resource.data.driverId == request.auth.uid);
// Any authenticated user can create
allow create: if isAuthenticated();
// Only admin can update/delete
allow update, delete: if isAdmin();
```

### 6. Invoices Collection

**Path**: `/invoices/{invoiceId}`

Stores invoice information.

#### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| invoiceNumber | String | Yes | Unique invoice number |
| loadId | String | Yes | Associated load ID |
| status | String | Yes | "draft", "sent", "paid" |
| issueDate | Timestamp | Yes | Invoice issue date |
| dueDate | Timestamp | No | Payment due date |
| clientName | String | Yes | Client/company name |
| clientAddress | String | Yes | Client address |
| lineItems | Array | Yes | Array of line items |
| subtotal | Number | Yes | Subtotal amount |
| tax | Number | No | Tax amount |
| total | Number | Yes | Total amount |
| notes | String | No | Invoice notes |
| createdBy | String | Yes | User ID who created |
| createdAt | Timestamp | Yes | Creation timestamp |

#### Line Item Schema

```json
{
  "description": "Transportation service",
  "quantity": 1,
  "unitPrice": 1500.00,
  "amount": 1500.00
}
```

#### Example Document

```json
{
  "invoiceNumber": "INV-2024-001",
  "loadId": "load-123",
  "status": "sent",
  "issueDate": "2024-01-06T00:00:00Z",
  "dueDate": "2024-01-21T00:00:00Z",
  "clientName": "ABC Logistics Inc.",
  "clientAddress": "789 Business Blvd, Chicago, IL 60601",
  "lineItems": [
    {
      "description": "Transportation: NY to LA",
      "quantity": 1,
      "unitPrice": 1500.00,
      "amount": 1500.00
    }
  ],
  "subtotal": 1500.00,
  "tax": 120.00,
  "total": 1620.00,
  "notes": "Payment due within 15 days",
  "createdBy": "admin-456",
  "createdAt": "2024-01-06T09:00:00Z"
}
```

### 7. Geofences Collection

**Path**: `/geofences/{geofenceId}`

Stores geofence definitions for automated tracking.

#### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | String | Yes | Geofence name |
| latitude | Number | Yes | Center latitude |
| longitude | Number | Yes | Center longitude |
| radius | Number | Yes | Radius in meters |
| type | String | Yes | "pickup" or "delivery" |
| loadId | String | No | Associated load ID |
| isActive | Boolean | Yes | Active status |
| createdAt | Timestamp | Yes | Creation timestamp |

#### Example Document

```json
{
  "name": "ABC Warehouse",
  "latitude": 40.7128,
  "longitude": -74.0060,
  "radius": 200,
  "type": "pickup",
  "loadId": "load-123",
  "isActive": true,
  "createdAt": "2024-01-01T08:00:00Z"
}
```

### 8. Statistics Snapshots Collection

**Path**: `/statistics_snapshots/{snapshotId}`

Stores periodic statistics snapshots.

#### Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| period | String | Yes | "daily", "weekly", "monthly" |
| date | Timestamp | Yes | Snapshot date |
| totalRevenue | Number | Yes | Total revenue |
| totalExpenses | Number | Yes | Total expenses |
| netProfit | Number | Yes | Net profit |
| completedLoads | Number | Yes | Loads completed |
| activeDrivers | Number | Yes | Active drivers count |
| metrics | Map | No | Additional metrics |

#### Example Document

```json
{
  "period": "monthly",
  "date": "2024-01-01T00:00:00Z",
  "totalRevenue": 125000.00,
  "totalExpenses": 45000.00,
  "netProfit": 80000.00,
  "completedLoads": 85,
  "activeDrivers": 12,
  "metrics": {
    "averageLoadRate": 1470.59,
    "averageMilesPerLoad": 2100.5
  }
}
```

## Storage Structure

### Firebase Storage Buckets

Storage is organized in the following structure:

```
gs://[PROJECT-ID].appspot.com/
├── loads/
│   └── {loadId}/
│       └── pods/
│           ├── pod-1.jpg
│           ├── pod-2.jpg
│           └── pod-3.jpg
├── receipts/
│   └── {driverId}/
│       ├── receipt-1.jpg
│       ├── receipt-2.jpg
│       └── receipt-3.jpg
├── drivers/
│   └── {driverId}/
│       ├── license.pdf
│       ├── insurance.pdf
│       └── documents/
└── profiles/
    └── {userId}/
        └── profile-photo.jpg
```

### Upload POD Image

```dart
// Upload proof of delivery
final ref = FirebaseStorage.instance
    .ref()
    .child('loads/$loadId/pods/$fileName');

await ref.putFile(imageFile);
final url = await ref.getDownloadURL();
```

### Upload Receipt

```dart
// Upload expense receipt
final ref = FirebaseStorage.instance
    .ref()
    .child('receipts/$driverId/$fileName');

await ref.putFile(imageFile);
final url = await ref.getDownloadURL();
```

### Storage Security Rules

```javascript
// POD images
match /loads/{loadId}/pods/{fileName} {
  allow read: if isAuthenticated();
  allow write: if isAuthenticated() && 
    request.resource.size < 10 * 1024 * 1024 && // 10MB limit
    request.resource.contentType.matches('image/.*');
  allow delete: if isAdmin();
}

// Receipt images
match /receipts/{driverId}/{fileName} {
  allow read: if isAdmin() || 
              (isAuthenticated() && request.auth.uid == driverId);
  allow write: if isAuthenticated() && 
    request.resource.size < 10 * 1024 * 1024;
  allow delete: if isAdmin();
}
```

## Security Rules

### Firestore Security Rules

Complete security rules are defined in `firestore.rules`:

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
             request.auth.token.role == 'admin';
    }
    
    function isDriver(driverId) {
      return isAuthenticated() && 
             request.auth.uid == driverId;
    }
    
    // Apply collection rules...
  }
}
```

## Data Models

### Data Model Relationships

```
User (1) ───────> (1) Driver
                      │
                      │ (1:M)
                      ▼
                   Loads ◄───── (1:M) ───── PODs
                      │
                      │ (1:M)
                      ▼
                  Expenses
                      
Loads (1) ───────> (1) Invoice
```

### Model Classes

All models are defined in `lib/models/`:

- `app_user.dart` - User model
- `driver.dart` - Driver model
- `load.dart` - Load model
- `pod.dart` - POD model
- `expense.dart` - Expense model
- `invoice.dart` - Invoice model
- `statistics.dart` - Statistics model

## API Integration Points

### Service Layer

All Firebase interactions go through service classes in `lib/services/`:

#### AuthService
```dart
class AuthService {
  Future<User?> signIn(String email, String password);
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Stream<User?> get authStateChanges;
}
```

#### FirestoreService
```dart
class FirestoreService {
  // Drivers
  Future<Driver?> getDriver(String driverId);
  Stream<List<Driver>> streamDrivers();
  Future<void> updateDriver({...});
  
  // Loads
  Future<String> createLoad({...});
  Stream<List<LoadModel>> streamLoads({String? driverId});
  Future<void> updateLoadStatus(String loadId, String status);
  
  // Expenses
  Future<void> createExpense(Expense expense);
  Stream<List<Expense>> streamExpenses({String? driverId});
}
```

#### StorageService
```dart
class StorageService {
  Future<String> uploadPOD(String loadId, File imageFile);
  Future<String> uploadReceipt(String driverId, File imageFile);
  Future<void> deleteFile(String path);
}
```

#### InvoiceService
```dart
class InvoiceService {
  Future<String> createInvoice(Invoice invoice);
  Future<void> updateInvoiceStatus(String id, String status);
  Stream<List<Invoice>> streamInvoices();
  Future<Uint8List> generateInvoicePDF(Invoice invoice);
}
```

## Error Handling

### Firebase Exception Handling

```dart
try {
  await firestoreService.createLoad(...);
} on FirebaseException catch (e) {
  switch (e.code) {
    case 'permission-denied':
      print('Permission denied');
      break;
    case 'not-found':
      print('Document not found');
      break;
    case 'unavailable':
      print('Service unavailable');
      break;
    default:
      print('Firebase error: ${e.message}');
  }
} catch (e) {
  print('Unexpected error: $e');
}
```

### Common Error Codes

| Code | Description |
|------|-------------|
| permission-denied | User lacks permission |
| not-found | Document doesn't exist |
| already-exists | Document already exists |
| invalid-argument | Invalid data provided |
| unavailable | Service temporarily unavailable |
| unauthenticated | User not authenticated |

## Cloud Functions (Future Enhancement)

Currently not implemented, but planned for future releases:

- Automated email notifications for invoices
- Scheduled statistics aggregation
- Data cleanup and archiving
- Push notification triggers
- Webhook integrations

---

**Last Updated**: Phase 11 Completion
**Version**: 2.0.0
**Firebase Project**: GUD Express
