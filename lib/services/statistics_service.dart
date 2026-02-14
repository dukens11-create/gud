import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/statistics.dart';

/// Statistics service for calculating and managing business analytics.
/// 
/// **Security**: All methods verify user authentication before executing queries.
/// Throws [FirebaseAuthException] if user is not authenticated.
class StatisticsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Verify user is authenticated before executing Firestore operations
  /// 
  /// Throws [FirebaseAuthException] with code 'unauthenticated' if user is not signed in
  void _requireAuth() {
    if (_auth.currentUser == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message: 'User must be signed in to access statistics data',
      );
    }
  }

  // Calculate statistics for a period
  Future<Statistics> calculateStatistics({
    required DateTime startDate,
    required DateTime endDate,
    String? driverId,
  }) async {
    _requireAuth();
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
    // 🔴 COMPOSITE INDEX REQUIRED when driverId filter is present
    // Query: where('date', >=) + where('date', <=) + optional where('driverId', ==)
    //
    // When driverId is provided, required composite index:
    // {
    //   "collectionGroup": "expenses",
    //   "queryScope": "COLLECTION",
    //   "fields": [
    //     {"fieldPath": "driverId", "order": "ASCENDING"},
    //     {"fieldPath": "date", "order": "ASCENDING"}
    //   ]
    // }
    //
    // ISSUE: This index does NOT exist in firestore.indexes.json
    print('[StatisticsService] Executing expense query for statistics');
    print('  Collection: expenses');
    print('  Where: date >= $startDate');
    print('  Where: date <= $endDate');
    
    Query expensesQuery = _db.collection('expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    
    if (driverId != null) {
      print('  Where: driverId == $driverId');
      print('  ⚠️  REQUIRES COMPOSITE INDEX: driverId ASC + date ASC');
      expensesQuery = expensesQuery.where('driverId', isEqualTo: driverId);
    } else {
      print('  Date range only: uses single-field index');
    }
    
    final expensesSnapshot = await expensesQuery.get();
    print('[StatisticsService] Expense query returned ${expensesSnapshot.docs.length} documents');
    final expenses = expensesSnapshot.docs;
    
    // Calculate totals
    final totalRevenue = loads.fold(0.0, 
        (sum, doc) => sum + (((doc.data() as Map<String, dynamic>)['rate'] ?? 0) as num).toDouble());
    
    final totalExpenses = expenses.fold(0.0,
        (sum, doc) => sum + (((doc.data() as Map<String, dynamic>)['amount'] ?? 0) as num).toDouble());
    
    final totalMiles = loads.fold(0.0,
        (sum, doc) => sum + (((doc.data() as Map<String, dynamic>)['miles'] ?? 0) as num).toDouble());
    
    final deliveredLoads = loads.where(
        (doc) => ['delivered', 'completed'].contains((doc.data() as Map<String, dynamic>)['status'])).length;
    
    final averageRate = loads.isEmpty ? 0.0 : totalRevenue / loads.length;
    final ratePerMile = totalMiles == 0 ? 0.0 : totalRevenue / totalMiles;
    
    // Calculate per-driver stats if not filtering by driver
    Map<String, dynamic> driverStats = {};
    if (driverId == null) {
      final driversSnapshot = await _db.collection('drivers').get();
      for (var driverDoc in driversSnapshot.docs) {
        final dId = driverDoc.id;
        final driverLoads = loads.where((l) => (l.data() as Map<String, dynamic>)['driverId'] == dId).toList();
        final driverRevenue = driverLoads.fold(0.0,
            (sum, doc) => sum + (((doc.data() as Map<String, dynamic>)['rate'] ?? 0) as num).toDouble());
        final driverDelivered = driverLoads.where(
            (doc) => ['delivered', 'completed'].contains((doc.data() as Map<String, dynamic>)['status'])).length;
        
        driverStats[dId] = {
          'revenue': driverRevenue,
          'loads': driverLoads.length,
          'delivered': driverDelivered,
          'name': (driverDoc.data() as Map<String, dynamic>)['name'] ?? 'Unknown',
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
    _requireAuth();
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
    _requireAuth();
    await _db.collection('statistics_snapshots').add(stats.toMap());
  }

  // Get historical statistics
  Future<List<Statistics>> getHistoricalStatistics({
    int limit = 12,
  }) async {
    _requireAuth();
    final snapshot = await _db
        .collection('statistics_snapshots')
        .orderBy('periodEnd', descending: true)
        .limit(limit)
        .get();
    
    return snapshot.docs.map((doc) => Statistics.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }
}
