import 'package:shared_preferences/shared_preferences.dart';

/// Feature flags for controlling app features remotely
/// 
/// Allows enabling/disabling features without app updates
/// In production, load from Firebase Remote Config
class FeatureFlags {
  // Singleton pattern
  static final FeatureFlags _instance = FeatureFlags._internal();
  factory FeatureFlags() => _instance;
  FeatureFlags._internal();

  SharedPreferences? _prefs;

  // Feature flag keys
  static const String _biometricAuthKey = 'feature_biometric_auth';
  static const String _geofencingKey = 'feature_geofencing';
  static const String _offlineModeKey = 'feature_offline_mode';
  static const String _analyticsKey = 'feature_analytics';
  static const String _backgroundLocationKey = 'feature_background_location';
  static const String _pushNotificationsKey = 'feature_push_notifications';
  static const String _invoicingKey = 'feature_invoicing';
  static const String _exportReportsKey = 'feature_export_reports';
  static const String _driverPerformanceKey = 'feature_driver_performance';
  static const String _expenseTrackingKey = 'feature_expense_tracking';

  // Default values (fallback if not set)
  final Map<String, bool> _defaults = {
    _biometricAuthKey: true,
    _geofencingKey: true,
    _offlineModeKey: true,
    _analyticsKey: true,
    _backgroundLocationKey: true,
    _pushNotificationsKey: true,
    _invoicingKey: true,
    _exportReportsKey: true,
    _driverPerformanceKey: true,
    _expenseTrackingKey: true,
  };

  /// Initialize feature flags
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    
    // In production, this would fetch from Firebase Remote Config
    // await _fetchRemoteConfig();
  }

  /// Get feature flag value
  bool _getFlag(String key) {
    if (_prefs == null) {
      return _defaults[key] ?? false;
    }
    return _prefs!.getBool(key) ?? _defaults[key] ?? false;
  }

  /// Set feature flag value (for testing/development)
  Future<void> _setFlag(String key, bool value) async {
    if (_prefs != null) {
      await _prefs!.setBool(key, value);
    }
  }

  // Getters for each feature flag
  
  /// Biometric authentication (fingerprint/face ID)
  bool get isBiometricAuthEnabled => _getFlag(_biometricAuthKey);
  Future<void> setBiometricAuth(bool value) => _setFlag(_biometricAuthKey, value);

  /// Geofencing (automatic location-based actions)
  bool get isGeofencingEnabled => _getFlag(_geofencingKey);
  Future<void> setGeofencing(bool value) => _setFlag(_geofencingKey, value);

  /// Offline mode (local data storage and sync)
  bool get isOfflineModeEnabled => _getFlag(_offlineModeKey);
  Future<void> setOfflineMode(bool value) => _setFlag(_offlineModeKey, value);

  /// Analytics (Firebase Analytics, user tracking)
  bool get isAnalyticsEnabled => _getFlag(_analyticsKey);
  Future<void> setAnalytics(bool value) => _setFlag(_analyticsKey, value);

  /// Background location tracking
  bool get isBackgroundLocationEnabled => _getFlag(_backgroundLocationKey);
  Future<void> setBackgroundLocation(bool value) => _setFlag(_backgroundLocationKey, value);

  /// Push notifications
  bool get isPushNotificationsEnabled => _getFlag(_pushNotificationsKey);
  Future<void> setPushNotifications(bool value) => _setFlag(_pushNotificationsKey, value);

  /// Invoicing system
  bool get isInvoicingEnabled => _getFlag(_invoicingKey);
  Future<void> setInvoicing(bool value) => _setFlag(_invoicingKey, value);

  /// Export reports (CSV/PDF)
  bool get isExportReportsEnabled => _getFlag(_exportReportsKey);
  Future<void> setExportReports(bool value) => _setFlag(_exportReportsKey, value);

  /// Driver performance tracking
  bool get isDriverPerformanceEnabled => _getFlag(_driverPerformanceKey);
  Future<void> setDriverPerformance(bool value) => _setFlag(_driverPerformanceKey, value);

  /// Expense tracking
  bool get isExpenseTrackingEnabled => _getFlag(_expenseTrackingKey);
  Future<void> setExpenseTracking(bool value) => _setFlag(_expenseTrackingKey, value);

  /// Get all feature flags as a map
  Map<String, bool> getAllFlags() {
    return {
      'Biometric Auth': isBiometricAuthEnabled,
      'Geofencing': isGeofencingEnabled,
      'Offline Mode': isOfflineModeEnabled,
      'Analytics': isAnalyticsEnabled,
      'Background Location': isBackgroundLocationEnabled,
      'Push Notifications': isPushNotificationsEnabled,
      'Invoicing': isInvoicingEnabled,
      'Export Reports': isExportReportsEnabled,
      'Driver Performance': isDriverPerformanceEnabled,
      'Expense Tracking': isExpenseTrackingEnabled,
    };
  }

  /// Reset all feature flags to defaults
  Future<void> resetToDefaults() async {
    if (_prefs != null) {
      for (var entry in _defaults.entries) {
        await _prefs!.setBool(entry.key, entry.value);
      }
    }
  }

  /// Fetch feature flags from Firebase Remote Config
  /// This is a placeholder - implement with firebase_remote_config package
  Future<void> _fetchRemoteConfig() async {
    // TODO: Implement Firebase Remote Config integration
    // 
    // Example implementation:
    // 
    // final remoteConfig = FirebaseRemoteConfig.instance;
    // await remoteConfig.setConfigSettings(RemoteConfigSettings(
    //   fetchTimeout: const Duration(minutes: 1),
    //   minimumFetchInterval: const Duration(hours: 1),
    // ));
    // 
    // await remoteConfig.setDefaults(_defaults);
    // await remoteConfig.fetchAndActivate();
    // 
    // // Update local values from remote config
    // for (var key in _defaults.keys) {
    //   final value = remoteConfig.getBool(key);
    //   await _setFlag(key, value);
    // }
  }

  /// Manually trigger remote config fetch (for testing)
  Future<void> refreshRemoteConfig() async {
    await _fetchRemoteConfig();
  }
}

/// Global instance for easy access
final featureFlags = FeatureFlags();
