import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/datetime_utils.dart';

class LoadModel {
  final String id;
  final String loadNumber;
  final String driverId;
  final String? driverName;
  final String pickupAddress;
  final String deliveryAddress;
  final double rate;
  /// Load Status Progression:
  /// 1. pending    - Admin created load, awaiting driver acceptance
  /// 2. accepted   - Driver accepted the load
  /// 3. in_transit - Driver started the trip
  /// 4. delivered  - Driver completed delivery
  /// 
  /// Optional:
  /// - declined    - Driver declined the load
  /// 
  /// Legacy statuses (for backward compatibility):
  /// - assigned    - Old status, treated similar to accepted
  /// - picked_up   - Legacy status, kept for historical loads
  final String status;
  final DateTime createdAt;
  final DateTime? pickedUpAt;
  final DateTime? tripStartAt;
  final DateTime? tripEndAt;
  final double miles;
  final DateTime? deliveredAt;
  final String? notes;
  final String createdBy;
  final String? bolPhotoUrl;      // Bill of Lading photo URL
  final String? podPhotoUrl;      // Proof of Delivery photo URL
  final DateTime? bolUploadedAt;  // When BOL was uploaded
  final DateTime? podUploadedAt;  // When POD was uploaded
  final DateTime? acceptedAt;     // When driver accepted the load
  final String? paymentStatus;    // Payment status: 'unpaid', 'paid', 'partial'
  final String? paymentId;        // Reference to payment document
  final String? rateconUrl;       // Rate confirmation file URL
  final String? rateconFileName;  // Original filename of the rate confirmation
  final DateTime? rateconUploadedAt; // When ratecon was uploaded by admin
  final DateTime? rateconSentAt;  // When ratecon notification was sent to driver
  final String? rateconSentStatus; // Delivery status: 'sent'
  final int adminUnreadCount;     // Unread chat messages for admin
  final int driverUnreadCount;    // Unread chat messages for driver

  LoadModel({
    required this.id,
    required this.loadNumber,
    required this.driverId,
    this.driverName,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.rate,
    required this.status,
    DateTime? createdAt,
    this.pickedUpAt,
    this.tripStartAt,
    this.tripEndAt,
    this.miles = 0.0,
    this.deliveredAt,
    this.notes,
    this.createdBy = '',
    this.bolPhotoUrl,
    this.podPhotoUrl,
    this.bolUploadedAt,
    this.podUploadedAt,
    this.acceptedAt,
    this.paymentStatus,
    this.paymentId,
    this.rateconUrl,
    this.rateconFileName,
    this.rateconUploadedAt,
    this.rateconSentAt,
    this.rateconSentStatus,
    this.adminUnreadCount = 0,
    this.driverUnreadCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'loadNumber': loadNumber,
    'driverId': driverId,
    if (driverName != null) 'driverName': driverName,
    'pickupAddress': pickupAddress,
    'deliveryAddress': deliveryAddress,
    'rate': rate,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    if (pickedUpAt != null) 'pickedUpAt': pickedUpAt!.toIso8601String(),
    if (tripStartAt != null) 'tripStartAt': tripStartAt!.toIso8601String(),
    if (tripEndAt != null) 'tripEndAt': tripEndAt!.toIso8601String(),
    'miles': miles,
    if (deliveredAt != null) 'deliveredAt': deliveredAt!.toIso8601String(),
    if (notes != null) 'notes': notes,
    'createdBy': createdBy,
    if (bolPhotoUrl != null) 'bolPhotoUrl': bolPhotoUrl,
    if (podPhotoUrl != null) 'podPhotoUrl': podPhotoUrl,
    if (bolUploadedAt != null) 'bolUploadedAt': bolUploadedAt!.toIso8601String(),
    if (podUploadedAt != null) 'podUploadedAt': podUploadedAt!.toIso8601String(),
    if (acceptedAt != null) 'acceptedAt': acceptedAt!.toIso8601String(),
    if (paymentStatus != null) 'paymentStatus': paymentStatus,
    if (paymentId != null) 'paymentId': paymentId,
    if (rateconUrl != null) 'rateconUrl': rateconUrl,
    if (rateconFileName != null) 'rateconFileName': rateconFileName,
    if (rateconUploadedAt != null) 'rateconUploadedAt': rateconUploadedAt!.toIso8601String(),
    if (rateconSentAt != null) 'rateconSentAt': rateconSentAt!.toIso8601String(),
    if (rateconSentStatus != null) 'rateconSentStatus': rateconSentStatus,
    'adminUnreadCount': adminUnreadCount,
    'driverUnreadCount': driverUnreadCount,
  };

  static LoadModel fromDoc(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      throw FormatException('Document ${doc.id} has no data');
    }
    return fromMap(doc.id, data as Map<String, dynamic>);
  }

  static LoadModel fromMap(String id, Map<String, dynamic> d) {
    try {
      return LoadModel(
        id: id,
        loadNumber: (d['loadNumber'] ?? '') as String,
        driverId: (d['driverId'] ?? '') as String,
        driverName: d['driverName'] as String?,
        pickupAddress: (d['pickupAddress'] ?? '') as String,
        deliveryAddress: (d['deliveryAddress'] ?? '') as String,
        rate: (d['rate'] ?? 0).toDouble(),
        status: (d['status'] ?? 'assigned') as String,
        createdAt: DateTimeUtils.parseDateTime(d['createdAt']),
        pickedUpAt: DateTimeUtils.parseDateTime(d['pickedUpAt']),
        tripStartAt: DateTimeUtils.parseDateTime(d['tripStartAt']),
        tripEndAt: DateTimeUtils.parseDateTime(d['tripEndAt']),
        miles: (d['miles'] ?? 0).toDouble(),
        deliveredAt: DateTimeUtils.parseDateTime(d['deliveredAt']),
        notes: d['notes'] as String?,
        createdBy: (d['createdBy'] ?? '') as String,
        bolPhotoUrl: d['bolPhotoUrl'] as String?,
        podPhotoUrl: d['podPhotoUrl'] as String?,
        bolUploadedAt: DateTimeUtils.parseDateTime(d['bolUploadedAt']),
        podUploadedAt: DateTimeUtils.parseDateTime(d['podUploadedAt']),
        acceptedAt: DateTimeUtils.parseDateTime(d['acceptedAt']),
        paymentStatus: d['paymentStatus'] as String?,
        paymentId: d['paymentId'] as String?,
        rateconUrl: d['rateconUrl'] as String?,
        rateconFileName: d['rateconFileName'] as String?,
        rateconUploadedAt: DateTimeUtils.parseDateTime(d['rateconUploadedAt']),
        rateconSentAt: DateTimeUtils.parseDateTime(d['rateconSentAt']),
        rateconSentStatus: d['rateconSentStatus'] as String?,
        adminUnreadCount: ((d['adminUnreadCount'] ?? 0) as num).toInt(),
        driverUnreadCount: ((d['driverUnreadCount'] ?? 0) as num).toInt(),
      );
    } catch (e) {
      throw FormatException(
        'Failed to parse LoadModel from document $id: $e',
      );
    }
  }
}
