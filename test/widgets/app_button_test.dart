import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gud_app/widgets/app_button.dart';

void main() {
  group('AppButton Widget', () {
    testWidgets('renders button with label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Test Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      var wasCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Click Me',
              onPressed: () {
                wasCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(wasCalled, true);
    });

    testWidgets('shows loading indicator when isLoading is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Loading Button',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading Button'), findsNothing);
    });

    testWidgets('does not call onPressed when loading',
        (WidgetTester tester) async {
      var wasCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Loading Button',
              onPressed: () {
                wasCalled = true;
              },
              isLoading: true,
            ),
          ),
        ),
      );

      // Try to tap the button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Callback should not have been called
      expect(wasCalled, false);
    });

    testWidgets('applies custom color when provided',
        (WidgetTester tester) async {
      const customColor = Colors.red;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Colored Button',
              onPressed: () {},
              color: customColor,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final buttonColor = button.style?.backgroundColor?.resolve({});

      expect(buttonColor, customColor);
    });

    testWidgets('uses theme color when no custom color provided',
        (WidgetTester tester) async {
      const themeColor = Colors.blue;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(primaryColor: themeColor),
          home: Scaffold(
            body: AppButton(
              label: 'Theme Button',
              onPressed: () {},
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final buttonColor = button.style?.backgroundColor?.resolve({});

      expect(buttonColor, themeColor);
    });

    testWidgets('has correct dimensions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Size Test',
              onPressed: () {},
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(ElevatedButton),
          matching: find.byType(SizedBox),
        ),
      );

      expect(sizedBox.width, double.infinity);
      expect(sizedBox.height, 50);
    });

    testWidgets('has correct text styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Style Test',
              onPressed: () {},
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Style Test'));

      expect(text.style?.fontSize, 16);
      expect(text.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('has rounded corners', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Corner Test',
              onPressed: () {},
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      final shape = button.style?.shape?.resolve({}) as RoundedRectangleBorder?;

      expect(shape?.borderRadius, BorderRadius.circular(8));
    });

    testWidgets('loading indicator has correct styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Loading',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(SizedBox),
        ).first,
      );

      expect(sizedBox.width, 20);
      expect(sizedBox.height, 20);

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );

      expect(indicator.strokeWidth, 2);
      expect(indicator.color, Colors.white);
    });
  });
}
