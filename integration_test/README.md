# Integration Tests for GUD Express

This directory contains comprehensive integration tests for the GUD Express Flutter application. Integration tests verify end-to-end user flows and interactions across multiple screens and services.

## Test Files

### 1. `authentication_flow_test.dart`
Tests all authentication-related flows:
- ✅ Complete admin login flow (credentials → sign in → navigate to admin home)
- ✅ Complete driver login flow (credentials → sign in → navigate to driver home)
- ✅ Login with invalid credentials (error handling)
- ✅ Login with empty credentials (validation)
- ✅ Admin logout flow
- ✅ Driver logout flow
- ✅ Role-based navigation (admin vs driver)

### 2. `load_management_flow_test.dart`
Tests load management and status update flows:
- ✅ Admin views all loads in the dashboard
- ✅ Driver views assigned loads
- ✅ Driver views load details
- ✅ Driver updates load status: assigned → picked_up
- ✅ Driver updates load status: picked_up → in_transit
- ✅ Driver updates load status: in_transit → delivered
- ✅ Load list updates reflect status changes
- ✅ Status-specific action buttons display correctly

### 3. `pod_upload_flow_test.dart`
Tests Proof of Delivery (POD) upload flows:
- ✅ Driver navigates to upload POD screen
- ✅ Driver opens image source selection dialog
- ✅ Driver enters delivery notes
- ✅ Upload validation (requires image)
- ✅ Load information display on POD screen
- ✅ Navigation between screens
- ✅ POD upload button visibility based on load status
- ✅ Complete POD upload flow with notes

## Running Integration Tests

### Prerequisites

1. **Flutter SDK**: Ensure Flutter is installed and up to date:
   ```bash
   flutter --version
   flutter doctor
   ```

2. **Device/Emulator**: Integration tests require a device or emulator:
   - **Android Emulator**: Start an Android emulator
   - **iOS Simulator**: Start an iOS simulator (Mac only)
   - **Physical Device**: Connect a physical device with debugging enabled

3. **Firebase Setup** (Optional):
   - Tests can run with or without Firebase
   - The app uses mock data when Firebase is unavailable
   - For Firebase testing, ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are configured

### Running All Integration Tests

Run all integration tests:
```bash
flutter test integration_test
```

### Running Individual Test Files

Run a specific test suite:
```bash
# Authentication tests only
flutter test integration_test/authentication_flow_test.dart

# Load management tests only
flutter test integration_test/load_management_flow_test.dart

# POD upload tests only
flutter test integration_test/pod_upload_flow_test.dart
```

### Running on Specific Devices

Run tests on a specific device:
```bash
# List available devices
flutter devices

# Run on specific device
flutter test integration_test/authentication_flow_test.dart -d <device-id>

# Examples:
flutter test integration_test -d chrome           # Web
flutter test integration_test -d emulator-5554     # Android
flutter test integration_test -d "iPhone 14"       # iOS
```

### Running with Verbose Output

Get detailed test output:
```bash
flutter test integration_test --verbose
```

### Running with Coverage

Generate code coverage reports:
```bash
flutter test integration_test --coverage
```

Then generate HTML report:
```bash
# Install lcov (if not already installed)
# Mac: brew install lcov
# Linux: sudo apt-get install lcov

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Test Configuration

### Test Credentials

The tests use these mock credentials (from `MockDataService`):

**Admin Account:**
- Email: `admin@gud.com`
- Password: `admin123`
- Role: Admin

**Driver Account:**
- Email: `driver@gud.com`
- Password: `driver123`
- Role: Driver

### Mock Data

Tests use three pre-loaded demo loads:
1. **LOAD-001**: Assigned status (LA → SF, $2,500)
2. **LOAD-002**: In transit status (San Diego → Portland, $3,200)
3. **LOAD-003**: Delivered status (Seattle → Phoenix, $2,800)

## Test Architecture

### Integration Test Structure

Each test file follows this pattern:

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Test Group Name', () {
    setUp(() async {
      // Reset state before each test
      final mockService = MockDataService();
      await mockService.signOut();
    });

    testWidgets('Test description', (tester) async {
      // 1. Start app
      app.main();
      await tester.pumpAndSettle();

      // 2. Perform user actions
      // ...

      // 3. Verify results
      expect(find.text('Expected Text'), findsOneWidget);
    });
  });
}
```

### Key Testing Utilities

- **`pumpAndSettle()`**: Waits for all animations and rebuilds to complete
- **`find.text()`**: Finds widgets by text content
- **`find.byType()`**: Finds widgets by type
- **`find.byIcon()`**: Finds widgets by icon
- **`tester.tap()`**: Simulates user tap
- **`tester.enterText()`**: Simulates text input
- **`tester.pageBack()`**: Simulates back navigation
- **`expect()`**: Asserts test expectations

## Troubleshooting

### Common Issues

**Issue: Tests fail with "No device found"**
```bash
# Solution: Start an emulator or connect a device
flutter emulators --launch <emulator-id>
# Or connect physical device
```

**Issue: Tests timeout**
```bash
# Solution: Increase timeout duration in test
await tester.pumpAndSettle(const Duration(seconds: 5));
```

**Issue: Firebase initialization errors**
```
# These are expected and handled by the app
# The app falls back to offline/demo mode
# Tests will still pass
```

**Issue: Widget not found errors**
```bash
# Solution: Ensure proper wait times
await tester.pumpAndSettle();  # Wait for animations
await tester.pump(const Duration(milliseconds: 500));  # Wait for specific duration
```

**Issue: Image picker tests fail**
```
# Note: Image picker requires platform-specific mocking
# Current tests verify UI flow without actual image selection
# For full image picker testing, use platform channels mocking
```

### Debug Mode

Run tests in debug mode for better error messages:
```bash
flutter test integration_test --debug
```

### Test Output Files

Failed tests generate screenshots:
```
build/app/outputs/androidTest-results/connected/
```

## Best Practices

### Writing New Integration Tests

1. **Test User Flows, Not Implementation**: Focus on what users do, not how the code works
2. **Use Descriptive Test Names**: Make it clear what scenario is being tested
3. **Keep Tests Independent**: Each test should run successfully in isolation
4. **Reset State**: Always reset app state in `setUp()` hooks
5. **Wait for Animations**: Use `pumpAndSettle()` after navigation and interactions
6. **Verify Expected Outcomes**: Always include assertions (`expect()`)
7. **Handle Asynchrony**: Use proper `await` for all async operations

### Example Test Pattern

```dart
testWidgets('User can complete checkout flow', (tester) async {
  // Arrange: Set up initial state
  app.main();
  await tester.pumpAndSettle();
  
  // Act: Perform user actions
  await _loginAsUser(tester);
  await _addItemToCart(tester);
  await _proceedToCheckout(tester);
  
  // Assert: Verify outcomes
  expect(find.text('Order Confirmed'), findsOneWidget);
  expect(find.text('Order #12345'), findsOneWidget);
});
```

## Continuous Integration

### GitHub Actions

Add to `.github/workflows/test.yml`:

```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Start simulator
        run: |
          xcrun simctl boot "iPhone 14" || true
      
      - name: Run integration tests
        run: flutter test integration_test
```

## Additional Resources

- [Flutter Integration Testing Docs](https://docs.flutter.dev/testing/integration-tests)
- [Flutter Testing Best Practices](https://docs.flutter.dev/testing/best-practices)
- [WidgetTester API Reference](https://api.flutter.dev/flutter/flutter_test/WidgetTester-class.html)
- [integration_test Package](https://pub.dev/packages/integration_test)

## Test Coverage

Current coverage by feature:

| Feature | Coverage | Test File |
|---------|----------|-----------|
| Authentication | ✅ Complete | `authentication_flow_test.dart` |
| Role-based Access | ✅ Complete | `authentication_flow_test.dart` |
| Load Viewing | ✅ Complete | `load_management_flow_test.dart` |
| Load Status Updates | ✅ Complete | `load_management_flow_test.dart` |
| POD Upload UI | ✅ Complete | `pod_upload_flow_test.dart` |
| Navigation | ✅ Complete | All test files |
| Error Handling | ✅ Complete | All test files |

## Contributing

When adding new integration tests:

1. Follow the existing test structure and naming conventions
2. Update this README with new test descriptions
3. Ensure tests pass on multiple platforms (Android, iOS, Web)
4. Include proper error handling and edge cases
5. Document any special setup requirements

## Support

For questions or issues with integration tests:
- Check troubleshooting section above
- Review Flutter testing documentation
- Check test output and error messages
- Ensure device/emulator is properly configured
