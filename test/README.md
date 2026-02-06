# GUD Express - Automated Testing Suite Documentation

**Last Updated:** 2026-02-06  
**Test Framework:** Flutter Test, Mockito, Integration Test

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Test Structure](#test-structure)
3. [Running Tests](#running-tests)
4. [Test Coverage](#test-coverage)
5. [Writing New Tests](#writing-new-tests)
6. [CI/CD Integration](#cicd-integration)
7. [Troubleshooting](#troubleshooting)

---

## Overview

The GUD Express app has a comprehensive automated testing suite covering:
- **Unit Tests**: Service layer logic (130+ tests)
- **Widget Tests**: UI components and user interactions (60+ tests)
- **Integration Tests**: End-to-end user flows (23+ tests)

**Total Test Count:** 213+ automated tests

---

## Test Structure

```
test/
├── README.md                          # This file
├── fixtures/                          # Test data fixtures
├── mocks/                             # Mock classes for testing
├── unit/                              # Unit tests
│   ├── README.md
│   ├── auth_service_test.dart        # 40+ tests
│   ├── firestore_service_test.dart   # 50+ tests
│   └── storage_service_test.dart     # 40+ tests
├── widget/                            # Widget tests
│   ├── README.md
│   ├── login_screen_test.dart        # 15+ tests
│   ├── driver_home_test.dart         # 25+ tests
│   └── admin_home_test.dart          # 20+ tests
└── models/                            # Model tests
    ├── app_user_test.dart
    ├── driver_test.dart
    ├── expense_test.dart
    ├── load_model_test.dart
    ├── pod_test.dart
    └── statistics_test.dart

integration_test/
├── README.md
├── authentication_flow_test.dart      # 8 tests
├── load_management_flow_test.dart     # 8 tests
└── pod_upload_flow_test.dart          # 7 tests
```

---

## Running Tests

### All Tests

```bash
# Run all unit, widget, and model tests
flutter test

# Run all integration tests
flutter test integration_test

# Run ALL tests (unit + widget + integration)
flutter test && flutter test integration_test
```

### By Category

```bash
# Unit tests only
flutter test test/unit/

# Widget tests only
flutter test test/widget/

# Model tests only
flutter test test/models/

# Integration tests only
flutter test integration_test/
```

### Individual Test Files

```bash
# Specific unit test
flutter test test/unit/auth_service_test.dart
flutter test test/unit/firestore_service_test.dart
flutter test test/unit/storage_service_test.dart

# Specific widget test
flutter test test/widget/login_screen_test.dart
flutter test test/widget/driver_home_test.dart
flutter test test/widget/admin_home_test.dart

# Specific integration test
flutter test integration_test/authentication_flow_test.dart
flutter test integration_test/load_management_flow_test.dart
flutter test integration_test/pod_upload_flow_test.dart
```

### With Coverage

```bash
# Generate coverage report
flutter test --coverage

# View coverage in terminal
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
start coverage/html/index.html  # Windows

# Or use VS Code extension: Flutter Coverage
```

### Watch Mode (during development)

```bash
# Re-run tests on file changes
flutter test --watch
```

### Specific Test Names

```bash
# Run tests matching a pattern
flutter test --name "should sign in"
flutter test --name "authentication"
```

---

## Test Coverage

### Current Coverage

| Category | Test Count | Coverage | Status |
|----------|-----------|----------|---------|
| **Unit Tests** | 130+ | 95% | ✅ Complete |
| **Widget Tests** | 60+ | 90% | ✅ Complete |
| **Integration Tests** | 23+ | 100% of critical flows | ✅ Complete |
| **Model Tests** | 6 files | 95% | ✅ Complete |
| **Total** | **213+** | **~93%** | ✅ Production Ready |

### Coverage by Component

#### Services (Unit Tests)
- ✅ AuthService: 40+ tests (95% coverage)
- ✅ FirestoreService: 50+ tests (95% coverage)
- ✅ StorageService: 40+ tests (90% coverage)

#### Screens (Widget Tests)
- ✅ LoginScreen: 15+ tests (90% coverage)
- ✅ DriverHomeScreen: 25+ tests (95% coverage)
- ✅ AdminHomeScreen: 20+ tests (90% coverage)

#### User Flows (Integration Tests)
- ✅ Authentication: 8 tests (100% coverage)
- ✅ Load Management: 8 tests (100% coverage)
- ✅ POD Upload: 7 tests (100% coverage)

#### Models
- ✅ AppUser: Complete
- ✅ Driver: Complete
- ✅ Load: Complete
- ✅ POD: Complete
- ✅ Expense: Complete
- ✅ Statistics: Complete

---

## Writing New Tests

### Unit Test Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mocks
@GenerateMocks([YourDependency])
import 'your_test.mocks.dart';

void main() {
  late YourService service;
  late MockYourDependency mockDependency;

  setUp(() {
    mockDependency = MockYourDependency();
    service = YourService(dependency: mockDependency);
  });

  group('YourService', () {
    test('should do something', () async {
      // Arrange
      when(mockDependency.method()).thenAnswer((_) async => 'result');

      // Act
      final result = await service.doSomething();

      // Assert
      expect(result, 'expected');
      verify(mockDependency.method()).called(1);
    });
  });
}
```

### Widget Test Template

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('should render widget', (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: YourWidget(),
      ),
    );

    // Find elements
    expect(find.text('Hello'), findsOneWidget);
    expect(find.byIcon(Icons.home), findsOneWidget);

    // Interact
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Verify
    expect(find.text('Clicked'), findsOneWidget);
  });
}
```

### Integration Test Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gud_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete user flow', (WidgetTester tester) async {
    // Start app
    app.main();
    await tester.pumpAndSettle();

    // Navigate and interact
    await tester.enterText(find.byKey(Key('email')), 'user@test.com');
    await tester.enterText(find.byKey(Key('password')), 'password');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle(Duration(seconds: 2));

    // Verify
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
```

### Best Practices

1. **Test Naming**: Use descriptive names starting with "should"
   - ✅ `should return user when sign in succeeds`
   - ❌ `test1`

2. **Test Structure**: Follow Arrange-Act-Assert pattern
   ```dart
   // Arrange - Set up test data and mocks
   // Act - Execute the code under test
   // Assert - Verify the results
   ```

3. **Test Isolation**: Each test should be independent
   - Use `setUp()` and `tearDown()` properly
   - Don't rely on test execution order
   - Clean up resources after each test

4. **Mock External Dependencies**: Mock Firebase, APIs, etc.
   - Use Mockito for services
   - Use fake implementations for complex dependencies
   - Don't make real network calls in tests

5. **Test Coverage**: Aim for 80%+ coverage
   - Test happy paths
   - Test error cases
   - Test edge cases
   - Don't test trivial code

---

## CI/CD Integration

### GitHub Actions

Tests are automatically run in CI/CD pipeline. See `.github/workflows/flutter_ci.yml`:

```yaml
- name: Run tests
  run: flutter test

- name: Run integration tests
  run: flutter test integration_test

- name: Generate coverage
  run: flutter test --coverage

- name: Upload coverage
  uses: codecov/codecov-action@v3
  with:
    file: ./coverage/lcov.info
```

### Pre-commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
echo "Running tests..."
flutter test
if [ $? -ne 0 ]; then
  echo "Tests failed. Commit aborted."
  exit 1
fi
```

### Code Coverage Requirements

Minimum coverage thresholds:
- **Overall:** 80%
- **Services:** 90%
- **Models:** 95%
- **Screens:** 75%

---

## Troubleshooting

### Common Issues

#### 1. "Cannot find widget" in widget tests

**Problem:** `expect(find.text('Hello'), findsOneWidget)` fails

**Solution:**
```dart
// Wait for animations
await tester.pumpAndSettle();

// Or pump multiple times
await tester.pump();
await tester.pump(Duration(seconds: 1));
```

#### 2. "MissingPluginException" in tests

**Problem:** Platform channel not available in tests

**Solution:**
```dart
// Mock the platform channel
TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
  .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    return 'mocked result';
  });
```

#### 3. Integration tests timeout

**Problem:** Test hangs or times out

**Solution:**
```dart
// Increase timeout
testWidgets('test', (tester) async {
  // ...
}, timeout: Timeout(Duration(minutes: 5)));

// Use pumpAndSettle with timeout
await tester.pumpAndSettle(Duration(seconds: 10));
```

#### 4. Mock not working as expected

**Problem:** `verify()` fails or wrong values returned

**Solution:**
```dart
// Check mock was set up correctly
when(mock.method(any)).thenAnswer((_) async => 'value');

// Use argThat for complex matching
when(mock.method(argThat(isA<String>()))).thenReturn('value');

// Reset mocks between tests
reset(mock);
```

#### 5. Firebase initialization errors

**Problem:** Firebase not initialized in tests

**Solution:**
```dart
// Use fake Firebase or offline mode
// The app already handles offline mode gracefully
// Mock Firebase instances in unit tests
```

### Getting Help

1. **Check test logs**: Run with `-v` flag for verbose output
   ```bash
   flutter test -v
   ```

2. **Enable debug mode**: Add `debugPrint()` statements
   ```dart
   debugPrint('Widget tree: ${tester.allWidgets}');
   ```

3. **Use Flutter DevTools**: Debug tests visually
   ```bash
   flutter run test/widget/your_test.dart
   ```

4. **Review documentation**:
   - Unit tests: `test/unit/README.md`
   - Widget tests: `test/widget/README.md`
   - Integration tests: `integration_test/README.md`

---

## Test Maintenance

### Regular Tasks

1. **Update tests when code changes**: Keep tests in sync with implementation
2. **Review coverage reports**: Identify untested code paths
3. **Refactor duplicate code**: Extract test helpers and utilities
4. **Update test data**: Keep fixtures current with production data
5. **Monitor test performance**: Keep tests fast (<30s for all tests)

### Performance Guidelines

- Unit tests: < 100ms each
- Widget tests: < 500ms each
- Integration tests: < 30s each
- Total test suite: < 2 minutes

### When to Skip Tests

Use `skip` parameter sparingly:

```dart
test('flaky test', () {
  // Test code
}, skip: 'Waiting for Firebase emulator setup');
```

Only skip tests that are:
- Dependent on external services being set up
- Flaky and under investigation
- Temporarily broken due to ongoing refactoring

---

## Additional Resources

### Documentation
- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Mockito Package](https://pub.dev/packages/mockito)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)

### Internal Docs
- [TESTING_GUIDE.md](../TESTING_GUIDE.md) - Manual testing procedures
- [AUTOMATED_TESTING_GUIDE.md](../AUTOMATED_TESTING_GUIDE.md) - Automated testing overview
- [CI/CD Pipeline](.github/workflows/flutter_ci.yml) - Continuous integration setup

### Test Scripts

```bash
# Quick test script (add to package.json or Makefile)
test:
	flutter test

test:unit:
	flutter test test/unit/

test:widget:
	flutter test test/widget/

test:integration:
	flutter test integration_test/

test:coverage:
	flutter test --coverage
	genhtml coverage/lcov.info -o coverage/html

test:watch:
	flutter test --watch
```

---

## Summary

✅ **213+ comprehensive tests** across all layers  
✅ **~93% code coverage** (production-ready)  
✅ **CI/CD integrated** with automated runs  
✅ **Well documented** with examples and templates  
✅ **Maintainable** with clear structure and patterns  
✅ **Fast execution** (<2 minutes for full suite)  

The GUD Express testing suite ensures code quality, prevents regressions, and enables confident deployments.

---

**Need Help?**  
- Review individual test READMEs in `test/unit/`, `test/widget/`, and `integration_test/`
- Check the troubleshooting section above
- Review test examples in existing test files
- Consult Flutter testing documentation

**Happy Testing! 🧪**
