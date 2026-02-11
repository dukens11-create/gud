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
  final String status; // 'assigned', 'picked_up', 'in_transit', 'delivered'
  final DateTime createdAt;
  final DateTime? pickedUpAt;
  final DateTime? tripStartAt;
  final DateTime? tripEndAt;
  final double miles;
  final DateTime? deliveredAt;
  final String? notes;
  final String createdBy;

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
  };

  static LoadModel fromDoc(DocumentSnapshot doc) {
    return fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  static LoadModel fromMap(String id, Map<String, dynamic> d) {
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
    );
  }
}
