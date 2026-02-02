import 'package:cloud_firestore/cloud_firestore.dart';

class LoadModel {
  final String id;
  final String loadNumber;
  final String driverId;
  final String pickupAddress;
  final String deliveryAddress;
  final double rate;
  final String status; // assigned|picked_up|in_transit|delivered
  final DateTime? tripStartAt;
  final DateTime? tripEndAt;
  final double miles;
  final DateTime? deliveredAt;

  LoadModel({
    required this.id,
    required this.loadNumber,
    required this.driverId,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.rate,
    required this.status,
    required this.tripStartAt,
    required this.tripEndAt,
    required this.miles,
    required this.deliveredAt,
  });

  Map<String, dynamic> toMap() => {
    'loadNumber': loadNumber,
    'driverId': driverId,
    'pickupAddress': pickupAddress,
    'deliveryAddress': deliveryAddress,
    'rate': rate,
    'status': status,
    'tripStartAt': tripStartAt == null ? null : Timestamp.fromDate(tripStartAt!),
    'tripEndAt': tripEndAt == null ? null : Timestamp.fromDate(tripEndAt!),
    'miles': miles,
    'deliveredAt': deliveredAt == null ? null : Timestamp.fromDate(deliveredAt!),
    'createdAt': FieldValue.serverTimestamp(),
  };

  static LoadModel fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    DateTime? _dt(dynamic v) => v == null ? null : (v as Timestamp).toDate();

    return LoadModel(
      id: doc.id,
      loadNumber: (d['loadNumber'] ?? '') as String,
      driverId: (d['driverId'] ?? '') as String,
      pickupAddress: (d['pickupAddress'] ?? '') as String,
      deliveryAddress: (d['deliveryAddress'] ?? '') as String,
      rate: (d['rate'] ?? 0).toDouble(),
      status: (d['status'] ?? 'assigned') as String,
      tripStartAt: _dt(d['tripStartAt']),
      tripEndAt: _dt(d['tripEndAt']),
      miles: (d['miles'] ?? 0).toDouble(),
      deliveredAt: _dt(d['deliveredAt']),
    );
  }
}