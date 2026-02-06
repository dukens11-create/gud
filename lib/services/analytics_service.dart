import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Analytics Service
/// 
/// Provides user behavior tracking and analytics:
/// - Screen view tracking
/// - Event logging
/// - User property management
/// - Conversion tracking
/// 
/// This is a wrapper around Firebase Analytics that provides
/// a consistent interface and simplified API for the app.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  static AnalyticsService get instance => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  bool _initialized = false;

  /// Initialize the analytics service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Analytics is automatically initialized with Firebase
      // but we can configure it here
      await _analytics.setAnalyticsCollectionEnabled(!kDebugMode);
      
      _initialized = true;
      debugPrint('✅ Analytics Service initialized');
    } catch (e) {
      debugPrint('⚠️ Error initializing Analytics Service: $e');
      rethrow;
    }
  }

  /// Log a custom event
  /// 
  /// [name] - Event name (must be alphanumeric + underscore)
  /// [parameters] - Optional event parameters (max 25 parameters)
  Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    if (!_initialized) {
      debugPrint('⚠️ Analytics not initialized, skipping event: $name');
      return;
    }

    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      debugPrint('📊 Analytics event: $name ${parameters ?? ""}');
    } catch (e) {
      debugPrint('⚠️ Error logging event $name: $e');
    }
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_initialized) return;

    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      debugPrint('📊 Screen view: $screenName');
    } catch (e) {
      debugPrint('⚠️ Error logging screen view: $e');
    }
  }

  /// Set user ID
  Future<void> setUserId(String? id) async {
    if (!_initialized) return;

    try {
      await _analytics.setUserId(id: id);
    } catch (e) {
      debugPrint('⚠️ Error setting user ID: $e');
    }
  }

  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (!_initialized) return;

    try {
      await _analytics.setUserProperty(
        name: name,
        value: value,
      );
    } catch (e) {
      debugPrint('⚠️ Error setting user property: $e');
    }
  }

  /// Log login event
  Future<void> logLogin({String? method}) async {
    await logEvent('login', parameters: {
      if (method != null) 'method': method,
    });
  }

  /// Log sign up event
  Future<void> logSignUp({String? method}) async {
    await logEvent('sign_up', parameters: {
      if (method != null) 'method': method,
    });
  }

  /// Log search event
  Future<void> logSearch(String searchTerm) async {
    await logEvent('search', parameters: {
      'search_term': searchTerm,
    });
  }

  /// Log select content event
  Future<void> logSelectContent({
    required String contentType,
    required String itemId,
  }) async {
    await logEvent('select_content', parameters: {
      'content_type': contentType,
      'item_id': itemId,
    });
  }

  /// Get the Firebase Analytics instance for advanced usage
  FirebaseAnalytics get firebaseAnalytics => _analytics;
}
