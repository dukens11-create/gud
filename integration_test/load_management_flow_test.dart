import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gud_app/main.dart' as app;
import 'package:gud_app/services/mock_data_service.dart';

/// Integration tests for load management flows
/// 
/// **IMPORTANT**: These tests require Firebase to be configured and running.
/// The demo credentials (admin@gud.com/admin123 and driver@gud.com/driver123) 
/// have been removed from the codebase for production readiness.
/// 
/// To run these tests, you must:
/// 1. Set up Firebase Authentication with test accounts
/// 2. Create a test configuration file or use environment variables for credentials
/// 3. Update the test account credentials in each test method (search for "enterText" calls)
/// 4. Ensure Firebase is properly initialized before running tests
/// 
/// Example: Replace 'admin@gud.com' and 'admin123' with your Firebase test account credentials
/// in the enterText calls throughout this file.
/// 
/// Tests cover:
/// - Admin views all loads
/// - Driver views assigned loads
/// - Driver updates load status (pickup → in transit → delivered)
/// - Load list updates in real-time
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Load Management Flow Tests', () {
    late MockDataService mockService;

    setUp(() async {
      // Reset mock data service before each test
      mockService = MockDataService();
      await mockService.signOut();
    });

    testWidgets('Admin views all loads', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Login as admin
      final emailField = find.byType(TextField).at(0);
      final passwordField = find.byType(TextField).at(1);
      
      await tester.enterText(emailField, 'admin@gud.com');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      
      await tester.enterText(passwordField, 'admin123');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      final loginButton = find.text('Sign In');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify we're on admin home
      expect(find.text('Admin Dashboard'), findsOneWidget);

      // Verify all loads are visible
      expect(find.text('LOAD-001'), findsOneWidget);
      expect(find.text('LOAD-002'), findsOneWidget);
      expect(find.text('LOAD-003'), findsOneWidget);

      // Verify load statuses are shown
      expect(find.textContaining('assigned'), findsOneWidget);
      expect(find.textContaining('in_transit'), findsOneWidget);
      expect(find.textContaining('delivered'), findsOneWidget);

      // Verify load rates are shown
      expect(find.textContaining('\$2500.00'), findsOneWidget);
      expect(find.textContaining('\$3200.00'), findsOneWidget);
      expect(find.textContaining('\$2800.00'), findsOneWidget);
    });

    testWidgets('Driver views assigned loads', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Login as driver
      final emailField = find.byType(TextField).at(0);
      final passwordField = find.byType(TextField).at(1);
      
      await tester.enterText(emailField, 'driver@gud.com');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      
      await tester.enterText(passwordField, 'driver123');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      final loginButton = find.text('Sign In');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify we're on driver home
      expect(find.text('My Loads'), findsOneWidget);

      // Verify driver's assigned loads are visible
      expect(find.text('LOAD-001'), findsOneWidget);
      expect(find.text('LOAD-002'), findsOneWidget);
      expect(find.text('LOAD-003'), findsOneWidget);
    });

    testWidgets('Driver views load details', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Login as driver
      final emailField = find.byType(TextField).at(0);
      final passwordField = find.byType(TextField).at(1);
      
      await tester.enterText(emailField, 'driver@gud.com');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      
      await tester.enterText(passwordField, 'driver123');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      final loginButton = find.text('Sign In');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap on first load to view details
      await tester.tap(find.text('LOAD-001').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify load detail screen is shown
      expect(find.text('LOAD-001'), findsOneWidget);
      expect(find.text('Load Details'), findsOneWidget);
      expect(find.text('Locations'), findsOneWidget);
      
      // Verify addresses are shown
      expect(find.textContaining('Los Angeles'), findsOneWidget);
      expect(find.textContaining('San Francisco'), findsOneWidget);

      // Verify rate is shown
      expect(find.textContaining('\$2500.00'), findsOneWidget);

      // Verify status chip is shown
      expect(find.text('ASSIGNED'), findsOneWidget);
    });

    testWidgets('Driver updates load status - pickup', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Login as driver
      final emailField = find.byType(TextField).at(0);
      final passwordField = find.byType(TextField).at(1);
      
      await tester.enterText(emailField, 'driver@gud.com');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      
      await tester.enterText(passwordField, 'driver123');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      final loginButton = find.text('Sign In');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap on first load (which is in 'assigned' status)
      await tester.tap(find.text('LOAD-001').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify we can see the pickup button
      final pickupButton = find.widgetWithText(ElevatedButton, 'Mark as Picked Up');
      expect(pickupButton, findsOneWidget);

      // Tap pickup button
      await tester.tap(pickupButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify snackbar confirmation
      expect(find.text('Load marked as picked up'), findsOneWidget);

      // Wait for snackbar to disappear
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify status has changed
      expect(find.text('PICKED_UP'), findsOneWidget);
    });

    testWidgets('Driver updates load status - start trip (in transit)', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Login as driver
      final emailField = find.byType(TextField).at(0);
      final passwordField = find.byType(TextField).at(1);
      
      await tester.enterText(emailField, 'driver@gud.com');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      
      await tester.enterText(passwordField, 'driver123');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      final loginButton = find.text('Sign In');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // First update load to picked_up status
      await tester.tap(find.text('LOAD-001').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final pickupButton = find.widgetWithText(ElevatedButton, 'Mark as Picked Up');
      await tester.tap(pickupButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Now find and tap the start trip button
      final startTripButton = find.widgetWithText(ElevatedButton, 'Start Trip');
      expect(startTripButton, findsOneWidget);

      await tester.tap(startTripButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify snackbar confirmation
      expect(find.text('Trip started'), findsOneWidget);

      // Wait for snackbar to disappear
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify status has changed to in_transit
      expect(find.text('IN_TRANSIT'), findsOneWidget);
    });

    testWidgets('Driver updates load status - complete delivery', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Login as driver
      final emailField = find.byType(TextField).at(0);
      final passwordField = find.byType(TextField).at(1);
      
      await tester.enterText(emailField, 'driver@gud.com');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      
      await tester.enterText(passwordField, 'driver123');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      final loginButton = find.text('Sign In');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate through all status updates
      await tester.tap(find.text('LOAD-001').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Mark as picked up
      await tester.tap(find.widgetWithText(ElevatedButton, 'Mark as Picked Up'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Start trip
      await tester.tap(find.widgetWithText(ElevatedButton, 'Start Trip'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Mark as delivered - button is called "Complete Delivery"
      final deliveredButton = find.widgetWithText(ElevatedButton, 'Complete Delivery');
      expect(deliveredButton, findsOneWidget);

      await tester.tap(deliveredButton);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // A dialog should appear asking for miles
      expect(find.text('Complete Delivery'), findsAtLeastNWidget(1));
      expect(find.text('Total Miles'), findsOneWidget);

      // Enter miles
      final milesField = find.byType(TextField).last;
      await tester.enterText(milesField, '380');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      // Tap Complete button in dialog
      await tester.tap(find.widgetWithText(TextButton, 'Complete'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify snackbar confirmation
      expect(find.text('Delivery completed'), findsOneWidget);
    });

    testWidgets('Driver navigates between loads and sees updated statuses', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Login as driver
      final emailField = find.byType(TextField).at(0);
      final passwordField = find.byType(TextField).at(1);
      
      await tester.enterText(emailField, 'driver@gud.com');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      
      await tester.enterText(passwordField, 'driver123');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      final loginButton = find.text('Sign In');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap on first load
      await tester.tap(find.text('LOAD-001').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Update status to picked_up
      await tester.tap(find.widgetWithText(ElevatedButton, 'Mark as Picked Up'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Go back to load list
      await tester.pageBack();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Tap on another load
      await tester.tap(find.text('LOAD-002').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify we're viewing LOAD-002
      expect(find.text('LOAD-002'), findsOneWidget);
      expect(find.text('IN_TRANSIT'), findsOneWidget);

      // Go back and check first load again
      await tester.pageBack();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.text('LOAD-001').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify status is still picked_up
      expect(find.text('PICKED_UP'), findsOneWidget);
    });

    testWidgets('Load status buttons are shown/hidden based on current status', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Login as driver
      final emailField = find.byType(TextField).at(0);
      final passwordField = find.byType(TextField).at(1);
      
      await tester.enterText(emailField, 'driver@gud.com');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      
      await tester.enterText(passwordField, 'driver123');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      final loginButton = find.text('Sign In');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // View delivered load (LOAD-003)
      await tester.tap(find.text('LOAD-003').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify no action buttons are shown for delivered load
      expect(find.widgetWithText(ElevatedButton, 'Mark as Picked Up'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Start Trip'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Complete Delivery'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Upload Proof of Delivery'), findsNothing);

      // Go back and view assigned load (LOAD-001)
      await tester.pageBack();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.text('LOAD-001').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify only pickup button is shown for assigned load
      expect(find.widgetWithText(ElevatedButton, 'Mark as Picked Up'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Start Trip'), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'Complete Delivery'), findsNothing);
    });
  });
}
