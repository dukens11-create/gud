import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/driver_extended.dart';
import '../utils/datetime_utils.dart';

/// Service for managing extended driver features including:
/// - Driver ratings
/// - Certifications
/// - Document verification
/// - Performance tracking
/// - Availability management
/// 
/// **Security**: All methods verify user authentication before executing queries.
class DriverExtendedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _requireAuth() {
    if (_auth.currentUser == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message: 'User must be signed in to access driver data',
      );
    }
  }

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
    _requireAuth();
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
    _requireAuth();
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
    _requireAuth();
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
    _requireAuth();
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
    _requireAuth();
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
    _requireAuth();
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
    _requireAuth();
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
    _requireAuth();
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
    _requireAuth();
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
    _requireAuth();
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
    _requireAuth();
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
    _requireAuth();
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
    _requireAuth();
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
    _requireAuth();
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
    _requireAuth();
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
    _requireAuth();
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
    _requireAuth();
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
    _requireAuth();
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
      final deliveredAt = DateTimeUtils.parseDateTime(data['deliveredAt']);
      final expectedDate = DateTimeUtils.parseDateTime(data['expectedDate']);
      
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
    _requireAuth();
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

  // ========== TRUCK DOCUMENT MANAGEMENT ==========
  
  /// Upload truck document
  Future<String> uploadTruckDocument({
    required String truckNumber,
    required String documentType,
    required String url,
    required DateTime expiryDate,
  }) async {
    _requireAuth();
    final docRef = await _db
        .collection('trucks')
        .doc(truckNumber)
        .collection('documents')
        .add({
      'truckNumber': truckNumber,
      'type': documentType,
      'url': url,
      'uploadedAt': FieldValue.serverTimestamp(),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'status': 'pending',
    });

    return docRef.id;
  }

  /// Get truck documents expiring soon (within 30 days)
  Future<List<TruckDocument>> getExpiringTruckDocuments() async {
    _requireAuth();
    final thirtyDaysFromNow =
        DateTime.now().add(const Duration(days: 30));

    final snapshot = await _db
        .collectionGroup('documents')
        .where('truckNumber', isNotEqualTo: null)
        .where('status', isEqualTo: 'valid')
        .where('expiryDate', isLessThan: Timestamp.fromDate(thirtyDaysFromNow))
        .get();

    return snapshot.docs.map((doc) => TruckDocument.fromDoc(doc)).toList();
  }

  /// Stream truck documents for a specific truck
  Stream<List<TruckDocument>> streamTruckDocuments(String truckNumber) {
    _requireAuth();
    return _db
        .collection('trucks')
        .doc(truckNumber)
        .collection('documents')
        .orderBy('expiryDate')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TruckDocument.fromDoc(doc)).toList());
  }

  // ========== EXPIRATION ALERT MANAGEMENT ==========
  
  /// Create expiration alert
  Future<String> createExpirationAlert({
    String? driverId,
    String? documentId,
    String? truckNumber,
    required ExpirationAlertType type,
    required DateTime expiryDate,
  }) async {
    _requireAuth();
    final daysRemaining = expiryDate.difference(DateTime.now()).inDays;
    
    final docRef = await _db.collection('expiration_alerts').add({
      'driverId': driverId,
      'documentId': documentId,
      'truckNumber': truckNumber,
      'type': type.value,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'status': 'pending',
      'daysRemaining': daysRemaining,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Get all active expiration alerts
  Stream<List<ExpirationAlert>> streamExpirationAlerts() {
    _requireAuth();
    return _db
        .collection('expiration_alerts')
        .where('status', whereIn: ['pending', 'sent'])
        .orderBy('expiryDate')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ExpirationAlert.fromDoc(doc)).toList());
  }

  /// Get expiration alerts for a specific driver
  Stream<List<ExpirationAlert>> streamDriverExpirationAlerts(String driverId) {
    _requireAuth();
    return _db
        .collection('expiration_alerts')
        .where('driverId', isEqualTo: driverId)
        .where('status', whereIn: ['pending', 'sent'])
        .orderBy('expiryDate')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ExpirationAlert.fromDoc(doc)).toList());
  }

  /// Acknowledge expiration alert
  Future<void> acknowledgeExpirationAlert({
    required String alertId,
    required String userId,
  }) async {
    _requireAuth();
    await _db.collection('expiration_alerts').doc(alertId).update({
      'status': 'acknowledged',
      'acknowledgedAt': FieldValue.serverTimestamp(),
      'acknowledgedBy': userId,
    });
  }

  /// Dismiss expiration alert
  Future<void> dismissExpirationAlert(String alertId) async {
    _requireAuth();
    await _db.collection('expiration_alerts').doc(alertId).update({
      'status': 'dismissed',
    });
  }

  /// Get expiration alert summary for admin dashboard
  Future<Map<String, dynamic>> getExpirationAlertSummary() async {
    _requireAuth();
    final alertsSnapshot = await _db
        .collection('expiration_alerts')
        .where('status', whereIn: ['pending', 'sent'])
        .get();

    final alerts = alertsSnapshot.docs
        .map((doc) => ExpirationAlert.fromDoc(doc))
        .toList();

    int criticalCount = 0;
    int warningCount = 0;
    
    for (var alert in alerts) {
      if (alert.isCritical) {
        criticalCount++;
      } else {
        warningCount++;
      }
    }

    return {
      'totalAlerts': alerts.length,
      'criticalAlerts': criticalCount,
      'warningAlerts': warningCount,
      'alerts': alerts,
    };
  }

  /// Update days remaining for all active alerts
  Future<void> updateAlertsRemainingDays() async {
    _requireAuth();
    final alertsSnapshot = await _db
        .collection('expiration_alerts')
        .where('status', whereIn: ['pending', 'sent'])
        .get();

    final batch = _db.batch();
    
    for (var doc in alertsSnapshot.docs) {
      final alert = ExpirationAlert.fromDoc(doc);
      final daysRemaining = alert.expiryDate.difference(DateTime.now()).inDays;
      
      batch.update(doc.reference, {'daysRemaining': daysRemaining});
    }

    await batch.commit();
  }
}
