import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Analytics Service
/// 
/// Comprehensive event tracking and user analytics using Firebase Analytics
/// 
/// Tracks:
/// - User authentication events (login, logout, signup)
/// - Load management events (create, assign, complete)
/// - POD upload events
/// - Driver location updates
/// - Screen views and navigation
/// - Errors and exceptions
/// - User engagement metrics
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  
  bool _initialized = false;
  String? _currentUserId;
  String? _currentUserRole;

  /// Initialize analytics service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      _initialized = true;
      print('✅ Analytics service initialized');
    } catch (e) {
      print('❌ Error initializing analytics service: $e');
    }
  }

  /// Set user properties for analytics
  Future<void> setUserProperties({
    required String userId,
    required String role,
    String? name,
    String? email,
  }) async {
    _currentUserId = userId;
    _currentUserRole = role;

    try {
      await _analytics.setUserId(id: userId);
      await _analytics.setUserProperty(name: 'user_role', value: role);
      
      if (name != null) {
        await _analytics.setUserProperty(name: 'user_name', value: name);
      }
      
      // Set user ID in Crashlytics for crash tracking
      await _crashlytics.setUserIdentifier(userId);
      await _crashlytics.setCustomKey('user_role', role);
      
      print('✅ User properties set for analytics');
    } catch (e) {
      print('❌ Error setting user properties: $e');
    }
  }

  /// Clear user data on logout
  Future<void> clearUserData() async {
    _currentUserId = null;
    _currentUserRole = null;
    
    try {
      await _analytics.setUserId(id: null);
      await _crashlytics.setUserIdentifier('');
      print('✅ User data cleared from analytics');
    } catch (e) {
      print('❌ Error clearing user data: $e');
    }
  }

  // ==================== AUTHENTICATION EVENTS ====================

  /// Track user login
  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
    await _logCustomEvent('user_login', parameters: {
      'method': method,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track user signup
  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
    await _logCustomEvent('user_signup', parameters: {
      'method': method,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track user logout
  Future<void> logLogout() async {
    await _logCustomEvent('user_logout', parameters: {
      'user_id': _currentUserId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // ==================== LOAD MANAGEMENT EVENTS ====================

  /// Track load creation
  Future<void> logLoadCreated({
    required String loadId,
    required String pickupCity,
    required String deliveryCity,
    double? amount,
  }) async {
    await _logCustomEvent('load_created', parameters: {
      'load_id': loadId,
      'pickup_city': pickupCity,
      'delivery_city': deliveryCity,
      'amount': amount?.toString() ?? 'unknown',
      'created_by': _currentUserId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track load assignment
  Future<void> logLoadAssigned({
    required String loadId,
    required String driverId,
    required String driverName,
  }) async {
    await _logCustomEvent('load_assigned', parameters: {
      'load_id': loadId,
      'driver_id': driverId,
      'driver_name': driverName,
      'assigned_by': _currentUserId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track load status change
  Future<void> logLoadStatusChanged({
    required String loadId,
    required String oldStatus,
    required String newStatus,
  }) async {
    await _logCustomEvent('load_status_changed', parameters: {
      'load_id': loadId,
      'old_status': oldStatus,
      'new_status': newStatus,
      'changed_by': _currentUserId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track load completion
  Future<void> logLoadCompleted({
    required String loadId,
    required String driverId,
    required Duration duration,
  }) async {
    await _logCustomEvent('load_completed', parameters: {
      'load_id': loadId,
      'driver_id': driverId,
      'duration_minutes': duration.inMinutes.toString(),
      'completed_by': _currentUserId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // ==================== POD EVENTS ====================

  /// Track POD upload
  Future<void> logPODUploaded({
    required String loadId,
    required String driverId,
    int photoCount = 1,
  }) async {
    await _logCustomEvent('pod_uploaded', parameters: {
      'load_id': loadId,
      'driver_id': driverId,
      'photo_count': photoCount.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track POD verification
  Future<void> logPODVerified({
    required String loadId,
    required String verifiedBy,
  }) async {
    await _logCustomEvent('pod_verified', parameters: {
      'load_id': loadId,
      'verified_by': verifiedBy,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // ==================== LOCATION EVENTS ====================

  /// Track driver location update
  Future<void> logLocationUpdate({
    required String driverId,
    required double latitude,
    required double longitude,
    String? accuracy,
  }) async {
    // Only log this event periodically to avoid excessive analytics calls
    await _logCustomEvent('location_updated', parameters: {
      'driver_id': driverId,
      'latitude': latitude.toStringAsFixed(6),
      'longitude': longitude.toStringAsFixed(6),
      'accuracy': accuracy ?? 'unknown',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track geofence entry
  Future<void> logGeofenceEntry({
    required String loadId,
    required String geofenceType, // 'pickup' or 'delivery'
  }) async {
    await _logCustomEvent('geofence_entered', parameters: {
      'load_id': loadId,
      'geofence_type': geofenceType,
      'driver_id': _currentUserId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track geofence exit
  Future<void> logGeofenceExit({
    required String loadId,
    required String geofenceType,
  }) async {
    await _logCustomEvent('geofence_exited', parameters: {
      'load_id': loadId,
      'geofence_type': geofenceType,
      'driver_id': _currentUserId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // ==================== SCREEN TRACKING ====================

  /// Track screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  /// Track navigation
  Future<void> logNavigation({
    required String from,
    required String to,
  }) async {
    await _logCustomEvent('navigation', parameters: {
      'from_screen': from,
      'to_screen': to,
      'user_id': _currentUserId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // ==================== ERROR AND EXCEPTION TRACKING ====================

  /// Track error
  Future<void> logError({
    required String error,
    String? stackTrace,
    String? context,
  }) async {
    await _logCustomEvent('app_error', parameters: {
      'error': error,
      'context': context ?? 'unknown',
      'user_id': _currentUserId,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Also log to Crashlytics for non-fatal errors
    await _crashlytics.recordError(
      error,
      stackTrace != null ? StackTrace.fromString(stackTrace) : null,
      reason: context,
      fatal: false,
    );
  }

  /// Track exception
  Future<void> logException({
    required Exception exception,
    StackTrace? stackTrace,
    String? context,
  }) async {
    await _crashlytics.recordError(
      exception,
      stackTrace,
      reason: context,
      fatal: false,
    );
  }

  // ==================== USER ENGAGEMENT EVENTS ====================

  /// Track search
  Future<void> logSearch(String searchTerm) async {
    await _analytics.logSearch(searchTerm: searchTerm);
  }

  /// Track button click
  Future<void> logButtonClick(String buttonName) async {
    await _logCustomEvent('button_click', parameters: {
      'button_name': buttonName,
      'user_id': _currentUserId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track feature usage
  Future<void> logFeatureUsed(String featureName) async {
    await _logCustomEvent('feature_used', parameters: {
      'feature_name': featureName,
      'user_id': _currentUserId,
      'user_role': _currentUserRole,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track share
  Future<void> logShare({
    required String contentType,
    required String itemId,
    String? method,
  }) async {
    await _analytics.logShare(
      contentType: contentType,
      itemId: itemId,
      method: method ?? 'unknown',
    );
  }

  // ==================== BUSINESS METRICS ====================

  /// Track revenue/payment
  Future<void> logPurchase({
    required double value,
    required String currency,
    String? transactionId,
  }) async {
    await _analytics.logPurchase(
      value: value,
      currency: currency,
      transactionId: transactionId,
    );
  }

  /// Track earnings
  Future<void> logEarnings({
    required String driverId,
    required double amount,
    required String loadId,
  }) async {
    await _logCustomEvent('earnings_recorded', parameters: {
      'driver_id': driverId,
      'amount': amount.toString(),
      'load_id': loadId,
      'currency': 'USD',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track expense
  Future<void> logExpense({
    required String expenseId,
    required String category,
    required double amount,
  }) async {
    await _logCustomEvent('expense_recorded', parameters: {
      'expense_id': expenseId,
      'category': category,
      'amount': amount.toString(),
      'recorded_by': _currentUserId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // ==================== PERFORMANCE TRACKING ====================

  /// Track time spent on screen
  Future<void> logTimeSpent({
    required String screenName,
    required Duration duration,
  }) async {
    await _logCustomEvent('time_spent', parameters: {
      'screen_name': screenName,
      'duration_seconds': duration.inSeconds.toString(),
      'user_id': _currentUserId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track app session
  Future<void> logSessionStart() async {
    await _logCustomEvent('session_start', parameters: {
      'user_id': _currentUserId,
      'user_role': _currentUserRole,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track app session end
  Future<void> logSessionEnd(Duration sessionDuration) async {
    await _logCustomEvent('session_end', parameters: {
      'user_id': _currentUserId,
      'duration_seconds': sessionDuration.inSeconds.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // ==================== CUSTOM EVENT LOGGING ====================

  /// Log custom event
  Future<void> _logCustomEvent(
    String name, {
    Map<String, String>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      print('❌ Error logging analytics event: $e');
    }
  }

  /// Log custom event with flexible parameters
  Future<void> logCustomEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    // Convert all parameter values to strings for Firebase Analytics
    final Map<String, String>? stringParams = parameters?.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    
    await _logCustomEvent(eventName, parameters: stringParams);
  }

  /// Get FirebaseAnalytics instance for advanced usage
  FirebaseAnalytics get analytics => _analytics;
}
