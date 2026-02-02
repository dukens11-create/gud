import 'package:cloud_firestore/cloud_firestore.dart';

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
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'amount': amount,
    'category': category,
    'description': description,
    'date': Timestamp.fromDate(date),
    if (driverId != null) 'driverId': driverId,
    if (loadId != null) 'loadId': loadId,
    if (receiptUrl != null) 'receiptUrl': receiptUrl,
    'createdBy': createdBy,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  static Expense fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    DateTime? _parseTimestamp(dynamic v) => v == null ? null : (v as Timestamp).toDate();

    return Expense(
      id: doc.id,
      amount: (d['amount'] ?? 0).toDouble(),
      category: (d['category'] ?? 'other') as String,
      description: (d['description'] ?? '') as String,
      date: _parseTimestamp(d['date']) ?? DateTime.now(),
      driverId: d['driverId'] as String?,
      loadId: d['loadId'] as String?,
      receiptUrl: d['receiptUrl'] as String?,
      createdBy: (d['createdBy'] ?? '') as String,
      createdAt: _parseTimestamp(d['createdAt']),
    );
  }
}
