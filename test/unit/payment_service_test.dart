import 'package:flutter_test/flutter_test.dart';
import 'package:gud_app/services/payment_service.dart';

void main() {
  group('PaymentService', () {
    group('calculateDriverPayment', () {
      test('calculates correct payment for standard load rate', () {
        final service = PaymentService();
        
        final payment = service.calculateDriverPayment(1000.0);
        
        expect(payment, 850.0);
      });

      test('calculates correct payment for various load rates', () {
        final service = PaymentService();
        
        final testCases = [
          {'loadRate': 1000.0, 'expectedPayment': 850.0},
          {'loadRate': 500.0, 'expectedPayment': 425.0},
          {'loadRate': 2000.0, 'expectedPayment': 1700.0},
          {'loadRate': 100.0, 'expectedPayment': 85.0},
          {'loadRate': 0.0, 'expectedPayment': 0.0},
        ];

        for (final testCase in testCases) {
          final payment = service.calculateDriverPayment(testCase['loadRate']!);
          expect(payment, testCase['expectedPayment']);
        }
      });

      test('handles decimal load rates correctly', () {
        final service = PaymentService();
        
        final payment = service.calculateDriverPayment(1234.56);
        
        // 1234.56 * 0.85 = 1049.376
        expect(payment, closeTo(1049.376, 0.001));
      });

      test('uses correct commission rate constant', () {
        expect(PaymentService.DRIVER_COMMISSION_RATE, 0.85);
      });

      test('driver payment plus company share equals load rate', () {
        final service = PaymentService();
        final loadRate = 1000.0;
        
        final driverPayment = service.calculateDriverPayment(loadRate);
        final companyShare = loadRate - driverPayment;
        
        expect(driverPayment + companyShare, loadRate);
        expect(companyShare, 150.0);
      });

      test('handles large load rates', () {
        final service = PaymentService();
        
        final payment = service.calculateDriverPayment(100000.0);
        
        expect(payment, 85000.0);
      });

      test('handles small load rates', () {
        final service = PaymentService();
        
        final payment = service.calculateDriverPayment(0.50);
        
        expect(payment, closeTo(0.425, 0.001));
      });
    });

    group('Constants', () {
      test('DRIVER_COMMISSION_RATE is 0.85', () {
        expect(PaymentService.DRIVER_COMMISSION_RATE, 0.85);
      });

      test('commission represents 85 percent', () {
        final percentageValue = PaymentService.DRIVER_COMMISSION_RATE * 100;
        expect(percentageValue, 85.0);
      });

      test('company keeps 15 percent', () {
        final companyPercentage = (1 - PaymentService.DRIVER_COMMISSION_RATE) * 100;
        expect(companyPercentage, 15.0);
      });
    });
  });
}
