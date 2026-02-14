import 'package:flutter_test/flutter_test.dart';
import 'package:gud_app/models/payment.dart';

void main() {
  group('Payment', () {
    final testDate = DateTime(2024, 1, 1);
    final paymentDate = DateTime(2024, 1, 15);
    
    test('constructor creates valid Payment', () {
      final payment = Payment(
        id: 'payment-123',
        driverId: 'driver-456',
        loadId: 'load-789',
        amount: 850.0,
        loadRate: 1000.0,
        status: 'pending',
        paymentDate: paymentDate,
        createdAt: testDate,
        createdBy: 'admin-123',
        notes: 'Test payment',
      );

      expect(payment.id, 'payment-123');
      expect(payment.driverId, 'driver-456');
      expect(payment.loadId, 'load-789');
      expect(payment.amount, 850.0);
      expect(payment.loadRate, 1000.0);
      expect(payment.status, 'pending');
      expect(payment.paymentDate, paymentDate);
      expect(payment.createdAt, testDate);
      expect(payment.createdBy, 'admin-123');
      expect(payment.notes, 'Test payment');
    });

    test('constructor uses default createdAt when not provided', () {
      final beforeCreate = DateTime.now();
      
      final payment = Payment(
        id: 'payment-123',
        driverId: 'driver-456',
        loadId: 'load-789',
        amount: 850.0,
        loadRate: 1000.0,
        status: 'pending',
        createdBy: 'admin-123',
      );

      final afterCreate = DateTime.now();

      expect(payment.createdAt, isNotNull);
      expect(payment.createdAt.isAfter(beforeCreate) || 
             payment.createdAt.isAtSameMomentAs(beforeCreate), true);
      expect(payment.createdAt.isBefore(afterCreate) || 
             payment.createdAt.isAtSameMomentAs(afterCreate), true);
    });

    test('commissionRate property returns 0.85', () {
      final payment = Payment(
        id: 'payment-123',
        driverId: 'driver-456',
        loadId: 'load-789',
        amount: 850.0,
        loadRate: 1000.0,
        status: 'pending',
        createdBy: 'admin-123',
      );

      expect(payment.commissionRate, 0.85);
    });

    test('companyShare property calculates correctly', () {
      final payment = Payment(
        id: 'payment-123',
        driverId: 'driver-456',
        loadId: 'load-789',
        amount: 850.0,
        loadRate: 1000.0,
        status: 'pending',
        createdBy: 'admin-123',
      );

      expect(payment.companyShare, 150.0);
    });

    test('toMap serializes Payment correctly', () {
      final payment = Payment(
        id: 'payment-123',
        driverId: 'driver-456',
        loadId: 'load-789',
        amount: 850.0,
        loadRate: 1000.0,
        status: 'paid',
        paymentDate: paymentDate,
        createdAt: testDate,
        createdBy: 'admin-123',
        notes: 'Test payment',
      );

      final map = payment.toMap();

      expect(map['driverId'], 'driver-456');
      expect(map['loadId'], 'load-789');
      expect(map['amount'], 850.0);
      expect(map['loadRate'], 1000.0);
      expect(map['status'], 'paid');
      expect(map['paymentDate'], paymentDate.toIso8601String());
      expect(map['createdAt'], testDate.toIso8601String());
      expect(map['createdBy'], 'admin-123');
      expect(map['notes'], 'Test payment');
      expect(map.containsKey('id'), false);
    });

    test('toMap omits null optional fields', () {
      final payment = Payment(
        id: 'payment-123',
        driverId: 'driver-456',
        loadId: 'load-789',
        amount: 850.0,
        loadRate: 1000.0,
        status: 'pending',
        createdAt: testDate,
        createdBy: 'admin-123',
      );

      final map = payment.toMap();

      expect(map.containsKey('paymentDate'), false);
      expect(map.containsKey('notes'), false);
    });

    test('fromMap deserializes Payment correctly', () {
      final map = {
        'driverId': 'driver-456',
        'loadId': 'load-789',
        'amount': 850.0,
        'loadRate': 1000.0,
        'status': 'paid',
        'paymentDate': paymentDate.toIso8601String(),
        'createdAt': testDate.toIso8601String(),
        'createdBy': 'admin-123',
        'notes': 'Test payment',
      };

      final payment = Payment.fromMap('payment-123', map);

      expect(payment.id, 'payment-123');
      expect(payment.driverId, 'driver-456');
      expect(payment.loadId, 'load-789');
      expect(payment.amount, 850.0);
      expect(payment.loadRate, 1000.0);
      expect(payment.status, 'paid');
      expect(payment.paymentDate, paymentDate);
      expect(payment.createdAt, testDate);
      expect(payment.createdBy, 'admin-123');
      expect(payment.notes, 'Test payment');
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'driverId': 'driver-456',
        'loadId': 'load-789',
        'amount': 850.0,
        'loadRate': 1000.0,
        'status': 'pending',
        'createdAt': testDate.toIso8601String(),
        'createdBy': 'admin-123',
      };

      final payment = Payment.fromMap('payment-123', map);

      expect(payment.paymentDate, null);
      expect(payment.notes, null);
    });

    test('fromMap uses default values for missing fields', () {
      final map = <String, dynamic>{
        'createdAt': testDate.toIso8601String(),
      };

      final payment = Payment.fromMap('payment-123', map);

      expect(payment.driverId, '');
      expect(payment.loadId, '');
      expect(payment.amount, 0.0);
      expect(payment.loadRate, 0.0);
      expect(payment.status, 'pending');
      expect(payment.createdBy, '');
    });

    test('serialization roundtrip maintains data integrity', () {
      final original = Payment(
        id: 'payment-123',
        driverId: 'driver-456',
        loadId: 'load-789',
        amount: 850.0,
        loadRate: 1000.0,
        status: 'paid',
        paymentDate: paymentDate,
        createdAt: testDate,
        createdBy: 'admin-123',
        notes: 'Completed payment',
      );

      final map = original.toMap();
      final deserialized = Payment.fromMap(original.id, map);

      expect(deserialized.id, original.id);
      expect(deserialized.driverId, original.driverId);
      expect(deserialized.loadId, original.loadId);
      expect(deserialized.amount, original.amount);
      expect(deserialized.loadRate, original.loadRate);
      expect(deserialized.status, original.status);
      expect(deserialized.paymentDate, original.paymentDate);
      expect(deserialized.createdAt, original.createdAt);
      expect(deserialized.createdBy, original.createdBy);
      expect(deserialized.notes, original.notes);
    });

    test('handles different payment statuses', () {
      final statuses = ['pending', 'paid', 'cancelled'];
      
      for (final status in statuses) {
        final payment = Payment(
          id: 'payment-test',
          driverId: 'driver-456',
          loadId: 'load-789',
          amount: 850.0,
          loadRate: 1000.0,
          status: status,
          createdBy: 'admin-123',
        );

        expect(payment.status, status);
        
        final map = payment.toMap();
        expect(map['status'], status);
        
        final deserialized = Payment.fromMap(payment.id, map);
        expect(deserialized.status, status);
      }
    });

    test('handles numeric type conversions correctly', () {
      final map = {
        'driverId': 'driver-456',
        'loadId': 'load-789',
        'amount': 850, // int instead of double
        'loadRate': 1000, // int instead of double
        'status': 'pending',
        'createdAt': testDate.toIso8601String(),
        'createdBy': 'admin-123',
      };

      final payment = Payment.fromMap('payment-test', map);

      expect(payment.amount, 850.0);
      expect(payment.amount, isA<double>());
      expect(payment.loadRate, 1000.0);
      expect(payment.loadRate, isA<double>());
    });

    test('calculates correct driver payment for 85% commission', () {
      final payment = Payment(
        id: 'payment-123',
        driverId: 'driver-456',
        loadId: 'load-789',
        amount: 850.0, // 85% of 1000
        loadRate: 1000.0,
        status: 'pending',
        createdBy: 'admin-123',
      );

      expect(payment.amount, 850.0);
      expect(payment.loadRate, 1000.0);
      expect(payment.commissionRate, 0.85);
      expect(payment.companyShare, 150.0);
      expect(payment.amount + payment.companyShare, payment.loadRate);
    });

    test('handles zero amounts', () {
      final payment = Payment(
        id: 'payment-zero',
        driverId: 'driver-456',
        loadId: 'load-789',
        amount: 0.0,
        loadRate: 0.0,
        status: 'pending',
        createdBy: 'admin-123',
      );

      expect(payment.amount, 0.0);
      expect(payment.loadRate, 0.0);
      expect(payment.companyShare, 0.0);
    });

    test('companyShare calculation with different load rates', () {
      final testCases = [
        {'loadRate': 1000.0, 'amount': 850.0, 'expectedShare': 150.0},
        {'loadRate': 500.0, 'amount': 425.0, 'expectedShare': 75.0},
        {'loadRate': 2000.0, 'amount': 1700.0, 'expectedShare': 300.0},
        {'loadRate': 100.0, 'amount': 85.0, 'expectedShare': 15.0},
      ];

      for (final testCase in testCases) {
        final payment = Payment(
          id: 'payment-test',
          driverId: 'driver-456',
          loadId: 'load-789',
          amount: testCase['amount']!,
          loadRate: testCase['loadRate']!,
          status: 'pending',
          createdBy: 'admin-123',
        );

        expect(payment.companyShare, testCase['expectedShare']);
      }
    });
  });
}
