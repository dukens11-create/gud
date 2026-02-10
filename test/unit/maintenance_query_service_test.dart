import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gud_app/screens/maintenance_tracking.dart';

void main() {
  // Note: These tests verify the service interface, parameter handling,
  // and data transformation logic. For full integration testing with Firestore,
  // consider using Firebase emulators or fake_cloud_firestore package.

  group('MaintenanceQueryService', () {
    late MaintenanceQueryService service;

    setUp(() {
      service = MaintenanceQueryService();
    });

    group('Method Signatures', () {
      test('getMaintenanceHistory accepts optional parameters', () {
        // Verify that the method can be called with no parameters
        expect(
          () => service.getMaintenanceHistory(),
          returnsNormally,
        );

        // Verify that the method can be called with truckNumber
        expect(
          () => service.getMaintenanceHistory(truckNumber: 'TRK-001'),
          returnsNormally,
        );

        // Verify that the method can be called with limit
        expect(
          () => service.getMaintenanceHistory(limit: 10),
          returnsNormally,
        );

        // Verify that the method can be called with both parameters
        expect(
          () => service.getMaintenanceHistory(
            truckNumber: 'TRK-001',
            limit: 10,
          ),
          returnsNormally,
        );
      });

      test('getUpcomingMaintenance accepts optional parameters', () {
        expect(
          () => service.getUpcomingMaintenance(),
          returnsNormally,
        );

        expect(
          () => service.getUpcomingMaintenance(truckNumber: 'TRK-001'),
          returnsNormally,
        );

        expect(
          () => service.getUpcomingMaintenance(daysAhead: 30),
          returnsNormally,
        );

        expect(
          () => service.getUpcomingMaintenance(
            truckNumber: 'TRK-001',
            limit: 5,
            daysAhead: 30,
          ),
          returnsNormally,
        );
      });

      test('getAllMaintenance accepts optional parameters', () {
        expect(
          () => service.getAllMaintenance(),
          returnsNormally,
        );

        expect(
          () => service.getAllMaintenance(truckNumber: 'TRK-001'),
          returnsNormally,
        );

        expect(
          () => service.getAllMaintenance(descending: false),
          returnsNormally,
        );

        expect(
          () => service.getAllMaintenance(
            truckNumber: 'TRK-001',
            limit: 20,
            descending: true,
          ),
          returnsNormally,
        );
      });

      test('stream methods return correct types', () {
        // Verify stream types
        expect(
          service.streamMaintenanceHistory(),
          isA<Stream<List<Map<String, dynamic>>>>(),
        );

        expect(
          service.streamUpcomingMaintenance(),
          isA<Stream<List<Map<String, dynamic>>>>(),
        );

        expect(
          service.streamAllMaintenance(),
          isA<Stream<List<Map<String, dynamic>>>>(),
        );
      });

      test('getMaintenanceStats requires truckNumber', () {
        // This should compile and return a Future
        expect(
          service.getMaintenanceStats('TRK-001'),
          isA<Future<Map<String, dynamic>>>(),
        );
      });

      test('getTruckNumbersWithMaintenance returns list of strings', () {
        expect(
          service.getTruckNumbersWithMaintenance(),
          isA<Future<List<String>>>(),
        );
      });
    });

    group('MaintenanceRecord Model', () {
      test('fromMap creates valid MaintenanceRecord', () {
        final data = {
          'driverId': 'driver-123',
          'truckNumber': 'TRK-001',
          'maintenanceType': 'Oil Change',
          'serviceDate': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'cost': 150.50,
          'nextServiceDue': Timestamp.fromDate(DateTime(2024, 4, 15)),
          'serviceProvider': 'ABC Service Center',
          'notes': 'Replaced oil filter',
          'createdAt': Timestamp.now(),
        };

        final record = MaintenanceRecord.fromMap('doc-123', data);

        expect(record.id, 'doc-123');
        expect(record.driverId, 'driver-123');
        expect(record.truckNumber, 'TRK-001');
        expect(record.maintenanceType, 'Oil Change');
        expect(record.cost, 150.50);
        expect(record.serviceProvider, 'ABC Service Center');
        expect(record.notes, 'Replaced oil filter');
        expect(record.nextServiceDue, isNotNull);
      });

      test('fromMap handles missing optional fields', () {
        final data = {
          'driverId': 'driver-123',
          'truckNumber': 'TRK-001',
          'maintenanceType': 'Tire Rotation',
          'serviceDate': Timestamp.fromDate(DateTime(2024, 1, 15)),
          'cost': 50.0,
        };

        final record = MaintenanceRecord.fromMap('doc-456', data);

        expect(record.id, 'doc-456');
        expect(record.nextServiceDue, isNull);
        expect(record.serviceProvider, isNull);
        expect(record.notes, isNull);
        expect(record.createdAt, isNull);
      });

      test('toMap converts MaintenanceRecord to map', () {
        final record = MaintenanceRecord(
          id: 'doc-789',
          driverId: 'driver-456',
          truckNumber: 'TRK-002',
          maintenanceType: 'Brake Inspection',
          serviceDate: DateTime(2024, 2, 1),
          cost: 200.0,
          nextServiceDue: DateTime(2024, 8, 1),
          serviceProvider: 'XYZ Auto Shop',
          notes: 'All brakes checked',
          createdAt: DateTime.now(),
        );

        final map = record.toMap();

        expect(map['driverId'], 'driver-456');
        expect(map['truckNumber'], 'TRK-002');
        expect(map['maintenanceType'], 'Brake Inspection');
        expect(map['cost'], 200.0);
        expect(map['serviceDate'], isA<Timestamp>());
        expect(map['nextServiceDue'], isA<Timestamp>());
        expect(map['serviceProvider'], 'XYZ Auto Shop');
        expect(map['notes'], 'All brakes checked');
        expect(map['createdAt'], isA<Timestamp>());
      });

      test('isHistory returns true for past dates', () {
        final record = MaintenanceRecord(
          id: 'doc-123',
          driverId: 'driver-123',
          truckNumber: 'TRK-001',
          maintenanceType: 'Oil Change',
          serviceDate: DateTime.now().subtract(const Duration(days: 10)),
          cost: 100.0,
        );

        expect(record.isHistory, isTrue);
        expect(record.isUpcoming, isFalse);
      });

      test('isUpcoming returns true for future dates', () {
        final record = MaintenanceRecord(
          id: 'doc-123',
          driverId: 'driver-123',
          truckNumber: 'TRK-001',
          maintenanceType: 'Tire Rotation',
          serviceDate: DateTime.now().add(const Duration(days: 10)),
          cost: 50.0,
        );

        expect(record.isUpcoming, isTrue);
        expect(record.isHistory, isFalse);
      });

      test('daysUntilService calculates correctly', () {
        // Future date
        final futureRecord = MaintenanceRecord(
          id: 'doc-123',
          driverId: 'driver-123',
          truckNumber: 'TRK-001',
          maintenanceType: 'Inspection',
          serviceDate: DateTime.now().add(const Duration(days: 5)),
          cost: 75.0,
        );

        expect(futureRecord.daysUntilService, closeTo(5, 1));

        // Past date (will be negative)
        final pastRecord = MaintenanceRecord(
          id: 'doc-456',
          driverId: 'driver-123',
          truckNumber: 'TRK-001',
          maintenanceType: 'Oil Change',
          serviceDate: DateTime.now().subtract(const Duration(days: 3)),
          cost: 100.0,
        );

        expect(pastRecord.daysUntilService, lessThan(0));
      });

      test('isNextServiceDue returns true when due within 30 days', () {
        // Due in 15 days
        final dueSoonRecord = MaintenanceRecord(
          id: 'doc-123',
          driverId: 'driver-123',
          truckNumber: 'TRK-001',
          maintenanceType: 'Oil Change',
          serviceDate: DateTime.now().subtract(const Duration(days: 60)),
          cost: 100.0,
          nextServiceDue: DateTime.now().add(const Duration(days: 15)),
        );

        expect(dueSoonRecord.isNextServiceDue, isTrue);

        // Due in 60 days (not due soon)
        final notDueRecord = MaintenanceRecord(
          id: 'doc-456',
          driverId: 'driver-123',
          truckNumber: 'TRK-001',
          maintenanceType: 'Tire Rotation',
          serviceDate: DateTime.now().subtract(const Duration(days: 30)),
          cost: 50.0,
          nextServiceDue: DateTime.now().add(const Duration(days: 60)),
        );

        expect(notDueRecord.isNextServiceDue, isFalse);

        // No next service due
        final noNextServiceRecord = MaintenanceRecord(
          id: 'doc-789',
          driverId: 'driver-123',
          truckNumber: 'TRK-001',
          maintenanceType: 'Inspection',
          serviceDate: DateTime.now().subtract(const Duration(days: 10)),
          cost: 75.0,
        );

        expect(noNextServiceRecord.isNextServiceDue, isFalse);
      });
    });

    group('Error Handling', () {
      test('methods should handle errors gracefully', () {
        // Note: Without Firebase emulator or mocks, we can't test actual error
        // handling, but we can verify the methods are properly async/await
        expect(
          service.getMaintenanceHistory(),
          isA<Future<List<Map<String, dynamic>>>>(),
        );

        expect(
          service.getUpcomingMaintenance(),
          isA<Future<List<Map<String, dynamic>>>>(),
        );

        expect(
          service.getAllMaintenance(),
          isA<Future<List<Map<String, dynamic>>>>(),
        );

        expect(
          service.getMaintenanceStats('TRK-001'),
          isA<Future<Map<String, dynamic>>>(),
        );

        expect(
          service.getTruckNumbersWithMaintenance(),
          isA<Future<List<String>>>(),
        );
      });
    });

    group('Query Parameters Validation', () {
      test('handles empty truckNumber parameter', () {
        // Empty string should be treated as no filter
        expect(
          () => service.getMaintenanceHistory(truckNumber: ''),
          returnsNormally,
        );

        expect(
          () => service.getUpcomingMaintenance(truckNumber: ''),
          returnsNormally,
        );

        expect(
          () => service.getAllMaintenance(truckNumber: ''),
          returnsNormally,
        );
      });

      test('handles various limit values', () {
        expect(
          () => service.getMaintenanceHistory(limit: 0),
          returnsNormally,
        );

        expect(
          () => service.getMaintenanceHistory(limit: 1),
          returnsNormally,
        );

        expect(
          () => service.getMaintenanceHistory(limit: 100),
          returnsNormally,
        );
      });

      test('handles various daysAhead values', () {
        expect(
          () => service.getUpcomingMaintenance(daysAhead: 0),
          returnsNormally,
        );

        expect(
          () => service.getUpcomingMaintenance(daysAhead: 1),
          returnsNormally,
        );

        expect(
          () => service.getUpcomingMaintenance(daysAhead: 365),
          returnsNormally,
        );
      });

      test('handles descending parameter', () {
        expect(
          () => service.getAllMaintenance(descending: true),
          returnsNormally,
        );

        expect(
          () => service.getAllMaintenance(descending: false),
          returnsNormally,
        );
      });
    });
  });
}
