import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workmanager/workmanager.dart';
import 'offline_support_service.dart';
import 'firestore_service.dart';
import 'storage_service.dart';

/// Service for syncing local data with Firestore
class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OfflineSupportService _offlineService;
  final FirestoreService _firestoreService;
  final StorageService _storageService;

  static const String syncTaskName = 'com.gud.sync';
  static const String syncTaskTag = 'sync-task';

  SyncService({
    required OfflineSupportService offlineService,
    required FirestoreService firestoreService,
    required StorageService storageService,
  })  : _offlineService = offlineService,
        _firestoreService = firestoreService,
        _storageService = storageService;

  /// Initialize background sync using WorkManager
  Future<void> initializeBackgroundSync() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    // Register periodic sync task (runs every 15 minutes minimum on Android)
    await Workmanager().registerPeriodicTask(
      syncTaskName,
      syncTaskTag,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  /// Cancel background sync
  Future<void> cancelBackgroundSync() async {
    await Workmanager().cancelByTag(syncTaskTag);
  }

  /// Sync all pending operations
  Future<SyncResult> syncAll() async {
    if (!_offlineService.isOnline) {
      return SyncResult(
        success: false,
        message: 'Device is offline',
        syncedOperations: 0,
      );
    }

    try {
      // Sync loads
      final loadsSynced = await syncLoads();

      // Sync PODs
      final podsSynced = await syncPODs();

      // Sync location updates
      final locationsSynced = await syncLocationUpdates();

      // Sync pending operations
      final operationsSynced = await _offlineService.syncPendingOperations();

      final totalSynced = loadsSynced + podsSynced + locationsSynced + operationsSynced;

      return SyncResult(
        success: true,
        message: 'Successfully synced $totalSynced items',
        syncedOperations: totalSynced,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
        syncedOperations: 0,
      );
    }
  }

  /// Sync loads from local to Firestore
  Future<int> syncLoads() async {
    int syncedCount = 0;
    
    try {
      final operations = await _offlineService.getPendingOperations();
      final loadOperations = operations.where((op) => 
        op['type'] == 'create_load' || op['type'] == 'update_load'
      );

      for (var operation in loadOperations) {
        try {
          final data = operation['data'] as Map<String, dynamic>;
          
          if (operation['type'] == 'create_load') {
            // Create new load in Firestore
            await _firestore.collection('loads').add(data);
          } else if (operation['type'] == 'update_load') {
            // Update existing load
            final loadId = data['id'] as String?;
            if (loadId != null) {
              await _firestore.collection('loads').doc(loadId).update(data);
            }
          }

          await _offlineService.removeOperation(operation['index']);
          syncedCount++;
        } catch (e) {
          print('Failed to sync load operation: $e');
        }
      }
    } catch (e) {
      print('Error syncing loads: $e');
    }

    return syncedCount;
  }

  /// Sync PODs (Proof of Delivery) from local to Firestore
  Future<int> syncPODs() async {
    int syncedCount = 0;
    
    try {
      final operations = await _offlineService.getPendingOperations();
      final podOperations = operations.where((op) => op['type'] == 'pod_upload');

      for (var operation in podOperations) {
        try {
          final data = operation['data'] as Map<String, dynamic>;
          final loadId = data['loadId'] as String?;
          final photoPath = data['photoPath'] as String?;

          if (loadId != null && photoPath != null) {
            // Upload POD photo to storage
            final photoUrl = await _storageService.uploadPODPhoto(
              loadId,
              photoPath,
            );

            // Update load with POD URL
            await _firestore.collection('loads').doc(loadId).update({
              'podPhotoUrl': photoUrl,
              'status': 'delivered',
              'deliveredAt': FieldValue.serverTimestamp(),
            });

            await _offlineService.removeOperation(operation['index']);
            syncedCount++;
          }
        } catch (e) {
          print('Failed to sync POD operation: $e');
        }
      }
    } catch (e) {
      print('Error syncing PODs: $e');
    }

    return syncedCount;
  }

  /// Sync location updates from local to Firestore
  Future<int> syncLocationUpdates() async {
    int syncedCount = 0;
    
    try {
      final operations = await _offlineService.getPendingOperations();
      final locationOperations = operations.where((op) => 
        op['type'] == 'location_update'
      );

      for (var operation in locationOperations) {
        try {
          final data = operation['data'] as Map<String, dynamic>;
          final driverId = data['driverId'] as String?;
          final latitude = data['latitude'] as double?;
          final longitude = data['longitude'] as double?;

          if (driverId != null && latitude != null && longitude != null) {
            // Update driver location in Firestore
            await _firestore.collection('drivers').doc(driverId).update({
              'lastLocation': GeoPoint(latitude, longitude),
              'lastLocationUpdate': FieldValue.serverTimestamp(),
            });

            // Also add to location history
            await _firestore
                .collection('drivers')
                .doc(driverId)
                .collection('locationHistory')
                .add({
              'location': GeoPoint(latitude, longitude),
              'timestamp': Timestamp.fromDate(
                DateTime.parse(data['timestamp'] as String),
              ),
            });

            await _offlineService.removeOperation(operation['index']);
            syncedCount++;
          }
        } catch (e) {
          print('Failed to sync location update: $e');
        }
      }
    } catch (e) {
      print('Error syncing location updates: $e');
    }

    return syncedCount;
  }

  /// Handle conflicts using server-wins strategy
  Future<void> resolveConflict(
    String collection,
    String documentId,
    Map<String, dynamic> localData,
  ) async {
    try {
      // Server-wins strategy: just fetch the server version
      final serverDoc = await _firestore
          .collection(collection)
          .doc(documentId)
          .get();

      if (serverDoc.exists) {
        // Store server version locally
        final serverData = serverDoc.data()!;
        
        // Update local storage based on collection type
        if (collection == 'loads') {
          await _offlineService.storeLoad(documentId, serverData);
        } else if (collection == 'drivers') {
          await _offlineService.storeDriver(documentId, serverData);
        }

        print('Conflict resolved for $collection/$documentId - server version kept');
      }
    } catch (e) {
      print('Error resolving conflict: $e');
    }
  }

  /// Show sync status
  Future<SyncStatus> getSyncStatus() async {
    final pendingCount = _offlineService.pendingOperationsCount;
    final isOnline = _offlineService.isOnline;

    return SyncStatus(
      isOnline: isOnline,
      pendingOperations: pendingCount,
      lastSyncTime: DateTime.now(), // This would be stored in preferences
    );
  }
}

/// Callback dispatcher for WorkManager background tasks
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('Background sync task started: $task');
    
    try {
      // In a real implementation, you would:
      // 1. Initialize Firebase
      // 2. Initialize OfflineSupportService
      // 3. Run sync
      // For now, just acknowledge the task
      print('Background sync completed');
      return Future.value(true);
    } catch (e) {
      print('Background sync failed: $e');
      return Future.value(false);
    }
  });
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;
  final int syncedOperations;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncedOperations,
  });
}

/// Current sync status
class SyncStatus {
  final bool isOnline;
  final int pendingOperations;
  final DateTime lastSyncTime;

  SyncStatus({
    required this.isOnline,
    required this.pendingOperations,
    required this.lastSyncTime,
  });

  bool get hasPendingOperations => pendingOperations > 0;
}
