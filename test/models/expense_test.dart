import 'package:flutter_test/flutter_test.dart';
import 'package:gud_app/models/expense.dart';

void main() {
  group('Expense', () {
    final testDate = DateTime(2024, 1, 1);
    final expenseDate = DateTime(2024, 1, 15);
    
    test('constructor creates valid Expense', () {
      final expense = Expense(
        id: 'expense-123',
        amount: 150.50,
        category: 'fuel',
        description: 'Fuel fill-up at Station XYZ',
        date: expenseDate,
        driverId: 'driver-456',
        loadId: 'load-789',
        receiptUrl: 'https://example.com/receipt.jpg',
        createdBy: 'driver-456',
        createdAt: testDate,
      );

      expect(expense.id, 'expense-123');
      expect(expense.amount, 150.50);
      expect(expense.category, 'fuel');
      expect(expense.description, 'Fuel fill-up at Station XYZ');
      expect(expense.date, expenseDate);
      expect(expense.driverId, 'driver-456');
      expect(expense.loadId, 'load-789');
      expect(expense.receiptUrl, 'https://example.com/receipt.jpg');
      expect(expense.createdBy, 'driver-456');
      expect(expense.createdAt, testDate);
    });

    test('constructor uses default createdAt when not provided', () {
      final beforeCreate = DateTime.now();
      
      final expense = Expense(
        id: 'expense-123',
        amount: 100.0,
        category: 'tolls',
        description: 'Highway toll',
        date: expenseDate,
        createdBy: 'driver-456',
      );

      final afterCreate = DateTime.now();

      expect(expense.createdAt, isNotNull);
      expect(expense.createdAt.isAfter(beforeCreate) || 
             expense.createdAt.isAtSameMomentAs(beforeCreate), true);
      expect(expense.createdAt.isBefore(afterCreate) || 
             expense.createdAt.isAtSameMomentAs(afterCreate), true);
    });

    test('toMap serializes Expense correctly', () {
      final expense = Expense(
        id: 'expense-123',
        amount: 150.50,
        category: 'fuel',
        description: 'Fuel fill-up',
        date: expenseDate,
        driverId: 'driver-456',
        loadId: 'load-789',
        receiptUrl: 'https://example.com/receipt.jpg',
        createdBy: 'driver-456',
        createdAt: testDate,
      );

      final map = expense.toMap();

      expect(map['amount'], 150.50);
      expect(map['category'], 'fuel');
      expect(map['description'], 'Fuel fill-up');
      expect(map['date'], expenseDate.toIso8601String());
      expect(map['driverId'], 'driver-456');
      expect(map['loadId'], 'load-789');
      expect(map['receiptUrl'], 'https://example.com/receipt.jpg');
      expect(map['createdBy'], 'driver-456');
      expect(map['createdAt'], testDate.toIso8601String());
      expect(map.containsKey('id'), false);
    });

    test('toMap omits null optional fields', () {
      final expense = Expense(
        id: 'expense-123',
        amount: 100.0,
        category: 'tolls',
        description: 'Highway toll',
        date: expenseDate,
        createdBy: 'driver-456',
        createdAt: testDate,
      );

      final map = expense.toMap();

      expect(map.containsKey('driverId'), false);
      expect(map.containsKey('loadId'), false);
      expect(map.containsKey('receiptUrl'), false);
    });

    test('fromMap deserializes Expense correctly', () {
      final map = {
        'amount': 150.50,
        'category': 'maintenance',
        'description': 'Oil change',
        'date': expenseDate.toIso8601String(),
        'driverId': 'driver-456',
        'loadId': 'load-789',
        'receiptUrl': 'https://example.com/receipt.jpg',
        'createdBy': 'driver-456',
        'createdAt': testDate.toIso8601String(),
      };

      final expense = Expense.fromMap('expense-123', map);

      expect(expense.id, 'expense-123');
      expect(expense.amount, 150.50);
      expect(expense.category, 'maintenance');
      expect(expense.description, 'Oil change');
      expect(expense.date, expenseDate);
      expect(expense.driverId, 'driver-456');
      expect(expense.loadId, 'load-789');
      expect(expense.receiptUrl, 'https://example.com/receipt.jpg');
      expect(expense.createdBy, 'driver-456');
      expect(expense.createdAt, testDate);
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'amount': 100.0,
        'category': 'tolls',
        'description': 'Toll',
        'date': expenseDate.toIso8601String(),
        'createdBy': 'driver-456',
        'createdAt': testDate.toIso8601String(),
      };

      final expense = Expense.fromMap('expense-123', map);

      expect(expense.driverId, null);
      expect(expense.loadId, null);
      expect(expense.receiptUrl, null);
    });

    test('fromMap uses default values for missing fields', () {
      final map = <String, dynamic>{
        'date': expenseDate.toIso8601String(),
      };

      final expense = Expense.fromMap('expense-123', map);

      expect(expense.amount, 0.0);
      expect(expense.category, 'other');
      expect(expense.description, '');
      expect(expense.createdBy, '');
    });

    test('serialization roundtrip maintains data integrity', () {
      final original = Expense(
        id: 'expense-123',
        amount: 200.75,
        category: 'insurance',
        description: 'Monthly insurance payment',
        date: expenseDate,
        driverId: 'driver-456',
        loadId: 'load-789',
        receiptUrl: 'https://example.com/receipt.jpg',
        createdBy: 'admin-123',
        createdAt: testDate,
      );

      final map = original.toMap();
      final deserialized = Expense.fromMap(original.id, map);

      expect(deserialized.id, original.id);
      expect(deserialized.amount, original.amount);
      expect(deserialized.category, original.category);
      expect(deserialized.description, original.description);
      expect(deserialized.date, original.date);
      expect(deserialized.driverId, original.driverId);
      expect(deserialized.loadId, original.loadId);
      expect(deserialized.receiptUrl, original.receiptUrl);
      expect(deserialized.createdBy, original.createdBy);
      expect(deserialized.createdAt, original.createdAt);
    });

    test('handles different expense categories', () {
      final categories = ['fuel', 'maintenance', 'tolls', 'insurance', 'other'];
      
      for (final category in categories) {
        final expense = Expense(
          id: 'expense-test',
          amount: 100.0,
          category: category,
          description: 'Test expense',
          date: expenseDate,
          createdBy: 'test-user',
        );

        expect(expense.category, category);
        
        final map = expense.toMap();
        expect(map['category'], category);
        
        final deserialized = Expense.fromMap(expense.id, map);
        expect(deserialized.category, category);
      }
    });

    test('handles numeric type conversions correctly', () {
      final map = {
        'amount': 150, // int instead of double
        'category': 'fuel',
        'description': 'Test',
        'date': expenseDate.toIso8601String(),
        'createdBy': 'driver-456',
        'createdAt': testDate.toIso8601String(),
      };

      final expense = Expense.fromMap('expense-test', map);

      expect(expense.amount, 150.0);
      expect(expense.amount, isA<double>());
    });

    test('handles zero and negative amounts', () {
      // Zero amount
      final zeroExpense = Expense(
        id: 'expense-zero',
        amount: 0.0,
        category: 'other',
        description: 'Zero expense',
        date: expenseDate,
        createdBy: 'test-user',
      );

      expect(zeroExpense.amount, 0.0);
      
      // Negative amount (refund)
      final refundExpense = Expense(
        id: 'expense-refund',
        amount: -50.0,
        category: 'other',
        description: 'Refund',
        date: expenseDate,
        createdBy: 'test-user',
      );

      expect(refundExpense.amount, -50.0);
    });
  });
}
