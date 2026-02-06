# Testing Guide

This comprehensive guide covers testing strategies, patterns, and best practices for the GUD Express Trucking Management App.

## Table of Contents

- [Overview](#overview)
- [Running Tests](#running-tests)
- [Test Structure and Organization](#test-structure-and-organization)
- [Writing Unit Tests](#writing-unit-tests)
- [Writing Widget Tests](#writing-widget-tests)
- [Writing Integration Tests](#writing-integration-tests)
- [Test Coverage](#test-coverage)
- [Mock Data Setup](#mock-data-setup)
- [Testing Firebase Services](#testing-firebase-services)
- [Running Specific Tests](#running-specific-tests)
- [Continuous Testing](#continuous-testing)

## Overview

The GUD app uses Flutter's comprehensive testing framework with three types of tests:

- **Unit Tests**: Test individual functions, methods, and classes in isolation
- **Widget Tests**: Test individual widgets and their interactions
- **Integration Tests**: Test complete features and user flows

### Testing Stack

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0          # Mocking framework
  mocktail: ^1.0.1         # Alternative mocking library
  build_runner: ^2.4.0     # Code generation for mocks
  integration_test:
    sdk: flutter
  flutter_driver:
    sdk: flutter
```

## Running Tests

### Run All Tests

```bash
# Run all unit and widget tests
flutter test

# Run with verbose output
flutter test --verbose

# Run with coverage report
flutter test --coverage
```

### Run Unit Tests Only

```bash
# Run all unit tests
flutter test test/models/ test/services/

# Run specific unit test file
flutter test test/models/load_model_test.dart
```

### Run Widget Tests Only

```bash
# Run all widget tests
flutter test test/widgets/

# Run specific widget test
flutter test test/widgets/app_button_test.dart
```

### Run Integration Tests

```bash
# Run on connected device/emulator
flutter test integration_test/

# Run specific integration test
flutter test integration_test/app_test.dart

# Run with driver
flutter drive --target=integration_test/app_test.dart
```

## Test Structure and Organization

```
test/
├── models/                    # Unit tests for data models
│   ├── app_user_test.dart
│   ├── driver_test.dart
│   ├── expense_test.dart
│   ├── invoice_test.dart
│   ├── load_model_test.dart
│   ├── pod_test.dart
│   └── statistics_test.dart
├── services/                  # Unit tests for services
│   ├── auth_service_test.dart
│   ├── firestore_service_test.dart
│   ├── invoice_service_test.dart
│   └── export_service_test.dart
├── widgets/                   # Widget tests
│   ├── app_button_test.dart
│   └── loading_screen_test.dart
└── helpers/                   # Test utilities
    ├── mock_data.dart
    └── test_helpers.dart

integration_test/
├── app_test.dart             # End-to-end app tests
├── login_flow_test.dart      # Authentication flows
├── load_management_test.dart # Load CRUD operations
└── invoice_flow_test.dart    # Invoice creation and export
```

## Writing Unit Tests

Unit tests verify individual functions and classes work correctly in isolation.

### Basic Unit Test Structure

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gud_app/models/load.dart';

void main() {
  group('LoadModel', () {
    test('constructor creates valid LoadModel', () {
      // Arrange
      final testDate = DateTime(2024, 1, 1);
      
      // Act
      final load = LoadModel(
        id: 'test-id',
        loadNumber: 'LD-001',
        driverId: 'driver-1',
        driverName: 'John Doe',
        pickupAddress: '123 Main St',
        deliveryAddress: '456 Oak Ave',
        rate: 1500.0,
        status: 'assigned',
        createdAt: testDate,
      );

      // Assert
      expect(load.id, 'test-id');
      expect(load.loadNumber, 'LD-001');
      expect(load.rate, 1500.0);
    });

    test('toMap converts model to Map correctly', () {
      // Arrange
      final load = LoadModel(/* ... */);
      
      // Act
      final map = load.toMap();
      
      // Assert
      expect(map['loadNumber'], 'LD-001');
      expect(map['rate'], 1500.0);
    });

    test('fromMap creates model from Map correctly', () {
      // Arrange
      final map = {
        'loadNumber': 'LD-001',
        'driverId': 'driver-1',
        'pickupAddress': '123 Main St',
        'deliveryAddress': '456 Oak Ave',
        'rate': 1500.0,
        'status': 'assigned',
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      // Act
      final load = LoadModel.fromMap('test-id', map);
      
      // Assert
      expect(load.id, 'test-id');
      expect(load.loadNumber, 'LD-001');
    });
  });
}
```

### Testing Model Validation

```dart
test('validates required fields', () {
  expect(
    () => LoadModel(
      id: '',
      loadNumber: '',
      // Missing required fields
    ),
    throwsA(isA<AssertionError>()),
  );
});

test('handles null optional fields', () {
  final load = LoadModel(
    id: 'test-id',
    loadNumber: 'LD-001',
    driverId: 'driver-1',
    pickupAddress: '123 Main St',
    deliveryAddress: '456 Oak Ave',
    rate: 1500.0,
    status: 'assigned',
  );
  
  expect(load.notes, isNull);
  expect(load.deliveredAt, isNull);
});
```

## Writing Widget Tests

Widget tests verify that UI components render correctly and respond to user interactions.

### Basic Widget Test

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gud_app/widgets/app_button.dart';

void main() {
  testWidgets('AppButton renders with text', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            text: 'Click Me',
            onPressed: () {},
          ),
        ),
      ),
    );

    // Assert
    expect(find.text('Click Me'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('AppButton calls onPressed when tapped', (WidgetTester tester) async {
    // Arrange
    bool wasPressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            text: 'Click Me',
            onPressed: () => wasPressed = true,
          ),
        ),
      ),
    );

    // Act
    await tester.tap(find.byType(AppButton));
    await tester.pump();

    // Assert
    expect(wasPressed, isTrue);
  });

  testWidgets('AppButton shows loading indicator when loading', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(
            text: 'Click Me',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      ),
    );

    // Assert
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Click Me'), findsNothing);
  });
}
```

### Testing Forms and Input

```dart
testWidgets('LoginScreen validates email input', (WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(home: LoginScreen()));

  // Find email field
  final emailField = find.byKey(Key('email_field'));
  
  // Enter invalid email
  await tester.enterText(emailField, 'invalid-email');
  await tester.pump();
  
  // Tap submit button
  await tester.tap(find.text('Login'));
  await tester.pump();
  
  // Verify validation error appears
  expect(find.text('Please enter a valid email'), findsOneWidget);
});
```

### Testing Navigation

```dart
testWidgets('Navigate to profile screen on button tap', (WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    home: HomeScreen(),
    routes: {
      '/profile': (context) => ProfileScreen(),
    },
  ));

  // Tap profile button
  await tester.tap(find.byIcon(Icons.person));
  await tester.pumpAndSettle(); // Wait for navigation animation

  // Verify navigation occurred
  expect(find.byType(ProfileScreen), findsOneWidget);
});
```

## Writing Integration Tests

Integration tests verify complete user flows and feature functionality.

### Basic Integration Test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gud_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Flow', () {
    testWidgets('Complete login flow', (WidgetTester tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(
        find.byKey(Key('email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(Key('password_field')),
        'password123',
      );

      // Tap login button
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle(Duration(seconds: 5));

      // Verify successful login
      expect(find.text('Dashboard'), findsOneWidget);
    });
  });
}
```

### Testing Complete Features

```dart
testWidgets('Create and view invoice', (WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();

  // Navigate to invoice creation
  await tester.tap(find.byIcon(Icons.receipt));
  await tester.pumpAndSettle();
  
  await tester.tap(find.text('Create Invoice'));
  await tester.pumpAndSettle();

  // Fill invoice form
  await tester.enterText(find.byKey(Key('invoice_number')), 'INV-001');
  await tester.tap(find.text('Select Load'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('LD-001').first);
  await tester.pumpAndSettle();

  // Save invoice
  await tester.tap(find.text('Save Invoice'));
  await tester.pumpAndSettle(Duration(seconds: 3));

  // Verify invoice appears in list
  expect(find.text('INV-001'), findsOneWidget);
});
```

## Test Coverage

### Coverage Requirements

The project maintains **>80% test coverage** across all critical components:

- Models: >90% coverage
- Services: >80% coverage
- Widgets: >70% coverage
- Screens: >60% coverage

### Generate Coverage Report

```bash
# Run tests with coverage
flutter test --coverage

# Generate HTML report (requires lcov)
genhtml coverage/lcov.info -o coverage/html

# Open coverage report
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
start coverage/html/index.html  # Windows
```

### View Coverage Summary

```bash
# Install lcov if needed
brew install lcov  # macOS
sudo apt-get install lcov  # Linux

# Generate summary
lcov --summary coverage/lcov.info
```

### Coverage in CI/CD

Coverage reports are automatically generated in CI/CD pipelines:

```yaml
# .github/workflows/test.yml
- name: Run tests with coverage
  run: flutter test --coverage

- name: Upload coverage to Codecov
  uses: codecov/codecov-action@v3
  with:
    files: ./coverage/lcov.info
```

## Mock Data Setup

### Creating Mock Data

```dart
// test/helpers/mock_data.dart
import 'package:gud_app/models/load.dart';
import 'package:gud_app/models/driver.dart';

class MockData {
  static LoadModel createMockLoad({
    String? id,
    String? loadNumber,
    String? driverId,
  }) {
    return LoadModel(
      id: id ?? 'mock-load-1',
      loadNumber: loadNumber ?? 'LD-001',
      driverId: driverId ?? 'mock-driver-1',
      driverName: 'Test Driver',
      pickupAddress: '123 Test St, Test City, TS 12345',
      deliveryAddress: '456 Mock Ave, Mock City, MC 67890',
      rate: 1500.0,
      status: 'assigned',
      miles: 150.0,
      createdBy: 'admin',
    );
  }

  static DriverModel createMockDriver({String? id, String? name}) {
    return DriverModel(
      id: id ?? 'mock-driver-1',
      name: name ?? 'Test Driver',
      email: 'test@driver.com',
      phone: '555-0100',
      licenseNumber: 'DL123456',
      isActive: true,
    );
  }

  static List<LoadModel> createMockLoadList(int count) {
    return List.generate(
      count,
      (i) => createMockLoad(
        id: 'mock-load-$i',
        loadNumber: 'LD-${i.toString().padLeft(3, '0')}',
      ),
    );
  }
}
```

### Using Mock Data in Tests

```dart
test('processes multiple loads correctly', () {
  // Arrange
  final loads = MockData.createMockLoadList(5);
  
  // Act
  final totalRevenue = loads.fold(0.0, (sum, load) => sum + load.rate);
  
  // Assert
  expect(totalRevenue, 7500.0); // 5 loads * 1500
  expect(loads.length, 5);
});
```

## Testing Firebase Services

### Using Mockito for Firebase Mocking

#### Generate Mocks

```dart
// test/mocks/firebase_mocks.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  DocumentSnapshot,
  QuerySnapshot,
  FirebaseAuth,
  User,
  UserCredential,
])
void main() {}
```

Generate mock classes:

```bash
flutter pub run build_runner build
```

#### Mock Firestore Service

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:gud_app/services/firestore_service.dart';
import '../mocks/firebase_mocks.mocks.dart';

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDocument;
  late FirestoreService service;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockDocument = MockDocumentReference();
    service = FirestoreService(firestore: mockFirestore);
  });

  group('FirestoreService', () {
    test('getLoads returns list of loads', () async {
      // Arrange
      final mockQuerySnapshot = MockQuerySnapshot();
      final mockDocSnapshot = MockDocumentSnapshot();
      
      when(mockFirestore.collection('loads'))
          .thenReturn(mockCollection);
      when(mockCollection.get())
          .thenAnswer((_) async => mockQuerySnapshot);
      when(mockQuerySnapshot.docs)
          .thenReturn([mockDocSnapshot]);
      when(mockDocSnapshot.id).thenReturn('load-1');
      when(mockDocSnapshot.data()).thenReturn({
        'loadNumber': 'LD-001',
        'driverId': 'driver-1',
        'pickupAddress': '123 Main St',
        'deliveryAddress': '456 Oak Ave',
        'rate': 1500.0,
        'status': 'assigned',
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Act
      final loads = await service.getLoads();

      // Assert
      expect(loads.length, 1);
      expect(loads.first.loadNumber, 'LD-001');
      verify(mockFirestore.collection('loads')).called(1);
    });

    test('createLoad adds load to Firestore', () async {
      // Arrange
      final load = MockData.createMockLoad();
      
      when(mockFirestore.collection('loads'))
          .thenReturn(mockCollection);
      when(mockCollection.add(any))
          .thenAnswer((_) async => mockDocument);
      when(mockDocument.id).thenReturn('new-load-id');

      // Act
      await service.createLoad(load);

      // Assert
      verify(mockCollection.add(load.toMap())).called(1);
    });
  });
}
```

#### Mock Firebase Auth

```dart
test('login authenticates user successfully', () async {
  // Arrange
  final mockAuth = MockFirebaseAuth();
  final mockUserCredential = MockUserCredential();
  final mockUser = MockUser();
  
  when(mockAuth.signInWithEmailAndPassword(
    email: anyNamed('email'),
    password: anyNamed('password'),
  )).thenAnswer((_) async => mockUserCredential);
  
  when(mockUserCredential.user).thenReturn(mockUser);
  when(mockUser.uid).thenReturn('test-uid');
  when(mockUser.email).thenReturn('test@example.com');

  final authService = AuthService(auth: mockAuth);

  // Act
  final result = await authService.signIn(
    'test@example.com',
    'password123',
  );

  // Assert
  expect(result, isTrue);
  verify(mockAuth.signInWithEmailAndPassword(
    email: 'test@example.com',
    password: 'password123',
  )).called(1);
});
```

### Using Mocktail (Alternative)

Mocktail doesn't require code generation:

```dart
import 'package:mocktail/mocktail.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}
class MockCollectionRef extends Mock implements CollectionReference {}

test('example with mocktail', () async {
  final mockFirestore = MockFirestore();
  final mockCollection = MockCollectionRef();
  
  when(() => mockFirestore.collection('loads'))
      .thenReturn(mockCollection);
  
  // Test logic here
});
```

## Running Specific Tests

### Run Tests by Name

```bash
# Run tests matching a pattern
flutter test --name "LoadModel"

# Run tests in a specific file
flutter test test/models/load_model_test.dart

# Run specific test group
flutter test --name "LoadModel toMap"
```

### Run Tests by Tag

Add tags to tests:

```dart
test('expensive computation', () {
  // test code
}, tags: ['slow']);

test('quick validation', () {
  // test code
}, tags: ['fast']);
```

Run by tag:

```bash
# Run only fast tests
flutter test --tags fast

# Exclude slow tests
flutter test --exclude-tags slow
```

### Run Tests in Watch Mode

```bash
# Install flutter_test_runner
dart pub global activate flutter_test_runner

# Run in watch mode
flutter test --watch
```

## Continuous Testing

### GitHub Actions Integration

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info
```

### Pre-commit Hooks

Create `.git/hooks/pre-commit`:

```bash
#!/bin/sh

# Run tests before commit
flutter test --no-pub

if [ $? -ne 0 ]; then
  echo "Tests failed. Commit aborted."
  exit 1
fi
```

Make it executable:

```bash
chmod +x .git/hooks/pre-commit
```

### Test on File Change

Using `watchexec`:

```bash
# Install watchexec
brew install watchexec  # macOS

# Watch for changes and run tests
watchexec -e dart -w lib -w test -- flutter test
```

### Code Quality Checks

```bash
# Run analyzer
flutter analyze

# Format code
flutter format lib test

# Check for outdated packages
flutter pub outdated
```

## Best Practices

### 1. Arrange-Act-Assert Pattern

```dart
test('example', () {
  // Arrange: Set up test data and conditions
  final input = 'test';
  
  // Act: Execute the code being tested
  final result = processInput(input);
  
  // Assert: Verify the results
  expect(result, expectedValue);
});
```

### 2. Use Descriptive Test Names

```dart
// Good ✅
test('validates email format and rejects invalid emails', () {});

// Bad ❌
test('test1', () {});
```

### 3. Test Edge Cases

```dart
test('handles empty list', () {});
test('handles null values', () {});
test('handles maximum integer value', () {});
test('handles special characters in strings', () {});
```

### 4. Keep Tests Independent

```dart
// Each test should be able to run independently
setUp(() {
  // Reset state before each test
});

tearDown(() {
  // Clean up after each test
});
```

### 5. Use Matchers Effectively

```dart
expect(value, equals(42));
expect(value, isNull);
expect(value, isNotNull);
expect(list, isEmpty);
expect(list, isNotEmpty);
expect(list, hasLength(5));
expect(list, contains('item'));
expect(() => throw Error(), throwsA(isA<Error>()));
expect(future, completes);
expect(stream, emits('value'));
```

## Troubleshooting

### Common Issues

#### Tests Timeout

```dart
// Increase timeout for slow tests
test('slow operation', () async {
  // test code
}, timeout: Timeout(Duration(seconds: 60)));
```

#### Widget Tests Fail

```bash
# Ensure golden files are updated
flutter test --update-goldens
```

#### Integration Tests Don't Run

```bash
# Make sure device/emulator is running
flutter devices

# Try specific driver command
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart
```

#### Mock Generation Fails

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

## Additional Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Integration Testing Guide](https://docs.flutter.dev/testing/integration-tests)
- [Test Coverage Best Practices](https://docs.flutter.dev/testing/code-coverage)

---

**Last Updated**: Phase 11 Completion
**Version**: 2.0.0
