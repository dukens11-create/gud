import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gud_app/models/driver_extended.dart';

void main() {
  group('ExpirationAlert', () {
    test('constructor creates valid ExpirationAlert', () {
      final now = DateTime.now();
      final expiryDate = now.add(const Duration(days: 15));
      
      final alert = ExpirationAlert(
        id: 'alert-123',
        driverId: 'driver-456',
        documentId: 'doc-789',
        truckNumber: 'TRK-001',
        type: ExpirationAlertType.driverLicense,
        expiryDate: expiryDate,
        status: AlertStatus.pending,
        daysRemaining: 15,
        createdAt: now,
      );

      expect(alert.id, 'alert-123');
      expect(alert.driverId, 'driver-456');
      expect(alert.documentId, 'doc-789');
      expect(alert.truckNumber, 'TRK-001');
      expect(alert.type, ExpirationAlertType.driverLicense);
      expect(alert.expiryDate, expiryDate);
      expect(alert.status, AlertStatus.pending);
      expect(alert.daysRemaining, 15);
      expect(alert.createdAt, now);
    });

    test('isCritical returns true for less than 7 days', () {
      final alert = ExpirationAlert(
        id: 'alert-123',
        type: ExpirationAlertType.medicalCard,
        expiryDate: DateTime.now().add(const Duration(days: 6)),
        daysRemaining: 6,
        createdAt: DateTime.now(),
      );

      expect(alert.isCritical, true);
    });

    test('isCritical returns false for 7 or more days', () {
      final alert = ExpirationAlert(
        id: 'alert-123',
        type: ExpirationAlertType.medicalCard,
        expiryDate: DateTime.now().add(const Duration(days: 7)),
        daysRemaining: 7,
        createdAt: DateTime.now(),
      );

      expect(alert.isCritical, false);
    });

    test('priorityColor returns red for critical alerts', () {
      final alert = ExpirationAlert(
        id: 'alert-123',
        type: ExpirationAlertType.truckInsurance,
        expiryDate: DateTime.now().add(const Duration(days: 5)),
        daysRemaining: 5,
        createdAt: DateTime.now(),
      );

      expect(alert.priorityColor, 'red');
    });

    test('priorityColor returns yellow for warning alerts', () {
      final alert = ExpirationAlert(
        id: 'alert-123',
        type: ExpirationAlertType.truckRegistration,
        expiryDate: DateTime.now().add(const Duration(days: 20)),
        daysRemaining: 20,
        createdAt: DateTime.now(),
      );

      expect(alert.priorityColor, 'yellow');
    });

    test('toMap serializes ExpirationAlert correctly', () {
      final now = DateTime.now();
      final expiryDate = now.add(const Duration(days: 15));
      
      final alert = ExpirationAlert(
        id: 'alert-123',
        driverId: 'driver-456',
        type: ExpirationAlertType.driverLicense,
        expiryDate: expiryDate,
        status: AlertStatus.sent,
        daysRemaining: 15,
        createdAt: now,
        sentAt: now,
      );

      final map = alert.toMap();

      expect(map['driverId'], 'driver-456');
      expect(map['type'], 'driver_license');
      expect(map['status'], 'sent');
      expect(map['daysRemaining'], 15);
      expect(map['expiryDate'], isA<Timestamp>());
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('copyWith creates new instance with updated fields', () {
      final alert = ExpirationAlert(
        id: 'alert-123',
        type: ExpirationAlertType.medicalCard,
        expiryDate: DateTime.now().add(const Duration(days: 15)),
        daysRemaining: 15,
        status: AlertStatus.pending,
        createdAt: DateTime.now(),
      );

      final updatedAlert = alert.copyWith(
        status: AlertStatus.acknowledged,
        acknowledgedBy: 'user-123',
      );

      expect(updatedAlert.id, alert.id);
      expect(updatedAlert.status, AlertStatus.acknowledged);
      expect(updatedAlert.acknowledgedBy, 'user-123');
      expect(updatedAlert.daysRemaining, alert.daysRemaining);
    });
  });

  group('ExpirationAlertType', () {
    test('fromString returns correct type', () {
      expect(
        ExpirationAlertType.fromString('driver_license'),
        ExpirationAlertType.driverLicense,
      );
      expect(
        ExpirationAlertType.fromString('medical_card'),
        ExpirationAlertType.medicalCard,
      );
      expect(
        ExpirationAlertType.fromString('truck_registration'),
        ExpirationAlertType.truckRegistration,
      );
      expect(
        ExpirationAlertType.fromString('truck_insurance'),
        ExpirationAlertType.truckInsurance,
      );
    });

    test('fromString returns other for unknown type', () {
      expect(
        ExpirationAlertType.fromString('unknown_type'),
        ExpirationAlertType.other,
      );
    });

    test('displayName returns correct name', () {
      expect(
        ExpirationAlertType.driverLicense.displayName,
        'Driver License',
      );
      expect(
        ExpirationAlertType.medicalCard.displayName,
        'DOT Medical Card',
      );
      expect(
        ExpirationAlertType.truckRegistration.displayName,
        'Truck Registration',
      );
      expect(
        ExpirationAlertType.truckInsurance.displayName,
        'Truck Insurance',
      );
    });
  });

  group('AlertStatus', () {
    test('fromString returns correct status', () {
      expect(AlertStatus.fromString('pending'), AlertStatus.pending);
      expect(AlertStatus.fromString('sent'), AlertStatus.sent);
      expect(AlertStatus.fromString('acknowledged'), AlertStatus.acknowledged);
      expect(AlertStatus.fromString('dismissed'), AlertStatus.dismissed);
    });

    test('fromString returns pending for unknown status', () {
      expect(AlertStatus.fromString('unknown'), AlertStatus.pending);
    });

    test('displayName returns correct name', () {
      expect(AlertStatus.pending.displayName, 'Pending');
      expect(AlertStatus.sent.displayName, 'Sent');
      expect(AlertStatus.acknowledged.displayName, 'Acknowledged');
      expect(AlertStatus.dismissed.displayName, 'Dismissed');
    });
  });

  group('TruckDocument', () {
    test('constructor creates valid TruckDocument', () {
      final now = DateTime.now();
      final expiryDate = now.add(const Duration(days: 365));
      
      final doc = TruckDocument(
        id: 'doc-123',
        truckNumber: 'TRK-001',
        type: TruckDocumentType.registration,
        url: 'https://example.com/doc.pdf',
        uploadedAt: now,
        expiryDate: expiryDate,
        status: DocumentStatus.valid,
      );

      expect(doc.id, 'doc-123');
      expect(doc.truckNumber, 'TRK-001');
      expect(doc.type, TruckDocumentType.registration);
      expect(doc.url, 'https://example.com/doc.pdf');
      expect(doc.uploadedAt, now);
      expect(doc.expiryDate, expiryDate);
      expect(doc.status, DocumentStatus.valid);
    });

    test('isExpiringSoon returns true for documents expiring within 30 days', () {
      final doc = TruckDocument(
        id: 'doc-123',
        truckNumber: 'TRK-001',
        type: TruckDocumentType.insurance,
        url: 'https://example.com/doc.pdf',
        uploadedAt: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 25)),
      );

      expect(doc.isExpiringSoon, true);
    });

    test('isExpiringSoon returns false for documents expiring after 30 days', () {
      final doc = TruckDocument(
        id: 'doc-123',
        truckNumber: 'TRK-001',
        type: TruckDocumentType.registration,
        url: 'https://example.com/doc.pdf',
        uploadedAt: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 35)),
      );

      expect(doc.isExpiringSoon, false);
    });

    test('isExpired returns true for expired documents', () {
      final doc = TruckDocument(
        id: 'doc-123',
        truckNumber: 'TRK-001',
        type: TruckDocumentType.insurance,
        url: 'https://example.com/doc.pdf',
        uploadedAt: DateTime.now().subtract(const Duration(days: 400)),
        expiryDate: DateTime.now().subtract(const Duration(days: 5)),
      );

      expect(doc.isExpired, true);
    });

    test('isExpired returns false for valid documents', () {
      final doc = TruckDocument(
        id: 'doc-123',
        truckNumber: 'TRK-001',
        type: TruckDocumentType.registration,
        url: 'https://example.com/doc.pdf',
        uploadedAt: DateTime.now(),
        expiryDate: DateTime.now().add(const Duration(days: 100)),
      );

      expect(doc.isExpired, false);
    });

    test('daysUntilExpiry returns correct number of days', () {
      final expiryDate = DateTime.now().add(const Duration(days: 45));
      final doc = TruckDocument(
        id: 'doc-123',
        truckNumber: 'TRK-001',
        type: TruckDocumentType.registration,
        url: 'https://example.com/doc.pdf',
        uploadedAt: DateTime.now(),
        expiryDate: expiryDate,
      );

      expect(doc.daysUntilExpiry, 45);
    });
  });

  group('TruckDocumentType', () {
    test('fromString returns correct type', () {
      expect(
        TruckDocumentType.fromString('registration'),
        TruckDocumentType.registration,
      );
      expect(
        TruckDocumentType.fromString('insurance'),
        TruckDocumentType.insurance,
      );
      expect(
        TruckDocumentType.fromString('inspection'),
        TruckDocumentType.inspection,
      );
    });

    test('fromString returns other for unknown type', () {
      expect(
        TruckDocumentType.fromString('unknown'),
        TruckDocumentType.other,
      );
    });

    test('displayName returns correct name', () {
      expect(
        TruckDocumentType.registration.displayName,
        'Truck Registration',
      );
      expect(
        TruckDocumentType.insurance.displayName,
        'Truck Insurance',
      );
      expect(
        TruckDocumentType.inspection.displayName,
        'Truck Inspection',
      );
    });
  });
}
