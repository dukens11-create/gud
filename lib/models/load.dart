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
  final DateTime? declinedAt;     // When driver declined the load
  final String? declineReason;    // Optional reason for declining

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
    this.declinedAt,
    this.declineReason,
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
    if (declinedAt != null) 'declinedAt': declinedAt!.toIso8601String(),
    if (declineReason != null) 'declineReason': declineReason,
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
        declinedAt: DateTimeUtils.parseDateTime(d['declinedAt']),
        declineReason: d['declineReason'] as String?,
      );
    } catch (e) {
      throw FormatException(
        'Failed to parse LoadModel from document $id: $e',
      );
    }
  }
}
