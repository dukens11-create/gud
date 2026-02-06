import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gud_app/widgets/loading.dart';

void main() {
  group('LoadingScreen Widget', () {
    testWidgets('renders CircularProgressIndicator',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingScreen(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('has Scaffold structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingScreen(),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('centers the progress indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingScreen(),
        ),
      );

      final center = find.byType(Center);
      expect(center, findsOneWidget);

      final progressIndicator = find.byType(CircularProgressIndicator);
      expect(
        find.descendant(of: center, matching: progressIndicator),
        findsOneWidget,
      );
    });

    testWidgets('renders correctly in different screen sizes',
        (WidgetTester tester) async {
      // Test with default size
      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingScreen(),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Test with larger screen
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: LoadingScreen(),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('can be used as const widget', (WidgetTester tester) async {
      const loadingScreen1 = LoadingScreen();
      const loadingScreen2 = LoadingScreen();

      expect(identical(loadingScreen1, loadingScreen2), true);
    });
  });
}
