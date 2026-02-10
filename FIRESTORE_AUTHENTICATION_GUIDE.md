# Firestore Authentication Guide

This guide explains how authentication is enforced in the GUD Express application to prevent `[cloud_firestore/permission-denied]` errors.

## Overview

All Firestore operations in this application require user authentication. Both Firestore security rules and Dart code validate authentication before allowing data access.

## Security Rules

The `firestore.rules` file enforces authentication at the database level:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check authentication
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // All collections require authentication
    match /users/{userId} {
      allow read: if isAuthenticated();
      // ... role-based rules
    }
    
    match /drivers/{driverId} {
      allow read: if isAuthenticated();
      // ... role-based rules
    }
    
    match /loads/{loadId} {
      allow read: if isAuthenticated();
      // ... role-based rules
    }
    
    match /expenses/{expenseId} {
      allow read, create: if isAuthenticated();
      // ... role-based rules
    }
    
    match /invoices/{invoiceId} {
      allow read: if isAuthenticated();
      // ... role-based rules
    }
  }
}
```

## Client-Side Authentication Checks

All Firestore service classes now verify authentication before executing queries:

### Services with Authentication

The following services enforce authentication:

1. **FirestoreService** (`lib/services/firestore_service.dart`)
   - User management
   - Driver management
   - Load tracking
   - POD management
   - Statistics

2. **ExpenseService** (`lib/services/expense_service.dart`)
   - Expense tracking
   - Category analytics
   - Driver expenses

3. **InvoiceService** (`lib/services/invoice_service.dart`)
   - Invoice creation
   - Status management
   - Search and reporting

4. **StatisticsService** (`lib/services/statistics_service.dart`)
   - Performance analytics
   - Revenue calculations
   - Historical data

5. **DriverExtendedService** (`lib/services/driver_extended_service.dart`)
   - Driver ratings
   - Certifications
   - Document verification
   - Training records
   - Maintenance tracking

### Implementation Pattern

Each service uses this pattern:

```dart
class SomeService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Verify user is authenticated before executing Firestore operations
  void _requireAuth() {
    if (_auth.currentUser == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message: 'User must be signed in to access data',
      );
    }
  }
  
  Future<void> someMethod() async {
    _requireAuth(); // Check authentication first
    // ... then execute Firestore operations
    await _db.collection('...').get();
  }
}
```

## Error Handling in UI

When authentication fails, services throw a `FirebaseAuthException`. UI components should handle this gracefully:

### StreamBuilder Example

```dart
StreamBuilder<List<Load>>(
  stream: _firestoreService.streamAllLoads(),
  builder: (context, snapshot) {
    // Handle loading state
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    
    // Handle errors
    if (snapshot.hasError) {
      final error = snapshot.error;
      
      // Check for authentication error
      if (error is FirebaseAuthException && error.code == 'unauthenticated') {
        return Column(
          children: [
            Icon(Icons.lock, size: 48),
            SizedBox(height: 16),
            Text('Please sign in to access this data'),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: Text('Sign In'),
            ),
          ],
        );
      }
      
      // Check for permission denied error
      if (error is FirebaseException && error.code == 'permission-denied') {
        return Column(
          children: [
            Icon(Icons.block, size: 48),
            SizedBox(height: 16),
            Text('You don\'t have permission to access this data'),
            Text('Please contact your administrator'),
          ],
        );
      }
      
      // Generic error
      return Text('Error: ${snapshot.error}');
    }
    
    // Handle data
    final loads = snapshot.data ?? [];
    return ListView.builder(
      itemCount: loads.length,
      itemBuilder: (context, index) => LoadTile(loads[index]),
    );
  },
)
```

### FutureBuilder Example

```dart
FutureBuilder<Statistics>(
  future: _statisticsService.calculateStatistics(
    startDate: startDate,
    endDate: endDate,
  ),
  builder: (context, snapshot) {
    // Handle loading
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    
    // Handle errors
    if (snapshot.hasError) {
      final error = snapshot.error;
      
      if (error is FirebaseAuthException && error.code == 'unauthenticated') {
        return ElevatedButton(
          onPressed: () => _navigateToLogin(),
          child: Text('Sign in to view statistics'),
        );
      }
      
      if (error is FirebaseException && error.code == 'permission-denied') {
        return Text('Permission denied. Please sign in with proper credentials.');
      }
      
      return Text('Error: ${snapshot.error}');
    }
    
    // Handle data
    final stats = snapshot.data!;
    return StatisticsWidget(stats);
  },
)
```

## Common Error Codes

### `unauthenticated`
- **Thrown by**: Client-side authentication checks in service classes
- **Cause**: User is not signed in (`FirebaseAuth.instance.currentUser == null`)
- **Solution**: Redirect user to login screen

### `permission-denied`
- **Thrown by**: Firestore security rules
- **Cause**: User is authenticated but doesn't have permission for the requested operation
- **Common scenarios**:
  - Driver trying to access another driver's data
  - Driver trying to create/delete resources (admin-only)
  - User role not properly set in `/users/{uid}` document
- **Solution**: 
  1. Verify user's role is correctly set in Firestore
  2. Check security rules match your application logic
  3. Ensure user has proper permissions for the operation

## Best Practices

### 1. Always Check Authentication State

Use `authStateChanges` stream to track authentication:

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        }
        
        if (snapshot.hasData) {
          return HomePage(); // User is signed in
        }
        
        return LoginScreen(); // User is not signed in
      },
    );
  }
}
```

### 2. Handle Errors Gracefully

Never expose raw error messages to users. Provide helpful guidance:

```dart
String _getUserFriendlyError(dynamic error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'unauthenticated':
        return 'Please sign in to continue';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      default:
        return 'Authentication error. Please try again.';
    }
  }
  
  if (error is FirebaseException && error.code == 'permission-denied') {
    return 'You don\'t have permission to perform this action';
  }
  
  return 'An unexpected error occurred. Please try again later.';
}
```

### 3. Implement Offline Support

Handle network errors separately from authentication errors:

```dart
if (snapshot.hasError) {
  final error = snapshot.error;
  
  if (error is FirebaseException && error.code == 'unavailable') {
    return Column(
      children: [
        Icon(Icons.cloud_off),
        Text('No internet connection'),
        ElevatedButton(
          onPressed: () => _retry(),
          child: Text('Retry'),
        ),
      ],
    );
  }
  
  // ... handle other errors
}
```

### 4. Pre-Flight Checks

For critical operations, check authentication before attempting:

```dart
Future<void> createInvoice(Invoice invoice) async {
  // Check auth before showing UI
  if (_auth.currentUser == null) {
    _showLoginPrompt();
    return;
  }
  
  try {
    await _invoiceService.createInvoice(invoice);
    _showSuccessMessage();
  } on FirebaseAuthException catch (e) {
    if (e.code == 'unauthenticated') {
      _showLoginPrompt();
    }
  } on FirebaseException catch (e) {
    if (e.code == 'permission-denied') {
      _showPermissionError();
    }
  }
}
```

## Testing Authentication

### Manual Testing

1. **Test Unauthenticated Access**:
   - Sign out
   - Try to access data screens
   - Verify appropriate error message
   - Verify redirect to login

2. **Test Role-Based Access**:
   - Sign in as driver
   - Try to access admin-only features
   - Verify permission denied error
   - Sign in as admin
   - Verify full access

3. **Test Session Expiration**:
   - Sign in
   - Manually revoke token in Firebase Console
   - Try to access data
   - Verify authentication error

### Automated Testing

```dart
testWidgets('Shows login prompt when unauthenticated', (tester) async {
  // Mock unauthenticated state
  when(mockAuth.currentUser).thenReturn(null);
  
  await tester.pumpWidget(MyApp());
  await tester.pumpAndSettle();
  
  // Verify login screen is shown
  expect(find.byType(LoginScreen), findsOneWidget);
});

testWidgets('Shows permission error for unauthorized access', (tester) async {
  // Mock authenticated driver user
  when(mockAuth.currentUser).thenReturn(mockDriverUser);
  
  // Mock permission denied error
  when(mockFirestore.streamAllLoads()).thenAnswer(
    (_) => Stream.error(
      FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      ),
    ),
  );
  
  await tester.pumpWidget(MyApp());
  await tester.pumpAndSettle();
  
  // Verify error message
  expect(find.text('Permission denied'), findsOneWidget);
});
```

## Troubleshooting

### Problem: "permission-denied" even when signed in

**Possible causes**:
1. User document doesn't exist in `/users/{uid}`
2. User's `role` field is not set
3. User's role doesn't match security rules expectations

**Solution**:
1. Check Firebase Console → Authentication → Users
2. Check Firestore → users collection → find user by UID
3. Verify `role` field is set to "admin" or "driver"
4. If missing, create user document:
   ```javascript
   // In Firebase Console
   Collection: users
   Document ID: <user's UID>
   Fields:
     role: "admin" or "driver"
     name: "User Name"
     email: "user@example.com"
     createdAt: <timestamp>
   ```

### Problem: "unauthenticated" error on every request

**Possible causes**:
1. User is actually not signed in
2. Auth state not properly initialized
3. Token expired

**Solution**:
1. Check `FirebaseAuth.instance.currentUser` in debug
2. Verify `authStateChanges` stream is connected
3. Try signing out and signing in again
4. Check Firebase Console for authentication status

### Problem: Intermittent authentication errors

**Possible causes**:
1. Network issues
2. Token refresh failures
3. Race conditions in initialization

**Solution**:
1. Add proper error handling for network errors
2. Implement retry logic
3. Ensure Firebase is initialized before use:
   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp();
     runApp(MyApp());
   }
   ```

## Deployment

Before deploying to production:

1. **Deploy Security Rules**:
   ```bash
   firebase deploy --only firestore:rules
   ```

2. **Verify Rules**:
   - Open Firebase Console → Firestore → Rules
   - Use Rules Playground to test scenarios
   - Test both positive and negative cases

3. **Test Authentication Flow**:
   - Test with real user accounts
   - Test both admin and driver roles
   - Test permission boundaries

4. **Monitor Errors**:
   - Set up Firebase Crashlytics
   - Monitor authentication errors
   - Set up alerts for permission-denied spikes

## Support

For issues or questions:
- Review this guide
- Check [Firebase Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)
- Review [Firebase Authentication Documentation](https://firebase.google.com/docs/auth)
- Check application logs in Firebase Console

---

**Last Updated**: 2026-02-10  
**Version**: 1.0  
**Applies to**: GUD Express v1.0+
