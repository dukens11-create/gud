import 'package:cloud_firestore/cloud_firestore.dart';

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
    'createdAt': Timestamp.fromDate(createdAt),
    if (pickedUpAt != null) 'pickedUpAt': Timestamp.fromDate(pickedUpAt!),
    if (tripStartAt != null) 'tripStartAt': Timestamp.fromDate(tripStartAt!),
    if (tripEndAt != null) 'tripEndAt': Timestamp.fromDate(tripEndAt!),
    'miles': miles,
    if (deliveredAt != null) 'deliveredAt': Timestamp.fromDate(deliveredAt!),
    if (notes != null) 'notes': notes,
    'createdBy': createdBy,
  };

  static LoadModel fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    DateTime? _parseTimestamp(dynamic v) => v == null ? null : (v as Timestamp).toDate();

    return LoadModel(
      id: doc.id,
      loadNumber: (d['loadNumber'] ?? '') as String,
      driverId: (d['driverId'] ?? '') as String,
      driverName: d['driverName'] as String?,
      pickupAddress: (d['pickupAddress'] ?? '') as String,
      deliveryAddress: (d['deliveryAddress'] ?? '') as String,
      rate: (d['rate'] ?? 0).toDouble(),
      status: (d['status'] ?? 'assigned') as String,
      createdAt: _parseTimestamp(d['createdAt']),
      pickedUpAt: _parseTimestamp(d['pickedUpAt']),
      tripStartAt: _parseTimestamp(d['tripStartAt']),
      tripEndAt: _parseTimestamp(d['tripEndAt']),
      miles: (d['miles'] ?? 0).toDouble(),
      deliveredAt: _parseTimestamp(d['deliveredAt']),
      notes: d['notes'] as String?,
      createdBy: (d['createdBy'] ?? '') as String,
    );
  }
}
