import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for initializing Firebase Firestore with sample data
/// 
/// This service checks if collections are empty and populates them
/// with sample data on first app launch.
class FirebaseInitService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Check if trucks collection needs initialization
  /// 
  /// Returns true if the collection is empty, false otherwise.
  Future<bool> needsInitialization() async {
    final snapshot = await _db
        .collection('trucks')
        .limit(1)
        .get();
    return snapshot.docs.isEmpty;
  }

  /// Initialize trucks collection with 5 sample trucks
  /// 
  /// Creates sample trucks with various statuses.
  /// Uses batch writes for efficiency.
  /// 
  /// Throws exceptions on errors.
  Future<void> initializeSampleTrucks() async {
    final trucks = [
      {
        'truckNumber': 'T001',
        'vin': 'VIN001ABC123',
        'make': 'Ford',
        'model': 'F-150',
        'year': 2022,
        'plateNumber': 'ABC-1234',
        'status': 'available',
        'assignedDriverId': null,
        'assignedDriverName': null,
        'notes': 'Sample truck - edit or delete as needed',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'truckNumber': 'T002',
        'vin': 'VIN002DEF456',
        'make': 'Chevrolet',
        'model': 'Silverado 1500',
        'year': 2023,
        'plateNumber': 'DEF-5678',
        'status': 'available',
        'assignedDriverId': null,
        'assignedDriverName': null,
        'notes': 'Sample truck - edit or delete as needed',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'truckNumber': 'T003',
        'vin': 'VIN003GHI789',
        'make': 'RAM',
        'model': '1500',
        'year': 2021,
        'plateNumber': 'GHI-9012',
        'status': 'in_use',
        'assignedDriverId': null,
        'assignedDriverName': null,
        'notes': 'Sample truck currently in use',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'truckNumber': 'T004',
        'vin': 'VIN004JKL321',
        'make': 'GMC',
        'model': 'Sierra 2500HD',
        'year': 2023,
        'plateNumber': 'JKL-3456',
        'status': 'available',
        'assignedDriverId': null,
        'assignedDriverName': null,
        'notes': 'Sample heavy-duty truck',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'truckNumber': 'T005',
        'vin': 'VIN005MNO654',
        'make': 'Ford',
        'model': 'F-250',
        'year': 2020,
        'plateNumber': 'MNO-7890',
        'status': 'maintenance',
        'assignedDriverId': null,
        'assignedDriverName': null,
        'notes': 'Sample truck in maintenance',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    ];

    final batch = _db.batch();
    final collection = _db.collection('trucks');

    for (final truckData in trucks) {
      final docRef = collection.doc();
      batch.set(docRef, truckData);
    }

    await batch.commit();
  }

  /// Initialize trucks collection with sample data if empty (legacy method)
  /// 
  /// Creates 5 sample trucks with various statuses.
  /// Uses batch writes for efficiency.
  /// 
  /// Returns true if initialization was performed, false if trucks already exist.
  /// Throws exceptions on errors.
  @Deprecated('Use needsInitialization() and initializeSampleTrucks() instead')
  Future<bool> initializeTrucks() async {
    try {
      print('🚛 Checking trucks collection...');

      // Check if trucks collection is empty
      final needsInit = await needsInitialization();
      
      if (!needsInit) {
        print('✅ Trucks collection already has data, skipping initialization');
        return false;
      }

      print('📝 Trucks collection is empty, creating sample trucks...');

      // Create sample trucks
      await initializeSampleTrucks();

      print('✅ Successfully created 5 sample trucks');
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
