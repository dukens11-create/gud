import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driver_extended.dart';

/// Service for managing extended driver features including:
/// - Driver ratings
/// - Certifications
/// - Document verification
/// - Performance tracking
/// - Availability management
class DriverExtendedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ========== RATING SYSTEM ==========
  
  /// Submit a rating for a driver
  /// 
  /// Parameters:
  /// - [driverId]: Driver's unique identifier
  /// - [rating]: Rating value (1-5)
  /// - [loadId]: Associated load ID
  /// - [adminId]: Admin who submitted the rating
  /// - [comment]: Optional feedback comment
  Future<void> submitDriverRating({
    required String driverId,
    required double rating,
    required String loadId,
    required String adminId,
    String? comment,
  }) async {
    // Validate rating
    if (rating < 1 || rating > 5) {
      throw ArgumentError('Rating must be between 1 and 5');
    }

    // Create rating document
    await _db
        .collection('drivers')
        .doc(driverId)
        .collection('ratings')
        .add({
      'rating': rating,
      'loadId': loadId,
      'adminId': adminId,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update driver's average rating
    await _updateAverageRating(driverId);
  }

  /// Calculate and update driver's average rating
  Future<void> _updateAverageRating(String driverId) async {
    final ratingsSnapshot = await _db
        .collection('drivers')
        .doc(driverId)
        .collection('ratings')
        .get();

    if (ratingsSnapshot.docs.isEmpty) return;

    double totalRating = 0;
    for (var doc in ratingsSnapshot.docs) {
      totalRating += (doc.data()['rating'] as num).toDouble();
    }

    final averageRating = totalRating / ratingsSnapshot.docs.length;

    // Update driver document
    await _db.collection('drivers').doc(driverId).update({
      'averageRating': averageRating,
      'totalRatings': ratingsSnapshot.docs.length,
    });
  }

  /// Get driver's rating history
  Stream<List<Map<String, dynamic>>> streamDriverRatings(String driverId) {
    return _db
        .collection('drivers')
        .doc(driverId)
        .collection('ratings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  // ========== CERTIFICATION TRACKING ==========
  
  /// Add a certification for a driver
  Future<void> addCertification({
    required String driverId,
    required String certificationType,
    required String certificateNumber,
    required DateTime issueDate,
    required DateTime expiryDate,
    String? issuingAuthority,
  }) async {
    await _db
        .collection('drivers')
        .doc(driverId)
        .collection('certifications')
        .add({
      'type': certificationType,
      'certificateNumber': certificateNumber,
      'issueDate': Timestamp.fromDate(issueDate),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'issuingAuthority': issuingAuthority,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get driver's certifications
  Stream<List<Map<String, dynamic>>> streamDriverCertifications(
      String driverId) {
    return _db
        .collection('drivers')
        .doc(driverId)
        .collection('certifications')
        .orderBy('expiryDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  /// Update certification status
  Future<void> updateCertificationStatus({
    required String driverId,
    required String certificationId,
    required String status,
  }) async {
    await _db
        .collection('drivers')
        .doc(driverId)
        .collection('certifications')
        .doc(certificationId)
        .update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ========== DOCUMENT VERIFICATION ==========
  
  /// Upload driver document
  Future<String> uploadDriverDocument({
    required String driverId,
    required String documentType,
    required String url,
    required DateTime expiryDate,
  }) async {
    final docRef = await _db
        .collection('drivers')
        .doc(driverId)
        .collection('documents')
        .add({
      'driverId': driverId,
      'type': documentType,
      'url': url,
      'uploadedAt': FieldValue.serverTimestamp(),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'status': 'pending',
    });

    return docRef.id;
  }

  /// Get pending documents for verification
  Stream<List<DriverDocument>> streamPendingDocuments() {
    return _db
        .collectionGroup('documents')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => DriverDocument.fromDoc(doc)).toList());
  }

  /// Verify or reject a document
  Future<void> verifyDocument({
    required String driverId,
    required String documentId,
    required bool approved,
    required String adminId,
    String? notes,
  }) async {
    await _db
        .collection('drivers')
        .doc(driverId)
        .collection('documents')
        .doc(documentId)
        .update({
      'status': approved ? 'valid' : 'rejected',
      'verifiedBy': adminId,
      'verifiedAt': FieldValue.serverTimestamp(),
      'notes': notes,
    });
  }

  /// Get documents expiring soon (within 30 days)
  Future<List<DriverDocument>> getExpiringDocuments() async {
    final thirtyDaysFromNow =
        DateTime.now().add(const Duration(days: 30));

    final snapshot = await _db
        .collectionGroup('documents')
        .where('status', isEqualTo: 'valid')
        .where('expiryDate', isLessThan: Timestamp.fromDate(thirtyDaysFromNow))
        .get();

    return snapshot.docs.map((doc) => DriverDocument.fromDoc(doc)).toList();
  }

  // ========== AVAILABILITY MANAGEMENT ==========
  
  /// Set driver availability
  Future<void> setDriverAvailability({
    required String driverId,
    required DateTime startDate,
    required DateTime endDate,
    required bool isAvailable,
    String? reason,
  }) async {
    await _db
        .collection('drivers')
        .doc(driverId)
        .collection('availability')
        .add({
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isAvailable': isAvailable,
      'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get driver availability for a date range
  Stream<List<Map<String, dynamic>>> streamDriverAvailability({
    required String driverId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _db
        .collection('drivers')
        .doc(driverId)
        .collection('availability')
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  // ========== TRAINING & COMPLIANCE ==========
  
  /// Add training record for driver
  Future<void> addTrainingRecord({
    required String driverId,
    required String trainingName,
    required DateTime completedDate,
    DateTime? expiryDate,
    String? certificateUrl,
  }) async {
    await _db
        .collection('drivers')
        .doc(driverId)
        .collection('training')
        .add({
      'trainingName': trainingName,
      'completedDate': Timestamp.fromDate(completedDate),
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate) : null,
      'certificateUrl': certificateUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get driver training history
  Stream<List<Map<String, dynamic>>> streamDriverTraining(String driverId) {
    return _db
        .collection('drivers')
        .doc(driverId)
        .collection('training')
        .orderBy('completedDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  // ========== TRUCK MAINTENANCE ==========
  
  /// Add truck maintenance record
  Future<void> addMaintenanceRecord({
    required String driverId,
    required String truckNumber,
    required String maintenanceType,
    required DateTime serviceDate,
    required double cost,
    DateTime? nextServiceDue,
    String? serviceProvider,
    String? notes,
  }) async {
    await _db.collection('maintenance').add({
      'driverId': driverId,
      'truckNumber': truckNumber,
      'maintenanceType': maintenanceType,
      'serviceDate': Timestamp.fromDate(serviceDate),
      'cost': cost,
      'nextServiceDue':
          nextServiceDue != null ? Timestamp.fromDate(nextServiceDue) : null,
      'serviceProvider': serviceProvider,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get maintenance history for a truck
  Stream<List<Map<String, dynamic>>> streamTruckMaintenance(
      String truckNumber) {
    return _db
        .collection('maintenance')
        .where('truckNumber', isEqualTo: truckNumber)
        .orderBy('serviceDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {
                  'id': doc.id,
                  ...doc.data(),
                })
            .toList());
  }

  /// Get upcoming maintenance due
  Future<List<Map<String, dynamic>>> getUpcomingMaintenance() async {
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));

    final snapshot = await _db
        .collection('maintenance')
        .where('nextServiceDue', isGreaterThan: Timestamp.fromDate(now))
        .where('nextServiceDue',
            isLessThanOrEqualTo: Timestamp.fromDate(thirtyDaysFromNow))
        .get();

    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            })
        .toList();
  }

  // ========== PERFORMANCE DASHBOARD ==========
  
  /// Get driver performance metrics
  Future<Map<String, dynamic>> getDriverPerformanceMetrics(
      String driverId) async {
    // Get basic driver info
    final driverDoc = await _db.collection('drivers').doc(driverId).get();
    final driverData = driverDoc.data() ?? {};

    // Get ratings
    final ratingsSnapshot = await _db
        .collection('drivers')
        .doc(driverId)
        .collection('ratings')
        .get();

    // Get completed loads
    final loadsSnapshot = await _db
        .collection('loads')
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'delivered')
        .get();

    // Calculate metrics
    final totalLoads = loadsSnapshot.docs.length;
    final totalEarnings = loadsSnapshot.docs.fold<double>(
      0.0,
      (sum, doc) => sum + ((doc.data()['rate'] ?? 0) as num).toDouble(),
    );

    // On-time delivery calculation (assuming deliveryDate vs expectedDate)
    int onTimeDeliveries = 0;
    for (var load in loadsSnapshot.docs) {
      final data = load.data();
      final deliveredAt = (data['deliveredAt'] as Timestamp?)?.toDate();
      final expectedDate = (data['expectedDate'] as Timestamp?)?.toDate();
      
      if (deliveredAt != null && expectedDate != null) {
        if (deliveredAt.isBefore(expectedDate) ||
            deliveredAt.isAtSameMomentAs(expectedDate)) {
          onTimeDeliveries++;
        }
      }
    }

    final onTimeRate = totalLoads > 0 
        ? (onTimeDeliveries / totalLoads * 100).round()
        : 0;

    return {
      'driverId': driverId,
      'driverName': driverData['name'] ?? 'Unknown',
      'truckNumber': driverData['truckNumber'] ?? '',
      'averageRating': driverData['averageRating'] ?? 0.0,
      'totalRatings': ratingsSnapshot.docs.length,
      'completedLoads': totalLoads,
      'totalEarnings': totalEarnings,
      'onTimeDeliveryRate': onTimeRate,
      'status': driverData['status'] ?? 'unknown',
    };
  }

  /// Get all drivers performance summary
  Future<List<Map<String, dynamic>>> getAllDriversPerformance() async {
    final driversSnapshot = await _db.collection('drivers').get();
    
    final performanceList = <Map<String, dynamic>>[];
    
    for (var driverDoc in driversSnapshot.docs) {
      try {
        final metrics = await getDriverPerformanceMetrics(driverDoc.id);
        performanceList.add(metrics);
      } catch (e) {
        // Skip drivers with errors
        continue;
      }
    }

    return performanceList;
  }
}
