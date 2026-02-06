# Automated Testing Guide

This guide provides comprehensive information on testing the GUD Express app, including unit tests, widget tests, and integration tests.

## Table of Contents

1. [Testing Strategy](#testing-strategy)
2. [Setup](#setup)
3. [Unit Tests](#unit-tests)
4. [Widget Tests](#widget-tests)
5. [Integration Tests](#integration-tests)
6. [Running Tests](#running-tests)
7. [CI/CD Integration](#cicd-integration)
8. [Best Practices](#best-practices)

---

## Testing Strategy

### Testing Pyramid

```
        /\
       /  \
      / E2E \           Small number of integration tests
     /------\
    /        \
   / Widget   \         Medium number of widget tests
  /------------\
 /              \
/   Unit Tests   \     Large number of unit tests
------------------
```

### Coverage Goals

- **Unit Tests:** 80%+ coverage for services and models
- **Widget Tests:** 70%+ coverage for UI components
- **Integration Tests:** Key user flows and critical paths

---

## Setup

### Install Dependencies

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  build_runner: ^2.4.9
  test: ^1.25.8
  integration_test:
    sdk: flutter
```

Install:
```bash
flutter pub get
```

### Create Test Directory Structure

```
test/
├── unit/
│   ├── models/
│   │   ├── driver_test.dart
│   │   ├── load_test.dart
│   │   └── pod_test.dart
│   └── services/
│       ├── location_service_test.dart
│       ├── notification_service_test.dart
│       └── geofence_service_test.dart
├── widget/
│   ├── screens/
│   │   ├── admin_home_test.dart
│   │   └── driver_home_test.dart
│   └── widgets/
│       └── load_card_test.dart
└── integration/
    ├── admin_flow_test.dart
    └── driver_flow_test.dart
```

---

## Unit Tests

### Service Tests

#### Location Service Test Example

```dart
// test/unit/services/location_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:gud_app/services/location_service.dart';

@GenerateMocks([Geolocator])
void main() {
  group('LocationService', () {
    late LocationService locationService;

    setUp(() {
      locationService = LocationService();
    });

    test('positionToMap converts Position correctly', () {
      final position = Position(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: DateTime(2024, 1, 1, 12, 0),
        accuracy: 5.0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      final map = locationService.positionToMap(position);

      expect(map['lat'], 37.7749);
      expect(map['lng'], -122.4194);
      expect(map['accuracy'], 5.0);
      expect(map['timestamp'], isA<String>());
    });

    test('positionToMap throws error when timestamp is null', () {
      final position = Position(
        latitude: 37.7749,
        longitude: -122.4194,
        timestamp: null,
        accuracy: 5.0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      expect(
        () => locationService.positionToMap(position),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
```

#### Background Location Service Test

```dart
// test/unit/services/background_location_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gud_app/services/background_location_service.dart';

void main() {
  group('BackgroundLocationService', () {
    late BackgroundLocationService service;

    setUp(() {
      service = BackgroundLocationService();
    });

    tearDown(() {
      service.dispose();
    });

    test('isTracking is false initially', () {
      expect(service.isTracking, false);
    });

    test('stopTracking when not tracking does not throw', () {
      expect(() => service.stopTracking(), returnsNormally);
    });

    // TODO: Add more tests with mocked Geolocator
    // test('startTracking returns true when permissions granted', () async {
    //   // Mock Geolocator
    //   final result = await service.startTracking('driverId');
    //   expect(result, true);
    //   expect(service.isTracking, true);
    // });
  });
}
```

### Model Tests

#### Driver Extended Model Test

```dart
// test/unit/models/driver_extended_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:gud_app/models/driver_extended.dart';

void main() {
  group('DriverExtended', () {
    test('toMap and fromDoc are inverse operations', () {
      final driver = DriverExtended(
        id: 'driver1',
        name: 'John Doe',
        phone: '+1234567890',
        truckNumber: 'TRK-001',
        userId: 'user1',
        status: DriverStatus.available,
        licenseNumber: 'DL123456',
        cdlClass: 'A',
        endorsements: ['H', 'N'],
        completedLoads: 10,
        averageRating: 4.5,
        createdAt: DateTime.now(),
      );

      final map = driver.toMap();
      
      expect(map['name'], 'John Doe');
      expect(map['phone'], '+1234567890');
      expect(map['status'], 'available');
      expect(map['cdlClass'], 'A');
      expect(map['endorsements'], ['H', 'N']);
    });

    test('copyWith updates only specified fields', () {
      final driver = DriverExtended(
        id: 'driver1',
        name: 'John Doe',
        phone: '+1234567890',
        truckNumber: 'TRK-001',
        userId: 'user1',
        createdAt: DateTime.now(),
      );

      final updated = driver.copyWith(
        phone: '+9876543210',
        status: DriverStatus.onDuty,
      );

      expect(updated.name, 'John Doe'); // unchanged
      expect(updated.phone, '+9876543210'); // changed
      expect(updated.status, DriverStatus.onDuty); // changed
      expect(updated.truckNumber, 'TRK-001'); // unchanged
    });
  });

  group('DriverStatus', () {
    test('fromString returns correct enum value', () {
      expect(DriverStatus.fromString('available'), DriverStatus.available);
      expect(DriverStatus.fromString('on_duty'), DriverStatus.onDuty);
      expect(DriverStatus.fromString('off_duty'), DriverStatus.offDuty);
      expect(DriverStatus.fromString('inactive'), DriverStatus.inactive);
    });

    test('fromString returns default for invalid value', () {
      expect(DriverStatus.fromString('invalid'), DriverStatus.available);
    });

    test('displayName returns human-readable string', () {
      expect(DriverStatus.available.displayName, 'Available');
      expect(DriverStatus.onDuty.displayName, 'On Duty');
    });
  });

  group('DriverDocument', () {
    test('isExpiringSoon returns true when within 30 days', () {
      final doc = DriverDocument(
        id: 'doc1',
        driverId: 'driver1',
        type: DocumentType.license,
        url: 'https://example.com/doc.pdf',
        uploadedAt: DateTime.now(),
        expiryDate: DateTime.now().add(Duration(days: 20)),
      );

      expect(doc.isExpiringSoon, true);
    });

    test('isExpired returns true when past expiry date', () {
      final doc = DriverDocument(
        id: 'doc1',
        driverId: 'driver1',
        type: DocumentType.license,
        url: 'https://example.com/doc.pdf',
        uploadedAt: DateTime.now().subtract(Duration(days: 100)),
        expiryDate: DateTime.now().subtract(Duration(days: 10)),
      );

      expect(doc.isExpired, true);
    });
  });
}
```

---

## Widget Tests

### Screen Widget Tests

```dart
// test/widget/screens/admin_home_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gud_app/screens/admin/admin_home_screen.dart';

void main() {
  group('AdminHomeScreen', () {
    testWidgets('displays app title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminHomeScreen(userId: 'admin1'),
        ),
      );

      expect(find.text('GUD Express'), findsOneWidget);
    });

    testWidgets('shows floating action button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminHomeScreen(userId: 'admin1'),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    // TODO: Add more widget tests
    // - Test load list rendering
    // - Test navigation to create load screen
    // - Test navigation to drivers screen
  });
}
```

### Custom Widget Tests

```dart
// test/widget/widgets/load_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gud_app/models/load.dart';
import 'package:gud_app/widgets/load_card.dart';

void main() {
  group('LoadCard', () {
    testWidgets('displays load information', (WidgetTester tester) async {
      final load = LoadModel(
        id: 'load1',
        loadNumber: 'LOAD-001',
        pickupAddress: '123 Start St',
        deliveryAddress: '456 End Ave',
        rate: 1500.0,
        status: 'assigned',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadCard(load: load),
          ),
        ),
      );

      expect(find.text('LOAD-001'), findsOneWidget);
      expect(find.textContaining('123 Start St'), findsOneWidget);
      expect(find.textContaining('456 End Ave'), findsOneWidget);
      expect(find.textContaining('\$1,500'), findsOneWidget);
    });

    testWidgets('shows correct status color', (WidgetTester tester) async {
      final load = LoadModel(
        id: 'load1',
        loadNumber: 'LOAD-001',
        pickupAddress: '123 Start St',
        deliveryAddress: '456 End Ave',
        rate: 1500.0,
        status: 'delivered',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadCard(load: load),
          ),
        ),
      );

      // Find the status indicator widget
      // TODO: Verify the color matches 'delivered' status
    });
  });
}
```

---

## Integration Tests

### Setup Integration Test

```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gud_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('complete driver flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login as driver
      await tester.enterText(
        find.byType(TextField).first,
        'driver@example.com',
      );
      await tester.enterText(
        find.byType(TextField).last,
        'password123',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Verify driver home screen
      expect(find.text('Your Loads'), findsOneWidget);

      // TODO: Add more flow steps
      // - View load details
      // - Update load status
      // - Upload POD
    });

    testWidgets('admin creates and assigns load', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login as admin
      await tester.enterText(
        find.byType(TextField).first,
        'admin@example.com',
      );
      await tester.enterText(
        find.byType(TextField).last,
        'admin123',
      );
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Navigate to create load
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Fill load form
      // TODO: Add form filling steps

      // Submit
      await tester.tap(find.text('Create Load'));
      await tester.pumpAndSettle();

      // Verify success
      expect(find.text('Load created successfully'), findsOneWidget);
    });
  });
}
```

---

## Running Tests

### Run All Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# View coverage report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Run Specific Tests

```bash
# Run unit tests only
flutter test test/unit/

# Run widget tests only
flutter test test/widget/

# Run a specific test file
flutter test test/unit/models/driver_test.dart

# Run tests with specific tag
flutter test --tags=fast
```

### Run Integration Tests

```bash
# Run on connected device/emulator
flutter test integration_test/

# Run on specific device
flutter test integration_test/ -d <device-id>

# Run with driver (for performance profiling)
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
# .github/workflows/test.yml
name: Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

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
      
      - name: Analyze code
        run: flutter analyze
      
      - name: Run unit tests
        run: flutter test --coverage
      
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info
      
      - name: Check coverage threshold
        run: |
          flutter pub global activate coverage
          flutter pub global run coverage:test_with_coverage --minimum-coverage 80
```

### Codemagic Configuration

```yaml
# codemagic.yaml
workflows:
  test-workflow:
    name: Run Tests
    instance_type: mac_mini
    environment:
      flutter: stable
    scripts:
      - name: Get dependencies
        script: flutter pub get
      - name: Run tests
        script: |
          flutter test --coverage
          if [ $? -ne 0 ]; then
            echo "Tests failed!"
            exit 1
          fi
      - name: Check coverage
        script: |
          # Ensure minimum 80% coverage
          # Add coverage checking logic here
    artifacts:
      - coverage/
```

---

## Best Practices

### 1. Test Naming Convention

```dart
// Good
test('positionToMap converts Position correctly', () { ... });

// Bad
test('test1', () { ... });
```

### 2. Use setUp and tearDown

```dart
group('ServiceName', () {
  late Service service;

  setUp(() {
    service = Service();
  });

  tearDown(() {
    service.dispose();
  });

  test('...', () { ... });
});
```

### 3. Mock External Dependencies

```dart
// Use mockito for mocking
@GenerateMocks([FirebaseFirestore, FirebaseAuth])
void main() {
  late MockFirebaseFirestore mockFirestore;
  
  setUp(() {
    mockFirestore = MockFirebaseFirestore();
  });

  test('service uses Firestore correctly', () {
    when(mockFirestore.collection('users'))
        .thenReturn(mockCollection);
    
    // Test code
  });
}
```

### 4. Test Edge Cases

```dart
test('handles null values gracefully', () { ... });
test('handles empty lists', () { ... });
test('handles network errors', () { ... });
test('handles permission denied', () { ... });
```

### 5. Keep Tests Independent

```dart
// Good - each test is independent
test('test1', () { ... });
test('test2', () { ... });

// Bad - tests depend on each other
test('test1 sets up data', () { ... });
test('test2 uses data from test1', () { ... }); // BAD!
```

### 6. Use Test Tags

```dart
@Tags(['fast', 'unit'])
void main() {
  test('quick test', () { ... });
}

@Tags(['slow', 'integration'])
void main() {
  test('integration test', () { ... });
}

// Run: flutter test --tags=fast
```

---

## TODO Items

### High Priority
- [ ] Add unit tests for all service classes
- [ ] Create widget tests for main screens
- [ ] Implement integration tests for critical flows
- [ ] Set up test coverage reporting
- [ ] Add tests to CI/CD pipeline

### Medium Priority
- [ ] Add golden tests for UI consistency
- [ ] Implement performance tests
- [ ] Add accessibility tests
- [ ] Create mock data builders
- [ ] Add property-based tests

### Low Priority
- [ ] Add visual regression tests
- [ ] Implement load testing
- [ ] Add internationalization tests
- [ ] Create test documentation generator
- [ ] Set up automated test reporting

---

## Troubleshooting

### Common Issues

**Tests fail with Firebase errors:**
```dart
// Mock Firebase in tests
void main() {
  setupFirebaseAuthMocks();
  
  setUpAll(() async {
    await Firebase.initializeApp();
  });
}
```

**Widget tests fail with missing MaterialApp:**
```dart
// Wrap widget in MaterialApp
await tester.pumpWidget(
  MaterialApp(
    home: MyWidget(),
  ),
);
```

**Integration tests timeout:**
```bash
# Increase timeout
flutter test --timeout=5m
```

---

## Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)
- [Mockito Package](https://pub.dev/packages/mockito)
- [Integration Test Package](https://pub.dev/packages/integration_test)

---

**Version:** 1.0.0  
**Last Updated:** 2026-02-06  
**Status:** Guide complete, tests to be implemented
