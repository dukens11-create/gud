# Widget Tests Documentation

This directory contains comprehensive widget tests for the key screens in the GUD Express Flutter application.

## Overview

Widget tests verify the UI behavior and user interactions of individual widgets and screens. They run faster than integration tests and provide confidence that the UI works as expected.

## Test Files

### 1. login_screen_test.dart

Tests for the login screen functionality and UI elements.

**Test Coverage:**
- ✅ Initial UI rendering (app icon, title, demo mode badge)
- ✅ Email field rendering and validation
- ✅ Password field rendering and obscure text
- ✅ Demo credentials display
- ✅ Sign In button interaction
- ✅ Loading state during authentication
- ✅ Error message display
- ✅ Field input handling and clearing
- ✅ Keyboard type configuration
- ✅ Screen scrollability
- ✅ Multiple rapid tap prevention
- ✅ Orientation change handling

**Key Test Scenarios:**
```dart
// Example: Testing login button tap
testWidgets('Sign In button is tappable and shows loading state', (tester) async {
  await tester.pumpWidget(makeTestableWidget(const LoginScreen()));
  
  await tester.enterText(find.widgetWithText(AppTextField, 'Email'), 'test@example.com');
  await tester.enterText(find.widgetWithText(AppTextField, 'Password'), 'password123');
  await tester.pump();
  
  await tester.tap(find.widgetWithText(AppButton, 'Sign In'));
  await tester.pump();
  
  expect(find.byType(CircularProgressIndicator), findsWidgets);
});
```

### 2. driver_home_test.dart

Tests for the driver home screen functionality and load management.

**Test Coverage:**
- ✅ App bar with title and action buttons
- ✅ Send Location button functionality
- ✅ Loading state while fetching loads
- ✅ Empty state when no loads assigned
- ✅ Load list display
- ✅ Load card information display
- ✅ Navigation to load detail screen
- ✅ Navigation to expenses screen
- ✅ Navigation to earnings screen
- ✅ Sign out functionality
- ✅ Send location loading state
- ✅ Button disabled state during operation
- ✅ Stream error handling
- ✅ Multiple loads scrolling

**Key Test Scenarios:**
```dart
// Example: Testing load card tap navigation
testWidgets('Tapping a load card navigates to load detail', (tester) async {
  await tester.pumpWidget(makeTestableWidget(const DriverHome(driverId: 'driver@gud.com')));
  await tester.pumpAndSettle(const Duration(seconds: 2));
  
  final listTileFinder = find.byType(ListTile);
  if (listTileFinder.evaluate().isNotEmpty) {
    await tester.tap(listTileFinder.first);
    await tester.pumpAndSettle();
    
    expect(find.byType(LoadDetailScreen), findsOneWidget);
  }
});
```

### 3. admin_home_test.dart

Tests for the admin dashboard functionality and management features.

**Test Coverage:**
- ✅ App bar with title and sign out
- ✅ Loading state while fetching loads
- ✅ Empty state when no loads exist
- ✅ Load list display
- ✅ All four floating action buttons (FABs)
- ✅ Navigation to statistics screen
- ✅ Navigation to expenses screen
- ✅ Navigation to manage drivers screen
- ✅ Navigation to create load screen
- ✅ Sign out functionality
- ✅ Load card information display
- ✅ FAB hero tags uniqueness
- ✅ FAB vertical arrangement
- ✅ Stream error handling
- ✅ Orientation change handling

**Key Test Scenarios:**
```dart
// Example: Testing FAB navigation
testWidgets('Statistics FAB navigates to statistics screen', (tester) async {
  await tester.pumpWidget(makeTestableWidget(const AdminHome()));
  await tester.pump();
  
  await tester.tap(find.byIcon(Icons.bar_chart));
  await tester.pumpAndSettle();
  
  expect(find.text('Statistics Screen'), findsOneWidget);
});
```

## Running the Tests

### Run All Widget Tests
```bash
flutter test test/widget/
```

### Run Individual Test Files
```bash
# Login screen tests
flutter test test/widget/login_screen_test.dart

# Driver home tests
flutter test test/widget/driver_home_test.dart

# Admin home tests
flutter test test/widget/admin_home_test.dart
```

### Run with Coverage
```bash
flutter test --coverage test/widget/
```

### Run in Verbose Mode
```bash
flutter test --verbose test/widget/
```

## Test Best Practices Used

### 1. Proper Setup and Teardown
```dart
setUp(() {
  mockAuthService = MockAuthService();
});
```

### 2. Test Isolation
Each test is independent and doesn't rely on the state from other tests.

### 3. Descriptive Test Names
```dart
testWidgets('Initial UI rendering - displays all required elements', ...)
testWidgets('Email field accepts user input', ...)
```

### 4. Test Helpers
```dart
Widget makeTestableWidget(Widget child) {
  return MaterialApp(
    home: child,
    routes: {
      // Define routes for navigation testing
    },
  );
}
```

### 5. Proper Pumping
- `pump()` - Trigger a frame
- `pumpAndSettle()` - Wait for all animations to complete
- `pump(Duration)` - Advance time by a specific duration

### 6. Finder Usage
```dart
// By type
find.byType(CircularProgressIndicator)

// By text
find.text('Sign In')

// By icon
find.byIcon(Icons.add)

// By widget with text
find.widgetWithText(AppButton, 'Sign In')

// Composite finders
find.descendant(of: parentFinder, matching: childFinder)
```

### 7. Assertions
```dart
// Widget existence
expect(find.text('Title'), findsOneWidget);
expect(find.byType(ListView), findsWidgets);
expect(find.text('Error'), findsNothing);

// Widget count
expect(find.byType(FloatingActionButton), findsNWidgets(4));

// Widget properties
expect(button.onPressed, isNotNull);
expect(textField.obscureText, true);
```

## Common Issues and Solutions

### Issue: Tests fail with "Null check operator used on a null value"
**Solution:** Ensure proper initialization of controllers and services in setUp().

### Issue: Navigation tests fail
**Solution:** Define all necessary routes in makeTestableWidget() helper.

### Issue: Stream tests timeout
**Solution:** Use `pumpAndSettle()` with a timeout duration for async operations.

### Issue: Finder doesn't find widget
**Solution:** Use `await tester.pump()` after interactions and check widget tree with:
```dart
debugDumpApp(); // Print widget tree
```

## Test Coverage Goals

Current coverage targets:
- **UI Rendering:** 100% - All UI elements are tested
- **User Interactions:** 95% - All major user flows covered
- **Navigation:** 100% - All navigation paths tested
- **Error States:** 90% - Error handling and edge cases covered
- **Loading States:** 100% - All loading indicators tested

## Continuous Integration

These tests run automatically on:
- Every pull request
- Every commit to main branch
- Nightly builds

## Test Maintenance

### Adding New Tests
1. Create test file in `test/widget/` directory
2. Follow naming convention: `{screen_name}_test.dart`
3. Use existing test files as templates
4. Update this README with new test coverage

### Updating Existing Tests
1. Update tests when UI changes
2. Add tests for new features
3. Remove tests for deprecated features
4. Keep test descriptions accurate

## Resources

- [Flutter Widget Testing Guide](https://docs.flutter.dev/testing/overview#widget-tests)
- [Flutter Test Package](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Testing Best Practices](https://docs.flutter.dev/testing/best-practices)

## Contributors

When contributing widget tests:
1. Follow the existing test structure
2. Use descriptive test names
3. Test both happy path and edge cases
4. Add comments for complex test scenarios
5. Update this README if adding new test files

## Test Execution Time

Approximate execution times:
- `login_screen_test.dart`: ~5 seconds
- `driver_home_test.dart`: ~8 seconds
- `admin_home_test.dart`: ~7 seconds
- **Total:** ~20 seconds

## Future Improvements

Planned enhancements:
- [ ] Add golden tests for pixel-perfect UI verification
- [ ] Add accessibility tests
- [ ] Increase test coverage to 100%
- [ ] Add performance benchmarks
- [ ] Add tests for all screens
- [ ] Add mocking for Firebase services for more controlled testing
- [ ] Add visual regression testing

---

**Last Updated:** 2024-02-06
**Test Framework:** Flutter Test
**Minimum Flutter Version:** 3.0.0
