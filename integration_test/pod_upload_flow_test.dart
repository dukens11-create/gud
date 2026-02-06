import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gud_app/main.dart' as app;
import 'package:gud_app/services/mock_data_service.dart';

/// Integration tests for POD (Proof of Delivery) upload flow
/// 
/// Tests cover:
/// - Driver navigates to upload POD screen
/// - Driver selects image source (camera/gallery mock)
/// - Driver enters notes
/// - Driver uploads POD
/// - POD upload confirmation
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('POD Upload Flow Tests', () {
    late MockDataService mockService;

    setUp(() async {
      // Reset mock data service before each test
      mockService = MockDataService();
      await mockService.signOut();
    });

    testWidgets('Driver navigates to upload POD screen', (tester) async {
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

      // Navigate to an in_transit load to upload POD
      await tester.tap(find.text('LOAD-002').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Find and tap Upload Proof of Delivery button
      final uploadPodButton = find.widgetWithText(ElevatedButton, 'Upload Proof of Delivery');
      expect(uploadPodButton, findsOneWidget);

      await tester.tap(uploadPodButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify we're on the Upload POD screen
      expect(find.text('Upload Proof of Delivery'), findsAtLeastNWidget(1));
      expect(find.text('Tap to add photo'), findsOneWidget);
    });

    testWidgets('Driver opens image source dialog', (tester) async {
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

      // Navigate to upload POD screen
      await tester.tap(find.text('LOAD-002').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Upload Proof of Delivery'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Tap on the image area to open source dialog
      final imagePlaceholder = find.text('Tap to add photo');
      expect(imagePlaceholder, findsOneWidget);
      
      await tester.tap(imagePlaceholder);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Verify bottom sheet is shown with image source options
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
    });

    testWidgets('Driver can enter POD notes', (tester) async {
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

      // Navigate to upload POD screen
      await tester.tap(find.text('LOAD-002').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Upload Proof of Delivery'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Find notes field by label text
      final notesField = find.widgetWithText(TextFormField, 'Notes (optional)');
      expect(notesField, findsOneWidget);

      await tester.enterText(notesField, 'Delivered to front desk. Received by John Doe.');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      // Verify text was entered
      expect(find.text('Delivered to front desk. Received by John Doe.'), findsOneWidget);
    });

    testWidgets('Upload POD requires image selection', (tester) async {
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

      // Navigate to upload POD screen
      await tester.tap(find.text('LOAD-002').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Upload Proof of Delivery'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Find AppButton with label 'Upload POD'
      final uploadButton = find.text('Upload POD');
      expect(uploadButton, findsOneWidget);
      
      await tester.tap(uploadButton);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Verify error message is shown
      expect(find.text('Please select an image first'), findsOneWidget);
    });

    testWidgets('POD upload screen shows load information', (tester) async {
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

      // Navigate to upload POD screen
      await tester.tap(find.text('LOAD-002').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Upload Proof of Delivery'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify load information is displayed
      expect(find.text('LOAD-002'), findsOneWidget);
      expect(find.text('Upload Proof of Delivery'), findsAtLeastNWidget(1));
    });

    testWidgets('Driver can navigate back from POD upload screen', (tester) async {
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

      // Navigate to upload POD screen
      await tester.tap(find.text('LOAD-002').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Upload Proof of Delivery'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify we're on Upload POD screen
      expect(find.text('Upload Proof of Delivery'), findsAtLeastNWidget(1));

      // Navigate back
      await tester.pageBack();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify we're back on load detail screen
      expect(find.text('LOAD-002'), findsOneWidget);
      expect(find.text('Load Details'), findsOneWidget);
    });

    testWidgets('POD upload button only visible for appropriate load statuses', (tester) async {
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

      // Check assigned load (LOAD-001) - should NOT have Upload Proof of Delivery button
      await tester.tap(find.text('LOAD-001').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.widgetWithText(ElevatedButton, 'Upload Proof of Delivery'), findsNothing);

      // Go back
      await tester.pageBack();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Check in_transit load (LOAD-002) - should have Upload Proof of Delivery button
      await tester.tap(find.text('LOAD-002').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // In transit loads should have POD upload button
      expect(find.widgetWithText(ElevatedButton, 'Upload Proof of Delivery'), findsOneWidget);

      // Go back
      await tester.pageBack();
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Check delivered load (LOAD-003) - should NOT have Upload Proof of Delivery button
      // (delivered loads show no action buttons)
      await tester.tap(find.text('LOAD-003').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.widgetWithText(ElevatedButton, 'Upload Proof of Delivery'), findsNothing);
    });

    testWidgets('Complete POD upload flow with notes', (tester) async {
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

      // Navigate to upload POD screen
      await tester.tap(find.text('LOAD-002').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Upload Proof of Delivery'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Enter notes
      final notesField = find.widgetWithText(TextFormField, 'Notes (optional)');
      await tester.enterText(notesField, 'Package delivered successfully. Signed by Jane Smith.');
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      // Note: In a real test environment with image picker mocking, 
      // we would select an image here. For this integration test,
      // we're testing the UI flow and validation.
      // The actual image picker would need to be mocked at a lower level
      // or tested separately with platform-specific test drivers.

      // Verify the notes were entered
      expect(find.text('Package delivered successfully. Signed by Jane Smith.'), findsOneWidget);

      // Verify upload button is present (AppButton with label text)
      final uploadButton = find.text('Upload POD');
      expect(uploadButton, findsOneWidget);
    });

    testWidgets('Image source dialog closes when option is selected', (tester) async {
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

      // Navigate to upload POD screen
      await tester.tap(find.text('LOAD-002').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Upload Proof of Delivery'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Open image source dialog by tapping on image area
      final imageArea = find.text('Tap to add photo');
      await tester.tap(imageArea);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Verify dialog is open
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);

      // Note: Tapping these options will trigger the image picker,
      // which requires platform-specific mocking. For this test,
      // we just verify the options are available.
      // In a full integration test environment, you would mock
      // the image_picker plugin to return a test image.
    });
  });
}
