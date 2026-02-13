import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
  
  /// Maximum number of loads to fetch in a single query to prevent memory issues
  static const int maxLoadsLimit = 100;
  
  /// Valid load status values
  /// 
  /// **CRITICAL**: These values MUST use underscores, NOT hyphens
  /// (e.g., 'in_transit', not 'in-transit')
  /// 
  /// **Status Progression**:
  /// 1. pending    - Admin created load, awaiting driver acceptance
  /// 2. accepted   - Driver accepted the load
  /// 3. in_transit - Driver started the trip (underscore!)
  /// 4. delivered  - Load has been delivered
  /// 
  /// **Optional/Legacy**:
  /// - declined    - Driver declined the load
  /// - assigned    - Legacy status (treated like accepted for backward compatibility)
  /// - picked_up   - Legacy status (kept for historical loads)
  /// - completed   - Load fully completed
  /// - cancelled   - Load cancelled/deleted (soft delete)
  static const List<String> validLoadStatuses = [
    'pending',     // NEW: Load created, awaiting driver acceptance
    'accepted',    // NEW: Driver accepted the load
    'declined',    // NEW: Driver declined the load
    'assigned',    // Legacy: Load assigned to driver but not started
    'in_transit',  // Load currently being transported (underscore!)
    'delivered',   // Load has been delivered
    'completed',   // Load fully completed
    'picked_up',   // Legacy status - still valid for queries to support historical loads
    'cancelled',   // Load cancelled/deleted (soft delete)
  ];
  
  /// Email validation regex pattern
  static final RegExp _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  
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
    required String email,
    required String truckNumber,
  }) async {
    _requireAuth();
    
    print('🔧 Creating driver in Firestore: $driverId');
    
    if (driverId.isEmpty || name.isEmpty || phone.isEmpty || email.isEmpty || truckNumber.isEmpty) {
      throw ArgumentError('All driver fields must be non-empty');
    }
    
    // Validate email format
    if (!_emailRegex.hasMatch(email)) {
      throw ArgumentError('Invalid email address format');
    }
    
    try {
      await _db.collection('drivers').doc(driverId).set({
        'name': name,
        'phone': phone,
        'email': email,
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
  /// - [email]: Optional new email
  /// - [truckNumber]: Optional new truck number
  /// - [status]: Optional status ('available', 'on_trip', 'offline')
  /// - [isActive]: Optional active status flag
  Future<void> updateDriver({
    required String driverId,
    String? name,
    String? phone,
    String? email,
    String? truckNumber,
    String? status,
    bool? isActive,
  }) async {
    _requireAuth();
    
    // Validate email format if provided
    if (email != null && !_emailRegex.hasMatch(email)) {
      throw ArgumentError('Invalid email address format');
    }
    
    final Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (email != null) updates['email'] = email;
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
  /// - [driverId]: Assigned driver's ID (must be valid Firebase Auth UID)
  /// - [driverName]: Driver's name (denormalized for performance)
  /// - [pickupAddress]: Pickup location address
  /// - [deliveryAddress]: Delivery destination address
  /// - [rate]: Payment rate for this load
  /// - [miles]: Optional estimated miles
  /// - [notes]: Optional additional notes
  /// - [createdBy]: Admin user ID who created the load
  /// 
  /// **Validation**:
  /// - Checks for duplicate load numbers
  /// - Validates driver exists and is active
  /// - Validates all required fields are non-empty
  /// - Validates rate is non-negative
  /// 
  /// **Integration**: This is a critical admin-to-driver communication point.
  /// The driverId field MUST match the driver's Firebase Auth UID for proper
  /// load visibility on the driver's dashboard.
  /// 
  /// Throws [FirebaseAuthException] if user is not authenticated
  /// Throws [ArgumentError] if validation fails
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
    
    // Check for duplicate load number
    final isDuplicate = await loadNumberExists(loadNumber);
    if (isDuplicate) {
      throw ArgumentError('Load number $loadNumber already exists. Please use a unique load number.');
    }
    
    // Validate driver exists and is active
    final isValid = await isDriverValid(driverId);
    if (!isValid) {
      throw ArgumentError('Driver $driverId does not exist or is not active. Cannot assign load.');
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
        'status': 'pending',
        if (notes != null) 'notes': notes,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Load created successfully: ${docRef.id}');
      print('   📦 Load: $loadNumber');
      print('   👤 Driver: $driverName ($driverId)');
      print('   📍 Route: $pickupAddress → $deliveryAddress');
      print('   💰 Rate: \$$rate');
      
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
  /// Limited to most recent loads to prevent memory issues
  /// Skips documents that fail to parse instead of throwing
  Stream<List<LoadModel>> streamAllLoads() {
    _requireAuth();
    return _db
        .collection('loads')
        .orderBy('createdAt', descending: true)
        .limit(maxLoadsLimit)
        .snapshots()
        .map((snapshot) {
          final loads = <LoadModel>[];
          for (final doc in snapshot.docs) {
            try {
              loads.add(LoadModel.fromDoc(doc));
            } catch (e) {
              // Log error but continue processing other documents
              debugPrint('Warning: Failed to parse load document ${doc.id}: $e');
            }
          }
          return loads;
        });
  }

  /// Stream loads for a specific driver
  /// 
  /// Returns only loads assigned to the specified driver,
  /// ordered by creation time (newest first)
  /// 
  /// **IMPORTANT**: This query filters by `driverId` matching the authenticated driver's UID.
  /// Ensure that when assigning loads, the `driverId` field is set to the driver's Firebase Auth UID.
  /// 
  /// **Required Firestore Index**:
  /// - Collection: loads
  /// - Fields:
  ///   * driverId (Ascending)
  ///   * createdAt (Descending)
  /// 
  /// **Common Debug Steps**:
  /// 1. Verify driver is authenticated: Check that _auth.currentUser is not null
  /// 2. Check driverId matches: Ensure driverId parameter matches the Firebase Auth UID
  /// 3. Verify loads exist: Check Firestore console for loads with matching driverId
  /// 4. Check index status: Visit Firebase Console > Firestore > Indexes
  /// 5. Review logs: Look for console output starting with 🔍, 📊, or ❌
  /// 
  /// Parameters:
  /// - [driverId]: The Firebase Auth UID of the driver (must match driverId field in loads)
  Stream<List<LoadModel>> streamDriverLoads(String driverId) {
    _requireAuth();
    
    final currentUser = _auth.currentUser;
    print('🔍 Starting to stream loads for driver: $driverId');
    print('   👤 Current authenticated user UID: ${currentUser?.uid}');
    print('   🎯 Querying loads collection with filter: driverId == $driverId');
    
    try {
      return _db
          .collection('loads')
          .where('driverId', isEqualTo: driverId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            print('📊 Received ${snapshot.docs.length} load documents for driver $driverId');
            
            if (snapshot.docs.isEmpty) {
              print('ℹ️  No loads found for driver $driverId');
              print('   💡 Debug tips:');
              print('      1. Verify loads exist in Firestore with driverId = $driverId');
              print('      2. Check that load assignment sets driverId to Firebase Auth UID');
              print('      3. Ensure Firestore security rules allow driver to read their loads');
            }
            
            final loads = <LoadModel>[];
            for (final doc in snapshot.docs) {
              try {
                final load = LoadModel.fromDoc(doc);
                print('   ✓ Load ${load.loadNumber}: status=${load.status}, driverId=${load.driverId}');
                loads.add(load);
              } catch (e) {
                debugPrint('❌ Error parsing load document ${doc.id}: $e');
                // Continue processing other documents instead of crashing
              }
            }
            return loads;
          })
          .handleError((error) {
            print('❌ Error streaming driver loads: $error');
            // If this is an index error, provide helpful information
            if (error.toString().contains('index')) {
              print('⚠️  Firestore index required for query: driverId + createdAt');
              print('📝 Create index at: https://console.firebase.google.com/project/_/firestore/indexes');
            }
            // If this is a permission error, provide guidance
            if (error.toString().contains('permission') || error.toString().contains('PERMISSION_DENIED')) {
              print('⚠️  Permission denied - check Firestore security rules');
              print('   Ensure rules allow: if resource.data.driverId == request.auth.uid');
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
  /// **IMPORTANT**: This query filters by `driverId` matching the authenticated driver's UID
  /// AND by status. Ensure loads are assigned with the correct status values.
  /// 
  /// **NOTE**: This method should NOT be called with 'all' as the status value.
  /// For retrieving all loads without status filtering, use `streamDriverLoads()` instead.
  /// 
  /// Parameters:
  /// - [driverId]: Driver's Firebase Auth UID (must match driverId field in loads)
  /// - [status]: Load status to filter by. Must be one of the valid status values from
  ///   `FirestoreService.validLoadStatuses`:
  ///   * 'assigned' - Load assigned to driver but not started
  ///   * 'in_transit' - Load currently being transported (NOTE: underscore, not hyphen!)
  ///   * 'delivered' - Load has been delivered
  ///   * 'completed' - Load fully completed
  ///   * 'picked_up' - Legacy status (kept for backward compatibility)
  /// 
  /// **CRITICAL**: Status values MUST use underscores (in_transit), NOT hyphens (in-transit).
  /// Using incorrect status values will result in no loads being returned.
  /// 
  /// **Required Firestore Index**:
  /// - Collection: loads
  /// - Fields (in order):
  ///   * driverId (Ascending)
  ///   * status (Ascending)  
  ///   * createdAt (Descending)
  /// 
  /// **Common Debug Steps**:
  /// 1. Verify status value: Ensure using 'in_transit' not 'in-transit'
  /// 2. Check driverId matches: Ensure driverId parameter matches Firebase Auth UID
  /// 3. Verify loads exist: Check Firestore console for loads with matching driverId AND status
  /// 4. Check index status: Visit Firebase Console > Firestore > Indexes
  /// 5. Review logs: Look for console output showing query parameters and results
  /// 6. Test with 'all' filter: If specific status fails, try the all loads query
  /// 
  /// **If you encounter an index error**:
  /// 1. Copy the index creation link from the error message
  /// 2. Open it in your browser and click "Create Index"
  /// 3. Wait for index to be built (usually 2-5 minutes)
  /// 4. Alternatively: Run `firebase deploy --only firestore:indexes`
  /// 
  /// Index creation URL (replace PROJECT_ID):
  /// https://console.firebase.google.com/project/PROJECT_ID/firestore/indexes
  Stream<List<LoadModel>> streamDriverLoadsByStatus({
    required String driverId,
    required String status,
  }) {
    _requireAuth();
    
    final currentUser = _auth.currentUser;
    print('🔍 Starting to stream loads for driver: $driverId with status: $status');
    print('   👤 Current authenticated user UID: ${currentUser?.uid}');
    print('   🎯 Query filters: driverId == $driverId AND status == $status');
    print('   ⚠️  Status value check: "${status}" (must use underscores, e.g., "in_transit")');
    
    // Validate status value format - check against known valid values
    if (!FirestoreService.validLoadStatuses.contains(status)) {
      print('⚠️  WARNING: Unexpected status value: "$status"');
      print('   Valid values: ${FirestoreService.validLoadStatuses.join(", ")}');
      if (status.contains('-')) {
        print('   NOTE: Status contains hyphen - should use underscore (e.g., "in_transit" not "in-transit")');
      }
      print('   Query will continue but may return no results if status value is incorrect.');
    }
    
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
              print('   💡 Debug tips:');
              print('      1. Verify loads exist in Firestore with driverId = $driverId AND status = $status');
              print('      2. Check status value uses underscores (in_transit) not hyphens (in-transit)');
              print('      3. Ensure load assignment sets correct status value');
              print('      4. Verify Firestore security rules allow driver to read their loads');
              print('      5. Check Firestore indexes are deployed and enabled');
            }
            
            final loads = <LoadModel>[];
            for (final doc in snapshot.docs) {
              try {
                final load = LoadModel.fromDoc(doc);
                print('   ✓ Load ${load.loadNumber}: status=${load.status}, driverId=${load.driverId}, createdAt=${load.createdAt}');
                loads.add(load);
              } catch (e) {
                debugPrint('❌ Error parsing load document ${doc.id}: $e');
                debugPrint('   Document data: ${doc.data()}');
                // Continue processing other documents instead of crashing
              }
            }
            return loads;
          })
          .handleError((error) {
            print('❌ Error streaming driver loads by status: $error');
            
            // Provide helpful error message if index is missing
            if (error.toString().contains('index') || 
                error.toString().contains('requires an index')) {
              print(_getMissingIndexErrorMessage(driverId, status));
            }
            
            // If this is a permission error, provide guidance
            if (error.toString().contains('permission') || error.toString().contains('PERMISSION_DENIED')) {
              print('⚠️  Permission denied - check Firestore security rules');
              print('   Ensure rules allow: if resource.data.driverId == request.auth.uid');
              print('   Current user UID: ${currentUser?.uid}');
              print('   Query driverId: $driverId');
            }
            
            throw error;
          });
    } catch (e) {
      print('❌ Error setting up driver loads by status stream: $e');
      rethrow;
    }
  }

  /// Generate helpful error message for missing Firestore index
  /// 
  /// Provides detailed troubleshooting steps when a composite index is required
  /// but not available or not yet built in Firestore.
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

TROUBLESHOOTING:
- If index exists but still failing: Wait 2-5 minutes for index to finish building
- Check index status: Firebase Console > Firestore > Indexes
- Verify index configuration matches exactly (field order matters!)
- Ensure you're using correct status values (in_transit, not in-transit)
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
  /// **Admin-Driver Integration**: This method is critical for tracking load progress
  /// as drivers update status through their mobile app. Status changes are immediately
  /// visible to admins on their dashboard.
  /// 
  /// Common status values: 'assigned', 'in_transit', 'delivered', 'completed'
  /// 
  /// Parameters:
  /// - [loadId]: Load's document ID
  /// - [status]: New status value (must match validLoadStatuses)
  /// - [pickedUpAt]: Optional pickup timestamp
  /// - [tripStartAt]: Optional trip start timestamp
  /// - [deliveredAt]: Optional delivery timestamp
  /// 
  /// **Security**: Firestore rules ensure drivers can only update their own loads
  /// 
  /// Throws [ArgumentError] if status value is invalid
  Future<void> updateLoadStatus({
    required String loadId,
    required String status,
    DateTime? pickedUpAt,
    DateTime? tripStartAt,
    DateTime? deliveredAt,
  }) async {
    _requireAuth();
    
    print('📝 Updating load status: $loadId → $status');
    
    // Validate status value - throw error for invalid values
    if (!validLoadStatuses.contains(status)) {
      print('❌ Invalid status value "$status"');
      print('   Valid values: ${validLoadStatuses.join(", ")}');
      throw ArgumentError(
        'Invalid status "$status". Must be one of: ${validLoadStatuses.join(", ")}'
      );
    }
    
    final Map<String, dynamic> updates = {'status': status};
    if (pickedUpAt != null) {
      updates['pickedUpAt'] = Timestamp.fromDate(pickedUpAt);
      print('   🕐 Picked up at: $pickedUpAt');
    }
    if (tripStartAt != null) {
      updates['tripStartAt'] = Timestamp.fromDate(tripStartAt);
      print('   🚚 Trip started at: $tripStartAt');
    }
    if (deliveredAt != null) {
      updates['deliveredAt'] = Timestamp.fromDate(deliveredAt);
      print('   ✅ Delivered at: $deliveredAt');
    }
    
    try {
      await _db.collection('loads').doc(loadId).update(updates);
      print('✅ Load status updated successfully');
    } catch (e) {
      print('❌ Error updating load status: $e');
      rethrow;
    }
  }

  /// Mark load as delivered (one-tap action for drivers)
  /// 
  /// Simple wrapper for updateLoadStatus that marks a load as delivered.
  /// This provides a single-tap action for drivers to complete a delivery.
  /// 
  /// **Security**: Firestore rules ensure drivers can only update their own loads
  Future<void> markLoadAsDelivered(String loadId) async {
    _requireAuth();
    
    print('📦 Marking load as delivered: $loadId');
    
    await updateLoadStatus(
      loadId: loadId,
      status: 'delivered',
      deliveredAt: DateTime.now(),
    );
  }

  /// Accept a pending load
  /// 
  /// Changes load status from 'pending' to 'accepted' and records acceptance timestamp.
  /// This allows the driver to start the trip when ready.
  /// 
  /// Parameters:
  /// - loadId: The ID of the load to accept
  /// 
  /// Throws:
  /// - Exception if load not found or user not authenticated
  /// - Exception if load is not in pending status
  /// - Exception if user is not assigned to this load
  Future<void> acceptLoad(String loadId) async {
    _requireAuth();
    
    final loadRef = _db.collection('loads').doc(loadId);
    final loadDoc = await loadRef.get();
    
    if (!loadDoc.exists) {
      throw Exception('Load not found');
    }
    
    final loadData = loadDoc.data()!;
    
    // Verify the load is assigned to current user
    if (loadData['driverId'] != _auth.currentUser?.uid) {
      throw Exception('You are not assigned to this load');
    }
    
    // Verify load is in pending status
    if (loadData['status'] != 'pending') {
      throw Exception('This load has already been accepted or is no longer available');
    }
    
    // Update load to accepted status
    await loadRef.update({
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    debugPrint('✅ Load $loadId accepted by driver ${_auth.currentUser?.uid}');
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
  /// **Admin-Driver Integration**: Called when driver starts their trip.
  /// Sets status to 'in_transit' and records trip start time.
  /// Admin can monitor in real-time on their dashboard.
  /// 
  /// **Security**: Driver must be authenticated and own the load
  Future<void> startTrip(String loadId) async {
    _requireAuth();
    
    final currentUser = _auth.currentUser;
    print('🚚 Driver ${currentUser?.uid} starting trip for load: $loadId');
    
    try {
      await _db.collection('loads').doc(loadId).update({
        'status': 'in_transit',
        'tripStartAt': FieldValue.serverTimestamp(),
      });
      print('✅ Trip started successfully');
    } on FirebaseException catch (e) {
      print('❌ Firebase error starting trip: ${e.code}');
      if (e.code == 'permission-denied') {
        print('   ⚠️  Permission denied - driver may not own this load');
      }
      rethrow;
    } catch (e) {
      print('❌ Unexpected error starting trip: $e');
      rethrow;
    }
  }

  /// Mark a load as delivered
  /// 
  /// **Admin-Driver Integration**: Called when driver completes delivery.
  /// Sets status to 'delivered', records delivery time, and updates final miles.
  /// Triggers driver statistics update and admin notification.
  /// 
  /// Parameters:
  /// - [loadId]: Load's document ID
  /// - [miles]: Final trip miles (used for earnings calculation)
  /// 
  /// **Security**: Driver must be authenticated and own the load
  Future<void> endTrip(String loadId, double miles) async {
    _requireAuth();
    
    final currentUser = _auth.currentUser;
    print('📦 Driver ${currentUser?.uid} completing delivery for load: $loadId');
    print('   📏 Total miles: $miles');
    
    if (miles < 0) {
      throw ArgumentError('Miles cannot be negative');
    }
    
    try {
      // First, verify the load exists and get its current data
      final loadDoc = await _db.collection('loads').doc(loadId).get();
      
      if (!loadDoc.exists) {
        print('❌ Error: Load $loadId not found');
        throw FirebaseException(
          plugin: 'firestore',
          code: 'not-found',
          message: 'Load not found',
        );
      }
      
      final loadData = loadDoc.data()!;
      final loadDriverId = loadData['driverId'];
      final loadNumber = loadData['loadNumber'] ?? loadId;
      final rate = loadData['rate'] ?? 0;
      
      print('   Load number: $loadNumber');
      print('   Load driverId: $loadDriverId');
      print('   Current user UID: ${currentUser?.uid}');
      print('   Load rate: \$$rate');
      
      // Verify driver owns this load
      if (loadDriverId != currentUser?.uid) {
        print('⚠️  WARNING: Driver ID mismatch!');
        print('   Load driverId: $loadDriverId');
        print('   Current user UID: ${currentUser?.uid}');
        print('   This may cause permission issues or stats not updating');
      }
      
      await _db.collection('loads').doc(loadId).update({
        'status': 'delivered',
        'tripEndAt': FieldValue.serverTimestamp(),
        'deliveredAt': FieldValue.serverTimestamp(),
        'miles': miles,
      });
      
      print('✅ Delivery completed successfully');
      print('   Status changed to: delivered');
      print('   Timestamp: ${DateTime.now().toIso8601String()}');
      print('   ℹ️  Cloud Function "calculateEarnings" should now trigger');
      print('   Expected: drivers/${loadDriverId} will be updated with:');
      print('     - totalEarnings += \$$rate');
      print('     - completedLoads += 1');
      
      // Note: Driver statistics update should be triggered by a Cloud Function
      // or handled separately after this operation completes
    } on FirebaseException catch (e) {
      print('❌ Firebase error completing delivery: ${e.code}');
      if (e.code == 'permission-denied') {
        print('   ⚠️  Permission denied - driver may not own this load');
        print('   Check Firestore security rules');
      } else if (e.code == 'not-found') {
        print('   ⚠️  Load document not found: $loadId');
      } else {
        print('   Error message: ${e.message}');
      }
      rethrow;
    } catch (e) {
      print('❌ Unexpected error completing delivery: $e');
      rethrow;
    }
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

  /// Soft delete a load by setting its status to 'cancelled'
  /// 
  /// This marks the load as deleted without removing it from the database,
  /// preserving historical records and maintaining data integrity.
  Future<void> deleteLoad(String loadId) async {
    _requireAuth();
    try {
      await _db.collection('loads').doc(loadId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete load: $e');
    }
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

  /// Check if a load number already exists
  /// 
  /// Returns true if load number exists, false otherwise
  /// Used to prevent duplicate load number assignments
  /// 
  /// **Usage**: Call before creating a new load to ensure uniqueness
  Future<bool> loadNumberExists(String loadNumber) async {
    _requireAuth();
    
    if (loadNumber.isEmpty) {
      throw ArgumentError('Load number cannot be empty');
    }
    
    try {
      final snapshot = await _db
          .collection('loads')
          .where('loadNumber', isEqualTo: loadNumber)
          .limit(1)
          .get();
      
      final exists = snapshot.docs.isNotEmpty;
      
      if (exists) {
        print('⚠️  Load number $loadNumber already exists');
      } else {
        print('✅ Load number $loadNumber is available');
      }
      
      return exists;
    } catch (e) {
      print('❌ Error checking load number existence: $e');
      rethrow;
    }
  }

  /// Verify that a driver exists and is active
  /// 
  /// Returns true if driver exists and is active, false otherwise
  /// Throws [ArgumentError] if driverId is empty
  /// 
  /// **Usage**: Call before assigning loads to ensure driver is valid
  /// 
  /// **Integration**: Prevents orphaned loads with invalid driverIds
  /// 
  /// **Validation**: Checks BOTH isActive field and status field:
  /// - isActive must be true (defaults to true if not present)
  /// - status must NOT be 'inactive' (valid: 'available', 'on_trip')
  Future<bool> isDriverValid(String driverId) async {
    _requireAuth();
    
    if (driverId.isEmpty) {
      throw ArgumentError('Driver ID cannot be empty');
    }
    
    try {
      final doc = await _db.collection('drivers').doc(driverId).get();
      
      if (!doc.exists) {
        print('⚠️  Driver $driverId does not exist');
        return false;
      }
      
      final data = doc.data() as Map<String, dynamic>?;
      final isActive = data?['isActive'] ?? true;
      final status = data?['status'] as String?;
      
      if (!isActive) {
        print('⚠️  Driver $driverId exists but is not active (isActive=false)');
        return false;
      }
      
      if (status == 'inactive') {
        print('⚠️  Driver $driverId exists but has inactive status');
        return false;
      }
      
      print('✅ Driver $driverId is valid and active');
      return true;
    } catch (e) {
      print('❌ Error validating driver: $e');
      rethrow;
    }
  }

  /// Get count of active (non-completed) loads for a driver
  /// 
  /// Returns count of loads with status: assigned, picked_up, or in_transit
  /// Used to check driver availability before assignment
  /// 
  /// **Usage**: Check driver workload before assigning new loads
  /// 
  /// **Integration**: Helps prevent overloading drivers with too many simultaneous loads
  Future<int> getDriverActiveLoadCount(String driverId) async {
    _requireAuth();
    
    if (driverId.isEmpty) {
      throw ArgumentError('Driver ID cannot be empty');
    }
    
    try {
      final snapshot = await _db
          .collection('loads')
          .where('driverId', isEqualTo: driverId)
          .where('status', whereIn: ['assigned', 'picked_up', 'in_transit'])
          .get();
      
      final count = snapshot.docs.length;
      print('📊 Driver $driverId has $count active load(s)');
      
      return count;
    } catch (e) {
      print('❌ Error getting driver active load count: $e');
      rethrow;
    }
  }
}
