import 'package:flutter_test/flutter_test.dart';
import 'package:gud_app/models/load.dart';

void main() {
  group('LoadModel', () {
    final testDate = DateTime(2024, 1, 1);
    
    test('constructor creates valid LoadModel', () {
      final load = LoadModel(
        id: 'test-id',
        loadNumber: 'LD-001',
        driverId: 'driver-1',
        driverName: 'John Doe',
        pickupAddress: '123 Main St',
        deliveryAddress: '456 Oak Ave',
        rate: 1500.0,
        status: 'assigned',
        createdAt: testDate,
        notes: 'Test notes',
        miles: 150.0,
        createdBy: 'admin-1',
      );

      expect(load.id, 'test-id');
      expect(load.loadNumber, 'LD-001');
      expect(load.driverId, 'driver-1');
      expect(load.driverName, 'John Doe');
      expect(load.pickupAddress, '123 Main St');
      expect(load.deliveryAddress, '456 Oak Ave');
      expect(load.rate, 1500.0);
      expect(load.status, 'assigned');
      expect(load.createdAt, testDate);
      expect(load.notes, 'Test notes');
      expect(load.miles, 150.0);
      expect(load.createdBy, 'admin-1');
    });

    test('constructor uses default values when optional fields are null', () {
      final load = LoadModel(
        id: 'test-id',
        loadNumber: 'LD-001',
        driverId: 'driver-1',
        pickupAddress: '123 Main St',
        deliveryAddress: '456 Oak Ave',
        rate: 1500.0,
        status: 'assigned',
      );

      expect(load.driverName, null);
      expect(load.notes, null);
      expect(load.miles, 0.0);
      expect(load.createdBy, '');
      expect(load.pickedUpAt, null);
      expect(load.deliveredAt, null);
      expect(load.createdAt, isNotNull);
    });

    test('toMap serializes LoadModel correctly', () {
      final load = LoadModel(
        id: 'test-id',
        loadNumber: 'LD-001',
        driverId: 'driver-1',
        driverName: 'John Doe',
        pickupAddress: '123 Main St',
        deliveryAddress: '456 Oak Ave',
        rate: 1500.0,
        status: 'assigned',
        createdAt: testDate,
        miles: 150.0,
        notes: 'Test notes',
        createdBy: 'admin-1',
      );

      final map = load.toMap();

      expect(map['loadNumber'], 'LD-001');
      expect(map['driverId'], 'driver-1');
      expect(map['driverName'], 'John Doe');
      expect(map['pickupAddress'], '123 Main St');
      expect(map['deliveryAddress'], '456 Oak Ave');
      expect(map['rate'], 1500.0);
      expect(map['status'], 'assigned');
      expect(map['createdAt'], testDate.toIso8601String());
      expect(map['miles'], 150.0);
      expect(map['notes'], 'Test notes');
      expect(map['createdBy'], 'admin-1');
    });

    test('toMap omits null optional fields', () {
      final load = LoadModel(
        id: 'test-id',
        loadNumber: 'LD-001',
        driverId: 'driver-1',
        pickupAddress: '123 Main St',
        deliveryAddress: '456 Oak Ave',
        rate: 1500.0,
        status: 'assigned',
        createdAt: testDate,
      );

      final map = load.toMap();

      expect(map.containsKey('driverName'), false);
      expect(map.containsKey('notes'), false);
      expect(map.containsKey('pickedUpAt'), false);
      expect(map.containsKey('deliveredAt'), false);
    });

    test('fromMap deserializes LoadModel correctly', () {
      final map = {
        'loadNumber': 'LD-001',
        'driverId': 'driver-1',
        'driverName': 'John Doe',
        'pickupAddress': '123 Main St',
        'deliveryAddress': '456 Oak Ave',
        'rate': 1500.0,
        'status': 'assigned',
        'createdAt': testDate.toIso8601String(),
        'miles': 150.0,
        'notes': 'Test notes',
        'createdBy': 'admin-1',
      };

      final load = LoadModel.fromMap('test-id', map);

      expect(load.id, 'test-id');
      expect(load.loadNumber, 'LD-001');
      expect(load.driverId, 'driver-1');
      expect(load.driverName, 'John Doe');
      expect(load.pickupAddress, '123 Main St');
      expect(load.deliveryAddress, '456 Oak Ave');
      expect(load.rate, 1500.0);
      expect(load.status, 'assigned');
      expect(load.createdAt, testDate);
      expect(load.miles, 150.0);
      expect(load.notes, 'Test notes');
      expect(load.createdBy, 'admin-1');
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'loadNumber': 'LD-001',
        'driverId': 'driver-1',
        'pickupAddress': '123 Main St',
        'deliveryAddress': '456 Oak Ave',
        'rate': 1500.0,
        'status': 'assigned',
        'createdAt': testDate.toIso8601String(),
      };

      final load = LoadModel.fromMap('test-id', map);

      expect(load.driverName, null);
      expect(load.notes, null);
      expect(load.miles, 0.0);
      expect(load.createdBy, '');
      expect(load.pickedUpAt, null);
      expect(load.deliveredAt, null);
    });

    test('fromMap uses default values for missing required fields', () {
      final map = <String, dynamic>{
        'rate': 1500.0,
      };

      final load = LoadModel.fromMap('test-id', map);

      expect(load.loadNumber, '');
      expect(load.driverId, '');
      expect(load.pickupAddress, '');
      expect(load.deliveryAddress, '');
      expect(load.status, 'assigned');
      expect(load.rate, 1500.0);
    });

    test('serialization roundtrip maintains data integrity', () {
      final original = LoadModel(
        id: 'test-id',
        loadNumber: 'LD-001',
        driverId: 'driver-1',
        driverName: 'John Doe',
        pickupAddress: '123 Main St',
        deliveryAddress: '456 Oak Ave',
        rate: 1500.0,
        status: 'delivered',
        createdAt: testDate,
        pickedUpAt: testDate.add(Duration(hours: 1)),
        deliveredAt: testDate.add(Duration(hours: 5)),
        miles: 150.0,
        notes: 'Test notes',
        createdBy: 'admin-1',
      );

      final map = original.toMap();
      final deserialized = LoadModel.fromMap(original.id, map);

      expect(deserialized.id, original.id);
      expect(deserialized.loadNumber, original.loadNumber);
      expect(deserialized.driverId, original.driverId);
      expect(deserialized.driverName, original.driverName);
      expect(deserialized.status, original.status);
      expect(deserialized.rate, original.rate);
      expect(deserialized.miles, original.miles);
      expect(deserialized.notes, original.notes);
      expect(deserialized.createdBy, original.createdBy);
    });

    test('handles different load statuses', () {
      final statuses = ['assigned', 'picked_up', 'in_transit', 'delivered'];
      
      for (final status in statuses) {
        final load = LoadModel(
          id: 'test-id',
          loadNumber: 'LD-001',
          driverId: 'driver-1',
          pickupAddress: '123 Main St',
          deliveryAddress: '456 Oak Ave',
          rate: 1500.0,
          status: status,
        );

        expect(load.status, status);
        
        final map = load.toMap();
        expect(map['status'], status);
        
        final deserialized = LoadModel.fromMap('test-id', map);
        expect(deserialized.status, status);
      }
    });
  });
}
