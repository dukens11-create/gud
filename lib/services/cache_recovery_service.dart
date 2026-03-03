import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'crash_reporting_service.dart';

/// Cache Recovery Service
///
/// Provides centralized detection and recovery from cache/local storage
/// corruption or errors:
/// - Detects SharedPreferences read/write failures
/// - Automatically clears corrupted cache
/// - Reports errors to Crashlytics for backend analytics
/// - Exposes recovery status so the UI can inform the user
///
/// ## Recovery Logic
///
/// 1. Any unhandled exception from SharedPreferences is caught here.
/// 2. The service attempts to call `SharedPreferences.clear()` to wipe
///    the corrupted data.
/// 3. The error is forwarded to [CrashReportingService] (Crashlytics) so
///    it appears in the Firebase Crashlytics dashboard.
/// 4. [wasCacheCleared] is set to `true` so the calling widget can show
///    an in-app banner / snackbar instead of letting the app crash.
class CacheRecoveryService {
  static final CacheRecoveryService _instance =
      CacheRecoveryService._internal();
  factory CacheRecoveryService() => _instance;
  static CacheRecoveryService get instance => _instance;
  CacheRecoveryService._internal();

  /// Set to `true` after the service has automatically cleared corrupted
  /// cache data. Reset to `false` once the UI has shown a recovery message.
  bool wasCacheCleared = false;

  /// Attempt to recover from a SharedPreferences error.
  ///
  /// Call this whenever a catch block catches an exception from a
  /// SharedPreferences operation. The method will:
  /// 1. Log the [error] and [stackTrace] to Crashlytics.
  /// 2. Try to clear all SharedPreferences data.
  /// 3. Set [wasCacheCleared] to `true`.
  ///
  /// Returns `true` if recovery succeeded (cache cleared), `false` otherwise.
  Future<bool> recoverFromCacheError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
  }) async {
    debugPrint('🚨 Cache/storage error detected: $error');
    if (context != null) {
      debugPrint('   Context: $context');
    }

    // Report to Crashlytics (non-fatal)
    try {
      await CrashReportingService().logError(
        error,
        stackTrace,
        reason: 'Cache/SharedPreferences corruption detected',
        context: context != null ? {'cache_context': context} : null,
      );
    } catch (reportingError) {
      debugPrint('⚠️ Could not report cache error to Crashlytics: $reportingError');
    }

    // Attempt to clear corrupted preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      wasCacheCleared = true;
      debugPrint('🗑️ Corrupted cache cleared successfully');
      return true;
    } catch (clearError) {
      debugPrint('❌ Failed to clear cache: $clearError');
      return false;
    }
  }

  /// Mark the recovery notification as shown so [wasCacheCleared] is reset.
  void acknowledgeRecovery() {
    wasCacheCleared = false;
  }
}
