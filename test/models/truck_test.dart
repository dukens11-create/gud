import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gud_app/models/truck.dart';

void main() {
  // Use fixed timestamp for deterministic tests
  final testDate = DateTime(2024, 1, 15, 10, 30, 0);
  
  group('Truck Model', () {
    test('normalizeStatus returns "available" for null status', () {
      expect(Truck.normalizeStatus(null), 'available');
    });

    test('normalizeStatus returns "available" for empty status', () {
      expect(Truck.normalizeStatus(''), 'available');
    });

    test('normalizeStatus returns "available" for invalid status', () {
      expect(Truck.normalizeStatus('invalid_status'), 'available');
      expect(Truck.normalizeStatus('out_of_service'), 'available');
      expect(Truck.normalizeStatus('broken'), 'available');
    });

    test('normalizeStatus returns valid status unchanged', () {
      expect(Truck.normalizeStatus('available'), 'available');
      expect(Truck.normalizeStatus('in_use'), 'in_use');
      expect(Truck.normalizeStatus('maintenance'), 'maintenance');
      expect(Truck.normalizeStatus('inactive'), 'inactive');
    });

    test('fromMap normalizes invalid status to "available"', () {
      final data = {
        'truckNumber': '004',
        'vin': 'VIN123',
        'make': 'Kenworth',
        'model': 'T680',
        'year': 2020,
        'plateNumber': 'ABC123',
        'status': null, // null status should become 'available'
        'createdAt': Timestamp.fromDate(testDate),
        'updatedAt': Timestamp.fromDate(testDate),
      };

      final truck = Truck.fromMap('truck-123', data);

      expect(truck.status, 'available');
      expect(truck.truckNumber, '004');
    });

    test('fromMap normalizes empty status to "available"', () {
      final data = {
        'truckNumber': '005',
        'vin': 'VIN456',
        'make': 'Peterbilt',
        'model': '579',
        'year': 2021,
        'plateNumber': 'XYZ789',
        'status': '', // empty status should become 'available'
        'createdAt': Timestamp.fromDate(testDate),
        'updatedAt': Timestamp.fromDate(testDate),
      };

      final truck = Truck.fromMap('truck-456', data);

      expect(truck.status, 'available');
    });

    test('fromMap preserves valid status values', () {
      final statuses = ['available', 'in_use', 'maintenance', 'inactive'];

      for (final status in statuses) {
        final data = {
          'truckNumber': '006',
          'vin': 'VIN789',
          'make': 'Freightliner',
          'model': 'Cascadia',
          'year': 2022,
          'plateNumber': 'LMN456',
          'status': status,
          'createdAt': Timestamp.fromDate(testDate),
          'updatedAt': Timestamp.fromDate(testDate),
        };

        final truck = Truck.fromMap('truck-789', data);
        expect(truck.status, status);
      }
    });

    test('validStatuses contains all expected values', () {
      expect(Truck.validStatuses, contains('available'));
      expect(Truck.validStatuses, contains('in_use'));
      expect(Truck.validStatuses, contains('maintenance'));
      expect(Truck.validStatuses, contains('inactive'));
      expect(Truck.validStatuses.length, 4);
    });

    test('toMap serializes truck correctly', () {
      final truck = Truck(
        id: 'truck-123',
        truckNumber: '007',
        vin: 'VIN999',
        make: 'Volvo',
        model: 'VNL',
        year: 2023,
        plateNumber: 'QWE123',
        status: 'available',
        assignedDriverId: 'driver-456',
        assignedDriverName: 'John Driver',
        notes: 'Test notes',
        createdAt: testDate,
        updatedAt: testDate,
      );

      final map = truck.toMap();

      expect(map['truckNumber'], '007');
      expect(map['vin'], 'VIN999');
      expect(map['make'], 'Volvo');
      expect(map['model'], 'VNL');
      expect(map['year'], 2023);
      expect(map['plateNumber'], 'QWE123');
      expect(map['status'], 'available');
      expect(map['assignedDriverId'], 'driver-456');
      expect(map['assignedDriverName'], 'John Driver');
      expect(map['notes'], 'Test notes');
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
    });

    test('copyWith creates new instance with updated fields', () {
      final original = Truck(
        id: 'truck-123',
        truckNumber: '008',
        vin: 'VIN111',
        make: 'Mack',
        model: 'Anthem',
        year: 2020,
        plateNumber: 'ASD456',
        status: 'available',
        createdAt: testDate,
        updatedAt: testDate,
      );

      final updated = original.copyWith(status: 'in_use');

      expect(updated.status, 'in_use');
      expect(updated.truckNumber, '008'); // Other fields unchanged
      expect(original.status, 'available'); // Original unchanged
    });

    test('isAvailable returns true for available status', () {
      final truck = Truck(
        id: 'truck-123',
        truckNumber: '009',
        vin: 'VIN222',
        make: 'International',
        model: 'LT',
        year: 2021,
        plateNumber: 'ZXC789',
        status: 'available',
        createdAt: testDate,
        updatedAt: testDate,
      );

      expect(truck.isAvailable, true);
    });

    test('isAvailable returns false for non-available status', () {
      final statuses = ['in_use', 'maintenance', 'inactive'];

      for (final status in statuses) {
        final truck = Truck(
          id: 'truck-123',
          truckNumber: '010',
          vin: 'VIN333',
          make: 'Western Star',
          model: '5700XE',
          year: 2022,
          plateNumber: 'RTY123',
          status: status,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(truck.isAvailable, false);
      }
    });

    test('statusDisplayName returns correct display names', () {
      final testCases = {
        'available': 'Available',
        'in_use': 'In Use',
        'maintenance': 'Maintenance',
        'inactive': 'Inactive',
      };

      for (final entry in testCases.entries) {
        final truck = Truck(
          id: 'truck-123',
          truckNumber: '011',
          vin: 'VIN444',
          make: 'Hino',
          model: 'XL',
          year: 2023,
          plateNumber: 'FGH456',
          status: entry.key,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(truck.statusDisplayName, entry.value);
      }
    });
  });
}
