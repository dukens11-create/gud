import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'config/environment_config.dart';
import 'services/crash_reporting_service.dart';
import 'services/analytics_service.dart';
import 'services/notification_service.dart';
import 'services/offline_support_service.dart';
import 'services/background_location_service.dart';
import 'services/geofence_service.dart';
import 'services/sync_service.dart';
import 'services/remote_config_service.dart';
import 'services/document_expiration_service.dart';
import 'services/firebase_init_service.dart';
import 'app.dart';

/// Initialize all background services
/// 
/// Services are initialized in dependency order:
/// 1. Crash reporting (must be first to catch all errors)
/// 2. App Check (security - protect against abuse)
/// 3. Analytics (for tracking initialization)
/// 4. Remote Config (for feature flags and configuration)
/// 5. Notifications (needed by other services)
/// 6. Offline support (needed by sync service)
/// 7. Background location (GPS tracking)
/// 8. Geofencing (location-based updates)
/// 9. Sync service (background synchronization)
Future<void> initializeServices() async {
  try {
    print('🚀 Initializing services...');

    // Initialize crash reporting first to catch any errors during initialization
    await CrashReportingService().initialize();
    print('✅ Crash Reporting Service initialized');

    // Initialize Firebase App Check for security
    try {
      await FirebaseAppCheck.instance.activate(
        // Use debug provider for development
        androidProvider: kDebugMode 
            ? AndroidProvider.debug 
            : AndroidProvider.playIntegrity,
        // Use debug provider for iOS in development
        appleProvider: kDebugMode 
            ? AppleProvider.debug 
            : AppleProvider.deviceCheck,
      );
      print('✅ Firebase App Check initialized');
    } catch (e) {
      print('⚠️ App Check initialization failed (non-critical): $e');
      // Don't throw - App Check failure shouldn't prevent app from running
    }

    // Initialize analytics
    await AnalyticsService.instance.initialize();
    print('✅ Analytics Service initialized');

    // Initialize Remote Config
    await RemoteConfigService().initialize();
    print('✅ Remote Config Service initialized');

    // Check maintenance mode
    if (RemoteConfigService().isMaintenanceMode) {
      print('🚧 App is in maintenance mode');
    }

    // Initialize notifications
    await NotificationService().initialize();
    print('✅ Notification Service initialized');

    // Initialize offline support
    await OfflineSupportService.instance.initialize();
    print('✅ Offline Support Service initialized');

    // Initialize background location (Note: actual tracking starts per-driver)
    // BackgroundLocationService is stateless and doesn't need initialization
    print('✅ Background Location Service ready');

    // Initialize geofencing (Note: geofences are created per-load)
    // GeofenceService is stateless and doesn't need initialization
    print('✅ Geofence Service ready');

    // Initialize sync service
    await SyncService.instance.initialize();
    print('✅ Sync Service initialized');

    // Initialize document expiration monitoring
    DocumentExpirationService().startMonitoring();
    print('✅ Document Expiration Service initialized');

    // Log successful initialization
    await AnalyticsService.instance.logEvent('services_initialized');
    print('✅ All services initialized successfully');
  } catch (e, stackTrace) {
    // Log the error but don't prevent app from starting
    print('⚠️ Error initializing services: $e');
    try {
      await CrashReportingService().logError(
        e,
        stackTrace,
        reason: 'Service initialization failed',
      );
    } catch (_) {
      // If crash reporting fails, just print
      print('⚠️ Could not log error to crash reporting');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Load environment variables
    try {
      await EnvironmentConfig.load();
      print('✅ Environment configuration loaded');
    } catch (e) {
      print('⚠️ Environment configuration not found, using defaults: $e');
    }

    // Initialize Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
    
    // Set up global error handlers
    FlutterError.onError = (errorDetails) {
      FlutterError.presentError(errorDetails);
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    
    // Catch async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    
    print('✅ Error handlers configured');

    // Initialize all services
    await initializeServices();
    
    // Initialize sample data if needed
    try {
      final initService = FirebaseInitService();
      if (await initService.needsInitialization()) {
        print('🚚 Initializing sample trucks...');
        await initService.initializeSampleTrucks();
        print('✅ Sample trucks created successfully!');
      }
    } catch (e) {
      print('⚠️ Error initializing sample data: $e');
    }
    
    // Log app open event
    FirebaseAnalytics analytics = FirebaseAnalytics.instance;
    await analytics.logAppOpen();
    print('✅ App open logged');
    
  } catch (e) {
    print('⚠️ Firebase initialization failed: $e');
    print('📱 Running in offline mode');
  }
  
  runApp(const GUDApp());
}
