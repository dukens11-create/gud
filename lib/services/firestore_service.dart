import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driver.dart';
import '../models/load_model.dart';
import '../models/pod.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['role'] ?? 'driver';
  }

  Stream<List<Driver>> streamDrivers() {
    return _db.collection('drivers').snapshots().map((snap) {
      return snap.docs.map((doc) => Driver.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> createDriver(Driver driver) async {
    await _db.collection('drivers').add(driver.toMap());
  }

  Future<void> createLoad(LoadModel load) async {
    await _db.collection('loads').add(load.toMap());
  }

  Stream<List<LoadModel>> streamAllLoads() {
    return _db.collection('loads').snapshots().map((snap) {
      return snap.docs.map((doc) => LoadModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Stream<List<LoadModel>> streamDriverLoads(String driverId) {
    return _db
        .collection('loads')
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => LoadModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> updateLoadStatus(String loadId, String status) async {
    await _db.collection('loads').doc(loadId).update({'status': status});
  }

  Future<void> startTrip(String loadId) async {
    await _db.collection('loads').doc(loadId).update({
      'status': 'in_transit',
      'tripStartTime': DateTime.now().toIso8601String(),
    });
  }

  Future<void> endTrip(String loadId, double miles) async {
    await _db.collection('loads').doc(loadId).update({
      'status': 'delivered',
      'tripEndTime': DateTime.now().toIso8601String(),
      'miles': miles,
    });
  }

  Future<void> addPOD(String loadId, POD pod) async {
    await _db
        .collection('loads')
        .doc(loadId)
        .collection('pods')
        .add(pod.toMap());
  }

  Stream<List<POD>> streamPODs(String loadId) {
    return _db
        .collection('loads')
        .doc(loadId)
        .collection('pods')
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => POD.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<double> getDriverEarnings(String driverId) async {
    final snap = await _db
        .collection('loads')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'delivered')
        .get();

    double total = 0;
    for (var doc in snap.docs) {
      final load = LoadModel.fromMap(doc.data(), doc.id);
      total += load.rate;
    }
    return total;
  }
}
