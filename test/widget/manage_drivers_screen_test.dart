import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gud_app/screens/admin/manage_drivers_screen.dart';
import 'package:gud_app/services/mock_data_service.dart';

/// Tests for ManageDriversScreen - verifying driver management functionality
void main() {
  group('ManageDriversScreen Widget Tests', () {
    setUp(() {
      // Reset mock data before each test
      MockDataService().signOut();
    });

    Widget makeTestableWidget(Widget child) {
      return MaterialApp(
        home: child,
      );
    }

    testWidgets('Initial UI rendering - displays app bar with title',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const ManageDriversScreen()));
      await tester.pump();

      // Verify app bar title
      expect(find.text('Manage Drivers'), findsOneWidget);
    });

    testWidgets('Displays loading indicator while fetching drivers',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const ManageDriversScreen()));

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Displays list of drivers after loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const ManageDriversScreen()));
      await tester.pumpAndSettle();

      // Should show at least one driver (John Driver from mock data)
      expect(find.text('John Driver'), findsOneWidget);
      expect(find.textContaining('Phone:'), findsWidgets);
      expect(find.textContaining('Truck:'), findsWidgets);
    });

    testWidgets('FloatingActionButton is present and enabled',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const ManageDriversScreen()));
      await tester.pumpAndSettle();

      // Verify FAB exists and has add icon
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('Tapping FAB shows add driver dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const ManageDriversScreen()));
      await tester.pumpAndSettle();

      // Tap the add button
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify dialog appears with correct title
      expect(find.text('Add New Driver'), findsOneWidget);
      expect(find.text('Driver Name'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Truck Number'), findsOneWidget);
    });

    testWidgets('Add driver dialog has Cancel and Add buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const ManageDriversScreen()));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('Cancel button closes add driver dialog without adding',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const ManageDriversScreen()));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('Add New Driver'), findsNothing);
    });

    testWidgets('Can add a new driver successfully',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const ManageDriversScreen()));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Enter driver information
      await tester.enterText(
        find.widgetWithText(TextField, 'Driver Name'),
        'Test Driver',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Phone Number'),
        '555-9999',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Truck Number'),
        'TRK-999',
      );

      // Tap Add button
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify success message
      expect(find.text('Driver added successfully'), findsOneWidget);

      // Verify new driver appears in list
      expect(find.text('Test Driver'), findsOneWidget);
    });

    testWidgets('Each driver has a popup menu for edit and delete',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const ManageDriversScreen()));
      await tester.pumpAndSettle();

      // Find popup menu button
      expect(find.byType(PopupMenuButton<String>), findsWidgets);
    });

    testWidgets('Can open edit driver dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const ManageDriversScreen()));
      await tester.pumpAndSettle();

      // Tap popup menu
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();

      // Tap edit option
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Verify edit dialog appears
      expect(find.text('Edit Driver'), findsOneWidget);
    });

    testWidgets('Can edit a driver successfully',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const ManageDriversScreen()));
      await tester.pumpAndSettle();

      // Tap popup menu
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();

      // Tap edit option
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Modify phone number
      await tester.enterText(
        find.widgetWithText(TextField, 'Phone Number'),
        '555-1111',
      );

      // Tap Save button
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify success message
      expect(find.text('Driver updated successfully'), findsOneWidget);
    });

    testWidgets('Validation: Empty fields show error when editing driver',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const ManageDriversScreen()));
      await tester.pumpAndSettle();

      // Open edit dialog
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Clear all fields
      await tester.enterText(
        find.widgetWithText(TextField, 'Driver Name'),
        '',
      );

      // Try to save with empty fields
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify error message appears (dialog should stay open)
      expect(find.text('Please fill in all fields'), findsOneWidget);
      expect(find.text('Edit Driver'), findsOneWidget); // Dialog still open
    });

    testWidgets('Can open delete driver dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const ManageDriversScreen()));
      await tester.pumpAndSettle();

      // Tap popup menu
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();

      // Tap delete option
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify delete confirmation dialog appears
      expect(find.text('Delete Driver'), findsOneWidget);
      expect(find.textContaining('Are you sure'), findsOneWidget);
    });

    testWidgets('Delete dialog has Cancel and Delete buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const ManageDriversScreen()));
      await tester.pumpAndSettle();

      // Open delete dialog
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsNWidgets(2)); // One in menu, one in dialog
    });

    testWidgets('Cancel button closes delete dialog without deleting',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const ManageDriversScreen()));
      await tester.pumpAndSettle();

      final initialDriverCount = tester.widgetList(find.byType(Card)).length;

      // Open delete dialog
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').first);
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('Delete Driver'), findsNothing);

      // Driver count should remain the same
      final finalDriverCount = tester.widgetList(find.byType(Card)).length;
      expect(finalDriverCount, equals(initialDriverCount));
    });

    testWidgets('Validation: Empty fields show error when adding driver',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const ManageDriversScreen()));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Try to add without filling fields
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify error message appears (dialog should stay open)
      expect(find.text('Please fill in all fields'), findsOneWidget);
      expect(find.text('Add New Driver'), findsOneWidget); // Dialog still open
    });

    testWidgets('Driver card displays all information correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const ManageDriversScreen()));
      await tester.pumpAndSettle();

      // Verify driver information is displayed
      expect(find.text('John Driver'), findsOneWidget);
      expect(find.textContaining('Phone: 555-0123'), findsOneWidget);
      expect(find.textContaining('Truck: TRK-001'), findsOneWidget);
      expect(find.textContaining('Status: available'), findsOneWidget);
    });

    testWidgets('Driver card displays earnings and completed loads',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const ManageDriversScreen()));
      await tester.pumpAndSettle();

      // Verify earnings and loads are displayed
      expect(find.textContaining('\$'), findsWidgets);
      expect(find.textContaining('loads'), findsWidgets);
    });

    testWidgets('Screen shows empty state when no drivers exist',
        (WidgetTester tester) async {
      // First, delete all drivers
      final mockService = MockDataService();
      final drivers = await mockService.getDrivers();
      for (final driver in drivers) {
        await mockService.deleteDriver(driver.id);
      }

      await tester.pumpWidget(makeTestableWidget(const ManageDriversScreen()));
      await tester.pumpAndSettle();

      // Verify empty state message
      expect(find.text('No drivers found. Add one to get started!'), findsOneWidget);
    });

    testWidgets('ManageDriversScreen is a StatefulWidget',
        (WidgetTester tester) async {
      await tester.pumpWidget(makeTestableWidget(const ManageDriversScreen()));
      await tester.pump();

      // Verify it's a StatefulWidget
      expect(find.byType(ManageDriversScreen), findsOneWidget);
      final screen = tester.widget<ManageDriversScreen>(
        find.byType(ManageDriversScreen),
      );
      expect(screen, isA<StatefulWidget>());
    });
  });
}
