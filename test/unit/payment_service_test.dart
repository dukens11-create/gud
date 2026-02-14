import 'package:flutter_test/flutter_test.dart';
import 'package:gud_app/services/payment_service.dart';

void main() {
  group('PaymentService', () {
    group('calculateDriverPaymentSync (deprecated)', () {
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
          // ignore: deprecated_member_use
          final payment = service.calculateDriverPaymentSync(testCase['loadRate']!);
          expect(payment, testCase['expectedPayment']);
        }
      });

      test('handles decimal load rates correctly', () {
        final service = PaymentService();
        
        // ignore: deprecated_member_use
        final payment = service.calculateDriverPaymentSync(1234.56);
        
        // 1234.56 * 0.85 = 1049.376
        expect(payment, closeTo(1049.376, 0.001));
      });

      test('uses correct commission rate constant', () {
        // ignore: deprecated_member_use
        expect(PaymentService.DRIVER_COMMISSION_RATE, 0.85);
        expect(PaymentService.DEFAULT_COMMISSION_RATE, 0.85);
      });

      test('driver payment plus company share equals load rate', () {
        final service = PaymentService();
        final loadRate = 1000.0;
        
        // ignore: deprecated_member_use
        final driverPayment = service.calculateDriverPaymentSync(loadRate);
        final companyShare = loadRate - driverPayment;
        
        expect(driverPayment + companyShare, loadRate);
        expect(companyShare, 150.0);
      });

      test('handles large load rates', () {
        final service = PaymentService();
        
        // ignore: deprecated_member_use
        final payment = service.calculateDriverPaymentSync(100000.0);
        
        expect(payment, 85000.0);
      });

      test('handles small load rates', () {
        final service = PaymentService();
        
        // ignore: deprecated_member_use
        final payment = service.calculateDriverPaymentSync(0.50);
        
        expect(payment, closeTo(0.425, 0.001));
      });
    });

    group('Constants', () {
      test('DEFAULT_COMMISSION_RATE is 0.85 (85%)', () {
        expect(PaymentService.DEFAULT_COMMISSION_RATE, 0.85);
        
        // Verify commission represents 85% and company keeps 15%
        final percentageValue = PaymentService.DEFAULT_COMMISSION_RATE * 100;
        final companyPercentage = (1 - PaymentService.DEFAULT_COMMISSION_RATE) * 100;
        
        expect(percentageValue, 85.0);
        expect(companyPercentage, 15.0);
      });
      
      test('Legacy DRIVER_COMMISSION_RATE is maintained for backward compatibility', () {
        // ignore: deprecated_member_use
        expect(PaymentService.DRIVER_COMMISSION_RATE, 0.85);
        // ignore: deprecated_member_use
        expect(PaymentService.DRIVER_COMMISSION_RATE, PaymentService.DEFAULT_COMMISSION_RATE);
      });
    });
  });
}
