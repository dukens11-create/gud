import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Summary of IFTA data (gallons and miles) for a single driver in a date range.
class IftaDriverSummary {
  final String driverId;
  final String? driverName;
  final double totalMiles;
  final double totalGallons;

  IftaDriverSummary({
    required this.driverId,
    this.driverName,
    required this.totalMiles,
    required this.totalGallons,
  });

  /// Miles per gallon; returns 0 when no fuel was recorded.
  double get mpg => totalGallons > 0 ? totalMiles / totalGallons : 0.0;
}

/// Service that aggregates IFTA (International Fuel Tax Agreement) data:
/// total gallons (from fuel expenses) and total miles (from delivered loads)
/// by driver for a given date range.
class IftaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _requireAuth() {
    if (_auth.currentUser == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message: 'User must be signed in to access IFTA data',
      );
    }
  }

  /// Returns IFTA totals grouped by driver for [startDate]..[endDate] (inclusive).
  ///
  /// Pass [driverId] to limit results to a single driver.
  /// Date comparisons use UTC midnight boundaries to be timezone-safe.
  Future<List<IftaDriverSummary>> getReport({
    required DateTime startDate,
    required DateTime endDate,
    String? driverId,
  }) async {
    _requireAuth();

    // Normalise to UTC midnight so the range is inclusive of the full end day.
    final start = DateTime.utc(startDate.year, startDate.month, startDate.day);
    final end = DateTime.utc(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    // ── Fuel expenses ────────────────────────────────────────────────────────
    // Query strategy: filter by driverId (equality) + date range when a
    // specific driver is requested, otherwise filter by date range only and
    // apply category filter client-side to avoid requiring a new composite index.
    final Map<String, double> gallonsByDriver = {};
    final Map<String, String?> driverNames = {};

    if (driverId != null) {
      // Uses existing composite index: driverId ASC + date ASC
      final expenseSnapshot = await _db
          .collection('expenses')
          .where('driverId', isEqualTo: driverId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      for (final doc in expenseSnapshot.docs) {
        final data = doc.data();
        if ((data['category'] as String?) == 'fuel') {
          final g = data['gallons'];
          if (g != null) {
            gallonsByDriver[driverId] =
                (gallonsByDriver[driverId] ?? 0.0) + (g as num).toDouble();
          }
        }
      }
    } else {
      // No composite index required – date range only uses single-field index.
      final expenseSnapshot = await _db
          .collection('expenses')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      for (final doc in expenseSnapshot.docs) {
        final data = doc.data();
        if ((data['category'] as String?) == 'fuel') {
          final id = data['driverId'] as String?;
          if (id != null) {
            final g = data['gallons'];
            if (g != null) {
              gallonsByDriver[id] =
                  (gallonsByDriver[id] ?? 0.0) + (g as num).toDouble();
            }
          }
        }
      }
    }

    // ── Delivered loads (miles) ───────────────────────────────────────────────
    final Map<String, double> milesByDriver = {};

    if (driverId != null) {
      // Uses existing composite index: driverId ASC + createdAt DESC
      final loadsSnapshot = await _db
          .collection('loads')
          .where('driverId', isEqualTo: driverId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      for (final doc in loadsSnapshot.docs) {
        final data = doc.data();
        if ((data['status'] as String?) == 'delivered') {
          final m = (data['miles'] ?? 0) as num;
          milesByDriver[driverId] =
              (milesByDriver[driverId] ?? 0.0) + m.toDouble();
          driverNames[driverId] ??= data['driverName'] as String?;
        }
      }
    } else {
      // Uses existing composite index: status ASC + createdAt DESC
      final loadsSnapshot = await _db
          .collection('loads')
          .where('status', isEqualTo: 'delivered')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      for (final doc in loadsSnapshot.docs) {
        final data = doc.data();
        final id = data['driverId'] as String?;
        if (id != null) {
          final m = (data['miles'] ?? 0) as num;
          milesByDriver[id] = (milesByDriver[id] ?? 0.0) + m.toDouble();
          driverNames[id] ??= data['driverName'] as String?;
        }
      }
    }

    // ── Merge results ─────────────────────────────────────────────────────────
    final allDriverIds = <String>{
      ...gallonsByDriver.keys,
      ...milesByDriver.keys,
    };

    return allDriverIds.map((id) {
      return IftaDriverSummary(
        driverId: id,
        driverName: driverNames[id],
        totalMiles: milesByDriver[id] ?? 0.0,
        totalGallons: gallonsByDriver[id] ?? 0.0,
      );
    }).toList()
      ..sort((a, b) => (a.driverName ?? a.driverId)
          .compareTo(b.driverName ?? b.driverId));
  }
}
