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

  Future<LoadModel?> getLoad(String loadId) async {
    final doc = await _db.collection('loads').doc(loadId).get();
    if (!doc.exists) return null;
    return LoadModel.fromDoc(doc);
  }

  Future<void> updateLoadStatus({
    required String loadId,
    required String status,
    DateTime? pickedUpAt,
    DateTime? tripStartedAt,
    DateTime? deliveredAt,
  }) async {
    final Map<String, dynamic> updates = {'status': status};
    if (pickedUpAt != null) updates['pickedUpAt'] = Timestamp.fromDate(pickedUpAt);
    if (tripStartedAt != null) updates['tripStartAt'] = Timestamp.fromDate(tripStartedAt);
    if (deliveredAt != null) updates['deliveredAt'] = Timestamp.fromDate(deliveredAt);
    await _db.collection('loads').doc(loadId).update(updates);
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

  Future<void> deleteLoad(String loadId) async {
    // Delete all PODs for this load
    final pods = await _db.collection('loads').doc(loadId).collection('pods').get();
    for (var doc in pods.docs) {
      await doc.reference.delete();
    }
    // Delete the load
    await _db.collection('loads').doc(loadId).delete();
  }

  // POD
  Future<void> addPod({
    required String loadId,
    required String imageUrl,
    String? notes,
    required String uploadedBy,
  }) async {
    await _db.collection('loads').doc(loadId).collection('pods').add({
      'loadId': loadId,
      'imageUrl': imageUrl,
      if (notes != null) 'notes': notes,
      'uploadedBy': uploadedBy,
      'uploadedAt': FieldValue.serverTimestamp(),
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

  Stream<double> streamDriverEarnings(String driverId) {
    return _db
        .collection('loads')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'delivered')
        .snapshots()
        .map((snap) {
      double total = 0;
      for (var doc in snap.docs) {
        total += (doc.data()['rate'] ?? 0).toDouble();
      }
      return total;
    });
  }

  // Load number generator
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
