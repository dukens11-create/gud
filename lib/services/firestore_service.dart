import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driver.dart';
import '../models/load.dart';
import '../models/pod.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // User role
  Future<String> getUserRole(String userId) async {
    DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
    return (doc.data() as Map<String, dynamic>?)?['role'] ?? 'driver';
  }

  // Drivers
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

  Stream<List<Driver>> streamDrivers() {
    return _db.collection('drivers').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Driver.fromMap(doc.id, doc.data())).toList(),
    );
  }

  // Loads
  Future<void> createLoad({
    required String loadNumber,
    required String driverId,
    required String pickupAddress,
    required String deliveryAddress,
    required double rate,
  }) async {
    await _db.collection('loads').add({
      'loadNumber': loadNumber,
      'driverId': driverId,
      'pickupAddress': pickupAddress,
      'deliveryAddress': deliveryAddress,
      'rate': rate,
      'status': 'assigned',
      'miles': 0.0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<LoadModel>> streamAllLoads() {
    return _db
        .collection('loads')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => LoadModel.fromDoc(doc)).toList());
  }

  Stream<List<LoadModel>> streamDriverLoads(String driverId) {
    return _db
        .collection('loads')
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => LoadModel.fromDoc(doc)).toList());
  }

  Future<void> updateLoadStatus(String loadId, String status) async {
    await _db.collection('loads').doc(loadId).update({'status': status});
  }

  Future<void> startTrip(String loadId) async {
    await _db.collection('loads').doc(loadId).update({
      'status': 'in_transit',
      'tripStartAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> endTrip(String loadId, double miles) async {
    await _db.collection('loads').doc(loadId).update({
      'status': 'delivered',
      'tripEndAt': FieldValue.serverTimestamp(),
      'deliveredAt': FieldValue.serverTimestamp(),
      'miles': miles,
    });
  }

  // POD
  Future<void> addPod(String loadId, String imageUrl, String notes) async {
    await _db.collection('loads').doc(loadId).collection('pods').add({
      'imageUrl': imageUrl,
      'uploadedAt': FieldValue.serverTimestamp(),
      'notes': notes,
    });
  }

  Stream<List<POD>> streamPods(String loadId) {
    return _db
        .collection('loads')
        .doc(loadId)
        .collection('pods')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => POD.fromDoc(doc)).toList());
  }

  // Earnings
  Future<double> getDriverEarnings(String driverId) async {
    final snapshot = await _db
        .collection('loads')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'delivered')
        .get();

    return snapshot.docs.fold(0.0, (sum, doc) {
      return sum + ((doc.data()['rate'] ?? 0) as num).toDouble();
    });
  }
}
