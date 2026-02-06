import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Service for managing offline data storage and queued operations
class OfflineSupportService {
  static const String _operationsBoxName = 'offline_operations';
  static const String _loadsBoxName = 'offline_loads';
  static const String _driversBoxName = 'offline_drivers';
  static const String _podsBoxName = 'offline_pods';

  Box<dynamic>? _operationsBox;
  Box<dynamic>? _loadsBox;
  Box<dynamic>? _driversBox;
  Box<dynamic>? _podsBox;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isOnline = true;
  final StreamController<bool> _onlineStatusController =
      StreamController<bool>.broadcast();

  /// Stream of online/offline status
  Stream<bool> get onlineStatus => _onlineStatusController.stream;

  /// Check if currently online
  bool get isOnline => _isOnline;

  /// Initialize Hive and create boxes
  Future<void> initialize() async {
    await Hive.initFlutter();

    _operationsBox = await Hive.openBox(_operationsBoxName);
    _loadsBox = await Hive.openBox(_loadsBoxName);
    _driversBox = await Hive.openBox(_driversBoxName);
    _podsBox = await Hive.openBox(_podsBoxName);

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
  }

  /// Update connection status based on connectivity result
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.isNotEmpty && !results.every((result) => result == ConnectivityResult.none);
    
    if (wasOnline != _isOnline) {
      _onlineStatusController.add(_isOnline);
      
      // If we just came online, try to sync
      if (_isOnline) {
        // Trigger sync - this would be handled by SyncService
        _handleOnlineReconnection();
      }
    }
  }

  /// Handle reconnection to online state
  void _handleOnlineReconnection() {
    // This is a placeholder - actual sync would be triggered by SyncService
    debugPrint('Back online - sync should be triggered');
  }

  /// Queue an offline operation
  /// Types: 'status_update', 'pod_upload', 'location_update', 'create_load', 'update_expense'
  Future<void> queueOperation(String type, Map<String, dynamic> data) async {
    if (_operationsBox == null) {
      throw Exception('OfflineSupportService not initialized');
    }

    final operation = {
      'type': type,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'retries': 0,
    };

    await _operationsBox!.add(operation);
    debugPrint('Queued operation: $type');
  }

  /// Get all pending operations
  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    if (_operationsBox == null) {
      throw Exception('OfflineSupportService not initialized');
    }

    final operations = <Map<String, dynamic>>[];
    for (var i = 0; i < _operationsBox!.length; i++) {
      final operation = _operationsBox!.getAt(i);
      if (operation != null) {
        operations.add({
          'index': i,
          ...Map<String, dynamic>.from(operation),
        });
      }
    }

    return operations;
  }

  /// Remove an operation from the queue
  Future<void> removeOperation(int index) async {
    if (_operationsBox == null) {
      throw Exception('OfflineSupportService not initialized');
    }

    await _operationsBox!.deleteAt(index);
  }

  /// Clear all pending operations
  Future<void> clearOperations() async {
    if (_operationsBox == null) {
      throw Exception('OfflineSupportService not initialized');
    }

    await _operationsBox!.clear();
  }

  /// Sync pending operations to server
  /// Returns number of operations successfully synced
  Future<int> syncPendingOperations() async {
    if (!_isOnline) {
      debugPrint('Cannot sync while offline');
      return 0;
    }

    final operations = await getPendingOperations();
    int syncedCount = 0;

    for (var operation in operations) {
      try {
        // This would call the appropriate service method based on type
        // For now, just mark as synced
        debugPrint('Syncing operation: ${operation['type']}');
        
        await removeOperation(operation['index']);
        syncedCount++;
      } catch (e) {
        debugPrint('Failed to sync operation: $e');
        // Increment retry count
        final retries = (operation['retries'] ?? 0) + 1;
        if (retries > 5) {
          // Too many retries, remove operation
          await removeOperation(operation['index']);
          debugPrint('Operation failed after 5 retries, removing');
        } else {
          // Update retry count
          await _operationsBox!.putAt(operation['index'], {
            ...operation,
            'retries': retries,
          });
        }
      }
    }

    return syncedCount;
  }

  /// Store load data locally
  Future<void> storeLoad(String loadId, Map<String, dynamic> loadData) async {
    if (_loadsBox == null) {
      throw Exception('OfflineSupportService not initialized');
    }

    await _loadsBox!.put(loadId, loadData);
  }

  /// Get load data from local storage
  Map<String, dynamic>? getLoad(String loadId) {
    if (_loadsBox == null) {
      throw Exception('OfflineSupportService not initialized');
    }

    final data = _loadsBox!.get(loadId);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  /// Store driver data locally
  Future<void> storeDriver(String driverId, Map<String, dynamic> driverData) async {
    if (_driversBox == null) {
      throw Exception('OfflineSupportService not initialized');
    }

    await _driversBox!.put(driverId, driverData);
  }

  /// Get driver data from local storage
  Map<String, dynamic>? getDriver(String driverId) {
    if (_driversBox == null) {
      throw Exception('OfflineSupportService not initialized');
    }

    final data = _driversBox!.get(driverId);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  /// Store POD data locally
  Future<void> storePOD(String podId, Map<String, dynamic> podData) async {
    if (_podsBox == null) {
      throw Exception('OfflineSupportService not initialized');
    }

    await _podsBox!.put(podId, podData);
  }

  /// Get POD data from local storage
  Map<String, dynamic>? getPOD(String podId) {
    if (_podsBox == null) {
      throw Exception('OfflineSupportService not initialized');
    }

    final data = _podsBox!.get(podId);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  /// Get count of pending operations
  int get pendingOperationsCount {
    return _operationsBox?.length ?? 0;
  }

  /// Clear all local data
  Future<void> clearAllLocalData() async {
    await _operationsBox?.clear();
    await _loadsBox?.clear();
    await _driversBox?.clear();
    await _podsBox?.clear();
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _onlineStatusController.close();
    await _operationsBox?.close();
    await _loadsBox?.close();
    await _driversBox?.close();
    await _podsBox?.close();
  }
}
