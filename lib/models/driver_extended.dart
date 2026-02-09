import 'package:cloud_firestore/cloud_firestore.dart';

/// Extended Driver Model
/// 
/// Comprehensive driver information including:
/// - Basic info (name, phone, truck)
/// - License and certifications
/// - Documents and expiration tracking
/// - Status management
/// - Performance metrics
/// - Location tracking
class DriverExtended {
  final String id;
  final String name;
  final String phone;
  final String truckNumber;
  final String userId;
  
  // Status
  final DriverStatus status;
  final DateTime? statusUpdatedAt;
  final DateTime? lastActiveAt;
  
  // License information
  final String? licenseNumber;
  final DateTime? licenseExpiry;
  final String? cdlClass; // Class A, B, or C
  final List<String> endorsements; // H, N, P, S, T, X
  
  // Location
  final Map<String, dynamic>? lastLocation;
  final DateTime? lastLocationUpdate;
  
  // Performance metrics
  final double averageRating;
  final int completedLoads;
  final double totalMiles;
  final int onTimeDeliveryRate; // percentage
  
  // Timestamps
  final DateTime createdAt;
  final DateTime? updatedAt;

  DriverExtended({
    required this.id,
    required this.name,
    required this.phone,
    required this.truckNumber,
    required this.userId,
    this.status = DriverStatus.available,
    this.statusUpdatedAt,
    this.lastActiveAt,
    this.licenseNumber,
    this.licenseExpiry,
    this.cdlClass,
    this.endorsements = const [],
    this.lastLocation,
    this.lastLocationUpdate,
    this.averageRating = 0.0,
    this.completedLoads = 0,
    this.totalMiles = 0.0,
    this.onTimeDeliveryRate = 0,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create from Firestore document
  factory DriverExtended.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return DriverExtended(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      truckNumber: data['truckNumber'] ?? '',
      userId: data['userId'] ?? '',
      status: DriverStatus.fromString(data['status'] ?? 'available'),
      statusUpdatedAt: (data['statusUpdatedAt'] as Timestamp?)?.toDate(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate(),
      licenseNumber: data['licenseNumber'],
      licenseExpiry: (data['licenseExpiry'] as Timestamp?)?.toDate(),
      cdlClass: data['cdlClass'],
      endorsements: List<String>.from(data['endorsements'] ?? []),
      lastLocation: data['lastLocation'],
      lastLocationUpdate: (data['lastLocationUpdate'] as Timestamp?)?.toDate(),
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      completedLoads: data['completedLoads'] ?? 0,
      totalMiles: (data['totalMiles'] ?? 0.0).toDouble(),
      onTimeDeliveryRate: data['onTimeDeliveryRate'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'truckNumber': truckNumber,
      'userId': userId,
      'status': status.value,
      'statusUpdatedAt': statusUpdatedAt != null 
          ? Timestamp.fromDate(statusUpdatedAt!) 
          : null,
      'lastActiveAt': lastActiveAt != null 
          ? Timestamp.fromDate(lastActiveAt!) 
          : null,
      'licenseNumber': licenseNumber,
      'licenseExpiry': licenseExpiry != null 
          ? Timestamp.fromDate(licenseExpiry!) 
          : null,
      'cdlClass': cdlClass,
      'endorsements': endorsements,
      'lastLocation': lastLocation,
      'lastLocationUpdate': lastLocationUpdate != null 
          ? Timestamp.fromDate(lastLocationUpdate!) 
          : null,
      'averageRating': averageRating,
      'completedLoads': completedLoads,
      'totalMiles': totalMiles,
      'onTimeDeliveryRate': onTimeDeliveryRate,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
  }

  /// Copy with updated fields
  DriverExtended copyWith({
    String? name,
    String? phone,
    String? truckNumber,
    DriverStatus? status,
    DateTime? statusUpdatedAt,
    DateTime? lastActiveAt,
    String? licenseNumber,
    DateTime? licenseExpiry,
    String? cdlClass,
    List<String>? endorsements,
    Map<String, dynamic>? lastLocation,
    DateTime? lastLocationUpdate,
    double? averageRating,
    int? completedLoads,
    double? totalMiles,
    int? onTimeDeliveryRate,
  }) {
    return DriverExtended(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      truckNumber: truckNumber ?? this.truckNumber,
      userId: userId,
      status: status ?? this.status,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      cdlClass: cdlClass ?? this.cdlClass,
      endorsements: endorsements ?? this.endorsements,
      lastLocation: lastLocation ?? this.lastLocation,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      averageRating: averageRating ?? this.averageRating,
      completedLoads: completedLoads ?? this.completedLoads,
      totalMiles: totalMiles ?? this.totalMiles,
      onTimeDeliveryRate: onTimeDeliveryRate ?? this.onTimeDeliveryRate,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Driver status enum
enum DriverStatus {
  available('available'),
  onDuty('on_duty'),
  offDuty('off_duty'),
  inactive('inactive');

  final String value;
  const DriverStatus(this.value);

  static DriverStatus fromString(String value) {
    return DriverStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => DriverStatus.available,
    );
  }

  String get displayName {
    switch (this) {
      case DriverStatus.available:
        return 'Available';
      case DriverStatus.onDuty:
        return 'On Duty';
      case DriverStatus.offDuty:
        return 'Off Duty';
      case DriverStatus.inactive:
        return 'Inactive';
    }
  }
}

/// Driver document model
class DriverDocument {
  final String id;
  final String driverId;
  final DocumentType type;
  final String url;
  final DateTime uploadedAt;
  final DateTime expiryDate;
  final DocumentStatus status;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? notes;

  DriverDocument({
    required this.id,
    required this.driverId,
    required this.type,
    required this.url,
    required this.uploadedAt,
    required this.expiryDate,
    this.status = DocumentStatus.pending,
    this.verifiedBy,
    this.verifiedAt,
    this.notes,
  });

  /// Create from Firestore document
  factory DriverDocument.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return DriverDocument(
      id: doc.id,
      driverId: data['driverId'] ?? '',
      type: DocumentType.fromString(data['type'] ?? 'other'),
      url: data['url'] ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      status: DocumentStatus.fromString(data['status'] ?? 'pending'),
      verifiedBy: data['verifiedBy'],
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
      notes: data['notes'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'type': type.value,
      'url': url,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'status': status.value,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt != null 
          ? Timestamp.fromDate(verifiedAt!) 
          : null,
      'notes': notes,
    };
  }

  /// Check if document is expiring soon (within 30 days)
  bool get isExpiringSoon {
    final now = DateTime.now();
    final daysUntilExpiry = expiryDate.difference(now).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }

  /// Check if document is expired
  bool get isExpired {
    return DateTime.now().isAfter(expiryDate);
  }
}

/// Document type enum
enum DocumentType {
  license('license'),
  medicalCard('medical_card'),
  insurance('insurance'),
  certification('certification'),
  other('other');

  final String value;
  const DocumentType(this.value);

  static DocumentType fromString(String value) {
    return DocumentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DocumentType.other,
    );
  }

  String get displayName {
    switch (this) {
      case DocumentType.license:
        return 'Driver License';
      case DocumentType.medicalCard:
        return 'Medical Card';
      case DocumentType.insurance:
        return 'Insurance';
      case DocumentType.certification:
        return 'Certification';
      case DocumentType.other:
        return 'Other';
    }
  }
}

/// Document status enum
enum DocumentStatus {
  pending('pending'),
  valid('valid'),
  expiringSoon('expiring_soon'),
  expired('expired'),
  rejected('rejected');

  final String value;
  const DocumentStatus(this.value);

  static DocumentStatus fromString(String value) {
    return DocumentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => DocumentStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case DocumentStatus.pending:
        return 'Pending Review';
      case DocumentStatus.valid:
        return 'Valid';
      case DocumentStatus.expiringSoon:
        return 'Expiring Soon';
      case DocumentStatus.expired:
        return 'Expired';
      case DocumentStatus.rejected:
        return 'Rejected';
    }
  }
}

/// Truck inspection model
class TruckInspection {
  final String id;
  final String driverId;
  final String truckNumber;
  final DateTime inspectionDate;
  final String inspector;
  final bool passed;
  final List<String> issues;
  final String? notes;
  final DateTime? nextDueDate;

  TruckInspection({
    required this.id,
    required this.driverId,
    required this.truckNumber,
    required this.inspectionDate,
    required this.inspector,
    required this.passed,
    this.issues = const [],
    this.notes,
    this.nextDueDate,
  });

  /// Create from Firestore document
  factory TruckInspection.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return TruckInspection(
      id: doc.id,
      driverId: data['driverId'] ?? '',
      truckNumber: data['truckNumber'] ?? '',
      inspectionDate: (data['inspectionDate'] as Timestamp).toDate(),
      inspector: data['inspector'] ?? '',
      passed: data['passed'] ?? false,
      issues: List<String>.from(data['issues'] ?? []),
      notes: data['notes'],
      nextDueDate: (data['nextDueDate'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'truckNumber': truckNumber,
      'inspectionDate': Timestamp.fromDate(inspectionDate),
      'inspector': inspector,
      'passed': passed,
      'issues': issues,
      'notes': notes,
      'nextDueDate': nextDueDate != null 
          ? Timestamp.fromDate(nextDueDate!) 
          : null,
    };
  }
}

/// Truck document model for registration and insurance
class TruckDocument {
  final String id;
  final String truckNumber;
  final TruckDocumentType type;
  final String url;
  final DateTime uploadedAt;
  final DateTime expiryDate;
  final DocumentStatus status;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? notes;

  TruckDocument({
    required this.id,
    required this.truckNumber,
    required this.type,
    required this.url,
    required this.uploadedAt,
    required this.expiryDate,
    this.status = DocumentStatus.pending,
    this.verifiedBy,
    this.verifiedAt,
    this.notes,
  });

  /// Create from Firestore document
  factory TruckDocument.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return TruckDocument(
      id: doc.id,
      truckNumber: data['truckNumber'] ?? '',
      type: TruckDocumentType.fromString(data['type'] ?? 'other'),
      url: data['url'] ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      status: DocumentStatus.fromString(data['status'] ?? 'pending'),
      verifiedBy: data['verifiedBy'],
      verifiedAt: (data['verifiedAt'] as Timestamp?)?.toDate(),
      notes: data['notes'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'truckNumber': truckNumber,
      'type': type.value,
      'url': url,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'status': status.value,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt != null 
          ? Timestamp.fromDate(verifiedAt!) 
          : null,
      'notes': notes,
    };
  }

  /// Check if document is expiring soon (within 30 days)
  bool get isExpiringSoon {
    final now = DateTime.now();
    final daysUntilExpiry = expiryDate.difference(now).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }

  /// Check if document is expired
  bool get isExpired {
    return DateTime.now().isAfter(expiryDate);
  }

  /// Get days until expiry
  int get daysUntilExpiry {
    return expiryDate.difference(DateTime.now()).inDays;
  }
}

/// Truck document type enum
enum TruckDocumentType {
  registration('registration'),
  insurance('insurance'),
  inspection('inspection'),
  other('other');

  final String value;
  const TruckDocumentType(this.value);

  static TruckDocumentType fromString(String value) {
    return TruckDocumentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TruckDocumentType.other,
    );
  }

  String get displayName {
    switch (this) {
      case TruckDocumentType.registration:
        return 'Truck Registration';
      case TruckDocumentType.insurance:
        return 'Truck Insurance';
      case TruckDocumentType.inspection:
        return 'Truck Inspection';
      case TruckDocumentType.other:
        return 'Other';
    }
  }
}

/// Expiration alert model
class ExpirationAlert {
  final String id;
  final String? driverId;
  final String? documentId;
  final String? truckNumber;
  final ExpirationAlertType type;
  final DateTime expiryDate;
  final AlertStatus status;
  final int daysRemaining;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;

  ExpirationAlert({
    required this.id,
    this.driverId,
    this.documentId,
    this.truckNumber,
    required this.type,
    required this.expiryDate,
    this.status = AlertStatus.pending,
    required this.daysRemaining,
    required this.createdAt,
    this.sentAt,
    this.acknowledgedAt,
    this.acknowledgedBy,
  });

  /// Create from Firestore document
  factory ExpirationAlert.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ExpirationAlert(
      id: doc.id,
      driverId: data['driverId'],
      documentId: data['documentId'],
      truckNumber: data['truckNumber'],
      type: ExpirationAlertType.fromString(data['type'] ?? 'other'),
      expiryDate: (data['expiryDate'] as Timestamp).toDate(),
      status: AlertStatus.fromString(data['status'] ?? 'pending'),
      daysRemaining: data['daysRemaining'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      sentAt: (data['sentAt'] as Timestamp?)?.toDate(),
      acknowledgedAt: (data['acknowledgedAt'] as Timestamp?)?.toDate(),
      acknowledgedBy: data['acknowledgedBy'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'documentId': documentId,
      'truckNumber': truckNumber,
      'type': type.value,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'status': status.value,
      'daysRemaining': daysRemaining,
      'createdAt': Timestamp.fromDate(createdAt),
      'sentAt': sentAt != null ? Timestamp.fromDate(sentAt!) : null,
      'acknowledgedAt': acknowledgedAt != null 
          ? Timestamp.fromDate(acknowledgedAt!) 
          : null,
      'acknowledgedBy': acknowledgedBy,
    };
  }

  /// Check if alert is critical (less than 7 days)
  bool get isCritical {
    return daysRemaining < 7;
  }

  /// Get priority color
  String get priorityColor {
    if (daysRemaining < 7) return 'red';
    if (daysRemaining <= 30) return 'yellow';
    return 'green';
  }

  /// Copy with updated fields
  ExpirationAlert copyWith({
    AlertStatus? status,
    DateTime? sentAt,
    DateTime? acknowledgedAt,
    String? acknowledgedBy,
    int? daysRemaining,
  }) {
    return ExpirationAlert(
      id: id,
      driverId: driverId,
      documentId: documentId,
      truckNumber: truckNumber,
      type: type,
      expiryDate: expiryDate,
      status: status ?? this.status,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      createdAt: createdAt,
      sentAt: sentAt ?? this.sentAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
    );
  }
}

/// Expiration alert type enum
enum ExpirationAlertType {
  driverLicense('driver_license'),
  medicalCard('medical_card'),
  truckRegistration('truck_registration'),
  truckInsurance('truck_insurance'),
  certification('certification'),
  other('other');

  final String value;
  const ExpirationAlertType(this.value);

  static ExpirationAlertType fromString(String value) {
    return ExpirationAlertType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ExpirationAlertType.other,
    );
  }

  String get displayName {
    switch (this) {
      case ExpirationAlertType.driverLicense:
        return 'Driver License';
      case ExpirationAlertType.medicalCard:
        return 'DOT Medical Card';
      case ExpirationAlertType.truckRegistration:
        return 'Truck Registration';
      case ExpirationAlertType.truckInsurance:
        return 'Truck Insurance';
      case ExpirationAlertType.certification:
        return 'Certification';
      case ExpirationAlertType.other:
        return 'Other';
    }
  }
}

/// Alert status enum
enum AlertStatus {
  pending('pending'),
  sent('sent'),
  acknowledged('acknowledged'),
  dismissed('dismissed');

  final String value;
  const AlertStatus(this.value);

  static AlertStatus fromString(String value) {
    return AlertStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => AlertStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case AlertStatus.pending:
        return 'Pending';
      case AlertStatus.sent:
        return 'Sent';
      case AlertStatus.acknowledged:
        return 'Acknowledged';
      case AlertStatus.dismissed:
        return 'Dismissed';
    }
  }
}
