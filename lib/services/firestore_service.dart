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

  Future<Driver?> getDriver(String driverId) async {
    final doc = await _db.collection('drivers').doc(driverId).get();
    if (!doc.exists) return null;
    return Driver.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

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
    DateTime? tripStartAt,
    DateTime? deliveredAt,
  }) async {
    final Map<String, dynamic> updates = {'status': status};
    if (pickedUpAt != null) updates['pickedUpAt'] = Timestamp.fromDate(pickedUpAt);
    if (tripStartAt != null) updates['tripStartAt'] = Timestamp.fromDate(tripStartAt);
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

  Future<int> getDriverCompletedLoads(String driverId) async {
    final snapshot = await _db
        .collection('loads')
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: ['delivered', 'completed'])
        .get();
    
    return snapshot.docs.length;
  }

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

  Future<void> deleteLoad(String loadId) async {
    // Delete all PODs for this load from top-level collection
    final pods = await _db.collection('pods').where('loadId', isEqualTo: loadId).get();
    for (var doc in pods.docs) {
      await doc.reference.delete();
    }
    // Delete the load
    await _db.collection('loads').doc(loadId).delete();
  }

  // POD - Using top-level pods collection
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

  Stream<List<POD>> streamPods(String loadId) {
    return _db
        .collection('pods')
        .where('loadId', isEqualTo: loadId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => POD.fromDoc(doc)).toList());
  }

  Future<void> deletePod(String podId) async {
    await _db.collection('pods').doc(podId).delete();
  }

  // Earnings
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
