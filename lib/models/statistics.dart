import 'package:cloud_firestore/cloud_firestore.dart';

class Statistics {
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;
  final int totalLoads;
  final int deliveredLoads;
  final double totalMiles;
  final double averageRate;
  final double ratePerMile;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Map<String, dynamic> driverStats;

  Statistics({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.totalLoads,
    required this.deliveredLoads,
    required this.totalMiles,
    required this.averageRate,
    required this.ratePerMile,
    required this.periodStart,
    required this.periodEnd,
    Map<String, dynamic>? driverStats,
  }) : driverStats = driverStats ?? {};

  Map<String, dynamic> toMap() => {
    'totalRevenue': totalRevenue,
    'totalExpenses': totalExpenses,
    'netProfit': netProfit,
    'totalLoads': totalLoads,
    'deliveredLoads': deliveredLoads,
    'totalMiles': totalMiles,
    'averageRate': averageRate,
    'ratePerMile': ratePerMile,
    'periodStart': Timestamp.fromDate(periodStart),
    'periodEnd': Timestamp.fromDate(periodEnd),
    'driverStats': driverStats,
  };

  static Statistics fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    DateTime? _parseTimestamp(dynamic v) => v == null ? null : (v as Timestamp).toDate();

    return Statistics(
      totalRevenue: (d['totalRevenue'] ?? 0).toDouble(),
      totalExpenses: (d['totalExpenses'] ?? 0).toDouble(),
      netProfit: (d['netProfit'] ?? 0).toDouble(),
      totalLoads: (d['totalLoads'] ?? 0) as int,
      deliveredLoads: (d['deliveredLoads'] ?? 0) as int,
      totalMiles: (d['totalMiles'] ?? 0).toDouble(),
      averageRate: (d['averageRate'] ?? 0).toDouble(),
      ratePerMile: (d['ratePerMile'] ?? 0).toDouble(),
      periodStart: _parseTimestamp(d['periodStart']) ?? DateTime.now(),
      periodEnd: _parseTimestamp(d['periodEnd']) ?? DateTime.now(),
      driverStats: (d['driverStats'] ?? {}) as Map<String, dynamic>,
    );
  }
}
