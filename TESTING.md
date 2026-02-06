# Testing Guide

**Version:** 2.0.0  
**Last Updated:** 2026-02-06

---

## Table of Contents

- [Overview](#overview)
- [Testing Philosophy](#testing-philosophy)
- [Setup](#setup)
- [Running Tests](#running-tests)
  - [Unit Tests](#unit-tests)
  - [Widget Tests](#widget-tests)
  - [Integration Tests](#integration-tests)
- [Test Coverage](#test-coverage)
- [Writing New Tests](#writing-new-tests)
  - [Unit Test Example](#unit-test-example)
  - [Widget Test Example](#widget-test-example)
  - [Integration Test Example](#integration-test-example)
- [Mock Data Usage](#mock-data-usage)
- [Testing Best Practices](#testing-best-practices)
- [Continuous Integration](#continuous-integration)
- [Troubleshooting](#troubleshooting)

---

## Overview

GUD Express uses a comprehensive testing strategy with three test levels:

1. **Unit Tests** - Test individual functions, classes, and services in isolation
2. **Widget Tests** - Test UI components and user interactions
3. **Integration Tests** - Test complete user flows and app behavior

**Current Test Structure:**
```
test/
├── unit/           # Service and model tests
├── widget/         # UI component tests
└── mocks/          # Mock data and helpers

integration_test/   # End-to-end tests
```

---

## Testing Philosophy

### Test Pyramid

Our testing follows the test pyramid approach:

```
        /\
       /  \      Integration Tests (Few)
      /────\     - Complete user flows
     /      \    - End-to-end scenarios
    /────────\   Widget Tests (More)
   /          \  - UI component behavior
  /────────────\ Unit Tests (Most)
 /              \ - Business logic
/────────────────\ - Services, models
```

### Key Principles

1. **Write Tests First** - TDD when possible
2. **Test Behavior, Not Implementation** - Focus on what, not how
3. **Keep Tests Simple** - One assertion per test when possible
4. **Use Mocks Wisely** - Mock external dependencies, not internal logic
5. **Fast Execution** - Unit tests should run in milliseconds
6. **Deterministic** - Tests should always produce the same result
7. **Isolated** - Tests should not depend on each other

---

## Setup

### Prerequisites

```bash
# Ensure Flutter is installed and updated
flutter --version
flutter doctor

# Get dependencies
flutter pub get
```

### Test Dependencies

Key testing packages (already in `pubspec.yaml`):

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0           # Mocking framework
  fake_cloud_firestore: ^2.5.0  # Mock Firestore
  firebase_auth_mocks: ^0.13.0  # Mock Firebase Auth
  integration_test:
    sdk: flutter
```

### Firebase Emulator (Optional)

For more realistic testing:

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Start emulators
firebase emulators:start
```

---

## Running Tests

### Unit Tests

Run all unit tests:

```bash
flutter test test/unit/
```

Run specific test file:

```bash
flutter test test/unit/services/auth_service_test.dart
```

Run tests with verbose output:

```bash
flutter test --verbose test/unit/
```

### Widget Tests

Run all widget tests:

```bash
flutter test test/widget/
```

Run specific widget test:

```bash
flutter test test/widget/login_screen_test.dart
```

### Integration Tests

Run on connected device/emulator:

```bash
# List available devices
flutter devices

# Run all integration tests
flutter test integration_test/

# Run specific integration test
flutter test integration_test/app_test.dart
```

Run on specific device:

```bash
flutter test integration_test/ -d <device_id>
```

### Run All Tests

```bash
# Run all tests (unit + widget)
flutter test

# Run all tests including integration
flutter test && flutter test integration_test/
```

---

## Test Coverage

### Generate Coverage Report

```bash
# Generate coverage data
flutter test --coverage

# View coverage report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Coverage Requirements

- **Minimum Target:** 70% overall coverage
- **Services:** 80%+ coverage (critical business logic)
- **Models:** 90%+ coverage (data integrity)
- **Screens:** 60%+ coverage (UI complexity)

### Check Coverage

```bash
# Install lcov (macOS)
brew install lcov

# Install lcov (Linux)
sudo apt-get install lcov

# Generate and display coverage summary
flutter test --coverage && lcov --summary coverage/lcov.info
```

---

## Writing New Tests

### Unit Test Example

**File:** `test/unit/services/auth_service_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:gud_app/services/auth_service.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockFirebaseAuth mockAuth;

    setUp(() {
      mockAuth = MockFirebaseAuth(signedIn: false);
      authService = AuthService(auth: mockAuth);
    });

    test('login with valid credentials succeeds', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      
      // Act
      final result = await authService.login(email, password);
      
      // Assert
      expect(result.isSuccess, true);
      expect(result.user, isNotNull);
    });

    test('login with invalid credentials fails', () async {
      // Arrange
      const email = 'invalid@example.com';
      const password = 'wrong';
      
      // Act
      final result = await authService.login(email, password);
      
      // Assert
      expect(result.isSuccess, false);
      expect(result.error, isNotNull);
    });

    test('getCurrentUser returns null when not logged in', () {
      // Act
      final user = authService.getCurrentUser();
      
      // Assert
      expect(user, isNull);
    });
  });
}
```

### Widget Test Example

**File:** `test/widget/login_screen_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gud_app/screens/login_screen.dart';
import 'package:gud_app/services/auth_service.dart';
import 'package:mockito/mockito.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  group('LoginScreen Widget Tests', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    testWidgets('displays email and password fields', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authService: mockAuthService),
        ),
      );

      // Assert
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('login button triggers authentication', (tester) async {
      // Arrange
      when(mockAuthService.login(any, any))
          .thenAnswer((_) async => AuthResult.success());
      
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authService: mockAuthService),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      verify(mockAuthService.login('test@example.com', 'password123')).called(1);
    });

    testWidgets('shows error message on failed login', (tester) async {
      // Arrange
      when(mockAuthService.login(any, any))
          .thenAnswer((_) async => AuthResult.failure('Invalid credentials'));
      
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authService: mockAuthService),
        ),
      );

      // Act
      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.enterText(find.byType(TextField).last, 'wrong');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Invalid credentials'), findsOneWidget);
    });
  });
}
```

### Integration Test Example

**File:** `integration_test/app_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gud_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Tests', () {
    testWidgets('complete login flow', (tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(
        find.byKey(const Key('emailField')),
        'admin@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'password123',
      );

      // Tap login button
      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pumpAndSettle();

      // Verify navigation to home screen
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('create and complete load flow', (tester) async {
      // Login first
      app.main();
      await tester.pumpAndSettle();
      // ... login steps ...

      // Navigate to create load
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill load form
      await tester.enterText(find.byKey(const Key('loadNumberField')), 'LOAD-001');
      await tester.enterText(find.byKey(const Key('pickupField')), '123 Main St');
      await tester.enterText(find.byKey(const Key('deliveryField')), '456 Oak Ave');
      
      // Submit
      await tester.tap(find.text('Create Load'));
      await tester.pumpAndSettle();

      // Verify load created
      expect(find.text('LOAD-001'), findsOneWidget);
    });
  });
}
```

---

## Mock Data Usage

### Creating Mock Data

**File:** `test/mocks/mock_data.dart`

```dart
import 'package:gud_app/models/load.dart';
import 'package:gud_app/models/driver.dart';
import 'package:gud_app/models/app_user.dart';

class MockData {
  // Mock Users
  static AppUser mockAdmin() => AppUser(
    uid: 'admin123',
    email: 'admin@example.com',
    role: 'admin',
    createdAt: DateTime(2024, 1, 1),
  );

  static AppUser mockDriver() => AppUser(
    uid: 'driver123',
    email: 'driver@example.com',
    role: 'driver',
    createdAt: DateTime(2024, 1, 1),
  );

  // Mock Drivers
  static Driver mockDriverProfile() => Driver(
    id: 'driver123',
    name: 'John Doe',
    email: 'john@example.com',
    phone: '555-1234',
    truckNumber: 'TRUCK-001',
    status: 'available',
    createdAt: DateTime(2024, 1, 1),
  );

  // Mock Loads
  static Load mockLoad() => Load(
    id: 'load123',
    loadNumber: 'LOAD-001',
    pickupLocation: '123 Main St, City A',
    deliveryLocation: '456 Oak Ave, City B',
    status: 'pending',
    driverId: 'driver123',
    driverName: 'John Doe',
    rate: 500.0,
    createdAt: DateTime(2024, 1, 1),
  );

  static Load mockCompletedLoad() => Load(
    id: 'load456',
    loadNumber: 'LOAD-002',
    pickupLocation: '789 Elm St, City C',
    deliveryLocation: '321 Pine Rd, City D',
    status: 'delivered',
    driverId: 'driver123',
    driverName: 'John Doe',
    rate: 750.0,
    createdAt: DateTime(2024, 1, 1),
    completedAt: DateTime(2024, 1, 2),
  );

  // Mock Lists
  static List<Load> mockLoadList() => [
    mockLoad(),
    mockCompletedLoad(),
    Load(
      id: 'load789',
      loadNumber: 'LOAD-003',
      pickupLocation: 'Warehouse A',
      deliveryLocation: 'Distribution Center B',
      status: 'in_progress',
      driverId: 'driver123',
      driverName: 'John Doe',
      rate: 600.0,
      createdAt: DateTime(2024, 1, 3),
    ),
  ];
}
```

### Using Mocks in Tests

```dart
import '../mocks/mock_data.dart';

test('calculate driver earnings', () {
  // Arrange
  final loads = MockData.mockLoadList();
  final completedLoads = loads.where((l) => l.status == 'delivered').toList();
  
  // Act
  final totalEarnings = completedLoads.fold<double>(
    0,
    (sum, load) => sum + load.rate,
  );
  
  // Assert
  expect(totalEarnings, 750.0);
});
```

---

## Testing Best Practices

### 1. Test Naming

Use descriptive test names that explain what is being tested:

```dart
// Good
test('login with invalid email returns error')

// Bad
test('test login')
```

### 2. AAA Pattern

Structure tests with Arrange-Act-Assert:

```dart
test('example test', () {
  // Arrange - Set up test data and conditions
  final input = 'test data';
  
  // Act - Execute the code under test
  final result = functionToTest(input);
  
  // Assert - Verify the expected outcome
  expect(result, expectedValue);
});
```

### 3. Test Independence

Each test should be independent:

```dart
// Good
group('LoadService', () {
  late LoadService service;
  
  setUp(() {
    service = LoadService(); // Fresh instance each test
  });
  
  test('test 1', () { /* ... */ });
  test('test 2', () { /* ... */ });
});

// Bad - Tests depend on each other
test('create load', () {
  final load = service.create(...);
  globalLoad = load; // Don't do this!
});

test('update load', () {
  service.update(globalLoad); // Depends on previous test
});
```

### 4. Mock External Dependencies

Always mock external services:

```dart
// Good - Mock Firestore
final mockFirestore = FakeFirebaseFirestore();

// Bad - Use real Firestore in tests
final firestore = FirebaseFirestore.instance; // Don't do this!
```

### 5. Test Edge Cases

Don't just test the happy path:

```dart
group('input validation', () {
  test('accepts valid email');
  test('rejects empty email');
  test('rejects email without @');
  test('rejects email without domain');
  test('handles very long email');
  test('handles special characters in email');
});
```

### 6. Use Test Data Builders

Create helper functions for complex test data:

```dart
class LoadBuilder {
  String id = 'load123';
  String loadNumber = 'LOAD-001';
  String status = 'pending';
  double rate = 500.0;
  
  LoadBuilder withId(String id) {
    this.id = id;
    return this;
  }
  
  LoadBuilder withStatus(String status) {
    this.status = status;
    return this;
  }
  
  Load build() => Load(
    id: id,
    loadNumber: loadNumber,
    status: status,
    rate: rate,
    // ... other fields
  );
}

// Usage
final load = LoadBuilder()
  .withId('custom-id')
  .withStatus('delivered')
  .build();
```

### 7. Async Testing

Properly handle async operations:

```dart
test('async operation completes', () async {
  // Use async/await
  final result = await service.fetchData();
  expect(result, isNotNull);
});

test('stream emits values', () async {
  // Test streams
  final stream = service.dataStream();
  
  expect(
    stream,
    emitsInOrder([value1, value2, value3]),
  );
});
```

### 8. Golden Tests for UI

Use golden tests for visual regression:

```dart
testWidgets('dashboard matches golden', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: DashboardScreen()),
  );
  
  await expectLater(
    find.byType(DashboardScreen),
    matchesGoldenFile('goldens/dashboard.png'),
  );
});
```

---

## Continuous Integration

### GitHub Actions

Our CI/CD pipeline runs tests automatically:

**`.github/workflows/test.yml`:**

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v2
        with:
          file: coverage/lcov.info
```

### Local Pre-Commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
echo "Running tests before commit..."
flutter test
if [ $? -ne 0 ]; then
  echo "Tests failed. Commit aborted."
  exit 1
fi
```

---

## Troubleshooting

### Common Issues

#### 1. Firebase Initialization Error

**Problem:** Tests fail with "Firebase has not been initialized"

**Solution:**
```dart
// Add to test setup
setUpAll(() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
});
```

#### 2. Widget Tests Timeout

**Problem:** Widget tests hang indefinitely

**Solution:**
```dart
// Use pumpAndSettle with timeout
await tester.pumpAndSettle(const Duration(seconds: 5));

// Or pump multiple times
for (int i = 0; i < 10; i++) {
  await tester.pump(const Duration(milliseconds: 100));
}
```

#### 3. Async Test Failures

**Problem:** Async operations not completing in tests

**Solution:**
```dart
// Ensure proper async/await usage
test('async test', () async { // Don't forget async
  final result = await service.fetchData(); // Don't forget await
  expect(result, isNotNull);
});
```

#### 4. Mock Not Working

**Problem:** Mock methods not being called

**Solution:**
```dart
// Verify mock setup
when(mockService.method()).thenReturn(value);

// Check call verification
verify(mockService.method()).called(1);
verifyNever(mockService.otherMethod());
```

#### 5. Integration Test Device Not Found

**Problem:** No devices available for integration tests

**Solution:**
```bash
# Start emulator
flutter emulators --launch <emulator_id>

# Or use Chrome for web tests
flutter test integration_test/ -d chrome
```

---

## Additional Resources

### Documentation
- [Flutter Testing Guide](https://flutter.dev/docs/testing)
- [Widget Testing](https://flutter.dev/docs/cookbook/testing/widget/introduction)
- [Integration Testing](https://flutter.dev/docs/testing/integration-tests)
- [Mockito Documentation](https://pub.dev/packages/mockito)

### Best Practices
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)
- [Test-Driven Development](https://flutter.dev/docs/cookbook/testing/unit/introduction)

### Tools
- [Flutter Test Coverage](https://flutter.dev/docs/cookbook/testing/unit/introduction#5-combine-multiple-tests-in-a-group)
- [Very Good CLI](https://pub.dev/packages/very_good_cli) - Testing templates

---

## Next Steps

1. **Expand Test Coverage** - Aim for 80%+ coverage across all services
2. **Add Golden Tests** - Create visual regression tests for key screens
3. **Performance Tests** - Add tests for app performance metrics
4. **Accessibility Tests** - Test screen reader and keyboard navigation
5. **Security Tests** - Validate security rules and data access

---

**Last Updated:** 2026-02-06  
**Maintained By:** GUD Express Development Team  
**Related Documents:**
- [CONTRIBUTING.md](CONTRIBUTING.md)
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- [docs/API.md](docs/API.md)
