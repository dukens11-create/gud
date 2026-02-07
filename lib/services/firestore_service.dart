import 'package:cloud_firestore/cloud_firestore.dart';
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
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // User Management
  
  /// Get user's role from Firestore
  /// 
  /// Returns 'admin' or 'driver', defaults to 'driver' if not found
  Future<String> getUserRole(String userId) async {
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
  Future<void> createDriver({
    required String driverId,
    required String name,
    required String phone,
    required String truckNumber,
  }) async {
    await _db.collection('drivers').doc(driverId).set({
      'name': name,
      'phone': phone,
      'truckNumber': truckNumber,
      'status': 'available',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream all drivers with real-time updates
  /// 
  /// Returns a stream that emits the complete list of drivers
  /// whenever any driver document changes
  Stream<List<Driver>> streamDrivers() {
    return _db.collection('drivers').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Driver.fromMap(doc.id, doc.data())).toList(),
    );
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
    return docRef.id;
  }

  /// Stream all loads with real-time updates
  /// 
  /// Returns loads ordered by creation time (newest first)
  Stream<List<LoadModel>> streamAllLoads() {
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
  Stream<List<LoadModel>> streamDriverLoads(String driverId) {
    return _db
        .collection('loads')
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => LoadModel.fromDoc(doc)).toList());
  }

  /// Get a single load's information
  /// 
  /// Returns [LoadModel] if found, null otherwise
  Future<LoadModel?> getLoad(String loadId) async {
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
    final Map<String, dynamic> updates = {'status': status};
    if (pickedUpAt != null) updates['pickedUpAt'] = Timestamp.fromDate(pickedUpAt);
    if (tripStartAt != null) updates['tripStartAt'] = Timestamp.fromDate(tripStartAt);
    if (deliveredAt != null) updates['deliveredAt'] = Timestamp.fromDate(deliveredAt);
    await _db.collection('loads').doc(loadId).update(updates);
  }

  /// Update load with arbitrary data
  /// 
  /// Updates the load document with provided data map
  /// Parameters:
  /// - [loadId]: Load's document ID
  /// - [data]: Map of fields to update
  Future<void> updateLoad(String loadId, Map<String, dynamic> data) async {
    await _db.collection('loads').doc(loadId).update(data);
  }

  /// Mark a load as in transit
  /// 
  /// Sets status to 'in_transit' and records trip start time
  Future<void> startTrip(String loadId) async {
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
    return _db
        .collection('pods')
        .where('loadId', isEqualTo: loadId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => POD.fromDoc(doc)).toList());
  }

  /// Delete a POD document
  Future<void> deletePod(String podId) async {
    await _db.collection('pods').doc(podId).delete();
  }

  // Earnings and Statistics
  
  /// Calculate total earnings for a driver
  /// 
  /// Sums rates from all delivered loads
  Future<double> getDriverEarnings(String driverId) async {
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
