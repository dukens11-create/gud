import 'package:flutter_test/flutter_test.dart';
import 'package:gud_app/models/app_user.dart';

void main() {
  group('AppUser', () {
    final testDate = DateTime(2024, 1, 1);
    
    test('constructor creates valid AppUser', () {
      final user = AppUser(
        uid: 'user-123',
        role: 'driver',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '555-1234',
        truckNumber: 'TRK-001',
        isActive: true,
        createdAt: testDate,
      );

      expect(user.uid, 'user-123');
      expect(user.role, 'driver');
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
      expect(user.phone, '555-1234');
      expect(user.truckNumber, 'TRK-001');
      expect(user.isActive, true);
      expect(user.createdAt, testDate);
    });

    test('constructor uses default values', () {
      final user = AppUser(
        uid: 'user-123',
        role: 'admin',
        name: 'Admin User',
        email: 'admin@example.com',
        phone: '555-9999',
        truckNumber: '',
      );

      expect(user.isActive, true);
      expect(user.createdAt, isNotNull);
    });

    test('toMap serializes AppUser correctly', () {
      final user = AppUser(
        uid: 'user-123',
        role: 'driver',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '555-1234',
        truckNumber: 'TRK-001',
        isActive: false,
        createdAt: testDate,
      );

      final map = user.toMap();

      expect(map['role'], 'driver');
      expect(map['name'], 'John Doe');
      expect(map['email'], 'john@example.com');
      expect(map['phone'], '555-1234');
      expect(map['truckNumber'], 'TRK-001');
      expect(map['isActive'], false);
      expect(map['createdAt'], testDate.toIso8601String());
      expect(map.containsKey('uid'), false); // uid is not serialized
    });

    test('fromMap deserializes AppUser correctly', () {
      final map = {
        'role': 'driver',
        'name': 'John Doe',
        'email': 'john@example.com',
        'phone': '555-1234',
        'truckNumber': 'TRK-001',
        'isActive': true,
        'createdAt': testDate.toIso8601String(),
      };

      final user = AppUser.fromMap('user-123', map);

      expect(user.uid, 'user-123');
      expect(user.role, 'driver');
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
      expect(user.phone, '555-1234');
      expect(user.truckNumber, 'TRK-001');
      expect(user.isActive, true);
      expect(user.createdAt, testDate);
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'phone': '555-1234',
      };

      final user = AppUser.fromMap('user-123', map);

      expect(user.role, 'driver'); // default
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
      expect(user.phone, '555-1234');
      expect(user.truckNumber, ''); // default
      expect(user.isActive, true); // default
      expect(user.createdAt, isNull); // null when not provided
    });

    test('serialization roundtrip maintains data integrity', () {
      final original = AppUser(
        uid: 'user-123',
        role: 'admin',
        name: 'Admin User',
        email: 'admin@example.com',
        phone: '555-9999',
        truckNumber: '',
        isActive: true,
        createdAt: testDate,
      );

      final map = original.toMap();
      final deserialized = AppUser.fromMap(original.uid, map);

      expect(deserialized.uid, original.uid);
      expect(deserialized.role, original.role);
      expect(deserialized.name, original.name);
      expect(deserialized.email, original.email);
      expect(deserialized.phone, original.phone);
      expect(deserialized.truckNumber, original.truckNumber);
      expect(deserialized.isActive, original.isActive);
      expect(deserialized.createdAt, original.createdAt);
    });

    test('handles admin role correctly', () {
      final admin = AppUser(
        uid: 'admin-1',
        role: 'admin',
        name: 'Admin User',
        email: 'admin@example.com',
        phone: '555-0000',
        truckNumber: '',
      );

      expect(admin.role, 'admin');
      expect(admin.truckNumber, ''); // admins don't need truck numbers
    });

    test('handles driver role correctly', () {
      final driver = AppUser(
        uid: 'driver-1',
        role: 'driver',
        name: 'Driver User',
        email: 'driver@example.com',
        phone: '555-1111',
        truckNumber: 'TRK-101',
      );

      expect(driver.role, 'driver');
      expect(driver.truckNumber, 'TRK-101');
    });

    test('handles inactive users', () {
      final inactiveUser = AppUser(
        uid: 'user-inactive',
        role: 'driver',
        name: 'Inactive Driver',
        email: 'inactive@example.com',
        phone: '555-2222',
        truckNumber: 'TRK-202',
        isActive: false,
      );

      expect(inactiveUser.isActive, false);
      
      final map = inactiveUser.toMap();
      expect(map['isActive'], false);
      
      final deserialized = AppUser.fromMap(inactiveUser.uid, map);
      expect(deserialized.isActive, false);
    });
  });
}
