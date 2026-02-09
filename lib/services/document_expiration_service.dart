import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driver_extended.dart';
import 'driver_extended_service.dart';
import 'notification_service.dart';

/// Document Expiration Monitoring Service
/// 
/// Handles:
/// - Periodic checking of document expiration dates
/// - Creating expiration alerts
/// - Sending notifications for expiring documents
/// - Monitoring driver licenses, medical cards, truck registration, and insurance
class DocumentExpirationService {
  static final DocumentExpirationService _instance = 
      DocumentExpirationService._internal();
  factory DocumentExpirationService() => _instance;
  DocumentExpirationService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DriverExtendedService _driverService = DriverExtendedService();
  final NotificationService _notificationService = NotificationService();

  Timer? _checkTimer;
  bool _isMonitoring = false;

  /// Start monitoring document expirations
  /// Runs daily check at midnight
  void startMonitoring() {
    if (_isMonitoring) {
      print('⚠️ Document expiration monitoring already running');
      return;
    }

    print('✅ Starting document expiration monitoring');
    _isMonitoring = true;

    // Run initial check immediately
    _checkExpiringDocuments();

    // Schedule daily checks (every 24 hours)
    _checkTimer = Timer.periodic(const Duration(hours: 24), (_) {
      _checkExpiringDocuments();
    });
  }

  /// Stop monitoring
  void stopMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _isMonitoring = false;
    print('✅ Document expiration monitoring stopped');
  }

  /// Check for expiring documents and create alerts
  Future<void> _checkExpiringDocuments() async {
    print('🔍 Checking for expiring documents...');
    
    try {
      // Update days remaining for existing alerts
      await _driverService.updateAlertsRemainingDays();

      // Check driver documents
      await _checkDriverDocuments();

      // Check truck documents
      await _checkTruckDocuments();

      print('✅ Document expiration check completed');
    } catch (e) {
      print('❌ Error checking expiring documents: $e');
    }
  }

  /// Check driver documents for expiration
  Future<void> _checkDriverDocuments() async {
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));

    // Get all drivers
    final driversSnapshot = await _db.collection('drivers').get();

    for (var driverDoc in driversSnapshot.docs) {
      final driverId = driverDoc.id;
      final driverData = driverDoc.data();

      // Check driver license expiration
      final licenseExpiry = (driverData['licenseExpiry'] as Timestamp?)?.toDate();
      if (licenseExpiry != null && 
          licenseExpiry.isAfter(now) && 
          licenseExpiry.isBefore(thirtyDaysFromNow)) {
        await _createOrUpdateAlert(
          driverId: driverId,
          type: ExpirationAlertType.driverLicense,
          expiryDate: licenseExpiry,
        );
      }

      // Check driver documents (medical cards, etc.)
      final documentsSnapshot = await _db
          .collection('drivers')
          .doc(driverId)
          .collection('documents')
          .where('status', isEqualTo: 'valid')
          .where('expiryDate', isGreaterThan: Timestamp.fromDate(now))
          .where('expiryDate', isLessThan: Timestamp.fromDate(thirtyDaysFromNow))
          .get();

      for (var docSnapshot in documentsSnapshot.docs) {
        final document = DriverDocument.fromDoc(docSnapshot);
        
        ExpirationAlertType alertType;
        switch (document.type) {
          case DocumentType.medicalCard:
            alertType = ExpirationAlertType.medicalCard;
            break;
          case DocumentType.license:
            alertType = ExpirationAlertType.driverLicense;
            break;
          case DocumentType.certification:
            alertType = ExpirationAlertType.certification;
            break;
          default:
            alertType = ExpirationAlertType.other;
        }

        await _createOrUpdateAlert(
          driverId: driverId,
          documentId: document.id,
          type: alertType,
          expiryDate: document.expiryDate,
        );
      }
    }
  }

  /// Check truck documents for expiration
  Future<void> _checkTruckDocuments() async {
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));

    // Get all truck documents that are expiring
    final trucksSnapshot = await _db.collection('trucks').get();

    for (var truckDoc in trucksSnapshot.docs) {
      final truckNumber = truckDoc.id;

      final documentsSnapshot = await _db
          .collection('trucks')
          .doc(truckNumber)
          .collection('documents')
          .where('status', isEqualTo: 'valid')
          .where('expiryDate', isGreaterThan: Timestamp.fromDate(now))
          .where('expiryDate', isLessThan: Timestamp.fromDate(thirtyDaysFromNow))
          .get();

      for (var docSnapshot in documentsSnapshot.docs) {
        final document = TruckDocument.fromDoc(docSnapshot);
        
        ExpirationAlertType alertType;
        switch (document.type) {
          case TruckDocumentType.registration:
            alertType = ExpirationAlertType.truckRegistration;
            break;
          case TruckDocumentType.insurance:
            alertType = ExpirationAlertType.truckInsurance;
            break;
          default:
            alertType = ExpirationAlertType.other;
        }

        // Get driver assigned to this truck
        final driversSnapshot = await _db
            .collection('drivers')
            .where('truckNumber', isEqualTo: truckNumber)
            .limit(1)
            .get();

        final driverId = driversSnapshot.docs.isNotEmpty 
            ? driversSnapshot.docs.first.id 
            : null;

        await _createOrUpdateAlert(
          driverId: driverId,
          documentId: document.id,
          truckNumber: truckNumber,
          type: alertType,
          expiryDate: document.expiryDate,
        );
      }
    }
  }

  /// Create or update an expiration alert
  Future<void> _createOrUpdateAlert({
    String? driverId,
    String? documentId,
    String? truckNumber,
    required ExpirationAlertType type,
    required DateTime expiryDate,
  }) async {
    // Check if alert already exists
    Query existingAlertQuery = _db
        .collection('expiration_alerts')
        .where('type', isEqualTo: type.value)
        .where('expiryDate', isEqualTo: Timestamp.fromDate(expiryDate));

    if (driverId != null) {
      existingAlertQuery = existingAlertQuery.where('driverId', isEqualTo: driverId);
    }
    if (documentId != null) {
      existingAlertQuery = existingAlertQuery.where('documentId', isEqualTo: documentId);
    }
    if (truckNumber != null) {
      existingAlertQuery = existingAlertQuery.where('truckNumber', isEqualTo: truckNumber);
    }

    final existingAlerts = await existingAlertQuery.get();

    if (existingAlerts.docs.isEmpty) {
      // Create new alert
      final alertId = await _driverService.createExpirationAlert(
        driverId: driverId,
        documentId: documentId,
        truckNumber: truckNumber,
        type: type,
        expiryDate: expiryDate,
      );

      print('✅ Created expiration alert: $alertId for ${type.displayName}');

      // Send notification
      await _sendExpirationNotification(
        driverId: driverId,
        type: type,
        expiryDate: expiryDate,
        truckNumber: truckNumber,
      );
    } else {
      // Update existing alert's days remaining
      final alertDoc = existingAlerts.docs.first;
      final daysRemaining = expiryDate.difference(DateTime.now()).inDays;
      
      await _db.collection('expiration_alerts').doc(alertDoc.id).update({
        'daysRemaining': daysRemaining,
      });
    }
  }

  /// Send expiration notification
  Future<void> _sendExpirationNotification({
    String? driverId,
    required ExpirationAlertType type,
    required DateTime expiryDate,
    String? truckNumber,
  }) async {
    final daysRemaining = expiryDate.difference(DateTime.now()).inDays;
    
    String title = '📄 Document Expiring Soon';
    String body = '${type.displayName} expires in $daysRemaining days';
    
    if (truckNumber != null) {
      body += ' for truck $truckNumber';
    }

    // Determine channel - use expiration_alerts for all expiration notifications
    String channelId = 'expiration_alerts';

    // Send notification to specific driver if available
    if (driverId != null) {
      try {
        final userDoc = await _db
            .collection('users')
            .where('driverId', isEqualTo: driverId)
            .limit(1)
            .get();

        if (userDoc.docs.isNotEmpty) {
          // In production, this would use Cloud Functions to send FCM
          print('📧 Sending notification to driver: $driverId');
        }
      } catch (e) {
        print('❌ Error sending notification: $e');
      }
    }

    // Also notify admins via topic
    print('📧 Notifying admins about ${type.displayName} expiring in $daysRemaining days');
  }

  /// Manual trigger for checking documents (useful for testing)
  Future<void> checkNow() async {
    print('🔍 Manual document expiration check triggered');
    await _checkExpiringDocuments();
  }

  /// Get monitoring status
  bool get isMonitoring => _isMonitoring;
}
