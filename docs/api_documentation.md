# GUD Express API Documentation

Complete reference for all service classes and their methods in the GUD Express application.

## Overview

The GUD Express app is built with a service-oriented architecture where business logic is encapsulated in reusable service classes. All services are located in `lib/services/`.

## Quick Reference

| Service | Purpose | Key Methods |
|---------|---------|-------------|
| `AuthService` | User authentication | `signIn()`, `register()`, `signOut()` |
| `FirestoreService` | Database operations | `createLoad()`, `streamDrivers()`, `updateLoadStatus()` |
| `StorageService` | File management | `pickImage()`, `uploadPodImage()` |
| `AdvancedAuthService` | OAuth providers | `signInWithGoogle()`, `signInWithApple()` |
| `LocationService` | GPS positioning | `getCurrentLocation()`, `requestLocationPermission()` |
| `BackgroundLocationService` | Background tracking | `startTracking()`, `stopTracking()` |
| `NotificationService` | Push notifications | `initialize()`, `sendNotification()` |
| `GeofenceService` | Geofencing | `createPickupGeofence()`, `monitorGeofences()` |
| `ExpenseService` | Expense tracking | `createExpense()`, `streamDriverExpenses()` |
| `StatisticsService` | Analytics | `calculateStatistics()`, `streamStatistics()` |
| `CrashReportingService` | Error tracking | `initialize()`, `logError()` |

---

## AuthService

**Location:** `lib/services/auth_service.dart`

### Purpose
Handles all authentication operations including sign in, sign out, user registration, and role management.

### Features
- Email/password authentication
- User profile creation in Firestore
- Role-based access control (admin/driver)
- Password reset functionality
- Offline mode support for testing
- Automatic error logging to Crashlytics

### Properties

```dart
User? currentUser          // Currently authenticated user
Stream<User?> authStateChanges  // Stream of auth state changes
```

### Methods

#### signIn(email, password)
Sign in an existing user with email and password.

**Parameters:**
- `String email` - User's email address
- `String password` - User's password

**Returns:** `Future<UserCredential?>` - Credential on success, null in offline mode

**Throws:** `FirebaseAuthException` on authentication failure

**Example:**
```dart
try {
  final credential = await authService.signIn('user@example.com', 'password123');
  print('Signed in: ${credential?.user?.email}');
} on FirebaseAuthException catch (e) {
  print('Error: ${e.message}');
}
```

**Note:** Requires Firebase Authentication to be configured. Demo credentials have been removed for production readiness.

---

#### register({required email, password, name, role, phone?, truckNumber?})
Register a new user with full profile information.

**Parameters:**
- `String email` - User's email (required)
- `String password` - User's password (required)
- `String name` - User's full name (required)
- `String role` - 'admin' or 'driver' (required)
- `String? phone` - Phone number (optional)
- `String? truckNumber` - Truck identifier for drivers (optional)

**Returns:** `Future<UserCredential?>` - Credential on success

**Example:**
```dart
await authService.register(
  email: 'newuser@example.com',
  password: 'securepass',
  name: 'John Doe',
  role: 'driver',
  phone: '555-0123',
  truckNumber: 'TRUCK-001',
);
```

---

#### signOut()
Sign out the currently authenticated user.

**Returns:** `Future<void>`

**Example:**
```dart
await authService.signOut();
```

---

#### getUserRole(uid)
Get the role of a user from Firestore.

**Parameters:**
- `String uid` - User's unique identifier

**Returns:** `Future<String>` - 'admin' or 'driver' (defaults to 'driver')

**Example:**
```dart
final role = await authService.getUserRole(user.uid);
if (role == 'admin') {
  // Show admin dashboard
}
```

---

#### resetPassword(email)
Send a password reset email to the user.

**Parameters:**
- `String email` - User's email address

**Returns:** `Future<void>`

**Throws:** `FirebaseAuthException` if email is invalid

**Example:**
```dart
await authService.resetPassword('user@gud.com');
```

---

## FirestoreService

**Location:** `lib/services/firestore_service.dart`

### Purpose
Manages all Firestore database operations for drivers, loads, PODs, and earnings.

### Collections Used
- `users` - User profiles and roles
- `drivers` - Driver information and stats
- `loads` - Load assignments and status
- `pods` - Proof of delivery documents
- `expenses` - Expense records

### Methods

#### createDriver({driverId, name, phone, truckNumber})
Create a new driver profile in Firestore.

**Parameters:**
- `String driverId` - Unique identifier (typically Firebase Auth UID)
- `String name` - Driver's full name
- `String phone` - Contact phone number
- `String truckNumber` - Assigned truck identifier

**Returns:** `Future<void>`

**Example:**
```dart
await firestoreService.createDriver(
  driverId: user.uid,
  name: 'John Doe',
  phone: '555-0123',
  truckNumber: 'TRUCK-001',
);
```

---

#### streamDrivers()
Get a real-time stream of all drivers.

**Returns:** `Stream<List<Driver>>` - Updates whenever driver data changes

**Example:**
```dart
StreamBuilder<List<Driver>>(
  stream: firestoreService.streamDrivers(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    final drivers = snapshot.data!;
    return ListView.builder(
      itemCount: drivers.length,
      itemBuilder: (ctx, i) => DriverListTile(drivers[i]),
    );
  },
)
```

---

#### createLoad({loadNumber, driverId, pickupAddress, deliveryAddress, rate, ...})
Create a new load assignment.

**Parameters:**
- `String loadNumber` - Human-readable identifier (e.g., 'LOAD-001')
- `String driverId` - Assigned driver's ID
- `String driverName` - Driver's name (denormalized)
- `String pickupAddress` - Pickup location
- `String deliveryAddress` - Delivery destination
- `double rate` - Payment rate
- `double? miles` - Estimated miles (optional)
- `String? notes` - Additional notes (optional)
- `String createdBy` - Admin user ID

**Returns:** `Future<String>` - Generated load document ID

**Example:**
```dart
final loadId = await firestoreService.createLoad(
  loadNumber: 'LOAD-042',
  driverId: driverId,
  driverName: 'John Doe',
  pickupAddress: '123 Main St, City A',
  deliveryAddress: '456 Oak Ave, City B',
  rate: 1500.00,
  miles: 250,
  createdBy: adminUserId,
);
```

---

#### streamDriverLoads(driverId)
Stream all loads for a specific driver.

**Parameters:**
- `String driverId` - Driver's identifier

**Returns:** `Stream<List<LoadModel>>` - Real-time load updates

**Example:**
```dart
stream: firestoreService.streamDriverLoads(currentUser.uid)
```

---

#### updateLoadStatus({loadId, status, pickedUpAt?, tripStartAt?, deliveredAt?})
Update a load's status and timestamps.

**Parameters:**
- `String loadId` - Load's document ID
- `String status` - New status ('assigned', 'in_transit', 'delivered', 'completed')
- `DateTime? pickedUpAt` - Pickup timestamp (optional)
- `DateTime? tripStartAt` - Trip start timestamp (optional)
- `DateTime? deliveredAt` - Delivery timestamp (optional)

**Returns:** `Future<void>`

**Example:**
```dart
await firestoreService.updateLoadStatus(
  loadId: load.id,
  status: 'in_transit',
  tripStartAt: DateTime.now(),
);
```

---

#### addPod({loadId, imageUrl, notes?, uploadedBy})
Add a proof of delivery document.

**Parameters:**
- `String loadId` - Associated load's ID
- `String imageUrl` - Cloud Storage URL of POD image
- `String? notes` - Optional delivery notes
- `String uploadedBy` - User ID who uploaded

**Returns:** `Future<String>` - POD document ID

**Example:**
```dart
final podId = await firestoreService.addPod(
  loadId: load.id,
  imageUrl: downloadUrl,
  notes: 'Delivered to front desk',
  uploadedBy: currentUser.uid,
);
```

---

#### streamDriverEarnings(driverId)
Stream real-time earnings for a driver.

**Parameters:**
- `String driverId` - Driver's identifier

**Returns:** `Stream<double>` - Total earnings from delivered loads

**Example:**
```dart
StreamBuilder<double>(
  stream: firestoreService.streamDriverEarnings(driverId),
  builder: (context, snapshot) {
    return Text('\$${snapshot.data?.toStringAsFixed(2) ?? '0.00'}');
  },
)
```

---

#### generateLoadNumber()
Generate the next sequential load number.

**Returns:** `Future<String>` - Format 'LOAD-XXX' (e.g., 'LOAD-001')

**Example:**
```dart
final loadNumber = await firestoreService.generateLoadNumber();
```

---

## StorageService

**Location:** `lib/services/storage_service.dart`

### Purpose
Manages file uploads to Firebase Cloud Storage, primarily for POD images.

### Methods

#### pickImage({required source})
Open the camera or gallery to select an image.

**Parameters:**
- `ImageSource source` - `ImageSource.camera` or `ImageSource.gallery`

**Returns:** `Future<File?>` - Selected image file or null if cancelled

**Image Optimization:**
- Max dimensions: 1920x1080 pixels
- Quality: 85%
- Format: JPEG

**Example:**
```dart
final file = await storageService.pickImage(source: ImageSource.camera);
if (file != null) {
  // Upload the image
}
```

---

#### uploadPodImage({loadId, file})
Upload a POD image to Firebase Storage.

**Parameters:**
- `String loadId` - Load ID for organizing storage
- `File file` - Image file to upload

**Returns:** `Future<String>` - Public download URL

**Storage Path:** `pods/{loadId}/{timestamp}.jpg`

**Example:**
```dart
final downloadUrl = await storageService.uploadPodImage(
  loadId: load.id,
  file: imageFile,
);
```

---

#### deletePOD(imageUrl)
Delete a POD image from storage.

**Parameters:**
- `String imageUrl` - Full download URL of the image

**Returns:** `Future<void>`

**Example:**
```dart
await storageService.deletePOD(pod.imageUrl);
```

---

## LocationService

**Location:** `lib/services/location_service.dart`

### Purpose
Handles GPS positioning, location permissions, and location data formatting.

### Methods

#### getCurrentLocation()
Get the device's current GPS position.

**Returns:** `Future<Position?>` - Current position or null on failure

**Accuracy:** High (uses GPS)

**Automatic Handling:**
- Checks if location services are enabled
- Requests permissions if needed
- Returns null if permission denied

**Example:**
```dart
final position = await locationService.getCurrentLocation();
if (position != null) {
  print('Lat: ${position.latitude}, Lng: ${position.longitude}');
}
```

---

#### requestLocationPermission()
Check and request location permissions.

**Returns:** `Future<bool>` - true if granted, false if denied

**Example:**
```dart
if (await locationService.requestLocationPermission()) {
  // Permission granted, proceed with location features
}
```

---

#### positionToMap(position)
Convert a Position object to a Firestore-compatible map.

**Parameters:**
- `Position position` - Geolocator position object

**Returns:** `Map<String, dynamic>` with keys: lat, lng, timestamp, accuracy

**Example:**
```dart
final locationMap = locationService.positionToMap(position);
await firestore.collection('locations').add(locationMap);
```

---

## ExpenseService

**Location:** `lib/services/expense_service.dart`

### Purpose
Manages expense tracking for drivers and loads.

### Methods

#### createExpense({amount, category, description, date, ...})
Create a new expense record.

**Parameters:**
- `double amount` - Expense amount
- `String category` - Expense category (fuel, maintenance, tolls, etc.)
- `String description` - Description
- `DateTime date` - Expense date
- `String? driverId` - Associated driver (optional)
- `String? loadId` - Associated load (optional)
- `String? receiptUrl` - Receipt image URL (optional)
- `String createdBy` - User who created the expense

**Returns:** `Future<String>` - Expense document ID

**Example:**
```dart
await expenseService.createExpense(
  amount: 85.50,
  category: 'fuel',
  description: 'Fuel for LOAD-042',
  date: DateTime.now(),
  driverId: driverId,
  loadId: loadId,
  createdBy: currentUser.uid,
);
```

---

#### streamDriverExpenses(driverId)
Stream expenses for a specific driver.

**Parameters:**
- `String driverId` - Driver's identifier

**Returns:** `Stream<List<Expense>>` - Real-time expense updates

**Example:**
```dart
stream: expenseService.streamDriverExpenses(driverId)
```

---

#### getExpensesByCategory({driverId?, startDate?, endDate?})
Get expense totals grouped by category.

**Parameters:**
- `String? driverId` - Filter by driver (optional)
- `DateTime? startDate` - Filter start date (optional)
- `DateTime? endDate` - Filter end date (optional)

**Returns:** `Future<Map<String, double>>` - Category totals

**Example:**
```dart
final categoryTotals = await expenseService.getExpensesByCategory(
  driverId: driverId,
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 1, 31),
);
// {'fuel': 450.00, 'maintenance': 230.00, 'tolls': 45.00}
```

---

## StatisticsService

**Location:** `lib/services/statistics_service.dart`

### Purpose
Calculate and stream business analytics and statistics.

### Methods

#### calculateStatistics({startDate, endDate, driverId?})
Calculate comprehensive statistics for a time period.

**Parameters:**
- `DateTime startDate` - Period start
- `DateTime endDate` - Period end
- `String? driverId` - Filter by driver (optional)

**Returns:** `Future<Statistics>` - Statistics object

**Calculated Metrics:**
- Total revenue
- Total expenses
- Net profit
- Total loads
- Delivered loads
- Total miles
- Average rate per load
- Rate per mile
- Per-driver breakdowns

**Example:**
```dart
final stats = await statisticsService.calculateStatistics(
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 1, 31),
);
print('Revenue: \$${stats.totalRevenue}');
print('Profit: \$${stats.netProfit}');
```

---

#### streamStatistics({startDate, endDate, driverId?})
Stream real-time statistics updates.

**Parameters:** Same as `calculateStatistics()`

**Returns:** `Stream<Statistics>` - Updates when loads change

**Example:**
```dart
StreamBuilder<Statistics>(
  stream: statisticsService.streamStatistics(
    startDate: monthStart,
    endDate: monthEnd,
  ),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return Loading();
    return StatsDashboard(stats: snapshot.data!);
  },
)
```

---

## NotificationService

**Location:** `lib/services/notification_service.dart`

### Purpose
Handle push notifications via Firebase Cloud Messaging.

### Features
- Request notification permissions
- Handle FCM tokens
- Display local notifications
- Process foreground/background notifications

### Methods

#### initialize()
Initialize the notification service.

**Returns:** `Future<void>`

**Setup:**
- Requests notification permissions
- Configures FCM
- Sets up notification handlers

**Example:**
```dart
await NotificationService().initialize();
```

---

#### sendLoadAssignmentNotification({driverId, loadNumber, pickup, delivery})
Send a notification when a new load is assigned.

**Parameters:**
- `String driverId` - Target driver
- `String loadNumber` - Load identifier
- `String pickup` - Pickup address
- `String delivery` - Delivery address

**Returns:** `Future<void>`

---

## BackgroundLocationService

**Location:** `lib/services/background_location_service.dart`

### Purpose
Track driver location in the background for real-time monitoring.

### Methods

#### startTracking(driverId, {intervalMinutes})
Start background location tracking.

**Parameters:**
- `String driverId` - Driver to track
- `int intervalMinutes` - Update frequency (default: 5)

**Returns:** `Future<bool>` - true if tracking started

**Example:**
```dart
final started = await backgroundLocationService.startTracking(
  driverId,
  intervalMinutes: 5,
);
```

---

#### stopTracking()
Stop background location tracking.

**Returns:** `Future<void>`

---

## GeofenceService

**Location:** `lib/services/geofence_service.dart`

### Purpose
Create and monitor geofences for automatic load status updates.

### Methods

#### createPickupGeofence({loadId, latitude, longitude, radius})
Create a geofence around a pickup location.

**Parameters:**
- `String loadId` - Associated load
- `double latitude` - Center latitude
- `double longitude` - Center longitude
- `double radius` - Radius in meters (default: 200)

**Returns:** `Future<String>` - Geofence ID

---

#### monitorGeofences(driverId)
Start monitoring geofences for a driver.

**Parameters:**
- `String driverId` - Driver to monitor

**Returns:** `Future<void>`

---

## CrashReportingService

**Location:** `lib/services/crash_reporting_service.dart`

### Purpose
Track errors and crashes via Firebase Crashlytics.

### Methods

#### initialize()
Initialize crash reporting.

**Returns:** `Future<void>`

**Setup:**
- Configures Crashlytics
- Sets up error handlers
- Disables in debug mode

---

#### logError(error, stackTrace, {reason?, context?})
Log a non-fatal error.

**Parameters:**
- `dynamic error` - Error object
- `StackTrace? stackTrace` - Stack trace
- `String? reason` - Error description
- `Map<String, dynamic>? context` - Additional context

**Returns:** `Future<void>`

**Example:**
```dart
try {
  // risky operation
} catch (e, stackTrace) {
  await crashReportingService.logError(
    e,
    stackTrace,
    reason: 'Failed to upload POD',
    context: {'loadId': load.id},
  );
}
```

---

## Best Practices

### Error Handling

Always wrap service calls in try-catch blocks:

```dart
try {
  await firestoreService.createLoad(...);
} on FirebaseException catch (e) {
  // Handle Firebase errors
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: ${e.message}')),
  );
}
```

### Streams and Memory Leaks

Always dispose of stream subscriptions:

```dart
class _MyWidgetState extends State<MyWidget> {
  late StreamSubscription _subscription;
  
  @override
  void initState() {
    super.initState();
    _subscription = firestoreService.streamLoads().listen((loads) {
      // Handle loads
    });
  }
  
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
```

Or use `StreamBuilder` which handles cleanup automatically:

```dart
StreamBuilder<List<Load>>(
  stream: firestoreService.streamLoads(),
  builder: (context, snapshot) { ... },
)
```

### Null Safety

All services are null-safe. Handle nullable returns appropriately:

```dart
final position = await locationService.getCurrentLocation();
if (position != null) {
  // Use position
} else {
  // Handle null case
}
```

### Dependency Injection

Services can be injected using Provider or GetIt:

```dart
// Using Provider
Provider<AuthService>(
  create: (_) => AuthService(),
  child: MyApp(),
)

// Accessing
final authService = Provider.of<AuthService>(context);
```

---

## Testing Services

### Unit Testing

Mock services in unit tests:

```dart
class MockAuthService extends Mock implements AuthService {}

void main() {
  test('should sign in user', () async {
    final mockAuth = MockAuthService();
    when(mockAuth.signIn(any, any))
        .thenAnswer((_) async => mockCredential);
    
    // Test your code
  });
}
```

### Integration Testing

Test services with Firebase emulators:

```dart
setUp(() async {
  await Firebase.initializeApp();
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
});
```

---

## Additional Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart API Reference](https://api.dart.dev/)
- [GUD Express Setup Guide](../SETUP.md)
- [Architecture Overview](../ARCHITECTURE.md)

## Support

For questions or issues with services:
1. Check this documentation
2. Review inline code comments
3. Check Firebase console for errors
4. Contact the development team
