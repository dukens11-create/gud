import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Crash Reporting and Analytics Service
/// 
/// Provides comprehensive error tracking and analytics:
/// - Automatic crash reporting via Firebase Crashlytics
/// - Custom error logging
/// - User analytics and behavior tracking
/// - Performance monitoring
/// 
/// Setup Requirements:
/// 1. Enable Crashlytics in Firebase Console
/// 2. Add Firebase Crashlytics SDK
/// 3. Configure crash reporting in main.dart
/// 4. Upload debug symbols for iOS
/// 
/// TODO: Add custom crash keys for better debugging
/// TODO: Implement user feedback integration
/// TODO: Add breadcrumb tracking for crash context
/// TODO: Set up alerts for critical errors
class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();
  factory CrashReportingService() => _instance;
  CrashReportingService._internal();

  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  bool _initialized = false;

  /// Initialize crash reporting and analytics
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Configure Crashlytics
      await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
      
      // Pass all uncaught errors to Crashlytics
      FlutterError.onError = _crashlytics.recordFlutterFatalError;
      
      // Pass all uncaught asynchronous errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics.recordError(error, stack, fatal: true);
        return true;
      };

      _initialized = true;
      print('✅ Crash reporting service initialized');
    } catch (e) {
      print('❌ Error initializing crash reporting: $e');
    }
  }

  /// Log a non-fatal error
  Future<void> logError(
    dynamic error, 
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Add context information as custom keys
      if (context != null) {
        for (final entry in context.entries) {
          await _crashlytics.setCustomKey(entry.key, entry.value.toString());
        }
      }

      // Add breadcrumb for context
      if (reason != null) {
        await _crashlytics.log('Error occurred: $reason');
      }

      // Log to Crashlytics
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: false,
      );

      print('⚠️ Error logged to Crashlytics: $error');
    } catch (e) {
      print('❌ Failed to log error to Crashlytics: $e');
    }
  }

  /// Log a breadcrumb message for debugging context
  /// 
  /// Breadcrumbs help understand the sequence of events leading to a crash
  Future<void> logBreadcrumb(String message, {Map<String, dynamic>? data}) async {
    try {
      await _crashlytics.log(message);
      
      // Add data as custom keys if provided
      if (data != null) {
        for (final entry in data.entries) {
          await _crashlytics.setCustomKey('breadcrumb_${entry.key}', entry.value.toString());
        }
      }
      
      print('🍞 Breadcrumb logged: $message');
    } catch (e) {
      print('❌ Failed to log breadcrumb: $e');
    }
  }

  /// Set user identifier for crash reports
  Future<void> setUserIdentifier(String userId, {String? email, String? role}) async {
    try {
      await _crashlytics.setUserIdentifier(userId);
      
      if (email != null) {
        await _crashlytics.setCustomKey('user_email', email);
      }
      
      if (role != null) {
        await _crashlytics.setCustomKey('user_role', role);
      }

      print('✅ User identifier set for crash reports: $userId');
    } catch (e) {
      print('❌ Failed to set user identifier: $e');
    }
  }

  /// Set custom keys for additional context
  Future<void> setCustomKeys(Map<String, dynamic> keys) async {
    try {
      for (final entry in keys.entries) {
        await _crashlytics.setCustomKey(entry.key, entry.value.toString());
      }
      print('✅ Custom keys set: ${keys.keys.join(', ')}');
    } catch (e) {
      print('❌ Failed to set custom keys: $e');
    }
  }

  /// Clear user identifier (e.g., on logout)
  Future<void> clearUserIdentifier() async {
    try {
      await _crashlytics.setUserIdentifier('');
      print('✅ User identifier cleared');
    } catch (e) {
      print('❌ Failed to clear user identifier: $e');
    }
  }

  /// Force a test crash (for testing only)
  void forceCrash() {
    if (kDebugMode) {
      _crashlytics.crash();
    }
  }

  // ===================
  // Analytics Methods
  // ===================

  /// Log a screen view event
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
    print('📊 Screen view logged: $screenName');
  }

  /// Log user login event
  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
    print('📊 Login logged: $method');
  }

  /// Log load creation event
  Future<void> logLoadCreated(String loadId, double rate) async {
    await _analytics.logEvent(
      name: 'load_created',
      parameters: {
        'load_id': loadId,
        'rate': rate,
      },
    );
    print('📊 Load created logged: $loadId');
  }

  /// Log load status change
  Future<void> logLoadStatusChange(String loadId, String oldStatus, String newStatus) async {
    await _analytics.logEvent(
      name: 'load_status_changed',
      parameters: {
        'load_id': loadId,
        'old_status': oldStatus,
        'new_status': newStatus,
      },
    );
    print('📊 Load status change logged: $oldStatus -> $newStatus');
  }

  /// Log POD upload event
  Future<void> logPODUploaded(String loadId, String podId) async {
    await _analytics.logEvent(
      name: 'pod_uploaded',
      parameters: {
        'load_id': loadId,
        'pod_id': podId,
      },
    );
    print('📊 POD upload logged: $podId');
  }

  /// Log driver location update
  Future<void> logLocationUpdate(String driverId, double accuracy) async {
    await _analytics.logEvent(
      name: 'location_updated',
      parameters: {
        'driver_id': driverId,
        'accuracy': accuracy,
      },
    );
  }

  /// Log notification received
  Future<void> logNotificationReceived(String notificationType) async {
    await _analytics.logEvent(
      name: 'notification_received',
      parameters: {
        'type': notificationType,
      },
    );
  }

  /// Log notification opened
  Future<void> logNotificationOpened(String notificationType) async {
    await _analytics.logEvent(
      name: 'notification_opened',
      parameters: {
        'type': notificationType,
      },
    );
  }

  /// Log custom event
  Future<void> logCustomEvent(String eventName, Map<String, dynamic>? parameters) async {
    await _analytics.logEvent(
      name: eventName,
      parameters: parameters?.map((key, value) => MapEntry(key, value as Object?)),
    );
    print('📊 Custom event logged: $eventName');
  }

  /// Set user properties for analytics
  Future<void> setUserProperties({
    required String userId,
    required String role,
    String? truckNumber,
  }) async {
    await _analytics.setUserId(id: userId);
    await _analytics.setUserProperty(name: 'user_role', value: role);
    
    if (truckNumber != null) {
      await _analytics.setUserProperty(name: 'truck_number', value: truckNumber);
    }

    print('✅ User properties set for analytics: $userId');
  }
}

// TODO: Add performance monitoring
// Track:
// - Screen load times
// - Network request durations
// - Database query performance
// - Image loading times

// TODO: Implement custom metrics
// Track business-specific metrics:
// - Average delivery time
// - POD upload success rate
// - Location tracking accuracy
// - Notification engagement rate

// TODO: Add A/B testing support
// Use Firebase Remote Config:
// - Test different UI layouts
// - Experiment with features
// - Measure user engagement
// - Roll out features gradually

// TODO: Create analytics dashboard
// Visualize:
// - Daily active users
// - Load completion rates
// - Driver performance metrics
// - Error rates and crash trends

// TODO: Implement user feedback collection
// Add in-app feedback:
// - Crash feedback forms
// - Feature request submissions
// - Bug report templates
// - User satisfaction surveys

// TODO: Add session recording
// Capture user journeys:
// - Session duration
// - User flow paths
// - Drop-off points
// - Feature usage patterns
