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
      final statuses = ['pending', 'accepted', 'declined', 'assigned', 'picked_up', 'in_transit', 'delivered'];
      
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

    test('constructor handles BOL and POD fields', () {
      final testDate = DateTime(2024, 1, 1);
      final load = LoadModel(
        id: 'test-id',
        loadNumber: 'LD-001',
        driverId: 'driver-1',
        pickupAddress: '123 Main St',
        deliveryAddress: '456 Oak Ave',
        rate: 1500.0,
        status: 'assigned',
        bolPhotoUrl: 'https://example.com/bol.jpg',
        podPhotoUrl: 'https://example.com/pod.jpg',
        bolUploadedAt: testDate,
        podUploadedAt: testDate.add(Duration(hours: 2)),
      );

      expect(load.bolPhotoUrl, 'https://example.com/bol.jpg');
      expect(load.podPhotoUrl, 'https://example.com/pod.jpg');
      expect(load.bolUploadedAt, testDate);
      expect(load.podUploadedAt, testDate.add(Duration(hours: 2)));
    });

    test('toMap includes BOL and POD fields when present', () {
      final testDate = DateTime(2024, 1, 1);
      final load = LoadModel(
        id: 'test-id',
        loadNumber: 'LD-001',
        driverId: 'driver-1',
        pickupAddress: '123 Main St',
        deliveryAddress: '456 Oak Ave',
        rate: 1500.0,
        status: 'assigned',
        bolPhotoUrl: 'https://example.com/bol.jpg',
        podPhotoUrl: 'https://example.com/pod.jpg',
        bolUploadedAt: testDate,
        podUploadedAt: testDate.add(Duration(hours: 2)),
      );

      final map = load.toMap();

      expect(map['bolPhotoUrl'], 'https://example.com/bol.jpg');
      expect(map['podPhotoUrl'], 'https://example.com/pod.jpg');
      expect(map['bolUploadedAt'], testDate.toIso8601String());
      expect(map['podUploadedAt'], testDate.add(Duration(hours: 2)).toIso8601String());
    });

    test('toMap omits BOL and POD fields when null', () {
      final load = LoadModel(
        id: 'test-id',
        loadNumber: 'LD-001',
        driverId: 'driver-1',
        pickupAddress: '123 Main St',
        deliveryAddress: '456 Oak Ave',
        rate: 1500.0,
        status: 'assigned',
      );

      final map = load.toMap();

      expect(map.containsKey('bolPhotoUrl'), false);
      expect(map.containsKey('podPhotoUrl'), false);
      expect(map.containsKey('bolUploadedAt'), false);
      expect(map.containsKey('podUploadedAt'), false);
    });

    test('fromMap deserializes BOL and POD fields correctly', () {
      final testDate = DateTime(2024, 1, 1);
      final map = {
        'loadNumber': 'LD-001',
        'driverId': 'driver-1',
        'pickupAddress': '123 Main St',
        'deliveryAddress': '456 Oak Ave',
        'rate': 1500.0,
        'status': 'assigned',
        'createdAt': testDate.toIso8601String(),
        'bolPhotoUrl': 'https://example.com/bol.jpg',
        'podPhotoUrl': 'https://example.com/pod.jpg',
        'bolUploadedAt': testDate.toIso8601String(),
        'podUploadedAt': testDate.add(Duration(hours: 2)).toIso8601String(),
      };

      final load = LoadModel.fromMap('test-id', map);

      expect(load.bolPhotoUrl, 'https://example.com/bol.jpg');
      expect(load.podPhotoUrl, 'https://example.com/pod.jpg');
      expect(load.bolUploadedAt, testDate);
      expect(load.podUploadedAt, testDate.add(Duration(hours: 2)));
    });

    test('constructor handles accept/decline fields', () {
      final testDate = DateTime(2024, 1, 1);
      final load = LoadModel(
        id: 'test-id',
        loadNumber: 'LD-001',
        driverId: 'driver-1',
        pickupAddress: '123 Main St',
        deliveryAddress: '456 Oak Ave',
        rate: 1500.0,
        status: 'accepted',
        acceptedAt: testDate,
        declineReason: null,
      );

      expect(load.acceptedAt, testDate);
      expect(load.declinedAt, null);
      expect(load.declineReason, null);
    });

    test('constructor handles declined load with reason', () {
      final testDate = DateTime(2024, 1, 1);
      final load = LoadModel(
        id: 'test-id',
        loadNumber: 'LD-001',
        driverId: 'driver-1',
        pickupAddress: '123 Main St',
        deliveryAddress: '456 Oak Ave',
        rate: 1500.0,
        status: 'declined',
        declinedAt: testDate,
        declineReason: 'Schedule conflict',
      );

      expect(load.status, 'declined');
      expect(load.declinedAt, testDate);
      expect(load.declineReason, 'Schedule conflict');
      expect(load.acceptedAt, null);
    });

    test('toMap includes accept/decline fields when present', () {
      final testDate = DateTime(2024, 1, 1);
      final load = LoadModel(
        id: 'test-id',
        loadNumber: 'LD-001',
        driverId: 'driver-1',
        pickupAddress: '123 Main St',
        deliveryAddress: '456 Oak Ave',
        rate: 1500.0,
        status: 'declined',
        declinedAt: testDate,
        declineReason: 'Truck maintenance',
      );

      final map = load.toMap();

      expect(map['declinedAt'], testDate.toIso8601String());
      expect(map['declineReason'], 'Truck maintenance');
      expect(map.containsKey('acceptedAt'), false);
    });

    test('toMap omits accept/decline fields when null', () {
      final load = LoadModel(
        id: 'test-id',
        loadNumber: 'LD-001',
        driverId: 'driver-1',
        pickupAddress: '123 Main St',
        deliveryAddress: '456 Oak Ave',
        rate: 1500.0,
        status: 'pending',
      );

      final map = load.toMap();

      expect(map.containsKey('acceptedAt'), false);
      expect(map.containsKey('declinedAt'), false);
      expect(map.containsKey('declineReason'), false);
    });

    test('fromMap deserializes accept/decline fields correctly', () {
      final testDate = DateTime(2024, 1, 1);
      final map = {
        'loadNumber': 'LD-001',
        'driverId': 'driver-1',
        'pickupAddress': '123 Main St',
        'deliveryAddress': '456 Oak Ave',
        'rate': 1500.0,
        'status': 'accepted',
        'createdAt': testDate.toIso8601String(),
        'acceptedAt': testDate.add(Duration(hours: 1)).toIso8601String(),
      };

      final load = LoadModel.fromMap('test-id', map);

      expect(load.status, 'accepted');
      expect(load.acceptedAt, testDate.add(Duration(hours: 1)));
      expect(load.declinedAt, null);
      expect(load.declineReason, null);
    });
  });
}
