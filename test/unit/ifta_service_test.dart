import 'package:flutter_test/flutter_test.dart';
import 'package:gud_app/services/ifta_service.dart';

void main() {
  group('IftaDriverSummary', () {
    test('mpg is 0 when no gallons recorded', () {
      final summary = IftaDriverSummary(
        driverId: 'driver-1',
        totalMiles: 500,
        totalGallons: 0,
      );
      expect(summary.mpg, 0.0);
    });

    test('mpg computed correctly when gallons > 0', () {
      final summary = IftaDriverSummary(
        driverId: 'driver-1',
        totalMiles: 600,
        totalGallons: 60,
      );
      expect(summary.mpg, closeTo(10.0, 0.001));
    });

    test('driverName defaults to null when not provided', () {
      final summary = IftaDriverSummary(
        driverId: 'driver-2',
        totalMiles: 100,
        totalGallons: 10,
      );
      expect(summary.driverName, isNull);
    });

    test('mpg is fractional for non-integer result', () {
      final summary = IftaDriverSummary(
        driverId: 'driver-3',
        totalMiles: 350,
        totalGallons: 30,
      );
      // 350 / 30 ≈ 11.6667
      expect(summary.mpg, closeTo(11.667, 0.001));
    });

    test('mpg returns 0 when totalMiles is 0 and totalGallons is 0', () {
      final summary = IftaDriverSummary(
        driverId: 'driver-4',
        totalMiles: 0,
        totalGallons: 0,
      );
      expect(summary.mpg, 0.0);
    });
  });

  group('IftaService', () {
    test('can be instantiated', () {
      expect(() => IftaService(), returnsNormally);
    });
  });
}
