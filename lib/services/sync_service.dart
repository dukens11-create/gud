import 'dart:async';
import 'package:flutter/foundation.dart';
import 'offline_support_service.dart';
import 'firestore_service.dart';
import '../utils/datetime_utils.dart';

/// Sync Service
/// 
/// Handles background synchronization of data:
/// - Syncs queued operations when online
/// - Handles conflict resolution
/// - Manages sync status and errors
/// - Periodic background sync
/// 
/// This service works with OfflineSupportService to sync queued
/// operations when the device comes back online.
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  static SyncService get instance => _instance;
  SyncService._internal();

  final OfflineSupportService _offlineService = OfflineSupportService.instance;
  final FirestoreService _firestoreService = FirestoreService();
  
  Timer? _syncTimer;
  bool _initialized = false;
  bool _isSyncing = false;

  /// Initialize the sync service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Start periodic sync (every 5 minutes)
      _syncTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => syncQueuedOperations(),
      );

      _initialized = true;
      debugPrint('✅ Sync Service initialized');

      // Perform initial sync
      await syncQueuedOperations();
    } catch (e) {
      debugPrint('⚠️ Error initializing Sync Service: $e');
      rethrow;
    }
  }

  /// Sync all queued operations
  Future<void> syncQueuedOperations() async {
    if (!_initialized || _isSyncing) return;

    // Don't sync in offline mode
    if (_offlineService.isOfflineMode) {
      debugPrint('📴 Skipping sync - offline mode enabled');
      return;
    }

    _isSyncing = true;
    debugPrint('🔄 Starting sync...');

    try {
      final queue = _offlineService.getQueuedOperations();
      
      if (queue.isEmpty) {
        debugPrint('✅ Sync complete - no operations to sync');
        return;
      }

      int synced = 0;
      int failed = 0;

      for (final operation in queue) {
        try {
          await _syncOperation(operation);
          synced++;
        } catch (e) {
          debugPrint('⚠️ Error syncing operation: $e');
          failed++;
        }
      }

      // Clear successfully synced operations
      if (synced > 0) {
        await _offlineService.clearQueue();
      }

      debugPrint('✅ Sync complete - $synced synced, $failed failed');
    } catch (e) {
      debugPrint('⚠️ Error during sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a single operation
  Future<void> _syncOperation(Map<String, dynamic> operation) async {
    final type = operation['type'] as String;
    final data = operation['data'] as Map<String, dynamic>;

    debugPrint('🔄 Syncing operation: $type');

    // Handle different operation types
    switch (type) {
      case 'create_load':
        // Sync load creation
        await _firestoreService.createLoad(
          loadNumber: data['loadNumber'] as String,
          driverId: data['driverId'] as String,
          driverName: data['driverName'] as String,
          pickupAddress: data['pickupAddress'] as String,
          deliveryAddress: data['deliveryAddress'] as String,
          rate: (data['rate'] as num).toDouble(),
          miles: data['miles'] != null ? (data['miles'] as num).toDouble() : null,
          notes: data['notes'] as String?,
          createdBy: data['createdBy'] as String,
        );
        break;
      case 'update_load':
        // Sync load update
        await _firestoreService.updateLoad(
          data['loadId'] as String,
          data,
        );
        break;
      case 'update_location':
        // Sync location update
        await _firestoreService.updateDriverLocation(
          driverId: data['driverId'] as String,
          latitude: data['latitude'] as double,
          longitude: data['longitude'] as double,
          timestamp: DateTimeUtils.parseDateTime(data['timestamp']) ?? DateTime.now(),
          accuracy: data['accuracy'] as double,
        );
        break;
      default:
        debugPrint('⚠️ Unknown operation type: $type');
    }
  }

  /// Force sync now
  Future<void> forceSyncNow() async {
    debugPrint('🔄 Force sync triggered');
    await syncQueuedOperations();
  }

  /// Check if sync is in progress
  bool get isSyncing => _isSyncing;

  /// Stop the sync service
  void dispose() {
    _syncTimer?.cancel();
    _initialized = false;
    debugPrint('🛑 Sync Service stopped');
  }
}
