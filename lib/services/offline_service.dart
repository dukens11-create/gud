import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../services/analytics_service.dart';
import '../services/crash_reporting_service.dart';

/// Offline Support Service
/// 
/// Provides comprehensive offline functionality:
/// - Network connectivity monitoring
/// - Local data caching with SQLite
/// - Operation queueing when offline
/// - Automatic sync when back online
/// - Conflict resolution strategies
class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final Connectivity _connectivity = Connectivity();
  final AnalyticsService _analytics = AnalyticsService();
  final CrashReportingService _crashReporting = CrashReportingService();
  
  Database? _database;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final _connectivityController = StreamController<bool>.broadcast();
  
  bool _isOnline = true;
  bool _initialized = false;

  /// Get online/offline status stream
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Get current online status
  bool get isOnline => _isOnline;

  /// Initialize offline service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize database
      await _initDatabase();

      // Check initial connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      _isOnline = !connectivityResult.contains(ConnectivityResult.none);
      
      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
      );

      _initialized = true;
      print('✅ Offline service initialized - ${_isOnline ? "Online" : "Offline"}');
      
      await _analytics.logCustomEvent('offline_service_initialized', parameters: {
        'initial_status': _isOnline ? 'online' : 'offline',
      });
    } catch (e) {
      print('❌ Error initializing offline service: $e');
      await _crashReporting.logError(e, StackTrace.current, reason: 'Offline service init failed');
    }
  }

  /// Initialize SQLite database
  Future<void> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'gud_offline.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Cached data table
        await db.execute('''
          CREATE TABLE cached_data (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            data TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            expiresAt INTEGER
          )
        ''');

        // Pending operations queue
        await db.execute('''
          CREATE TABLE pending_operations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            operation_type TEXT NOT NULL,
            collection TEXT NOT NULL,
            document_id TEXT,
            data TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            retry_count INTEGER DEFAULT 0,
            status TEXT DEFAULT 'pending'
          )
        ''');

        // Sync conflicts table
        await db.execute('''
          CREATE TABLE sync_conflicts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            collection TEXT NOT NULL,
            document_id TEXT NOT NULL,
            local_data TEXT NOT NULL,
            remote_data TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            resolved INTEGER DEFAULT 0
          )
        ''');

        print('✅ Offline database created');
      },
    );
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = !results.contains(ConnectivityResult.none);
    
    print('🌐 Connectivity changed: ${_isOnline ? "Online" : "Offline"}');
    
    _connectivityController.add(_isOnline);

    // Log connectivity change
    _analytics.logCustomEvent('connectivity_changed', parameters: {
      'status': _isOnline ? 'online' : 'offline',
      'previous_status': wasOnline ? 'online' : 'offline',
    });

    // Trigger sync when coming back online
    if (!wasOnline && _isOnline) {
      print('🔄 Back online - triggering sync');
      _onBackOnline();
    }
  }

  /// Called when app comes back online
  void _onBackOnline() {
    // Notify sync service to start syncing
    // This will be handled by SyncService
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Cache data locally
  Future<void> cacheData({
    required String id,
    required String type,
    required Map<String, dynamic> data,
    Duration? expiresIn,
  }) async {
    if (_database == null) return;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final expiresAt = expiresIn != null
          ? timestamp + expiresIn.inMilliseconds
          : null;

      await _database!.insert(
        'cached_data',
        {
          'id': id,
          'type': type,
          'data': jsonEncode(data),
          'timestamp': timestamp,
          'expiresAt': expiresAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('✅ Data cached: $type/$id');
    } catch (e) {
      print('❌ Error caching data: $e');
      await _crashReporting.logError(e, StackTrace.current);
    }
  }

  /// Get cached data
  Future<Map<String, dynamic>?> getCachedData({
    required String id,
    required String type,
  }) async {
    if (_database == null) return null;

    try {
      final results = await _database!.query(
        'cached_data',
        where: 'id = ? AND type = ?',
        whereArgs: [id, type],
      );

      if (results.isEmpty) return null;

      final row = results.first;
      final expiresAt = row['expiresAt'] as int?;
      
      // Check if expired
      if (expiresAt != null && expiresAt < DateTime.now().millisecondsSinceEpoch) {
        await deleteCachedData(id: id, type: type);
        return null;
      }

      return jsonDecode(row['data'] as String) as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error getting cached data: $e');
      return null;
    }
  }

  /// Get all cached data of a type
  Future<List<Map<String, dynamic>>> getCachedDataByType(String type) async {
    if (_database == null) return [];

    try {
      final results = await _database!.query(
        'cached_data',
        where: 'type = ?',
        whereArgs: [type],
      );

      final now = DateTime.now().millisecondsSinceEpoch;
      final validData = <Map<String, dynamic>>[];

      for (final row in results) {
        final expiresAt = row['expiresAt'] as int?;
        
        if (expiresAt == null || expiresAt >= now) {
          validData.add(jsonDecode(row['data'] as String) as Map<String, dynamic>);
        } else {
          // Delete expired data
          await deleteCachedData(id: row['id'] as String, type: type);
        }
      }

      return validData;
    } catch (e) {
      print('❌ Error getting cached data by type: $e');
      return [];
    }
  }

  /// Delete cached data
  Future<void> deleteCachedData({
    required String id,
    required String type,
  }) async {
    if (_database == null) return;

    try {
      await _database!.delete(
        'cached_data',
        where: 'id = ? AND type = ?',
        whereArgs: [id, type],
      );
    } catch (e) {
      print('❌ Error deleting cached data: $e');
    }
  }

  /// Clear all expired cache
  Future<void> clearExpiredCache() async {
    if (_database == null) return;

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _database!.delete(
        'cached_data',
        where: 'expiresAt IS NOT NULL AND expiresAt < ?',
        whereArgs: [now],
      );
      print('✅ Expired cache cleared');
    } catch (e) {
      print('❌ Error clearing expired cache: $e');
    }
  }

  // ==================== OPERATION QUEUE ====================

  /// Queue operation for later execution
  Future<int?> queueOperation({
    required String operationType,
    required String collection,
    String? documentId,
    required Map<String, dynamic> data,
  }) async {
    if (_database == null) return null;

    try {
      final id = await _database!.insert(
        'pending_operations',
        {
          'operation_type': operationType,
          'collection': collection,
          'document_id': documentId,
          'data': jsonEncode(data),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'retry_count': 0,
          'status': 'pending',
        },
      );

      print('✅ Operation queued: $operationType on $collection');
      
      await _analytics.logCustomEvent('operation_queued', parameters: {
        'operation_type': operationType,
        'collection': collection,
      });

      return id;
    } catch (e) {
      print('❌ Error queueing operation: $e');
      await _crashReporting.logError(e, StackTrace.current);
      return null;
    }
  }

  /// Get pending operations
  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    if (_database == null) return [];

    try {
      final results = await _database!.query(
        'pending_operations',
        where: 'status = ?',
        whereArgs: ['pending'],
        orderBy: 'timestamp ASC',
      );

      return results;
    } catch (e) {
      print('❌ Error getting pending operations: $e');
      return [];
    }
  }

  /// Get pending operations count
  Future<int> getPendingOperationsCount() async {
    if (_database == null) return 0;

    try {
      final result = await _database!.rawQuery(
        'SELECT COUNT(*) as count FROM pending_operations WHERE status = ?',
        ['pending'],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('❌ Error getting pending operations count: $e');
      return 0;
    }
  }

  /// Mark operation as completed
  Future<void> markOperationCompleted(int operationId) async {
    if (_database == null) return;

    try {
      await _database!.update(
        'pending_operations',
        {'status': 'completed'},
        where: 'id = ?',
        whereArgs: [operationId],
      );
    } catch (e) {
      print('❌ Error marking operation completed: $e');
    }
  }

  /// Mark operation as failed
  Future<void> markOperationFailed(int operationId) async {
    if (_database == null) return;

    try {
      await _database!.rawUpdate(
        'UPDATE pending_operations SET status = ?, retry_count = retry_count + 1 WHERE id = ?',
        ['failed', operationId],
      );
    } catch (e) {
      print('❌ Error marking operation failed: $e');
    }
  }

  /// Delete completed operations
  Future<void> deleteCompletedOperations() async {
    if (_database == null) return;

    try {
      await _database!.delete(
        'pending_operations',
        where: 'status = ?',
        whereArgs: ['completed'],
      );
      print('✅ Completed operations deleted');
    } catch (e) {
      print('❌ Error deleting completed operations: $e');
    }
  }

  // ==================== CONFLICT RESOLUTION ====================

  /// Record sync conflict
  Future<void> recordConflict({
    required String collection,
    required String documentId,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
  }) async {
    if (_database == null) return;

    try {
      await _database!.insert(
        'sync_conflicts',
        {
          'collection': collection,
          'document_id': documentId,
          'local_data': jsonEncode(localData),
          'remote_data': jsonEncode(remoteData),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'resolved': 0,
        },
      );

      print('⚠️ Sync conflict recorded: $collection/$documentId');
      
      await _analytics.logCustomEvent('sync_conflict', parameters: {
        'collection': collection,
        'document_id': documentId,
      });
    } catch (e) {
      print('❌ Error recording conflict: $e');
    }
  }

  /// Get unresolved conflicts
  Future<List<Map<String, dynamic>>> getUnresolvedConflicts() async {
    if (_database == null) return [];

    try {
      final results = await _database!.query(
        'sync_conflicts',
        where: 'resolved = ?',
        whereArgs: [0],
      );

      return results.map((row) {
        return {
          'id': row['id'],
          'collection': row['collection'],
          'document_id': row['document_id'],
          'local_data': jsonDecode(row['local_data'] as String),
          'remote_data': jsonDecode(row['remote_data'] as String),
          'timestamp': row['timestamp'],
        };
      }).toList();
    } catch (e) {
      print('❌ Error getting unresolved conflicts: $e');
      return [];
    }
  }

  /// Mark conflict as resolved
  Future<void> markConflictResolved(int conflictId) async {
    if (_database == null) return;

    try {
      await _database!.update(
        'sync_conflicts',
        {'resolved': 1},
        where: 'id = ?',
        whereArgs: [conflictId],
      );
      print('✅ Conflict resolved: $conflictId');
    } catch (e) {
      print('❌ Error marking conflict resolved: $e');
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Clear all offline data
  Future<void> clearAllData() async {
    if (_database == null) return;

    try {
      await _database!.delete('cached_data');
      await _database!.delete('pending_operations');
      await _database!.delete('sync_conflicts');
      print('✅ All offline data cleared');
    } catch (e) {
      print('❌ Error clearing all data: $e');
    }
  }

  /// Get storage statistics
  Future<Map<String, int>> getStorageStats() async {
    if (_database == null) return {};

    try {
      final cachedCount = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM cached_data'),
      ) ?? 0;

      final pendingCount = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM pending_operations WHERE status = ?', ['pending']),
      ) ?? 0;

      final conflictsCount = Sqflite.firstIntValue(
        await _database!.rawQuery('SELECT COUNT(*) FROM sync_conflicts WHERE resolved = ?', [0]),
      ) ?? 0;

      return {
        'cached_items': cachedCount,
        'pending_operations': pendingCount,
        'unresolved_conflicts': conflictsCount,
      };
    } catch (e) {
      print('❌ Error getting storage stats: $e');
      return {};
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _connectivityController.close();
    await _database?.close();
    _initialized = false;
    print('✅ Offline service disposed');
  }
}
