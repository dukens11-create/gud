import 'package:flutter_test/flutter_test.dart';
import 'package:gud_app/models/driver.dart';

void main() {
  group('Driver', () {
    test('constructor creates valid Driver', () {
      final driver = Driver(
        id: 'driver-123',
        name: 'John Doe',
        phone: '555-1234',
        truckNumber: 'TRK-001',
        status: 'available',
        totalEarnings: 5000.0,
        completedLoads: 10,
        isActive: true,
        lastLocation: {'lat': 40.7128, 'lng': -74.0060, 'timestamp': '2024-01-01T12:00:00Z'},
      );

      expect(driver.id, 'driver-123');
      expect(driver.name, 'John Doe');
      expect(driver.phone, '555-1234');
      expect(driver.truckNumber, 'TRK-001');
      expect(driver.status, 'available');
      expect(driver.totalEarnings, 5000.0);
      expect(driver.completedLoads, 10);
      expect(driver.isActive, true);
      expect(driver.lastLocation, isNotNull);
      expect(driver.lastLocation!['lat'], 40.7128);
    });

    test('constructor uses default values', () {
      final driver = Driver(
        id: 'driver-123',
        name: 'John Doe',
        phone: '555-1234',
        truckNumber: 'TRK-001',
        status: 'available',
      );

      expect(driver.totalEarnings, 0.0);
      expect(driver.completedLoads, 0);
      expect(driver.isActive, true);
      expect(driver.lastLocation, null);
    });

    test('toMap serializes Driver correctly', () {
      final driver = Driver(
        id: 'driver-123',
        name: 'John Doe',
        phone: '555-1234',
        truckNumber: 'TRK-001',
        status: 'on_trip',
        totalEarnings: 7500.0,
        completedLoads: 15,
        isActive: false,
        lastLocation: {'lat': 40.7128, 'lng': -74.0060},
      );

      final map = driver.toMap();

      expect(map['name'], 'John Doe');
      expect(map['phone'], '555-1234');
      expect(map['truckNumber'], 'TRK-001');
      expect(map['status'], 'on_trip');
      expect(map['totalEarnings'], 7500.0);
      expect(map['completedLoads'], 15);
      expect(map['isActive'], false);
      expect(map['lastLocation'], isNotNull);
      expect(map.containsKey('id'), false); // id is not serialized
    });

    test('toMap omits null lastLocation', () {
      final driver = Driver(
        id: 'driver-123',
        name: 'John Doe',
        phone: '555-1234',
        truckNumber: 'TRK-001',
        status: 'available',
      );

      final map = driver.toMap();

      expect(map.containsKey('lastLocation'), false);
    });

    test('fromMap deserializes Driver correctly', () {
      final map = {
        'name': 'Jane Smith',
        'phone': '555-5678',
        'truckNumber': 'TRK-002',
        'status': 'on_trip',
        'totalEarnings': 10000.0,
        'completedLoads': 20,
        'isActive': true,
        'lastLocation': {'lat': 34.0522, 'lng': -118.2437},
      };

      final driver = Driver.fromMap('driver-456', map);

      expect(driver.id, 'driver-456');
      expect(driver.name, 'Jane Smith');
      expect(driver.phone, '555-5678');
      expect(driver.truckNumber, 'TRK-002');
      expect(driver.status, 'on_trip');
      expect(driver.totalEarnings, 10000.0);
      expect(driver.completedLoads, 20);
      expect(driver.isActive, true);
      expect(driver.lastLocation, isNotNull);
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'name': 'Bob Wilson',
        'phone': '555-9999',
        'truckNumber': 'TRK-003',
      };

      final driver = Driver.fromMap('driver-789', map);

      expect(driver.name, 'Bob Wilson');
      expect(driver.phone, '555-9999');
      expect(driver.truckNumber, 'TRK-003');
      expect(driver.status, 'available'); // default
      expect(driver.totalEarnings, 0.0); // default
      expect(driver.completedLoads, 0); // default
      expect(driver.isActive, true); // default
      expect(driver.lastLocation, null);
    });

    test('serialization roundtrip maintains data integrity', () {
      final original = Driver(
        id: 'driver-123',
        name: 'John Doe',
        phone: '555-1234',
        truckNumber: 'TRK-001',
        status: 'available',
        totalEarnings: 5000.0,
        completedLoads: 10,
        isActive: true,
        lastLocation: {'lat': 40.7128, 'lng': -74.0060},
      );

      final map = original.toMap();
      final deserialized = Driver.fromMap(original.id, map);

      expect(deserialized.id, original.id);
      expect(deserialized.name, original.name);
      expect(deserialized.phone, original.phone);
      expect(deserialized.truckNumber, original.truckNumber);
      expect(deserialized.status, original.status);
      expect(deserialized.totalEarnings, original.totalEarnings);
      expect(deserialized.completedLoads, original.completedLoads);
      expect(deserialized.isActive, original.isActive);
      expect(deserialized.lastLocation, original.lastLocation);
    });

    test('handles different driver statuses', () {
      final statuses = ['available', 'on_trip', 'inactive'];
      
      for (final status in statuses) {
        final driver = Driver(
          id: 'driver-test',
          name: 'Test Driver',
          phone: '555-0000',
          truckNumber: 'TRK-000',
          status: status,
        );

        expect(driver.status, status);
        
        final map = driver.toMap();
        expect(map['status'], status);
        
        final deserialized = Driver.fromMap('driver-test', map);
        expect(deserialized.status, status);
      }
    });

    test('handles numeric type conversions correctly', () {
      final map = {
        'name': 'Test Driver',
        'phone': '555-0000',
        'truckNumber': 'TRK-000',
        'status': 'available',
        'totalEarnings': 1500, // int instead of double
        'completedLoads': 5,
        'isActive': true,
      };

      final driver = Driver.fromMap('driver-test', map);

      expect(driver.totalEarnings, 1500.0); // should be converted to double
      expect(driver.totalEarnings, isA<double>());
    });

    test('handles location data structure', () {
      final location = {
        'lat': 37.7749,
        'lng': -122.4194,
        'timestamp': '2024-01-01T10:30:00Z',
        'accuracy': 10.5,
      };

      final driver = Driver(
        id: 'driver-test',
        name: 'Test Driver',
        phone: '555-0000',
        truckNumber: 'TRK-000',
        status: 'on_trip',
        lastLocation: location,
      );

      expect(driver.lastLocation, location);
      
      final map = driver.toMap();
      expect(map['lastLocation'], location);
      
      final deserialized = Driver.fromMap(driver.id, map);
      expect(deserialized.lastLocation, location);
    });
  });
}
