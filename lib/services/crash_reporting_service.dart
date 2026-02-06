import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Breadcrumb for crash context
class Breadcrumb {
  final String message;
  final DateTime timestamp;
  final Map<String, String>? data;

  Breadcrumb({
    required this.message,
    required this.timestamp,
    this.data,
  });
}

/// Crash Reporting and Analytics Service
/// 
/// Provides comprehensive error tracking and analytics:
/// - Automatic crash reporting via Firebase Crashlytics
/// - Custom error logging with context
/// - Breadcrumb tracking for debugging
/// - User feedback integration
/// - Custom crash keys for better debugging
class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();
  factory CrashReportingService() => _instance;
  CrashReportingService._internal();

  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  bool _initialized = false;
  final List<Breadcrumb> _breadcrumbs = [];
  static const int _maxBreadcrumbs = 50;

  /// Initialize crash reporting and analytics
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Configure Crashlytics
      await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
      
      // Pass all uncaught errors to Crashlytics with breadcrumb
      FlutterError.onError = (FlutterErrorDetails details) {
        _crashlytics.recordFlutterFatalError(details);
        _addBreadcrumb('Flutter Fatal Error: ${details.exception}');
      };
      
      // Pass all uncaught asynchronous errors to Crashlytics with breadcrumb
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics.recordError(error, stack, fatal: true);
        _addBreadcrumb('Platform Error: $error');
        return true;
      };

      _initialized = true;
      print('✅ Crash reporting service initialized');
      
      _addBreadcrumb('CrashReportingService initialized');
    } catch (e) {
      print('❌ Error initializing crash reporting: $e');
    }
  }

  /// Add breadcrumb for crash context (private)
  void _addBreadcrumb(String message, {Map<String, String>? data}) {
    final breadcrumb = Breadcrumb(
      message: message,
      timestamp: DateTime.now(),
      data: data,
    );
    
    _breadcrumbs.add(breadcrumb);
    
    // Keep only the last N breadcrumbs
    if (_breadcrumbs.length > _maxBreadcrumbs) {
      _breadcrumbs.removeAt(0);
    }
    
    // Log to Crashlytics as custom log
    _crashlytics.log('${breadcrumb.timestamp.toIso8601String()}: $message');
  }

  /// Add public breadcrumb method for app to track user actions
  void addBreadcrumb(String message, {Map<String, String>? data}) {
    _addBreadcrumb(message, data: data);
  }

  /// Get breadcrumbs for debugging (useful for user feedback)
  List<Breadcrumb> getBreadcrumbs() {
    return List.unmodifiable(_breadcrumbs);
  }

  /// Set custom key for crash context
  Future<void> setCustomKey(String key, dynamic value) async {
    await _crashlytics.setCustomKey(key, value);
  }

  /// Log a non-fatal error
  Future<void> logError(
    dynamic error, 
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Add context information
      if (context != null) {
        for (final entry in context.entries) {
          await _crashlytics.setCustomKey(entry.key, entry.value);
        }
      }

      // Log to Crashlytics
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: false,
      );

      print('⚠️ Error logged: $error');
    } catch (e) {
      print('❌ Failed to log error: $e');
    }
  }

  /// Log a message for debugging context
  Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  /// Set user identifier for crash reports
  Future<void> setUserIdentifier(String userId, {String? email, String? role}) async {
    await _crashlytics.setUserIdentifier(userId);
    
    if (email != null) {
      await _crashlytics.setCustomKey('user_email', email);
    }
    
    if (role != null) {
      await _crashlytics.setCustomKey('user_role', role);
    }

    print('✅ User identifier set for crash reports: $userId');
  }

  /// Set custom keys for additional context
  Future<void> setCustomKeys(Map<String, dynamic> keys) async {
    for (final entry in keys.entries) {
      await _crashlytics.setCustomKey(entry.key, entry.value);
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
      parameters: parameters,
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

  // ===================
  // User Feedback Methods
  // ===================

  /// Record user feedback for a crash or error
  Future<void> recordUserFeedback({
    required String feedback,
    String? errorId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Log as custom event
      await _analytics.logEvent(
        name: 'user_feedback',
        parameters: {
          'feedback': feedback,
          'error_id': errorId ?? 'manual',
          'timestamp': DateTime.now().toIso8601String(),
          ...?metadata?.map((k, v) => MapEntry(k, v.toString())),
        },
      );

      // Add as breadcrumb
      _addBreadcrumb('User Feedback: $feedback', data: {'error_id': errorId ?? 'manual'});

      // Set as custom key for next crash
      await _crashlytics.setCustomKey('last_user_feedback', feedback);
      await _crashlytics.setCustomKey('feedback_timestamp', DateTime.now().toIso8601String());

      print('✅ User feedback recorded: $feedback');
    } catch (e) {
      print('❌ Error recording user feedback: $e');
    }
  }

  /// Record user rating
  Future<void> recordUserRating({
    required double rating,
    String? context,
    String? comment,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'user_rating',
        parameters: {
          'rating': rating.toString(),
          'context': context ?? 'general',
          'comment': comment ?? '',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _addBreadcrumb('User Rating: $rating/5.0', data: {
        'context': context ?? 'general',
      });

      print('✅ User rating recorded: $rating');
    } catch (e) {
      print('❌ Error recording user rating: $e');
    }
  }

  /// Record feature request
  Future<void> recordFeatureRequest({
    required String featureName,
    String? description,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'feature_request',
        parameters: {
          'feature': featureName,
          'description': description ?? '',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      _addBreadcrumb('Feature Request: $featureName');

      print('✅ Feature request recorded: $featureName');
    } catch (e) {
      print('❌ Error recording feature request: $e');
    }
  }

  /// Record bug report
  Future<void> recordBugReport({
    required String description,
    String? stepsToReproduce,
    String? expectedBehavior,
    String? actualBehavior,
  }) async {
    try {
      // Build breadcrumb trail for bug context
      final breadcrumbTrail = _breadcrumbs.map((b) => 
        '${b.timestamp.toIso8601String()}: ${b.message}'
      ).join('\n');

      await _analytics.logEvent(
        name: 'bug_report',
        parameters: {
          'description': description,
          'steps': stepsToReproduce ?? '',
          'expected': expectedBehavior ?? '',
          'actual': actualBehavior ?? '',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Log to Crashlytics for investigation
      await _crashlytics.recordError(
        Exception('User reported bug: $description'),
        StackTrace.current,
        reason: 'Bug report from user',
        fatal: false,
      );

      // Set custom keys with bug details
      await _crashlytics.setCustomKey('bug_description', description);
      await _crashlytics.setCustomKey('breadcrumb_trail', breadcrumbTrail);

      _addBreadcrumb('Bug Report: $description');

      print('✅ Bug report recorded: $description');
    } catch (e) {
      print('❌ Error recording bug report: $e');
    }
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
