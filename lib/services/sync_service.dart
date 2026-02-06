import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/offline_service.dart';
import '../services/analytics_service.dart';
import '../services/crash_reporting_service.dart';

/// Synchronization Service
/// 
/// Manages data synchronization between local and remote storage:
/// - Monitors online/offline transitions
/// - Syncs pending operations when online
/// - Uploads queued data to Firestore
/// - Downloads updates from server
/// - Handles sync conflicts with strategies
/// - Reports sync progress
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final OfflineService _offlineService = OfflineService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService();
  final CrashReportingService _crashReporting = CrashReportingService();

  StreamSubscription<bool>? _connectivitySubscription;
  final _syncProgressController = StreamController<SyncProgress>.broadcast();
  
  bool _isSyncing = false;
  bool _initialized = false;

  /// Get sync progress stream
  Stream<SyncProgress> get syncProgressStream => _syncProgressController.stream;

  /// Check if currently syncing
  bool get isSyncing => _isSyncing;

  /// Initialize sync service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Listen for connectivity changes
      _connectivitySubscription = _offlineService.connectivityStream.listen(
        _onConnectivityChanged,
      );

      _initialized = true;
      print('✅ Sync service initialized');
    } catch (e) {
      print('❌ Error initializing sync service: $e');
      await _crashReporting.logError(e, StackTrace.current);
    }
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(bool isOnline) {
    if (isOnline && !_isSyncing) {
      print('🔄 Device online - starting sync');
      syncAll();
    }
  }

  /// Sync all pending operations
  Future<void> syncAll() async {
    if (_isSyncing) {
      print('⚠️ Sync already in progress');
      return;
    }

    if (!_offlineService.isOnline) {
      print('⚠️ Cannot sync - device is offline');
      return;
    }

    _isSyncing = true;
    _emitProgress(SyncStatus.syncing, 0, 0);

    try {
      print('🔄 Starting sync...');
      
      // Get pending operations
      final pendingOps = await _offlineService.getPendingOperations();
      final totalOps = pendingOps.length;

      if (totalOps == 0) {
        print('✅ No pending operations to sync');
        _emitProgress(SyncStatus.completed, 0, 0);
        return;
      }

      print('📤 Syncing $totalOps pending operations...');
      int completed = 0;
      int failed = 0;

      // Process each operation
      for (final op in pendingOps) {
        try {
          await _syncOperation(op);
          await _offlineService.markOperationCompleted(op['id'] as int);
          completed++;
          
          _emitProgress(SyncStatus.syncing, completed, totalOps);
        } catch (e) {
          print('❌ Failed to sync operation ${op['id']}: $e');
          await _offlineService.markOperationFailed(op['id'] as int);
          failed++;
          
          await _crashReporting.logError(
            e, 
            StackTrace.current,
            reason: 'Sync operation failed',
          );
        }
      }

      // Clean up completed operations
      await _offlineService.deleteCompletedOperations();

      print('✅ Sync completed: $completed succeeded, $failed failed');
      
      _emitProgress(
        failed == 0 ? SyncStatus.completed : SyncStatus.partiallyCompleted,
        completed,
        totalOps,
      );

      await _analytics.logCustomEvent('sync_completed', parameters: {
        'total_operations': totalOps.toString(),
        'succeeded': completed.toString(),
        'failed': failed.toString(),
      });

    } catch (e) {
      print('❌ Sync failed: $e');
      _emitProgress(SyncStatus.failed, 0, 0);
      
      await _crashReporting.logError(e, StackTrace.current, reason: 'Sync failed');
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a single operation
  Future<void> _syncOperation(Map<String, dynamic> operation) async {
    final operationType = operation['operation_type'] as String;
    final collection = operation['collection'] as String;
    final documentId = operation['document_id'] as String?;
    final data = jsonDecode(operation['data'] as String) as Map<String, dynamic>;

    print('🔄 Syncing $operationType on $collection${documentId != null ? "/$documentId" : ""}');

    switch (operationType) {
      case 'create':
        await _syncCreate(collection, data);
        break;
      case 'update':
        if (documentId != null) {
          await _syncUpdate(collection, documentId, data);
        }
        break;
      case 'delete':
        if (documentId != null) {
          await _syncDelete(collection, documentId);
        }
        break;
      default:
        print('⚠️ Unknown operation type: $operationType');
    }
  }

  /// Sync create operation
  Future<void> _syncCreate(String collection, Map<String, dynamic> data) async {
    try {
      // Add server timestamp
      data['syncedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection(collection).add(data);
      print('✅ Created document in $collection');
    } catch (e) {
      print('❌ Error creating document: $e');
      rethrow;
    }
  }

  /// Sync update operation
  Future<void> _syncUpdate(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Check for conflicts
      final docSnapshot = await _firestore
          .collection(collection)
          .doc(documentId)
          .get();

      if (!docSnapshot.exists) {
        print('⚠️ Document does not exist, creating instead');
        await _syncCreate(collection, {...data, 'id': documentId});
        return;
      }

      final remoteData = docSnapshot.data()!;
      
      // Check for conflicts (simplified - compare timestamps)
      if (remoteData['updatedAt'] != null && data['updatedAt'] != null) {
        final remoteTimestamp = (remoteData['updatedAt'] as Timestamp).toDate();
        final localTimestamp = data['updatedAt'] is Timestamp
            ? (data['updatedAt'] as Timestamp).toDate()
            : DateTime.parse(data['updatedAt'] as String);

        if (remoteTimestamp.isAfter(localTimestamp)) {
          // Remote is newer - conflict detected
          await _handleConflict(collection, documentId, data, remoteData);
          return;
        }
      }

      // No conflict - proceed with update
      data['syncedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(collection).doc(documentId).update(data);
      print('✅ Updated document in $collection/$documentId');
    } catch (e) {
      print('❌ Error updating document: $e');
      rethrow;
    }
  }

  /// Sync delete operation
  Future<void> _syncDelete(String collection, String documentId) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
      print('✅ Deleted document from $collection/$documentId');
    } catch (e) {
      print('❌ Error deleting document: $e');
      rethrow;
    }
  }

  /// Handle sync conflict
  Future<void> _handleConflict(
    String collection,
    String documentId,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) async {
    print('⚠️ Conflict detected for $collection/$documentId');

    // Record conflict
    await _offlineService.recordConflict(
      collection: collection,
      documentId: documentId,
      localData: localData,
      remoteData: remoteData,
    );

    // Apply conflict resolution strategy
    final resolvedData = await _resolveConflict(
      collection,
      localData,
      remoteData,
    );

    if (resolvedData != null) {
      // Update with resolved data
      resolvedData['syncedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection(collection)
          .doc(documentId)
          .update(resolvedData);
      
      print('✅ Conflict resolved for $collection/$documentId');
    }
  }

  /// Resolve conflict using strategy
  Future<Map<String, dynamic>?> _resolveConflict(
    String collection,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) async {
    // Default strategy: Remote wins (last-write-wins from server)
    // You can implement more sophisticated strategies based on collection type
    
    switch (collection) {
      case 'loads':
        // For loads, prefer remote if status is more advanced
        return _resolveLoadConflict(localData, remoteData);
      
      case 'drivers':
      case 'users':
        // For user data, merge changes
        return _mergeUserData(localData, remoteData);
      
      default:
        // Default: remote wins
        return remoteData;
    }
  }

  /// Resolve load-specific conflicts
  Map<String, dynamic> _resolveLoadConflict(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    // Status progression: assigned -> in_transit -> at_pickup -> at_delivery -> delivered
    const statusPriority = {
      'assigned': 1,
      'in_transit': 2,
      'at_pickup': 3,
      'at_delivery': 4,
      'delivered': 5,
    };

    final localStatus = local['status'] as String?;
    final remoteStatus = remote['status'] as String?;

    // Use status with higher priority
    if (localStatus != null && remoteStatus != null) {
      final localPriority = statusPriority[localStatus] ?? 0;
      final remotePriority = statusPriority[remoteStatus] ?? 0;

      return localPriority > remotePriority ? local : remote;
    }

    return remote;
  }

  /// Merge user data
  Map<String, dynamic> _mergeUserData(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    // Merge strategy: take newer values for each field
    final merged = Map<String, dynamic>.from(remote);

    for (final key in local.keys) {
      if (key == 'updatedAt') continue;
      
      // If local has a value and remote doesn't, use local
      if (!remote.containsKey(key) || remote[key] == null) {
        merged[key] = local[key];
      }
    }

    return merged;
  }

  /// Sync specific collection data
  Future<void> syncCollection(String collection) async {
    if (!_offlineService.isOnline) {
      print('⚠️ Cannot sync collection - device is offline');
      return;
    }

    try {
      print('🔄 Syncing $collection collection...');

      final snapshot = await _firestore.collection(collection).get();
      
      for (final doc in snapshot.docs) {
        await _offlineService.cacheData(
          id: doc.id,
          type: collection,
          data: doc.data(),
          expiresIn: const Duration(hours: 24),
        );
      }

      print('✅ Synced ${snapshot.docs.length} documents from $collection');
    } catch (e) {
      print('❌ Error syncing collection: $e');
      await _crashReporting.logError(e, StackTrace.current);
    }
  }

  /// Download updates for a specific document
  Future<void> downloadDocument(String collection, String documentId) async {
    if (!_offlineService.isOnline) {
      print('⚠️ Cannot download - device is offline');
      return;
    }

    try {
      final doc = await _firestore
          .collection(collection)
          .doc(documentId)
          .get();

      if (doc.exists) {
        await _offlineService.cacheData(
          id: doc.id,
          type: collection,
          data: doc.data()!,
          expiresIn: const Duration(hours: 24),
        );
        
        print('✅ Downloaded $collection/$documentId');
      }
    } catch (e) {
      print('❌ Error downloading document: $e');
    }
  }

  /// Force sync now
  Future<void> forceSyncNow() async {
    print('🔄 Force sync requested');
    await syncAll();
  }

  /// Retry failed operations
  Future<void> retryFailedOperations() async {
    if (!_offlineService.isOnline) {
      print('⚠️ Cannot retry - device is offline');
      return;
    }

    print('🔄 Retrying failed operations...');
    await syncAll();
  }

  /// Get sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    final pendingCount = await _offlineService.getPendingOperationsCount();
    final conflicts = await _offlineService.getUnresolvedConflicts();
    final stats = await _offlineService.getStorageStats();

    return {
      'is_syncing': _isSyncing,
      'is_online': _offlineService.isOnline,
      'pending_operations': pendingCount,
      'unresolved_conflicts': conflicts.length,
      'storage_stats': stats,
    };
  }

  /// Emit sync progress
  void _emitProgress(SyncStatus status, int completed, int total) {
    final progress = SyncProgress(
      status: status,
      completed: completed,
      total: total,
      timestamp: DateTime.now(),
    );
    
    _syncProgressController.add(progress);
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _syncProgressController.close();
    _initialized = false;
    print('✅ Sync service disposed');
  }
}

/// Sync progress data
class SyncProgress {
  final SyncStatus status;
  final int completed;
  final int total;
  final DateTime timestamp;

  SyncProgress({
    required this.status,
    required this.completed,
    required this.total,
    required this.timestamp,
  });

  double get progress => total > 0 ? completed / total : 0.0;

  String get message {
    switch (status) {
      case SyncStatus.idle:
        return 'Sync idle';
      case SyncStatus.syncing:
        return 'Syncing $completed of $total operations';
      case SyncStatus.completed:
        return 'Sync completed successfully';
      case SyncStatus.partiallyCompleted:
        return 'Sync partially completed';
      case SyncStatus.failed:
        return 'Sync failed';
    }
  }
}

/// Sync status enum
enum SyncStatus {
  idle,
  syncing,
  completed,
  partiallyCompleted,
  failed,
}
