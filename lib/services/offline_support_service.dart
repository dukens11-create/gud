import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

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
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Load offline mode state
      _isOfflineMode = _prefs?.getBool('offline_mode') ?? false;
      
      _initialized = true;
      debugPrint('✅ Offline Support Service initialized');
    } catch (e) {
      debugPrint('⚠️ Error initializing Offline Support Service: $e');
      rethrow;
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
      final queue = List<Map<String, dynamic>>.from(
        (queueJson as List).map((e) => e as Map<String, dynamic>),
      );

      // Add new operation
      queue.add({
        'type': type,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Save updated queue
      await _prefs?.setString('sync_queue', queue.toString());
      debugPrint('📥 Operation queued: $type');
    } catch (e) {
      debugPrint('⚠️ Error queuing operation: $e');
    }
  }

  /// Get queued operations
  List<Map<String, dynamic>> getQueuedOperations() {
    if (!_initialized) return [];

    try {
      final queueJson = _prefs?.getString('sync_queue') ?? '[]';
      return List<Map<String, dynamic>>.from(
        (queueJson as List).map((e) => e as Map<String, dynamic>),
      );
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
