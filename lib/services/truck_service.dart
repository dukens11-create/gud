import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/truck.dart';

/// Service for managing truck operations
/// 
/// Provides CRUD operations for trucks and driver-truck assignment management
/// 
/// **Security**: All methods verify user authentication before executing queries.
class TruckService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _requireAuth() {
    if (_auth.currentUser == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message: 'User must be signed in to access truck data',
      );
    }
  }

  // ========== CRUD OPERATIONS ==========

  /// Create a new truck
  Future<String> createTruck(Truck truck) async {
    _requireAuth();

    // Check if truck number already exists
    final existing = await getTruckByNumber(truck.truckNumber);
    if (existing != null) {
      throw Exception('Truck number ${truck.truckNumber} already exists');
    }

    // Ensure truck has a valid status
    final validatedTruck = truck.copyWith(
      status: Truck.normalizeStatus(truck.status),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final docRef = await _db.collection('trucks').add(validatedTruck.toMap());
    return docRef.id;
  }

  /// Update an existing truck
  Future<void> updateTruck(String truckId, Truck truck) async {
    _requireAuth();

    // If truck number changed, check if new number already exists
    final currentTruck = await getTruck(truckId);
    if (currentTruck != null && 
        currentTruck.truckNumber != truck.truckNumber) {
      final existing = await getTruckByNumber(truck.truckNumber);
      if (existing != null && existing.id != truckId) {
        throw Exception('Truck number ${truck.truckNumber} already exists');
      }
    }

    await _db.collection('trucks').doc(truckId).update(
      truck.copyWith(updatedAt: DateTime.now()).toMap(),
    );
  }

  /// Toggle truck status between 'in_use' and 'available'
  /// This is a simple one-tap action for users to quickly update truck status
  Future<void> toggleTruckStatus(String truckId) async {
    _requireAuth();

    final truck = await getTruck(truckId);
    if (truck == null) {
      throw Exception('Truck not found');
    }

    // Don't allow toggling for trucks in maintenance or inactive status
    if (truck.status == 'maintenance' || truck.status == 'inactive') {
      throw Exception('Cannot toggle status for trucks in ${truck.status} state');
    }

    // Toggle between in_use and available
    final newStatus = truck.status == 'in_use' ? 'available' : 'in_use';

    await _db.collection('trucks').doc(truckId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Check if truck has active loads
  /// 
  /// Returns the count of active loads assigned to the driver currently using this truck.
  /// Active loads are those with status: assigned, accepted, in_transit, or picked_up.
  Future<int> getTruckActiveLoadCount(String truckId) async {
    _requireAuth();
    
    final truck = await getTruck(truckId);
    if (truck == null || truck.assignedDriverId == null) {
      return 0;
    }
    
    // Check for active loads assigned to the driver using this truck
    final snapshot = await _db
        .collection('loads')
        .where('driverId', isEqualTo: truck.assignedDriverId)
        .where('status', whereIn: ['assigned', 'accepted', 'in_transit', 'picked_up'])
        .get();
        
    return snapshot.docs.length;
  }

  /// Soft delete a truck (set status to inactive)
  Future<void> deleteTruck(String truckId) async {
    _requireAuth();

    // Unassign driver if assigned
    final truck = await getTruck(truckId);
    if (truck?.assignedDriverId != null) {
      await unassignDriver(truckId);
    }

    await _db.collection('trucks').doc(truckId).update({
      'status': 'inactive',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get a single truck by ID
  Future<Truck?> getTruck(String truckId) async {
    _requireAuth();

    final doc = await _db.collection('trucks').doc(truckId).get();
    if (!doc.exists) return null;

    return Truck.fromMap(doc.id, doc.data()!);
  }

  /// Get truck by truck number
  Future<Truck?> getTruckByNumber(String truckNumber) async {
    _requireAuth();

    final snapshot = await _db
        .collection('trucks')
        .where('truckNumber', isEqualTo: truckNumber)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return Truck.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());
  }

  /// Stream all trucks (excluding inactive)
  /// 
  /// Uses in-memory filtering to avoid requiring additional composite indexes.
  /// This ensures trucks with null, empty, or other status values are still loaded
  /// and can be properly displayed or filtered.
  Stream<List<Truck>> streamTrucks({bool includeInactive = false}) {
    _requireAuth();

    // Get all trucks and filter in-memory to avoid index issues
    return _db.collection('trucks')
        .orderBy('truckNumber')
        .snapshots()
        .map((snapshot) {
          final trucks = snapshot.docs
              .map((doc) => Truck.fromMap(doc.id, doc.data()))
              .toList();
          
          if (!includeInactive) {
            // Filter out inactive trucks in-memory
            return trucks.where((truck) => truck.status != 'inactive').toList();
          }
          
          return trucks;
        });
  }

  /// Stream available trucks only
  Stream<List<Truck>> streamAvailableTrucks() {
    _requireAuth();

    return _db
        .collection('trucks')
        .where('status', isEqualTo: 'available')
        .orderBy('truckNumber')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Truck.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ========== DRIVER-TRUCK ASSIGNMENT ==========

  /// Assign a driver to a truck
  Future<void> assignDriver({
    required String truckId,
    required String driverId,
    required String driverName,
  }) async {
    _requireAuth();

    final truck = await getTruck(truckId);
    if (truck == null) {
      throw Exception('Truck not found');
    }

    if (truck.status == 'inactive') {
      throw Exception('Cannot assign driver to inactive truck');
    }

    if (truck.status == 'maintenance') {
      throw Exception('Cannot assign driver to truck in maintenance');
    }

    // If truck is already assigned to another driver, unassign first
    if (truck.assignedDriverId != null && truck.assignedDriverId != driverId) {
      await unassignDriver(truckId);
    }

    // Update truck with driver assignment
    await _db.collection('trucks').doc(truckId).update({
      'assignedDriverId': driverId,
      'assignedDriverName': driverName,
      'status': 'in_use',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update driver with truck assignment (maintain consistency)
    await _db.collection('drivers').doc(driverId).update({
      'truckNumber': truck.truckNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Unassign driver from a truck
  Future<void> unassignDriver(String truckId) async {
    _requireAuth();

    final truck = await getTruck(truckId);
    if (truck == null) return;

    // Update truck to remove driver assignment
    await _db.collection('trucks').doc(truckId).update({
      'assignedDriverId': null,
      'assignedDriverName': null,
      'status': 'available',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // If driver was assigned, clear their truck number
    if (truck.assignedDriverId != null) {
      try {
        await _db.collection('drivers').doc(truck.assignedDriverId).update({
          'truckNumber': '',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // Driver might not exist anymore, ignore error
      }
    }
  }

  /// Get truck assigned to a driver
  Future<Truck?> getTruckByDriverId(String driverId) async {
    _requireAuth();

    final snapshot = await _db
        .collection('trucks')
        .where('assignedDriverId', isEqualTo: driverId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return Truck.fromMap(snapshot.docs.first.id, snapshot.docs.first.data());
  }

  /// Stream truck assigned to a driver (for real-time updates)
  Stream<Truck?> getTruckByDriverIdStream(String driverId) {
    _requireAuth();

    return _db
        .collection('trucks')
        .where('assignedDriverId', isEqualTo: driverId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      
      final data = snapshot.docs.first.data();
      if (data == null) return null;
      
      return Truck.fromMap(snapshot.docs.first.id, data);
    });
  }

  // ========== UTILITY METHODS ==========

  /// Generate next available truck number
  Future<String> generateNextTruckNumber() async {
    _requireAuth();

    final snapshot = await _db
        .collection('trucks')
        .orderBy('truckNumber', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return 'TRK-001';
    }

    final lastTruckNumber = snapshot.docs.first.data()['truckNumber'] as String;
    final match = RegExp(r'TRK-(\d+)').firstMatch(lastTruckNumber);

    if (match != null) {
      final number = int.parse(match.group(1)!);
      final nextNumber = number + 1;
      return 'TRK-${nextNumber.toString().padLeft(3, '0')}';
    }

    return 'TRK-001';
  }

  /// Validate truck number format
  bool validateTruckNumberFormat(String truckNumber) {
    final regex = RegExp(r'^TRK-\d{3}$');
    return regex.hasMatch(truckNumber);
  }

  /// Get truck statistics
  Future<Map<String, int>> getTruckStatistics() async {
    _requireAuth();

    final snapshot = await _db.collection('trucks').get();

    int available = 0;
    int inUse = 0;
    int maintenance = 0;
    int inactive = 0;

    for (var doc in snapshot.docs) {
      final status = doc.data()['status'] as String;
      switch (status) {
        case 'available':
          available++;
          break;
        case 'in_use':
          inUse++;
          break;
        case 'maintenance':
          maintenance++;
          break;
        case 'inactive':
          inactive++;
          break;
      }
    }

    return {
      'total': snapshot.docs.length,
      'available': available,
      'inUse': inUse,
      'maintenance': maintenance,
      'inactive': inactive,
    };
  }
}
