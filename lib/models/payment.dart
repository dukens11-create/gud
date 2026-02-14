import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/datetime_utils.dart';
import '../services/payment_service.dart';

/// Payment model for tracking driver compensation
/// 
/// Drivers receive a configurable percentage (default 85%) of the load rate for each delivery.
/// Payment documents are created automatically when a load is delivered.
/// Each payment stores the commission rate used at creation time.
class Payment {
  final String id;
  final String driverId;
  final String loadId;
  final double amount;        // Driver payment amount (loadRate * commissionRate)
  final double loadRate;      // Original load rate (100%)
  final double commissionRate; // Commission rate used for this payment (e.g., 0.85 for 85%)
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
    required this.commissionRate,
    required this.status,
    this.paymentDate,
    DateTime? createdAt,
    required this.createdBy,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Calculate company's share (amount not paid to driver)
  double get companyShare => loadRate - amount;

  /// Get commission rate as a formatted percentage string (e.g., "85%")
  String get commissionRatePercent => '${(commissionRate * 100).toStringAsFixed(0)}%';

  Map<String, dynamic> toMap() => {
    'driverId': driverId,
    'loadId': loadId,
    'amount': amount,
    'loadRate': loadRate,
    'commissionRate': commissionRate,
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
      commissionRate: (d['commissionRate'] ?? PaymentService.DEFAULT_COMMISSION_RATE).toDouble(), // Use constant for backward compatibility
      status: (d['status'] ?? 'pending') as String,
      paymentDate: DateTimeUtils.parseDateTime(d['paymentDate']),
      createdAt: DateTimeUtils.parseDateTime(d['createdAt']) ?? DateTime.now(),
      createdBy: (d['createdBy'] ?? '') as String,
      notes: d['notes'] as String?,
    );
  }
}
