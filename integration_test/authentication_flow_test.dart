import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gud_app/main.dart' as app;
import 'package:gud_app/services/mock_data_service.dart';

/// Integration tests for authentication flows
/// 
/// **IMPORTANT**: These tests require Firebase to be configured and running.
/// The demo credentials (admin@gud.com/admin123 and driver@gud.com/driver123) 
/// have been removed from the codebase for production readiness.
/// 
/// To run these tests, you must:
/// 1. Set up Firebase Authentication with test accounts
/// 2. Update the credentials below with your Firebase test account credentials
/// 3. Ensure Firebase is properly initialized before running tests
/// 
/// Tests cover:
/// - Complete login flow with valid credentials
/// - Login with invalid credentials (error handling)
/// - Logout flow
/// - Role-based navigation (admin vs driver)
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Tests', () {
    setUp(() async {
      // Reset mock data service before each test
      final mockService = MockDataService();
      await mockService.signOut();
    });

    testWidgets('Complete admin login flow - navigate to admin home', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify we're on the login screen
      expect(find.text('GUD Express'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);

      // Find email and password fields
      final emailField = find.byType(TextField).at(0);
      final passwordField = find.byType(TextField).at(1);
      
      // Enter admin credentials
      await tester.enterText(emailField, 'admin@gud.com');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      
      await tester.enterText(passwordField, 'admin123');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      // Tap login button (labeled "Sign In")
      final loginButton = find.text('Sign In');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify navigation to admin home
      expect(find.text('Admin Dashboard'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget); // Create load FAB
      expect(find.byIcon(Icons.people), findsOneWidget); // Drivers FAB
    });

    testWidgets('Complete driver login flow - navigate to driver home', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify we're on the login screen
      expect(find.text('GUD Express'), findsOneWidget);

      // Find email and password fields
      final emailField = find.byType(TextField).at(0);
      final passwordField = find.byType(TextField).at(1);
      
      // Enter driver credentials
      await tester.enterText(emailField, 'driver@gud.com');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      
      await tester.enterText(passwordField, 'driver123');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      // Tap login button (labeled "Sign In")
      final loginButton = find.text('Sign In');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify navigation to driver home
      expect(find.text('My Loads'), findsOneWidget);
      expect(find.byIcon(Icons.exit_to_app), findsOneWidget);
      
      // Verify driver can see their loads
      expect(find.text('LOAD-001'), findsOneWidget);
      expect(find.text('LOAD-002'), findsOneWidget);
    });

    testWidgets('Login with invalid credentials shows error', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Find email and password fields
      final emailField = find.byType(TextField).at(0);
      final passwordField = find.byType(TextField).at(1);
      
      // Enter invalid credentials
      await tester.enterText(emailField, 'invalid@gud.com');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      
      await tester.enterText(passwordField, 'wrongpassword');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      // Tap login button (labeled "Sign In")
      final loginButton = find.text('Sign In');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify error message is displayed
      expect(find.textContaining('Invalid'), findsOneWidget);
      
      // Verify we're still on the login screen
      expect(find.text('GUD Express'), findsOneWidget);
      expect(find.text('Sign In'), findsAtLeastNWidget(1));
    });

    testWidgets('Login with empty credentials shows error', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Don't enter any credentials, just tap login button
      final loginButton = find.text('Sign In');
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify error message is displayed
      expect(find.textContaining('Invalid'), findsOneWidget);
      
      // Verify we're still on the login screen
      expect(find.text('GUD Express'), findsOneWidget);
    });

    testWidgets('Admin logout flow', (tester) async {
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

      // Tap logout button
      final logoutButton = find.byIcon(Icons.exit_to_app);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify we're back on the login screen
      expect(find.text('GUD Express'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      
      // Verify admin home is no longer visible
      expect(find.text('Admin Dashboard'), findsNothing);
    });

    testWidgets('Driver logout flow', (tester) async {
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

      // Tap logout button
      final logoutButton = find.byIcon(Icons.exit_to_app);
      await tester.tap(logoutButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify we're back on the login screen
      expect(find.text('GUD Express'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      
      // Verify driver home is no longer visible
      expect(find.text('My Loads'), findsNothing);
    });

    testWidgets('Role-based navigation - admin cannot access driver screens directly', (tester) async {
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

      // Verify admin is on admin home, not driver home
      expect(find.text('Admin Dashboard'), findsOneWidget);
      expect(find.text('My Loads'), findsNothing);
    });

    testWidgets('Role-based navigation - driver cannot access admin screens directly', (tester) async {
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

      // Verify driver is on driver home, not admin home
      expect(find.text('My Loads'), findsOneWidget);
      expect(find.text('Admin Dashboard'), findsNothing);
    });
  });
}
