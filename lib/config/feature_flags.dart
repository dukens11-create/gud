/// Feature flags for controlling app functionality.
///
/// This file manages feature flags that allow enabling/disabling features
/// without code changes. Supports local overrides for testing and preparation
/// for remote config integration.
library;

import 'environment.dart';

/// Feature flags singleton for managing app features.
///
/// Features can be toggled based on environment, remote configuration,
/// or local overrides for testing.
///
/// Example usage:
/// ```dart
/// if (FeatureFlags.instance.enableBiometric) {
///   // Show biometric authentication option
/// }
/// ```
class FeatureFlags {
  FeatureFlags._internal();

  static final FeatureFlags _instance = FeatureFlags._internal();

  /// Gets the singleton instance of FeatureFlags.
  static FeatureFlags get instance => _instance;

  /// Local overrides for feature flags (useful for testing).
  final Map<String, bool> _localOverrides = {};

  /// Remote config values (to be integrated with Firebase Remote Config).
  final Map<String, bool> _remoteConfig = {};

  /// Whether remote config has been fetched.
  bool _remoteConfigFetched = false;

  // Authentication Features
  /// Enables biometric authentication (fingerprint/face ID).
  bool get enableBiometric =>
      _getFlag('enableBiometric', defaultValue: true);

  /// Enables two-factor authentication.
  bool get enableTwoFactorAuth =>
      _getFlag('enableTwoFactorAuth', defaultValue: false);

  /// Enables social login (Google, Apple).
  bool get enableSocialLogin =>
      _getFlag('enableSocialLogin', defaultValue: false);

  // Delivery Features
  /// Enables real-time GPS tracking for deliveries.
  bool get enableGpsTracking =>
      _getFlag('enableGpsTracking', defaultValue: true);

  /// Enables geofencing for automatic delivery status updates.
  bool get enableGeofencing =>
      _getFlag('enableGeofencing', defaultValue: true);

  /// Enables route optimization.
  bool get enableRouteOptimization =>
      _getFlag('enableRouteOptimization', defaultValue: false);

  /// Enables barcode/QR code scanning for deliveries.
  bool get enableBarcodeScanning =>
      _getFlag('enableBarcodeScanning', defaultValue: true);

  /// Enables delivery photos/proof of delivery.
  bool get enableDeliveryPhotos =>
      _getFlag('enableDeliveryPhotos', defaultValue: true);

  /// Enables signature capture for deliveries.
  bool get enableSignatureCapture =>
      _getFlag('enableSignatureCapture', defaultValue: true);

  // Financial Features
  /// Enables invoicing functionality.
  bool get enableInvoicing =>
      _getFlag('enableInvoicing', defaultValue: true);

  /// Enables expense tracking.
  bool get enableExpenseTracking =>
      _getFlag('enableExpenseTracking', defaultValue: true);

  /// Enables payment integration (Stripe, etc.).
  bool get enablePaymentIntegration =>
      _getFlag('enablePaymentIntegration', defaultValue: false);

  /// Enables tax calculation and reporting.
  bool get enableTaxCalculation =>
      _getFlag('enableTaxCalculation', defaultValue: true);

  // Analytics and Reporting
  /// Enables statistics and analytics dashboard.
  bool get enableStatistics =>
      _getFlag('enableStatistics', defaultValue: true);

  /// Enables detailed performance reports.
  bool get enablePerformanceReports =>
      _getFlag('enablePerformanceReports', defaultValue: true);

  /// Enables export functionality (PDF, CSV).
  bool get enableExport =>
      _getFlag('enableExport', defaultValue: true);

  // Notification Features
  /// Enables push notifications.
  bool get enablePushNotifications =>
      _getFlag('enablePushNotifications', defaultValue: true);

  /// Enables in-app notifications.
  bool get enableInAppNotifications =>
      _getFlag('enableInAppNotifications', defaultValue: true);

  /// Enables SMS notifications.
  bool get enableSmsNotifications =>
      _getFlag('enableSmsNotifications', defaultValue: false);

  /// Enables email notifications.
  bool get enableEmailNotifications =>
      _getFlag('enableEmailNotifications', defaultValue: true);

  // Admin Features
  /// Enables admin panel functionality.
  bool get enableAdminPanel =>
      _getFlag('enableAdminPanel', defaultValue: true);

  /// Enables user management features.
  bool get enableUserManagement =>
      _getFlag('enableUserManagement', defaultValue: true);

  /// Enables audit logs.
  bool get enableAuditLogs =>
      _getFlag('enableAuditLogs', defaultValue: EnvironmentConfig.isProduction);

  // Experimental Features
  /// Enables offline mode with data sync.
  bool get enableOfflineMode =>
      _getFlag('enableOfflineMode', defaultValue: false);

  /// Enables voice commands.
  bool get enableVoiceCommands =>
      _getFlag('enableVoiceCommands', defaultValue: false);

  /// Enables dark mode.
  bool get enableDarkMode =>
      _getFlag('enableDarkMode', defaultValue: true);

  /// Enables multi-language support.
  bool get enableMultiLanguage =>
      _getFlag('enableMultiLanguage', defaultValue: false);

  // Development/Debug Features
  /// Enables debug logging (auto-enabled in dev environment).
  bool get enableDebugLogging =>
      _getFlag('enableDebugLogging', defaultValue: EnvironmentConfig.isDevelopment);

  /// Enables performance overlay.
  bool get enablePerformanceOverlay =>
      _getFlag('enablePerformanceOverlay', defaultValue: false);

  /// Enables test mode (bypasses certain validations).
  bool get enableTestMode =>
      _getFlag('enableTestMode', defaultValue: EnvironmentConfig.isDevelopment);

  /// Gets a feature flag value with priority: local override > remote config > default.
  bool _getFlag(String key, {required bool defaultValue}) {
    // Check local override first (highest priority)
    if (_localOverrides.containsKey(key)) {
      return _localOverrides[key]!;
    }

    // Check remote config if available
    if (_remoteConfigFetched && _remoteConfig.containsKey(key)) {
      return _remoteConfig[key]!;
    }

    // Return default value
    return defaultValue;
  }

  /// Sets a local override for a feature flag (useful for testing).
  ///
  /// Local overrides take precedence over remote config and defaults.
  void setLocalOverride(String key, bool value) {
    _localOverrides[key] = value;
  }

  /// Removes a local override for a feature flag.
  void removeLocalOverride(String key) {
    _localOverrides.remove(key);
  }

  /// Clears all local overrides.
  void clearLocalOverrides() {
    _localOverrides.clear();
  }

  /// Gets all active local overrides.
  Map<String, bool> get localOverrides => Map.unmodifiable(_localOverrides);

  /// Initializes feature flags.
  ///
  /// This should be called once during app startup.
  /// It can fetch remote config values from Firebase Remote Config.
  Future<void> initialize() async {
    // TODO: Integrate with Firebase Remote Config
    // Example:
    // final remoteConfig = FirebaseRemoteConfig.instance;
    // await remoteConfig.setConfigSettings(RemoteConfigSettings(
    //   fetchTimeout: const Duration(minutes: 1),
    //   minimumFetchInterval: const Duration(hours: 1),
    // ));
    // await remoteConfig.fetchAndActivate();
    // _remoteConfig['enableBiometric'] = remoteConfig.getBool('enableBiometric');
    // ...
    // _remoteConfigFetched = true;

    _remoteConfigFetched = false; // Set to true when remote config is integrated
  }

  /// Fetches the latest remote config values.
  Future<void> fetchRemoteConfig() async {
    // TODO: Implement remote config fetching
    // This allows updating feature flags without app updates
  }

  /// Returns a debug-friendly string representation of feature flags.
  String toDebugString() {
    final flags = <String, bool>{
      'enableBiometric': enableBiometric,
      'enableTwoFactorAuth': enableTwoFactorAuth,
      'enableGpsTracking': enableGpsTracking,
      'enableGeofencing': enableGeofencing,
      'enableInvoicing': enableInvoicing,
      'enableExpenseTracking': enableExpenseTracking,
      'enableStatistics': enableStatistics,
      'enablePushNotifications': enablePushNotifications,
      'enableAdminPanel': enableAdminPanel,
      'enableOfflineMode': enableOfflineMode,
      'enableDarkMode': enableDarkMode,
      'enableDebugLogging': enableDebugLogging,
    };

    final buffer = StringBuffer('FeatureFlags(\n');
    flags.forEach((key, value) {
      final override = _localOverrides.containsKey(key) ? ' [OVERRIDE]' : '';
      buffer.writeln('  $key: $value$override');
    });
    buffer.write(')');
    return buffer.toString();
  }
}
