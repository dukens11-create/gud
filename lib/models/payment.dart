import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/datetime_utils.dart';

/// Payment model for tracking driver compensation
/// 
/// Drivers receive 85% of the load rate for each delivery.
/// Payment documents are created automatically when a load is delivered.
class Payment {
  final String id;
  final String driverId;
  final String loadId;
  final double amount;        // 85% of load rate
  final double loadRate;      // Original load rate (100%)
  final String status;        // 'pending', 'paid', 'cancelled'
  final DateTime? paymentDate; // When payment was made (null if pending)
  final DateTime createdAt;
  final String createdBy;
  final String? notes;

  Payment({
    required this.id,
    required this.driverId,
    required this.loadId,
    required this.amount,
    required this.loadRate,
    required this.status,
    this.paymentDate,
    DateTime? createdAt,
    required this.createdBy,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Calculate commission rate (always 0.85 for 85%)
  double get commissionRate => 0.85;

  /// Calculate company's share (15% of load rate)
  double get companyShare => loadRate - amount;

  Map<String, dynamic> toMap() => {
    'driverId': driverId,
    'loadId': loadId,
    'amount': amount,
    'loadRate': loadRate,
    'status': status,
    if (paymentDate != null) 'paymentDate': paymentDate!.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'createdBy': createdBy,
    if (notes != null) 'notes': notes,
  };

  static Payment fromDoc(DocumentSnapshot doc) {
    return fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  static Payment fromMap(String id, Map<String, dynamic> d) {
    return Payment(
      id: id,
      driverId: (d['driverId'] ?? '') as String,
      loadId: (d['loadId'] ?? '') as String,
      amount: (d['amount'] ?? 0).toDouble(),
      loadRate: (d['loadRate'] ?? 0).toDouble(),
      status: (d['status'] ?? 'pending') as String,
      paymentDate: DateTimeUtils.parseDateTime(d['paymentDate']),
      createdAt: DateTimeUtils.parseDateTime(d['createdAt']),
      createdBy: (d['createdBy'] ?? '') as String,
      notes: d['notes'] as String?,
    );
  }
}
