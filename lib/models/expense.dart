import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/datetime_utils.dart';

class Expense {
  final String id;
  final double amount;
  final String category; // 'fuel', 'maintenance', 'tolls', 'insurance', 'other'
  final String description;
  final DateTime date;
  final String? driverId;
  final String? loadId;
  final String? receiptUrl;
  final String createdBy;
  final DateTime createdAt;
  final double? gallons; // gallons of fuel (only for 'fuel' category)

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.driverId,
    this.loadId,
    this.receiptUrl,
    required this.createdBy,
    DateTime? createdAt,
    this.gallons,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'amount': amount,
    'category': category,
    'description': description,
    'date': date.toIso8601String(),
    if (driverId != null) 'driverId': driverId,
    if (loadId != null) 'loadId': loadId,
    if (receiptUrl != null) 'receiptUrl': receiptUrl,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    if (gallons != null) 'gallons': gallons,
  };

  static Expense fromDoc(DocumentSnapshot doc) {
    return fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  static Expense fromMap(String id, Map<String, dynamic> d) {
    return Expense(
      id: id,
      amount: (d['amount'] ?? 0).toDouble(),
      category: (d['category'] ?? 'other') as String,
      description: (d['description'] ?? '') as String,
      date: DateTimeUtils.parseDateTime(d['date']) ?? DateTime.now(),
      driverId: d['driverId'] as String?,
      loadId: d['loadId'] as String?,
      receiptUrl: d['receiptUrl'] as String?,
      createdBy: (d['createdBy'] ?? '') as String,
      createdAt: DateTimeUtils.parseDateTime(d['createdAt']),
      gallons: d['gallons'] != null ? (d['gallons'] as num).toDouble() : null,
    );
  }
}
