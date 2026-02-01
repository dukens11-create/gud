import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/driver.dart';
import '../models/load.dart';
import '../models/pod.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user role by UID
  Future<String> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final user = AppUser.fromMap(doc.data()!);
        return user.role;
      }
      return 'driver'; // Default role
    } catch (e) {
      rethrow;
    }
  }

  // Stream all drivers
  Stream<List<Driver>> streamDrivers() {
    return _firestore.collection('drivers').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Driver.fromMap(doc.data(), doc.id)).toList();
    });
  }

  // Create driver
  Future<void> createDriver({
    required String name,
    required String phone,
    required String truckNumber,
    required String userId,
  }) async {
    try {
      await _firestore.collection('drivers').add({
        'name': name,
        'phone': phone,
        'truckNumber': truckNumber,
        'status': 'active',
        'userId': userId,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Create load
  Future<void> createLoad({
    required String loadNumber,
    required String driverId,
    required String driverName,
    required String pickupAddress,
    required String deliveryAddress,
    required double rate,
  }) async {
    try {
      await _firestore.collection('loads').add({
        'loadNumber': loadNumber,
        'driverId': driverId,
        'driverName': driverName,
        'pickupAddress': pickupAddress,
        'deliveryAddress': deliveryAddress,
        'rate': rate,
        'status': 'assigned',
        'tripStartTime': null,
        'tripEndTime': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Stream all loads (admin view)
  Stream<List<LoadModel>> streamAllLoads() {
    return _firestore
        .collection('loads')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => LoadModel.fromDoc(doc)).toList();
    });
  }

  // Stream driver-specific loads
  Stream<List<LoadModel>> streamDriverLoads(String driverId) {
    return _firestore
        .collection('loads')
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => LoadModel.fromDoc(doc)).toList();
    });
  }

  // Update load status
  Future<void> updateLoadStatus(String loadId, String status) async {
    try {
      await _firestore.collection('loads').doc(loadId).update({
        'status': status,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Start trip
  Future<void> startTrip(String loadId) async {
    try {
      await _firestore.collection('loads').doc(loadId).update({
        'status': 'in_transit',
        'tripStartTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // End trip
  Future<void> endTrip(String loadId) async {
    try {
      await _firestore.collection('loads').doc(loadId).update({
        'status': 'delivered',
        'tripEndTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Add POD to subcollection
  Future<void> addPOD({
    required String loadId,
    required String imageUrl,
    required String notes,
  }) async {
    try {
      await _firestore
          .collection('loads')
          .doc(loadId)
          .collection('pods')
          .add({
        'loadId': loadId,
        'imageUrl': imageUrl,
        'notes': notes,
        'uploadedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Stream PODs for a load
  Stream<List<POD>> streamPODs(String loadId) {
    return _firestore
        .collection('loads')
        .doc(loadId)
        .collection('pods')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => POD.fromDoc(doc)).toList();
    });
  }

  // Calculate driver earnings
  Future<double> calculateDriverEarnings(String driverId) async {
    try {
      final snapshot = await _firestore
          .collection('loads')
          .where('driverId', isEqualTo: driverId)
          .where('status', isEqualTo: 'delivered')
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final load = LoadModel.fromDoc(doc);
        total += load.rate;
      }
      return total;
    } catch (e) {
      rethrow;
    }
  }

  // Get driver by user ID
  Future<Driver?> getDriverByUserId(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('drivers')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Driver.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
