import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/crash_reporting_service.dart';
import 'services/analytics_service.dart';
import 'services/notification_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
    
    // Initialize Crash Reporting Service
    final crashReporting = CrashReportingService();
    await crashReporting.initialize();
    
    // Initialize Analytics Service
    final analytics = AnalyticsService();
    await analytics.initialize();
    
    // Initialize Notification Service
    final notifications = NotificationService();
    await notifications.initialize();
    
    // Log app start
    await analytics.logCustomEvent('app_started', parameters: {
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    crashReporting.addBreadcrumb('App started successfully');
  } catch (e, stackTrace) {
    print('⚠️ Firebase initialization failed: $e');
    print('📱 Running in offline/demo mode');
    
    // Log error to crash reporting if available
    try {
      await CrashReportingService().logError(
        e,
        stackTrace,
        reason: 'Firebase initialization failed',
      );
    } catch (_) {
      // Ignore if crash reporting is not available
    }
  }
  
  runApp(const GUDApp());
}
