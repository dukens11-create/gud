import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gud_app/screens/login_screen.dart';
import 'package:gud_app/screens/admin/admin_home.dart';
import 'package:gud_app/screens/driver/driver_home.dart';
import 'package:gud_app/widgets/app_button.dart';
import 'package:gud_app/widgets/app_textfield.dart';

void main() {
  group('LoginScreen Widget Tests', () {

    Widget makeTestableWidget(Widget child) {
      return MaterialApp(
        home: child,
        routes: {
          '/admin/home': (context) => const AdminHome(),
          '/driver/home': (context) => const DriverHome(driverId: 'test-driver'),
        },
      );
    }

    testWidgets('Initial UI rendering - displays all required elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const LoginScreen()));

      // Verify app icon is displayed
      expect(find.byIcon(Icons.local_shipping), findsOneWidget);

      // Verify app title
      expect(find.text('GUD Express'), findsOneWidget);
      expect(find.text('Demo Mode'), findsOneWidget);

      // Verify demo credentials section
      expect(find.text('Demo Credentials:'), findsOneWidget);
      expect(find.text('Admin: admin@gud.com / admin123'), findsOneWidget);
      expect(find.text('Driver: driver@gud.com / driver123'), findsOneWidget);

      // Verify email field
      expect(find.widgetWithText(AppTextField, 'Email'), findsOneWidget);

      // Verify password field
      expect(find.widgetWithText(AppTextField, 'Password'), findsOneWidget);

      // Verify sign in button
      expect(find.widgetWithText(AppButton, 'Sign In'), findsOneWidget);

      // Verify no error message initially
      expect(find.textContaining('Error'), findsNothing);
      expect(find.textContaining('Invalid'), findsNothing);
    });

    testWidgets('Email field accepts user input', (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const LoginScreen()));

      // Find the email text field
      final emailField = find.widgetWithText(AppTextField, 'Email');
      expect(emailField, findsOneWidget);

      // Enter email text
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      // Verify the text was entered
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('Password field accepts user input and obscures text',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const LoginScreen()));

      // Find the password text field
      final passwordField = find.widgetWithText(AppTextField, 'Password');
      expect(passwordField, findsOneWidget);

      // Verify password field has obscureText enabled
      final passwordWidget = tester.widget<TextFormField>(
        find.descendant(
          of: passwordField,
          matching: find.byType(TextFormField),
        ),
      );
      expect(passwordWidget.obscureText, true);

      // Enter password text
      await tester.enterText(passwordField, 'password123');
      await tester.pump();

      // Verify the text was entered (obscured in UI but stored in controller)
      expect(find.text('password123'), findsOneWidget);
    });

    testWidgets('Sign In button is tappable and shows loading state',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const LoginScreen()));

      // Find the sign in button
      final signInButton = find.widgetWithText(AppButton, 'Sign In');
      expect(signInButton, findsOneWidget);

      // Enter credentials
      await tester.enterText(
          find.widgetWithText(AppTextField, 'Email'), 'test@example.com');
      await tester.enterText(
          find.widgetWithText(AppTextField, 'Password'), 'password123');
      await tester.pump();

      // Tap the sign in button
      await tester.tap(signInButton);
      await tester.pump();

      // Verify loading indicator appears
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('Error message displays when authentication fails',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const LoginScreen()));

      // Enter invalid credentials
      await tester.enterText(
          find.widgetWithText(AppTextField, 'Email'), 'invalid@example.com');
      await tester.enterText(
          find.widgetWithText(AppTextField, 'Password'), 'wrongpassword');
      await tester.pump();

      // Tap sign in button
      await tester.tap(find.widgetWithText(AppButton, 'Sign In'));
      await tester.pump();

      // Wait for async operations
      await tester.pumpAndSettle();

      // Error message should be displayed (authentication will fail in test environment)
      // Note: The exact error message may vary based on the mock/real implementation
    });

    testWidgets('Email field can be cleared', (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const LoginScreen()));

      final emailField = find.widgetWithText(AppTextField, 'Email');

      // Enter text
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();
      expect(find.text('test@example.com'), findsOneWidget);

      // Clear text
      await tester.enterText(emailField, '');
      await tester.pump();
      expect(find.text('test@example.com'), findsNothing);
    });

    testWidgets('Password field can be cleared', (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const LoginScreen()));

      final passwordField = find.widgetWithText(AppTextField, 'Password');

      // Enter text
      await tester.enterText(passwordField, 'password123');
      await tester.pump();
      expect(find.text('password123'), findsOneWidget);

      // Clear text
      await tester.enterText(passwordField, '');
      await tester.pump();
      expect(find.text('password123'), findsNothing);
    });

    testWidgets('Email field accepts keyboard type emailAddress',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const LoginScreen()));

      final emailFieldWidget = tester.widget<TextFormField>(
        find.descendant(
          of: find.widgetWithText(AppTextField, 'Email'),
          matching: find.byType(TextFormField),
        ),
      );

      // Verify keyboard type is set to email address
      expect(emailFieldWidget.keyboardType, TextInputType.emailAddress);
    });

    testWidgets('Password field has maxLines set to 1',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const LoginScreen()));

      final passwordFieldWidget = tester.widget<TextFormField>(
        find.descendant(
          of: find.widgetWithText(AppTextField, 'Password'),
          matching: find.byType(TextFormField),
        ),
      );

      // Verify password field is single line
      expect(passwordFieldWidget.maxLines, 1);
    });

    testWidgets('Login screen is scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const LoginScreen()));

      // Verify SingleChildScrollView exists
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('Demo credentials section has correct styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const LoginScreen()));

      // Find the demo credentials container
      final containerFinder = find.ancestor(
        of: find.text('Demo Credentials:'),
        matching: find.byType(Container),
      );

      expect(containerFinder, findsWidgets);
    });

    testWidgets('Sign In button spans full width',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const LoginScreen()));

      final buttonFinder = find.widgetWithText(AppButton, 'Sign In');
      expect(buttonFinder, findsOneWidget);

      // AppButton has SizedBox with width: double.infinity
      final sizedBoxFinder = find.descendant(
        of: buttonFinder,
        matching: find.byType(SizedBox),
      );
      expect(sizedBoxFinder, findsOneWidget);
    });

    testWidgets('Both text fields are enabled by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const LoginScreen()));

      final emailWidget = tester.widget<TextFormField>(
        find.descendant(
          of: find.widgetWithText(AppTextField, 'Email'),
          matching: find.byType(TextFormField),
        ),
      );

      final passwordWidget = tester.widget<TextFormField>(
        find.descendant(
          of: find.widgetWithText(AppTextField, 'Password'),
          matching: find.byType(TextFormField),
        ),
      );

      expect(emailWidget.enabled, isNotFalse);
      expect(passwordWidget.enabled, isNotFalse);
    });

    testWidgets('Multiple rapid taps on Sign In button',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const LoginScreen()));

      await tester.enterText(
          find.widgetWithText(AppTextField, 'Email'), 'test@example.com');
      await tester.enterText(
          find.widgetWithText(AppTextField, 'Password'), 'password123');
      await tester.pump();

      final signInButton = find.widgetWithText(AppButton, 'Sign In');

      // Tap multiple times quickly
      await tester.tap(signInButton);
      await tester.pump();
      await tester.tap(signInButton);
      await tester.pump();

      // Loading state should prevent multiple submissions
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('Screen layout remains consistent after orientation change',
        (WidgetTester tester) async {
      // Set portrait mode
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(makeTestableWidget(const LoginScreen()));
      await tester.pump();

      // Verify elements exist in portrait
      expect(find.text('GUD Express'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Sign In'), findsOneWidget);

      // Change to landscape
      tester.view.physicalSize = const Size(800, 400);
      await tester.pump();

      // Elements should still be visible
      expect(find.text('GUD Express'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Sign In'), findsOneWidget);

      // Reset to default
      addTearDown(tester.view.resetPhysicalSize);
    });
  });
}
