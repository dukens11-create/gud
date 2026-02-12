import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/truck.dart';

/// Service for initializing Firebase Firestore with sample data
/// 
/// This service checks if collections are empty and populates them
/// with sample data on first app launch.
class FirebaseInitService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize trucks collection with sample data if empty
  /// 
  /// Creates 5 sample trucks with various statuses.
  /// Uses batch writes for efficiency.
  /// 
  /// **Note**: This requires admin authentication to create trucks.
  /// Will silently fail if user is not authenticated or not an admin.
  /// 
  /// Returns true if initialization was performed, false if trucks already exist
  /// or if initialization was skipped due to permissions.
  /// Throws exceptions on errors.
  Future<bool> initializeTrucks() async {
    try {
      print('🚛 Checking trucks collection...');

      // Check authentication first
      if (_auth.currentUser == null) {
        print('ℹ️ No user authenticated, skipping truck initialization');
        return false;
      }

      // Check if trucks collection is empty
      // Note: This requires at least authenticated user (read permission)
      final snapshot = await _db.collection('trucks').limit(1).get();
      
      if (snapshot.docs.isNotEmpty) {
        print('✅ Trucks collection already has data, skipping initialization');
        return false;
      }

      print('📝 Trucks collection is empty, creating sample trucks...');

      // Create sample trucks
      final batch = _db.batch();
      final now = DateTime.now();

      final sampleTrucks = [
        {
          'truckNumber': 'TRK-001',
          'vin': '1HGBH41JXMN109186',
          'make': 'Ford',
          'model': 'F-150',
          'year': 2022,
          'plateNumber': 'ABC-1234',
          'status': 'available',
          'assignedDriverId': null,
          'assignedDriverName': null,
          'notes': 'Capacity: 1000 lbs. Excellent condition.',
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        },
        {
          'truckNumber': 'TRK-002',
          'vin': '2HGBH41JXMN109187',
          'make': 'Chevrolet',
          'model': 'Silverado',
          'year': 2021,
          'plateNumber': 'DEF-5678',
          'status': 'available',
          'assignedDriverId': null,
          'assignedDriverName': null,
          'notes': 'Capacity: 1500 lbs. Heavy duty.',
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        },
        {
          'truckNumber': 'TRK-003',
          'vin': '3HGBH41JXMN109188',
          'make': 'RAM',
          'model': '1500',
          'year': 2023,
          'plateNumber': 'GHI-9012',
          'status': 'in_use',
          'assignedDriverId': null,
          'assignedDriverName': null,
          'notes': 'Capacity: 1200 lbs. Currently on route.',
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        },
        {
          'truckNumber': 'TRK-004',
          'vin': '4HGBH41JXMN109189',
          'make': 'Toyota',
          'model': 'Tundra',
          'year': 2020,
          'plateNumber': 'JKL-3456',
          'status': 'in_use',
          'assignedDriverId': null,
          'assignedDriverName': null,
          'notes': 'Capacity: 1100 lbs. Reliable workhorse.',
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        },
        {
          'truckNumber': 'TRK-005',
          'vin': '5HGBH41JXMN109190',
          'make': 'GMC',
          'model': 'Sierra',
          'year': 2021,
          'plateNumber': 'MNO-7890',
          'status': 'maintenance',
          'assignedDriverId': null,
          'assignedDriverName': null,
          'notes': 'Capacity: 1300 lbs. Scheduled for routine maintenance.',
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        },
      ];

      // Add all trucks to batch
      for (final truckData in sampleTrucks) {
        final docRef = _db.collection('trucks').doc();
        batch.set(docRef, truckData);
      }

      // Commit the batch
      await batch.commit();

      print('✅ Successfully created ${sampleTrucks.length} sample trucks');
      return true;
    } catch (e) {
      print('❌ Error initializing trucks: $e');
      rethrow;
    }
  }

  /// Initialize all collections with sample data
  /// 
  /// This is the main entry point for database initialization.
  /// Currently only initializes trucks, but can be extended for other collections.
  Future<void> initializeDatabase() async {
    try {
      print('🚀 Starting database initialization...');

      // Initialize trucks
      final trucksInitialized = await initializeTrucks();

      if (trucksInitialized) {
        print('✅ Database initialization complete');
      } else {
        print('ℹ️ Database already initialized');
      }
    } catch (e) {
      print('❌ Database initialization failed: $e');
      rethrow;
    }
  }
}
