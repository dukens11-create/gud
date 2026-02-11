import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/driver.dart';
import '../models/load.dart';
import '../models/pod.dart';

/// Firestore database service for managing all database operations.
/// 
/// Provides CRUD operations for:
/// - User profiles and roles
/// - Driver management
/// - Load tracking and management
/// - POD (Proof of Delivery) documents
/// - Statistics and analytics
/// 
/// All methods use Firebase Firestore for real-time data synchronization.
/// 
/// **Security**: All methods verify user authentication before executing queries.
/// Throws [FirebaseAuthException] if user is not authenticated.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Verify user is authenticated before executing Firestore operations
  /// 
  /// Throws [FirebaseAuthException] with code 'unauthenticated' if user is not signed in
  void _requireAuth() {
    if (_auth.currentUser == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message: 'User must be signed in to access Firestore data',
      );
    }
  }

  // User Management
  
  /// Get user's role from Firestore
  /// 
  /// Returns 'admin' or 'driver', defaults to 'driver' if not found
  Future<String> getUserRole(String userId) async {
    _requireAuth();
    DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
    return (doc.data() as Map<String, dynamic>?)?['role'] ?? 'driver';
  }

  // Driver Management
  
  /// Create a new driver profile
  /// 
  /// Parameters:
  /// - [driverId]: Unique identifier (typically Firebase Auth UID)
  /// - [name]: Driver's full name
  /// - [phone]: Contact phone number
  /// - [truckNumber]: Assigned truck identifier
  /// 
  /// Throws [FirebaseAuthException] if user is not authenticated
  /// Throws [FirebaseException] if Firestore operation fails
  Future<void> createDriver({
    required String driverId,
    required String name,
    required String phone,
    required String truckNumber,
  }) async {
    _requireAuth();
    
    print('🔧 Creating driver in Firestore: $driverId');
    
    if (driverId.isEmpty || name.isEmpty || phone.isEmpty || truckNumber.isEmpty) {
      throw ArgumentError('All driver fields must be non-empty');
    }
    
    try {
      await _db.collection('drivers').doc(driverId).set({
        'name': name,
        'phone': phone,
        'truckNumber': truckNumber,
        'status': 'available',
        'isActive': true,  // Explicitly set isActive field
        'totalEarnings': 0.0,  // Initialize earnings
        'completedLoads': 0,  // Initialize load count
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Driver created successfully in Firestore: $driverId');
    } on FirebaseException catch (e) {
      print('❌ Firebase error creating driver: ${e.code} - ${e.message}');
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: e.code,
        message: 'Failed to create driver: ${e.message}',
      );
    } catch (e) {
      print('❌ Unexpected error creating driver in Firestore: $e');
      rethrow;
    }
  }

  /// Stream all drivers with real-time updates
  /// 
  /// Returns a stream that emits the complete list of drivers
  /// whenever any driver document changes
  /// 
  /// Throws [FirebaseAuthException] if user is not authenticated
  Stream<List<Driver>> streamDrivers() {
    _requireAuth();
    
    print('🔍 Starting to stream drivers from Firestore');
    
    return _db.collection('drivers').snapshots().map(
      (snapshot) {
        print('📊 Received ${snapshot.docs.length} driver documents from Firestore');
        
        final drivers = snapshot.docs.map((doc) {
          final data = doc.data();
          final isActive = data['isActive'] as bool?;
          print('   Driver ${doc.id}: isActive=$isActive');
          return Driver.fromMap(doc.id, data);
        }).toList();
        
        print('✅ Parsed ${drivers.length} drivers successfully');
        return drivers;
      },
    ).handleError((error) {
      print('❌ Error streaming drivers: $error');
      throw error;
    });
  }

  /// Update driver information
  /// 
  /// Only updates fields that are provided (non-null)
  /// Parameters:
  /// - [driverId]: Driver's unique identifier
  /// - [name]: Optional new name
  /// - [phone]: Optional new phone
  /// - [truckNumber]: Optional new truck number
  /// - [status]: Optional status ('available', 'on_trip', 'offline')
  /// - [isActive]: Optional active status flag
  Future<void> updateDriver({
    required String driverId,
    String? name,
    String? phone,
    String? truckNumber,
    String? status,
    bool? isActive,
  }) async {
    _requireAuth();
    final Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (truckNumber != null) updates['truckNumber'] = truckNumber;
    if (status != null) updates['status'] = status;
    if (isActive != null) updates['isActive'] = isActive;
    
    if (updates.isNotEmpty) {
      await _db.collection('drivers').doc(driverId).update(updates);
    }
  }

  /// Get a single driver's information
  /// 
  /// Returns [Driver] if found, null otherwise
  Future<Driver?> getDriver(String driverId) async {
    _requireAuth();
    final doc = await _db.collection('drivers').doc(driverId).get();
    if (!doc.exists) return null;
    return Driver.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  /// Update driver statistics after completing a load
  /// 
  /// Uses FieldValue.increment for atomic counter updates
  /// Parameters:
  /// - [driverId]: Driver's identifier
  /// - [earnings]: Amount to add to total earnings
  /// - [completedLoads]: Number of loads to add (typically 1)
  Future<void> updateDriverStats({
    required String driverId,
    required double earnings,
    required int completedLoads,
  }) async {
    _requireAuth();
    await _db.collection('drivers').doc(driverId).update({
      'totalEarnings': FieldValue.increment(earnings),
      'completedLoads': FieldValue.increment(completedLoads),
    });
  }

  /// Update driver's last known location
  Future<void> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
    required DateTime timestamp,
    double? accuracy,
  }) async {
    _requireAuth();
    await _db.collection('drivers').doc(driverId).update({
      'lastLocation': {
        'lat': latitude,
        'lng': longitude,
        'timestamp': timestamp.toIso8601String(),
        if (accuracy != null) 'accuracy': accuracy,
      },
    });
  }

  // Load Management
  
  /// Create a new load assignment
  /// 
  /// Returns the generated load document ID
  /// Parameters:
  /// - [loadNumber]: Human-readable load identifier (e.g., 'LOAD-001')
  /// - [driverId]: Assigned driver's ID
  /// - [driverName]: Driver's name (denormalized for performance)
  /// - [pickupAddress]: Pickup location address
  /// - [deliveryAddress]: Delivery destination address
  /// - [rate]: Payment rate for this load
  /// - [miles]: Optional estimated miles
  /// - [notes]: Optional additional notes
  /// - [createdBy]: Admin user ID who created the load
  /// 
  /// Throws [FirebaseAuthException] if user is not authenticated
  /// Throws [ArgumentError] if required fields are empty
  /// Throws [FirebaseException] if Firestore operation fails
  Future<String> createLoad({
    required String loadNumber,
    required String driverId,
    required String driverName,
    required String pickupAddress,
    required String deliveryAddress,
    required double rate,
    double? miles,
    String? notes,
    required String createdBy,
  }) async {
    _requireAuth();
    
    print('🔧 Creating load in Firestore: $loadNumber for driver $driverId');
    
    // Validate required fields
    if (loadNumber.isEmpty || driverId.isEmpty || driverName.isEmpty || 
        pickupAddress.isEmpty || deliveryAddress.isEmpty || createdBy.isEmpty) {
      throw ArgumentError('All required load fields must be non-empty');
    }
    
    if (rate < 0) {
      throw ArgumentError('Rate must be non-negative');
    }
    
    try {
      final docRef = await _db.collection('loads').add({
        'loadNumber': loadNumber,
        'driverId': driverId,
        'driverName': driverName,
        'pickupAddress': pickupAddress,
        'deliveryAddress': deliveryAddress,
        'rate': rate,
        if (miles != null) 'miles': miles,
        'status': 'assigned',
        if (notes != null) 'notes': notes,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Load created successfully: ${docRef.id}');
      return docRef.id;
    } on FirebaseException catch (e) {
      print('❌ Firebase error creating load: ${e.code} - ${e.message}');
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: e.code,
        message: 'Failed to create load: ${e.message}',
      );
    } catch (e) {
      print('❌ Unexpected error creating load: $e');
      rethrow;
    }
  }

  /// Stream all loads with real-time updates
  /// 
  /// Returns loads ordered by creation time (newest first)
  Stream<List<LoadModel>> streamAllLoads() {
    _requireAuth();
    return _db
        .collection('loads')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => LoadModel.fromDoc(doc)).toList());
  }

  /// Stream loads for a specific driver
  /// 
  /// Returns only loads assigned to the specified driver,
  /// ordered by creation time (newest first)
  /// 
  /// Note: This query requires a composite index on:
  /// - driverId (ascending)
  /// - createdAt (descending)
  Stream<List<LoadModel>> streamDriverLoads(String driverId) {
    _requireAuth();
    
    print('🔍 Starting to stream loads for driver: $driverId');
    
    try {
      return _db
          .collection('loads')
          .where('driverId', isEqualTo: driverId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            print('📊 Received ${snapshot.docs.length} load documents for driver $driverId');
            return snapshot.docs.map((doc) {
              try {
                return LoadModel.fromDoc(doc);
              } catch (e) {
                print('❌ Error parsing load document ${doc.id}: $e');
                rethrow;
              }
            }).toList();
          })
          .handleError((error) {
            print('❌ Error streaming driver loads: $error');
            // If this is an index error, provide helpful information
            if (error.toString().contains('index')) {
              print('⚠️  Firestore index required for query: driverId + createdAt');
              print('📝 Create index at: https://console.firebase.google.com/project/_/firestore/indexes');
            }
            throw error;
          });
    } catch (e) {
      print('❌ Error setting up driver loads stream: $e');
      rethrow;
    }
  }

  /// Stream loads for a specific driver filtered by status
  /// 
  /// Returns loads assigned to the specified driver with a specific status,
  /// ordered by creation time (newest first)
  /// 
  /// Parameters:
  /// - [driverId]: Driver's unique identifier
  /// - [status]: Load status to filter by ('assigned', 'in_transit', 'delivered')
  /// 
  /// **IMPORTANT: This query requires a Firestore composite index**
  /// 
  /// If you encounter an index error at runtime, create the index immediately:
  /// 1. Copy the index creation link from the error message
  /// 2. Open it in your browser and click "Create Index"
  /// 3. Wait for index to be built (usually takes a few minutes)
  /// 
  /// Required index fields:
  /// - Collection: loads
  /// - Fields:
  ///   * driverId (Ascending)
  ///   * status (Ascending)  
  ///   * createdAt (Descending)
  /// 
  /// Index creation URL (replace PROJECT_ID):
  /// https://console.firebase.google.com/project/PROJECT_ID/firestore/indexes
  Stream<List<LoadModel>> streamDriverLoadsByStatus({
    required String driverId,
    required String status,
  }) {
    _requireAuth();
    
    print('🔍 Starting to stream loads for driver: $driverId with status: $status');
    
    try {
      return _db
          .collection('loads')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            print('📊 Received ${snapshot.docs.length} load documents for driver $driverId with status $status');
            
            if (snapshot.docs.isEmpty) {
              print('ℹ️  No loads found for driver $driverId with status $status');
            }
            
            return snapshot.docs.map((doc) {
              try {
                final load = LoadModel.fromDoc(doc);
                print('   ✓ Load ${load.loadNumber}: status=${load.status}, createdAt=${load.createdAt}');
                return load;
              } catch (e) {
                print('❌ Error parsing load document ${doc.id}: $e');
                rethrow;
              }
            }).toList();
          })
          .handleError((error) {
            print('❌ Error streaming driver loads by status: $error');
            
            // Provide helpful error message if index is missing
            if (error.toString().contains('index') || 
                error.toString().contains('requires an index')) {
              print(_getMissingIndexErrorMessage(driverId, status));
            }
            
            throw error;
          });
    } catch (e) {
      print('❌ Error setting up driver loads by status stream: $e');
      rethrow;
    }
  }

  /// Generate helpful error message for missing Firestore index
  String _getMissingIndexErrorMessage(String driverId, String status) {
    return '''
⚠️  FIRESTORE INDEX REQUIRED ⚠️

This query requires a composite index to work efficiently.

Query details:
- Collection: loads
- Filters: driverId = $driverId, status = $status
- OrderBy: createdAt (descending)

IMMEDIATE ACTION REQUIRED:
1. Check the error message above for the index creation link
2. Click the link or manually create the index at:
   https://console.firebase.google.com/project/_/firestore/indexes
3. Add a composite index with these fields (in order):
   - driverId (Ascending)
   - status (Ascending)
   - createdAt (Descending)
4. Wait for the index to build (usually 2-5 minutes)
5. Retry the operation

Alternatively, the index may already be defined in firestore.indexes.json
and just needs to be deployed using: firebase deploy --only firestore:indexes
''';
  }

  /// Get a single load's information
  /// 
  /// Returns [LoadModel] if found, null otherwise
  Future<LoadModel?> getLoad(String loadId) async {
    _requireAuth();
    final doc = await _db.collection('loads').doc(loadId).get();
    if (!doc.exists) return null;
    return LoadModel.fromDoc(doc);
  }

  /// Update load status and timestamps
  /// 
  /// Common status values: 'assigned', 'in_transit', 'delivered', 'completed'
  /// Parameters:
  /// - [loadId]: Load's document ID
  /// - [status]: New status value
  /// - [pickedUpAt]: Optional pickup timestamp
  /// - [tripStartAt]: Optional trip start timestamp
  /// - [deliveredAt]: Optional delivery timestamp
  Future<void> updateLoadStatus({
    required String loadId,
    required String status,
    DateTime? pickedUpAt,
    DateTime? tripStartAt,
    DateTime? deliveredAt,
  }) async {
    _requireAuth();
    final Map<String, dynamic> updates = {'status': status};
    if (pickedUpAt != null) updates['pickedUpAt'] = Timestamp.fromDate(pickedUpAt);
    if (tripStartAt != null) updates['tripStartAt'] = Timestamp.fromDate(tripStartAt);
    if (deliveredAt != null) updates['deliveredAt'] = Timestamp.fromDate(deliveredAt);
    await _db.collection('loads').doc(loadId).update(updates);
  }

  /// Update load with arbitrary data
  /// 
  /// Generic method for updating load document with any data map.
  /// Used primarily by sync service for offline-to-online sync operations.
  /// For specific status updates, consider using updateLoadStatus() instead.
  /// 
  /// Parameters:
  /// - [loadId]: Load's document ID
  /// - [data]: Map of fields to update
  Future<void> updateLoad(String loadId, Map<String, dynamic> data) async {
    _requireAuth();
    await _db.collection('loads').doc(loadId).update(data);
  }

  /// Mark a load as in transit
  /// 
  /// Sets status to 'in_transit' and records trip start time
  Future<void> startTrip(String loadId) async {
    _requireAuth();
    await _db.collection('loads').doc(loadId).update({
      'status': 'in_transit',
      'tripStartAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark a load as delivered
  /// 
  /// Sets status to 'delivered', records delivery time, and updates miles
  /// Parameters:
  /// - [loadId]: Load's document ID
  /// - [miles]: Final trip miles
  Future<void> endTrip(String loadId, double miles) async {
    _requireAuth();
    await _db.collection('loads').doc(loadId).update({
      'status': 'delivered',
      'tripEndAt': FieldValue.serverTimestamp(),
      'deliveredAt': FieldValue.serverTimestamp(),
      'miles': miles,
    });
  }

  /// Get count of completed loads for a driver
  /// 
  /// Counts loads with status 'delivered' or 'completed'
  Future<int> getDriverCompletedLoads(String driverId) async {
    _requireAuth();
    final snapshot = await _db
        .collection('loads')
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: ['delivered', 'completed'])
        .get();
    
    return snapshot.docs.length;
  }

  /// Stream real-time dashboard statistics
  /// 
  /// Returns a map with:
  /// - totalLoads: Total number of loads
  /// - assignedLoads: Loads with 'assigned' status
  /// - inTransitLoads: Loads with 'in_transit' status
  /// - deliveredLoads: Loads with 'delivered' status
  /// - totalRevenue: Sum of all load rates
  Stream<Map<String, dynamic>> streamDashboardStats() {
    _requireAuth();
    return _db.collection('loads').snapshots().map((snapshot) {
      final loads = snapshot.docs;
      return {
        'totalLoads': loads.length,
        'assignedLoads': loads.where((d) => d.data()['status'] == 'assigned').length,
        'inTransitLoads': loads.where((d) => d.data()['status'] == 'in_transit').length,
        'deliveredLoads': loads.where((d) => d.data()['status'] == 'delivered').length,
        'totalRevenue': loads.fold(0.0, (sum, doc) => sum + ((doc.data()['rate'] ?? 0) as num).toDouble()),
      };
    });
  }

  /// Delete a load and all associated PODs
  /// 
  /// Cascades delete to all POD documents linked to this load
  Future<void> deleteLoad(String loadId) async {
    _requireAuth();
    // Delete all PODs for this load from top-level collection
    final pods = await _db.collection('pods').where('loadId', isEqualTo: loadId).get();
    for (var doc in pods.docs) {
      await doc.reference.delete();
    }
    // Delete the load
    await _db.collection('loads').doc(loadId).delete();
  }

  // POD (Proof of Delivery) Management
  
  /// Add a new POD document
  /// 
  /// Returns the generated POD document ID
  /// Parameters:
  /// - [loadId]: Associated load's ID
  /// - [imageUrl]: Cloud Storage URL of POD image
  /// - [notes]: Optional notes about the delivery
  /// - [uploadedBy]: User ID who uploaded the POD
  Future<String> addPod({
    required String loadId,
    required String imageUrl,
    String? notes,
    required String uploadedBy,
  }) async {
    _requireAuth();
    final docRef = await _db.collection('pods').add({
      'loadId': loadId,
      'imageUrl': imageUrl,
      if (notes != null) 'notes': notes,
      'uploadedBy': uploadedBy,
      'uploadedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Stream PODs for a specific load
  /// 
  /// Returns PODs ordered by upload time (newest first)
  Stream<List<POD>> streamPods(String loadId) {
    _requireAuth();
    return _db
        .collection('pods')
        .where('loadId', isEqualTo: loadId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => POD.fromDoc(doc)).toList());
  }

  /// Delete a POD document
  Future<void> deletePod(String podId) async {
    _requireAuth();
    await _db.collection('pods').doc(podId).delete();
  }

  // Earnings and Statistics
  
  /// Calculate total earnings for a driver
  /// 
  /// Sums rates from all delivered loads
  Future<double> getDriverEarnings(String driverId) async {
    _requireAuth();
    final snapshot = await _db
        .collection('loads')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'delivered')
        .get();

    return snapshot.docs.fold<double>(0.0, (sum, doc) {
      return sum + ((doc.data()['rate'] ?? 0) as num).toDouble();
    });
  }

  /// Stream real-time earnings for a driver
  /// 
  /// Updates whenever a new load is marked as delivered
  Stream<double> streamDriverEarnings(String driverId) {
    _requireAuth();
    return _db
        .collection('loads')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'delivered')
        .snapshots()
        .map((snap) {
      double total = 0.0;
      for (var doc in snap.docs) {
        final rate = doc.data()['rate'];
        total += (rate as num?)?.toDouble() ?? 0.0;
      }
      return total;
    });
  }

  // Utilities
  
  /// Generate next sequential load number
  /// 
  /// Returns format 'LOAD-XXX' where XXX is a 3-digit number
  /// Starting from 'LOAD-001' if no loads exist
  Future<String> generateLoadNumber() async {
    _requireAuth();
    final lastLoad = await _db
        .collection('loads')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (lastLoad.docs.isEmpty) return 'LOAD-001';

    final lastNumber = lastLoad.docs.first.data()['loadNumber'] as String;
    final number = int.parse(lastNumber.split('-')[1]) + 1;
    return 'LOAD-${number.toString().padLeft(3, '0')}';
  }
}
