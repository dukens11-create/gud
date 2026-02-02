import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/statistics.dart';

class StatisticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Calculate statistics for a period
  Future<Statistics> calculateStatistics({
    required DateTime startDate,
    required DateTime endDate,
    String? driverId,
  }) async {
    // Get loads
    Query loadsQuery = _db.collection('loads')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    
    if (driverId != null) {
      loadsQuery = loadsQuery.where('driverId', isEqualTo: driverId);
    }
    
    final loadsSnapshot = await loadsQuery.get();
    final loads = loadsSnapshot.docs;
    
    // Get expenses
    Query expensesQuery = _db.collection('expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    
    if (driverId != null) {
      expensesQuery = expensesQuery.where('driverId', isEqualTo: driverId);
    }
    
    final expensesSnapshot = await expensesQuery.get();
    final expenses = expensesSnapshot.docs;
    
    // Calculate totals
    final totalRevenue = loads.fold(0.0, 
        (sum, doc) => sum + ((doc.data()['rate'] ?? 0) as num).toDouble());
    
    final totalExpenses = expenses.fold(0.0,
        (sum, doc) => sum + ((doc.data()['amount'] ?? 0) as num).toDouble());
    
    final totalMiles = loads.fold(0.0,
        (sum, doc) => sum + ((doc.data()['miles'] ?? 0) as num).toDouble());
    
    final deliveredLoads = loads.where(
        (doc) => ['delivered', 'completed'].contains(doc.data()['status'])).length;
    
    final averageRate = loads.isEmpty ? 0.0 : totalRevenue / loads.length;
    final ratePerMile = totalMiles == 0 ? 0.0 : totalRevenue / totalMiles;
    
    // Calculate per-driver stats if not filtering by driver
    Map<String, dynamic> driverStats = {};
    if (driverId == null) {
      final driversSnapshot = await _db.collection('drivers').get();
      for (var driverDoc in driversSnapshot.docs) {
        final dId = driverDoc.id;
        final driverLoads = loads.where((l) => l.data()['driverId'] == dId).toList();
        final driverRevenue = driverLoads.fold(0.0,
            (sum, doc) => sum + ((doc.data()['rate'] ?? 0) as num).toDouble());
        final driverDelivered = driverLoads.where(
            (doc) => ['delivered', 'completed'].contains(doc.data()['status'])).length;
        
        driverStats[dId] = {
          'revenue': driverRevenue,
          'loads': driverLoads.length,
          'delivered': driverDelivered,
          'name': driverDoc.data()['name'] ?? 'Unknown',
        };
      }
    }
    
    return Statistics(
      totalRevenue: totalRevenue,
      totalExpenses: totalExpenses,
      netProfit: totalRevenue - totalExpenses,
      totalLoads: loads.length,
      deliveredLoads: deliveredLoads,
      totalMiles: totalMiles,
      averageRate: averageRate,
      ratePerMile: ratePerMile,
      periodStart: startDate,
      periodEnd: endDate,
      driverStats: driverStats,
    );
  }

  // Stream real-time statistics
  Stream<Statistics> streamStatistics({
    required DateTime startDate,
    required DateTime endDate,
    String? driverId,
  }) {
    // Combine loads and expenses streams
    return _db.collection('loads').snapshots().asyncMap((loadsSnapshot) async {
      return await calculateStatistics(
        startDate: startDate,
        endDate: endDate,
        driverId: driverId,
      );
    });
  }

  // Save statistics snapshot
  Future<void> saveStatisticsSnapshot(Statistics stats) async {
    await _db.collection('statistics_snapshots').add(stats.toMap());
  }

  // Get historical statistics
  Future<List<Statistics>> getHistoricalStatistics({
    int limit = 12,
  }) async {
    final snapshot = await _db
        .collection('statistics_snapshots')
        .orderBy('periodEnd', descending: true)
        .limit(limit)
        .get();
    
    return snapshot.docs.map((doc) => Statistics.fromDoc(doc)).toList();
  }
}
