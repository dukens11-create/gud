import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get user role
  Future<String> getUserRole(String userId) async {
    DocumentSnapshot doc = await _db.collection('users').doc(userId).get();
    return doc.data()?['role'] ?? 'unknown';
  }

  // Create a new driver
  Future<void> createDriver(String userId, Map<String, dynamic> driverData) async {
    await _db.collection('drivers').doc(userId).set(driverData);
  }

  // Stream of all drivers
  Stream<List<Map<String, dynamic>>> driversStream() {
    return _db.collection('drivers').snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  // Create a new load
  Future<void> createLoad(Map<String, dynamic> loadData) async {
    await _db.collection('loads').add(loadData);
  }

  // Stream of all loads
  Stream<List<Map<String, dynamic>>> allLoadsStream() {
    return _db.collection('loads').snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  // Stream of driver loads
  Stream<List<Map<String, dynamic>>> driverLoadsStream(String driverId) {
    return _db.collection('loads').where('driverId', isEqualTo: driverId).snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  // Update load status
  Future<void> updateLoadStatus(String loadId, String status) async {
    await _db.collection('loads').doc(loadId).update({'status': status});
  }

  // Start a trip
  Future<void> startTrip(String tripId) async {
    await _db.collection('trips').doc(tripId).update({'status': 'in progress'});
  }

  // End a trip
  Future<void> endTrip(String tripId) async {
    await _db.collection('trips').doc(tripId).update({'status': 'completed'});
  }

  // Stream of pods
  Stream<List<Map<String, dynamic>>> podsStream() {
    return _db.collection('pods').snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }

  // Add a new pod
  Future<void> addPod(Map<String, dynamic> podData) async {
    await _db.collection('pods').add(podData);
  }

  // Stream of driver earnings
  Stream<List<Map<String, dynamic>>> driverEarningsStream(String driverId) {
    return _db.collection('earnings').where('driverId', isEqualTo: driverId).snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
  }
}