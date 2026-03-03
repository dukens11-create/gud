import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'cache_recovery_service.dart';

/// Offline Support Service
/// 
/// Manages offline functionality and data caching:
/// - Detects network connectivity
/// - Caches data for offline access
/// - Queues operations for later sync
/// - Manages offline mode state
/// 
/// This service works in conjunction with SyncService to provide
/// seamless offline functionality.
class OfflineSupportService {
  static final OfflineSupportService _instance = OfflineSupportService._internal();
  factory OfflineSupportService() => _instance;
  static OfflineSupportService get instance => _instance;
  OfflineSupportService._internal();

  SharedPreferences? _prefs;
  bool _initialized = false;
  bool _isOfflineMode = false;

  /// Initialize the offline support service
  ///
  /// On cache corruption the service automatically clears all stored
  /// preferences via [CacheRecoveryService] and continues with a clean
  /// state rather than crashing.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Load offline mode state
      _isOfflineMode = _prefs?.getBool('offline_mode') ?? false;
      
      _initialized = true;
      debugPrint('✅ Offline Support Service initialized');
    } catch (e, stackTrace) {
      debugPrint('⚠️ Error initializing Offline Support Service: $e');
      // Attempt automatic cache recovery instead of crashing
      await CacheRecoveryService.instance.recoverFromCacheError(
        e,
        stackTrace,
        context: 'OfflineSupportService.initialize',
      );
      // Continue with a degraded (in-memory only) state
      _initialized = true;
    }
  }

  /// Check if the app is in offline mode
  bool get isOfflineMode => _isOfflineMode;

  /// Enable offline mode
  Future<void> enableOfflineMode() async {
    _isOfflineMode = true;
    await _prefs?.setBool('offline_mode', true);
    debugPrint('📴 Offline mode enabled');
  }

  /// Disable offline mode
  Future<void> disableOfflineMode() async {
    _isOfflineMode = false;
    await _prefs?.setBool('offline_mode', false);
    debugPrint('📶 Offline mode disabled');
  }

  /// Cache data locally
  Future<void> cacheData(String key, String value) async {
    if (!_initialized) return;

    try {
      await _prefs?.setString('cache_$key', value);
      debugPrint('💾 Cached data: $key');
    } catch (e) {
      debugPrint('⚠️ Error caching data: $e');
    }
  }

  /// Get cached data
  String? getCachedData(String key) {
    if (!_initialized) return null;

    try {
      return _prefs?.getString('cache_$key');
    } catch (e) {
      debugPrint('⚠️ Error getting cached data: $e');
      return null;
    }
  }

  /// Clear cached data
  Future<void> clearCache() async {
    if (!_initialized) return;

    try {
      final keys = _prefs?.getKeys() ?? {};
      for (final key in keys) {
        if (key.startsWith('cache_')) {
          await _prefs?.remove(key);
        }
      }
      debugPrint('🗑️ Cache cleared');
    } catch (e) {
      debugPrint('⚠️ Error clearing cache: $e');
    }
  }

  /// Queue an operation for later sync
  Future<void> queueOperation({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    if (!_initialized) return;

    try {
      // Get existing queue
      final queueJson = _prefs?.getString('sync_queue') ?? '[]';
      final List<dynamic> queueData = queueJson == '[]' 
          ? [] 
          : List<dynamic>.from(
              (await Future.value(queueJson)).split(',').map((e) => e.trim())
            );
      
      // For now, use a simple list of operation descriptions
      // In production, this should use proper JSON encoding
      final queue = queueData.map((e) => e.toString()).toList();

      // Add new operation as a simple string representation
      queue.add('$type:${data.toString()}');

      // Save updated queue
      await _prefs?.setString('sync_queue', queue.join(','));
      debugPrint('📥 Operation queued: $type');
    } catch (e) {
      debugPrint('⚠️ Error queuing operation: $e');
    }
  }

  /// Get queued operations
  List<Map<String, dynamic>> getQueuedOperations() {
    if (!_initialized) return [];

    try {
      final queueStr = _prefs?.getString('sync_queue') ?? '';
      if (queueStr.isEmpty) return [];
      
      // Parse simple string format
      // In production, this should use proper JSON decoding
      return queueStr.split(',').map((item) {
        final parts = item.split(':');
        if (parts.length < 2) return <String, dynamic>{};
        return <String, dynamic>{
          'type': parts[0],
          'data': parts.sublist(1).join(':'),
        };
      }).where((item) => item.isNotEmpty).toList();
    } catch (e) {
      debugPrint('⚠️ Error getting queued operations: $e');
      return [];
    }
  }

  /// Clear queued operations
  Future<void> clearQueue() async {
    if (!_initialized) return;

    try {
      await _prefs?.remove('sync_queue');
      debugPrint('🗑️ Queue cleared');
    } catch (e) {
      debugPrint('⚠️ Error clearing queue: $e');
    }
  }
}
