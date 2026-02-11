import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/datetime_utils.dart';

/// MaintenanceQueryService provides best-practice Firestore queries for maintenance tracking.
/// 
/// This service uses collectionGroup queries to access maintenance records across
/// all driver documents in the Firestore hierarchy. It supports:
/// - Fetching all maintenance records or filtering by truck number
/// - Separating historical records from upcoming maintenance
/// - Proper ordering by serviceDate and name fields
/// - Efficient query construction with async/await patterns
/// 
/// Usage example:
/// ```dart
/// final service = MaintenanceQueryService();
/// 
/// // Get all historical maintenance records
/// final history = await service.getMaintenanceHistory();
/// 
/// // Get upcoming maintenance for a specific truck
/// final upcoming = await service.getUpcomingMaintenance(truckNumber: 'TRK-001');
/// 
/// // Stream all maintenance records in real-time
/// Stream<List<MaintenanceRecord>> stream = service.streamAllMaintenance();
/// ```
class MaintenanceQueryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ========== MAINTENANCE HISTORY QUERIES ==========

  /// Fetch historical maintenance records (serviceDate < now).
  /// 
  /// Historical records are those where the service has already been completed.
  /// Results are ordered by serviceDate (descending) and then by name.
  /// 
  /// Parameters:
  /// - [truckNumber]: Optional filter to get records for a specific truck.
  ///   If null, returns records for all trucks.
  /// - [limit]: Optional limit on number of results returned. Defaults to no limit.
  /// 
  /// Returns a list of maintenance record maps with fields:
  /// - id: Document ID
  /// - driverId: Driver who owns the truck
  /// - truckNumber: Truck identification number
  /// - maintenanceType: Type/name of maintenance performed
  /// - serviceDate: Date the service was completed
  /// - cost: Cost of the service
  /// - serviceProvider: Company/person who performed the service
  /// - notes: Additional notes about the service
  /// - createdAt: Timestamp when record was created
  Future<List<Map<String, dynamic>>> getMaintenanceHistory({
    String? truckNumber,
    int? limit,
  }) async {
    try {
      // Start with collectionGroup query to access all maintenance records
      // across the entire Firestore database structure
      Query query = _db.collectionGroup('maintenance');

      // Filter by truck number if specified
      if (truckNumber != null && truckNumber.isNotEmpty) {
        query = query.where('truckNumber', isEqualTo: truckNumber);
      }

      // Filter for historical records: serviceDate < now
      final now = Timestamp.fromDate(DateTime.now());
      query = query.where('serviceDate', isLessThan: now);

      // Order by serviceDate descending (most recent first), then by maintenance type name
      // Note: Firestore requires composite indexes for queries with multiple orderBy clauses
      query = query
          .orderBy('serviceDate', descending: true)
          .orderBy('maintenanceType'); // Secondary sort by name/type

      // Apply limit if specified
      if (limit != null && limit > 0) {
        query = query.limit(limit);
      }

      // Execute query
      final snapshot = await query.get();

      // Transform QueryDocumentSnapshot to Map with document ID
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      // Log error and rethrow with context
      throw Exception('Failed to fetch maintenance history: $e');
    }
  }

  /// Stream historical maintenance records in real-time.
  /// 
  /// This provides a live-updating stream of historical maintenance records.
  /// Useful for displaying maintenance history that updates automatically
  /// when new records are added or existing ones are modified.
  /// 
  /// Note: The 'now' timestamp is captured at stream creation time, not
  /// recalculated on each emission. This provides a stable filter boundary
  /// and consistent results throughout the stream's lifetime.
  /// 
  /// Parameters:
  /// - [truckNumber]: Optional filter for a specific truck.
  /// - [limit]: Optional limit on number of results.
  /// 
  /// Returns a stream that emits a new list whenever the data changes.
  Stream<List<Map<String, dynamic>>> streamMaintenanceHistory({
    String? truckNumber,
    int? limit,
  }) {
    try {
      // Build query same as getMaintenanceHistory
      Query query = _db.collectionGroup('maintenance');

      if (truckNumber != null && truckNumber.isNotEmpty) {
        query = query.where('truckNumber', isEqualTo: truckNumber);
      }

      // Capture 'now' at stream creation for stable filter boundary
      final now = Timestamp.fromDate(DateTime.now());
      query = query.where('serviceDate', isLessThan: now);

      query = query
          .orderBy('serviceDate', descending: true)
          .orderBy('maintenanceType');

      if (limit != null && limit > 0) {
        query = query.limit(limit);
      }

      // Return stream that transforms snapshots to list of maps
      return query.snapshots().map(
            (snapshot) => snapshot.docs
                .map((doc) => {
                      'id': doc.id,
                      ...doc.data() as Map<String, dynamic>,
                    })
                .toList(),
          );
    } catch (e) {
      // Return error stream
      throw Exception('Failed to stream maintenance history: $e');
    }
  }

  // ========== UPCOMING MAINTENANCE QUERIES ==========

  /// Fetch upcoming maintenance records (serviceDate >= now).
  /// 
  /// Upcoming records are those scheduled for the future or today.
  /// Results are ordered by serviceDate (ascending) and then by name,
  /// so the most urgent maintenance appears first.
  /// 
  /// Parameters:
  /// - [truckNumber]: Optional filter to get records for a specific truck.
  /// - [limit]: Optional limit on number of results.
  /// - [daysAhead]: Optional filter to only include maintenance due within
  ///   the specified number of days. Defaults to null (no upper limit).
  /// 
  /// Returns a list of maintenance record maps.
  Future<List<Map<String, dynamic>>> getUpcomingMaintenance({
    String? truckNumber,
    int? limit,
    int? daysAhead,
  }) async {
    try {
      // Start with collectionGroup query
      Query query = _db.collectionGroup('maintenance');

      // Filter by truck number if specified
      if (truckNumber != null && truckNumber.isNotEmpty) {
        query = query.where('truckNumber', isEqualTo: truckNumber);
      }

      // Filter for upcoming records: serviceDate >= now
      final now = Timestamp.fromDate(DateTime.now());
      query = query.where('serviceDate', isGreaterThanOrEqualTo: now);

      // Optionally filter by days ahead
      if (daysAhead != null && daysAhead > 0) {
        final futureDate = DateTime.now().add(Duration(days: daysAhead));
        query = query.where('serviceDate',
            isLessThanOrEqualTo: Timestamp.fromDate(futureDate));
      }

      // Order by serviceDate ascending (soonest first), then by maintenance type name
      query = query
          .orderBy('serviceDate', descending: false)
          .orderBy('maintenanceType');

      // Apply limit if specified
      if (limit != null && limit > 0) {
        query = query.limit(limit);
      }

      // Execute query
      final snapshot = await query.get();

      // Transform to map list with document ID
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch upcoming maintenance: $e');
    }
  }

  /// Stream upcoming maintenance records in real-time.
  /// 
  /// Provides a live-updating stream of upcoming maintenance records.
  /// Automatically updates when records are added, modified, or when
  /// records transition from upcoming to historical.
  /// 
  /// Note: The 'now' timestamp is captured at stream creation time, not
  /// recalculated on each emission. This provides a stable filter boundary.
  /// Records that pass from future to past during the stream's lifetime
  /// will continue to appear in results until the stream is recreated.
  /// 
  /// Parameters:
  /// - [truckNumber]: Optional filter for a specific truck.
  /// - [limit]: Optional limit on number of results.
  /// - [daysAhead]: Optional filter for maintenance due within N days.
  /// 
  /// Returns a stream that emits a new list whenever the data changes.
  Stream<List<Map<String, dynamic>>> streamUpcomingMaintenance({
    String? truckNumber,
    int? limit,
    int? daysAhead,
  }) {
    try {
      // Build query same as getUpcomingMaintenance
      Query query = _db.collectionGroup('maintenance');

      if (truckNumber != null && truckNumber.isNotEmpty) {
        query = query.where('truckNumber', isEqualTo: truckNumber);
      }

      // Capture 'now' at stream creation for stable filter boundary
      final now = Timestamp.fromDate(DateTime.now());
      query = query.where('serviceDate', isGreaterThanOrEqualTo: now);

      if (daysAhead != null && daysAhead > 0) {
        final futureDate = DateTime.now().add(Duration(days: daysAhead));
        query = query.where('serviceDate',
            isLessThanOrEqualTo: Timestamp.fromDate(futureDate));
      }

      query = query
          .orderBy('serviceDate', descending: false)
          .orderBy('maintenanceType');

      if (limit != null && limit > 0) {
        query = query.limit(limit);
      }

      // Return stream
      return query.snapshots().map(
            (snapshot) => snapshot.docs
                .map((doc) => {
                      'id': doc.id,
                      ...doc.data() as Map<String, dynamic>,
                    })
                .toList(),
          );
    } catch (e) {
      throw Exception('Failed to stream upcoming maintenance: $e');
    }
  }

  // ========== COMBINED QUERIES ==========

  /// Fetch all maintenance records (both history and upcoming).
  /// 
  /// This is useful when you need a complete view of all maintenance
  /// regardless of date. Results are ordered by serviceDate and name.
  /// 
  /// Parameters:
  /// - [truckNumber]: Optional filter for a specific truck.
  /// - [limit]: Optional limit on number of results.
  /// - [descending]: Whether to order by date descending (newest first).
  ///   Defaults to true.
  /// 
  /// Returns a list of all maintenance records.
  Future<List<Map<String, dynamic>>> getAllMaintenance({
    String? truckNumber,
    int? limit,
    bool descending = true,
  }) async {
    try {
      Query query = _db.collectionGroup('maintenance');

      // Filter by truck number if specified
      if (truckNumber != null && truckNumber.isNotEmpty) {
        query = query.where('truckNumber', isEqualTo: truckNumber);
      }

      // Order by serviceDate and name
      query = query
          .orderBy('serviceDate', descending: descending)
          .orderBy('maintenanceType');

      // Apply limit if specified
      if (limit != null && limit > 0) {
        query = query.limit(limit);
      }

      // Execute query
      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch all maintenance records: $e');
    }
  }

  /// Stream all maintenance records in real-time.
  /// 
  /// Provides a live-updating stream of all maintenance records.
  /// 
  /// Parameters:
  /// - [truckNumber]: Optional filter for a specific truck.
  /// - [limit]: Optional limit on number of results.
  /// - [descending]: Whether to order by date descending (newest first).
  ///   Defaults to true.
  /// 
  /// Returns a stream of all maintenance records.
  Stream<List<Map<String, dynamic>>> streamAllMaintenance({
    String? truckNumber,
    int? limit,
    bool descending = true,
  }) {
    try {
      Query query = _db.collectionGroup('maintenance');

      if (truckNumber != null && truckNumber.isNotEmpty) {
        query = query.where('truckNumber', isEqualTo: truckNumber);
      }

      query = query
          .orderBy('serviceDate', descending: descending)
          .orderBy('maintenanceType');

      if (limit != null && limit > 0) {
        query = query.limit(limit);
      }

      return query.snapshots().map(
            (snapshot) => snapshot.docs
                .map((doc) => {
                      'id': doc.id,
                      ...doc.data() as Map<String, dynamic>,
                    })
                .toList(),
          );
    } catch (e) {
      throw Exception('Failed to stream all maintenance records: $e');
    }
  }

  // ========== UTILITY METHODS ==========

  /// Get maintenance statistics for a specific truck.
  /// 
  /// Provides aggregate information about maintenance for a truck including:
  /// - Total maintenance count
  /// - Total cost
  /// - Most recent maintenance date
  /// - Upcoming maintenance count
  /// 
  /// Parameters:
  /// - [truckNumber]: Truck identification number (required).
  /// 
  /// Returns a map with statistics.
  Future<Map<String, dynamic>> getMaintenanceStats(String truckNumber) async {
    try {
      // Fetch all maintenance for the truck
      final allRecords = await getAllMaintenance(truckNumber: truckNumber);

      if (allRecords.isEmpty) {
        return {
          'totalCount': 0,
          'totalCost': 0.0,
          'mostRecentDate': null,
          'upcomingCount': 0,
        };
      }

      // Calculate statistics
      final now = DateTime.now();
      double totalCost = 0.0;
      int upcomingCount = 0;
      DateTime? mostRecentDate;

      for (var record in allRecords) {
        // Add to total cost
        final cost = (record['cost'] as num?)?.toDouble() ?? 0.0;
        totalCost += cost;

        // Check if upcoming
        final serviceDate = DateTimeUtils.parseDateTime(record['serviceDate']) ?? DateTime.now();
        if (serviceDate.isAfter(now) || serviceDate.isAtSameMomentAs(now)) {
          upcomingCount++;
        }

        // Track most recent date
        if (mostRecentDate == null || serviceDate.isAfter(mostRecentDate)) {
          mostRecentDate = serviceDate;
        }
      }

      return {
        'totalCount': allRecords.length,
        'totalCost': totalCost,
        'mostRecentDate': mostRecentDate,
        'upcomingCount': upcomingCount,
      };
    } catch (e) {
      throw Exception('Failed to fetch maintenance stats: $e');
    }
  }

  /// Get list of all unique truck numbers with maintenance records.
  /// 
  /// This is useful for populating dropdowns or filters in the UI.
  /// 
  /// Returns a sorted list of unique truck numbers.
  Future<List<String>> getTruckNumbersWithMaintenance() async {
    try {
      // Query all maintenance records
      final snapshot = await _db.collectionGroup('maintenance').get();

      // Extract unique truck numbers
      final truckNumbers = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final truckNumber = data['truckNumber'] as String?;
        if (truckNumber != null && truckNumber.isNotEmpty) {
          truckNumbers.add(truckNumber);
        }
      }

      // Return sorted list
      final list = truckNumbers.toList();
      list.sort();
      return list;
    } catch (e) {
      throw Exception('Failed to fetch truck numbers: $e');
    }
  }
}

/// MaintenanceRecord is a typed data class for maintenance records.
/// 
/// This provides type-safe access to maintenance record fields and
/// can be used instead of Map<String, dynamic> for better code quality.
class MaintenanceRecord {
  final String id;
  final String driverId;
  final String truckNumber;
  final String maintenanceType;
  final DateTime serviceDate;
  final double cost;
  final DateTime? nextServiceDue;
  final String? serviceProvider;
  final String? notes;
  final DateTime? createdAt;

  MaintenanceRecord({
    required this.id,
    required this.driverId,
    required this.truckNumber,
    required this.maintenanceType,
    required this.serviceDate,
    required this.cost,
    this.nextServiceDue,
    this.serviceProvider,
    this.notes,
    this.createdAt,
  });

  /// Create MaintenanceRecord from Firestore document data.
  factory MaintenanceRecord.fromMap(String id, Map<String, dynamic> data) {
    return MaintenanceRecord(
      id: id,
      driverId: data['driverId'] as String? ?? '',
      truckNumber: data['truckNumber'] as String? ?? '',
      maintenanceType: data['maintenanceType'] as String? ?? '',
      serviceDate: DateTimeUtils.parseDateTime(data['serviceDate']) ?? DateTime.now(),
      cost: (data['cost'] as num?)?.toDouble() ?? 0.0,
      nextServiceDue: DateTimeUtils.parseDateTime(data['nextServiceDue']),
      serviceProvider: data['serviceProvider'] as String?,
      notes: data['notes'] as String?,
      createdAt: DateTimeUtils.parseDateTime(data['createdAt']),
    );
  }

  /// Convert MaintenanceRecord to a map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'truckNumber': truckNumber,
      'maintenanceType': maintenanceType,
      'serviceDate': Timestamp.fromDate(serviceDate),
      'cost': cost,
      'nextServiceDue':
          nextServiceDue != null ? Timestamp.fromDate(nextServiceDue!) : null,
      'serviceProvider': serviceProvider,
      'notes': notes,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  /// Check if this maintenance is historical (completed in the past).
  bool get isHistory => serviceDate.isBefore(DateTime.now());

  /// Check if this maintenance is upcoming (scheduled for future or today).
  bool get isUpcoming => !serviceDate.isBefore(DateTime.now());

  /// Get days until service (negative if in the past).
  int get daysUntilService =>
      serviceDate.difference(DateTime.now()).inDays;

  /// Check if next service is due (within 30 days).
  bool get isNextServiceDue {
    if (nextServiceDue == null) return false;
    final daysUntil = nextServiceDue!.difference(DateTime.now()).inDays;
    return daysUntil <= 30 && daysUntil >= 0;
  }
}
