import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Remote Config Service
/// 
/// Provides dynamic configuration and feature flags from Firebase Remote Config.
/// Allows server-side control of app features without requiring updates.
/// 
/// Features:
/// - Feature flags (biometric, geofencing, offline, analytics)
/// - Location update interval configuration
/// - Geofence radius settings
/// - Maintenance mode flag
/// - Force update flag
/// 
/// Setup Requirements:
/// 1. Enable Remote Config in Firebase Console
/// 2. Configure default values
/// 3. Set up parameter keys and types
class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  FirebaseRemoteConfig? _remoteConfig;
  bool _initialized = false;

  // Default values
  static const Map<String, dynamic> _defaults = {
    // Feature flags
    'enable_biometric_auth': true,
    'enable_geofencing': true,
    'enable_offline_mode': true,
    'enable_analytics': true,
    'enable_crashlytics': true,
    'enable_push_notifications': true,
    
    // Location settings
    'location_update_interval_minutes': 5,
    'location_accuracy_threshold_meters': 50.0,
    'enable_background_location': true,
    
    // Geofence settings
    'geofence_radius_meters': 200.0,
    'geofence_monitoring_interval_seconds': 30,
    'geofence_loitering_delay_ms': 60000,
    
    // App control
    'maintenance_mode': false,
    'maintenance_message': 'The app is currently under maintenance. Please check back later.',
    'force_update_required': false,
    'minimum_app_version': '2.0.0',
    
    // Notification settings
    'notification_priority': 'high',
    'enable_notification_sound': true,
    
    // Performance settings
    'max_cache_size_mb': 100,
    'image_cache_days': 7,
    
    // Business logic
    'max_loads_per_driver': 5,
    'pod_upload_required': true,
    'auto_calculate_earnings': true,
  };

  /// Initialize Remote Config with defaults
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Set config settings
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode 
              ? const Duration(minutes: 1)  // Short interval for testing
              : const Duration(hours: 1),   // Production interval
        ),
      );

      // Set default values
      await _remoteConfig!.setDefaults(_defaults);

      // Fetch and activate
      await _fetchAndActivate();

      _initialized = true;
      print('✅ Remote Config initialized');
    } catch (e) {
      print('❌ Error initializing Remote Config: $e');
      print('⚠️ Using default values only');
    }
  }

  /// Fetch and activate remote config values
  Future<bool> _fetchAndActivate() async {
    try {
      final activated = await _remoteConfig!.fetchAndActivate();
      if (activated) {
        print('✅ Remote Config fetched and activated');
      } else {
        print('ℹ️ Remote Config fetched but not activated (no changes)');
      }
      return activated;
    } catch (e) {
      print('❌ Error fetching Remote Config: $e');
      return false;
    }
  }

  /// Force fetch latest config (use sparingly to avoid quota limits)
  Future<bool> forceRefresh() async {
    if (_remoteConfig == null) return false;
    return await _fetchAndActivate();
  }

  // ===================
  // Feature Flags
  // ===================

  /// Check if biometric authentication is enabled
  bool get isBiometricAuthEnabled {
    return _remoteConfig?.getBool('enable_biometric_auth') ?? 
           _defaults['enable_biometric_auth'] as bool;
  }

  /// Check if geofencing is enabled
  bool get isGeofencingEnabled {
    return _remoteConfig?.getBool('enable_geofencing') ?? 
           _defaults['enable_geofencing'] as bool;
  }

  /// Check if offline mode is enabled
  bool get isOfflineModeEnabled {
    return _remoteConfig?.getBool('enable_offline_mode') ?? 
           _defaults['enable_offline_mode'] as bool;
  }

  /// Check if analytics is enabled
  bool get isAnalyticsEnabled {
    return _remoteConfig?.getBool('enable_analytics') ?? 
           _defaults['enable_analytics'] as bool;
  }

  /// Check if crashlytics is enabled
  bool get isCrashlyticsEnabled {
    return _remoteConfig?.getBool('enable_crashlytics') ?? 
           _defaults['enable_crashlytics'] as bool;
  }

  /// Check if push notifications are enabled
  bool get isPushNotificationsEnabled {
    return _remoteConfig?.getBool('enable_push_notifications') ?? 
           _defaults['enable_push_notifications'] as bool;
  }

  // ===================
  // Location Settings
  // ===================

  /// Get location update interval in minutes
  int get locationUpdateInterval {
    return _remoteConfig?.getInt('location_update_interval_minutes') ?? 
           _defaults['location_update_interval_minutes'] as int;
  }

  /// Get location accuracy threshold in meters
  double get locationAccuracyThreshold {
    return _remoteConfig?.getDouble('location_accuracy_threshold_meters') ?? 
           _defaults['location_accuracy_threshold_meters'] as double;
  }

  /// Check if background location tracking is enabled
  bool get isBackgroundLocationEnabled {
    return _remoteConfig?.getBool('enable_background_location') ?? 
           _defaults['enable_background_location'] as bool;
  }

  // ===================
  // Geofence Settings
  // ===================

  /// Get geofence radius in meters
  double get geofenceRadius {
    return _remoteConfig?.getDouble('geofence_radius_meters') ?? 
           _defaults['geofence_radius_meters'] as double;
  }

  /// Get geofence monitoring interval in seconds
  int get geofenceMonitoringInterval {
    return _remoteConfig?.getInt('geofence_monitoring_interval_seconds') ?? 
           _defaults['geofence_monitoring_interval_seconds'] as int;
  }

  /// Get geofence loitering delay in milliseconds
  int get geofenceLoiteringDelay {
    return _remoteConfig?.getInt('geofence_loitering_delay_ms') ?? 
           _defaults['geofence_loitering_delay_ms'] as int;
  }

  // ===================
  // App Control
  // ===================

  /// Check if app is in maintenance mode
  bool get isMaintenanceMode {
    return _remoteConfig?.getBool('maintenance_mode') ?? 
           _defaults['maintenance_mode'] as bool;
  }

  /// Get maintenance mode message
  String get maintenanceMessage {
    return _remoteConfig?.getString('maintenance_message') ?? 
           _defaults['maintenance_message'] as String;
  }

  /// Check if force update is required
  bool get isForceUpdateRequired {
    return _remoteConfig?.getBool('force_update_required') ?? 
           _defaults['force_update_required'] as bool;
  }

  /// Get minimum required app version
  String get minimumAppVersion {
    return _remoteConfig?.getString('minimum_app_version') ?? 
           _defaults['minimum_app_version'] as String;
  }

  // ===================
  // Business Logic
  // ===================

  /// Get maximum loads per driver
  int get maxLoadsPerDriver {
    return _remoteConfig?.getInt('max_loads_per_driver') ?? 
           _defaults['max_loads_per_driver'] as int;
  }

  /// Check if POD upload is required
  bool get isPodUploadRequired {
    return _remoteConfig?.getBool('pod_upload_required') ?? 
           _defaults['pod_upload_required'] as bool;
  }

  /// Check if automatic earnings calculation is enabled
  bool get isAutoCalculateEarnings {
    return _remoteConfig?.getBool('auto_calculate_earnings') ?? 
           _defaults['auto_calculate_earnings'] as bool;
  }

  // ===================
  // Utility Methods
  // ===================

  /// Get all current config values (for debugging)
  Map<String, dynamic> getAllValues() {
    if (_remoteConfig == null) return _defaults;

    return {
      ..._defaults.map((key, value) {
        if (value is bool) {
          return MapEntry(key, _remoteConfig!.getBool(key));
        } else if (value is int) {
          return MapEntry(key, _remoteConfig!.getInt(key));
        } else if (value is double) {
          return MapEntry(key, _remoteConfig!.getDouble(key));
        } else {
          return MapEntry(key, _remoteConfig!.getString(key));
        }
      }),
    };
  }

  /// Get value by key with type casting
  T? getValue<T>(String key) {
    if (_remoteConfig == null) return _defaults[key] as T?;

    if (T == bool) {
      return _remoteConfig!.getBool(key) as T;
    } else if (T == int) {
      return _remoteConfig!.getInt(key) as T;
    } else if (T == double) {
      return _remoteConfig!.getDouble(key) as T;
    } else if (T == String) {
      return _remoteConfig!.getString(key) as T;
    }
    return null;
  }
}

// TODO: Add Remote Config parameter groups
// Group parameters by feature for better organization:
// - location_*
// - geofence_*
// - notification_*
// - feature_*
// - app_control_*

// TODO: Implement A/B testing
// Use Remote Config for A/B testing:
// - Test different UI layouts
// - Test different feature combinations
// - Measure user engagement
// - Roll out features to percentage of users

// TODO: Add Remote Config listeners
// Listen for config updates in real-time:
// - Update UI when config changes
// - Show notification to user about new features
// - Prompt user to restart app if needed

// TODO: Implement Remote Config conditions
// Set conditions for different user segments:
// - Platform (iOS vs Android)
// - App version
// - User properties (role, location, etc.)
// - Custom conditions

// TODO: Add Remote Config analytics
// Track Remote Config usage:
// - Which features are most toggled
// - Which parameters are most accessed
// - Config fetch success rate
// - Impact of config changes on user behavior
