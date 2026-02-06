import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

/// Push Notification Service
/// 
/// Handles Firebase Cloud Messaging (FCM) for:
/// - Load assignment notifications
/// - Status update notifications
/// - Proof-of-delivery (POD) event notifications
/// - General announcements
/// 
/// Setup Requirements:
/// 1. Configure FCM in Firebase Console
/// 2. Add google-services.json (Android) and GoogleService-Info.plist (iOS)
/// 3. Configure iOS push notification capabilities
/// 4. Request notification permissions
/// 
/// TODO: Implement notification channels for Android
/// TODO: Add notification action handlers
/// TODO: Implement notification badges
/// TODO: Add rich notifications with images and actions
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _fcmToken;
  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request notification permissions
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('✅ User granted provisional notification permission');
      } else {
        print('⚠️ User declined notification permission');
        return;
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      _fcmToken = await _fcm.getToken();
      print('✅ FCM Token: $_fcmToken');

      // Listen for token refresh
      _fcm.onTokenRefresh.listen(_onTokenRefresh);

      // Configure message handlers
      FirebaseMessaging.onMessage.listen(_onMessageReceived);
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      _initialized = true;
      print('✅ Notification service initialized');
    } catch (e) {
      print('❌ Error initializing notification service: $e');
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // TODO: Create Android notification channels
    // Example channels:
    // - load_assignments: High priority for new load assignments
    // - status_updates: Default priority for status changes
    // - pod_events: Default priority for POD uploads
    // - announcements: Low priority for general messages
  }

  /// Handle foreground messages
  void _onMessageReceived(RemoteMessage message) {
    print('📱 Received foreground message: ${message.notification?.title}');
    
    // Display local notification
    _showLocalNotification(
      title: message.notification?.title ?? 'GUD Express',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );

    // TODO: Update app state based on notification type
    // - Refresh load list if load assignment
    // - Update load details if status change
    // - Show POD confirmation if delivery complete
  }

  /// Handle notification tap when app is in background
  void _onMessageOpenedApp(RemoteMessage message) {
    print('📱 Notification tapped: ${message.notification?.title}');
    
    // TODO: Navigate to appropriate screen based on notification type
    // Example:
    // if (message.data['type'] == 'load_assignment') {
    //   Navigator.pushNamed(context, '/load-detail', arguments: message.data['loadId']);
    // }
  }

  /// Handle notification tap from local notification
  void _onNotificationTapped(NotificationResponse response) {
    print('📱 Local notification tapped: ${response.payload}');
    
    // TODO: Parse payload and navigate to appropriate screen
  }

  /// Handle token refresh
  void _onTokenRefresh(String token) {
    _fcmToken = token;
    print('🔄 FCM token refreshed: $token');
    
    // TODO: Update token in Firestore for current user
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = 
        AndroidNotificationDetails(
          'default_channel',
          'Default Notifications',
          channelDescription: 'General notifications for GUD Express',
          importance: Importance.high,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Subscribe user to topic for targeted notifications
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    print('✅ Subscribed to topic: $topic');
  }

  /// Unsubscribe user from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    print('✅ Unsubscribed from topic: $topic');
  }

  /// Save FCM token to Firestore for user
  Future<void> saveFCMToken(String userId, String role) async {
    if (_fcmToken == null) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': _fcmToken,
        'fcmTokenUpdated': FieldValue.serverTimestamp(),
        'platform': Platform.isIOS ? 'ios' : 'android',
      });

      // Subscribe to role-based topics
      await subscribeToTopic(role); // 'admin' or 'driver'
      
      print('✅ FCM token saved for user: $userId');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  /// Send notification to specific user (requires Cloud Functions)
  /// 
  /// This is a placeholder - actual sending should be done from backend
  /// using Cloud Functions for Firebase for security
  /// 
  /// Example Cloud Function:
  /// ```javascript
  /// exports.sendLoadAssignmentNotification = functions.firestore
  ///   .document('loads/{loadId}')
  ///   .onUpdate(async (change, context) => {
  ///     const newData = change.after.data();
  ///     const driverId = newData.driverId;
  ///     
  ///     const driverDoc = await admin.firestore().collection('users').doc(driverId).get();
  ///     const fcmToken = driverDoc.data().fcmToken;
  ///     
  ///     const message = {
  ///       notification: {
  ///         title: 'New Load Assignment',
  ///         body: `You've been assigned load ${newData.loadNumber}`,
  ///       },
  ///       data: {
  ///         type: 'load_assignment',
  ///         loadId: context.params.loadId,
  ///       },
  ///       token: fcmToken,
  ///     };
  ///     
  ///     await admin.messaging().send(message);
  ///   });
  /// ```
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // TODO: Implement via Cloud Functions
    print('⚠️ Notification sending should be done via Cloud Functions');
    print('Title: $title, Body: $body, User: $userId');
  }

  /// Get current FCM token
  String? get token => _fcmToken;
}

/// Background message handler
/// Must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 Handling background message: ${message.messageId}');
  
  // TODO: Process background notifications
  // - Update local database
  // - Show notification
  // - Sync data if needed
}

// TODO: Implement notification types enum
// enum NotificationType {
//   loadAssignment,
//   statusUpdate,
//   podEvent,
//   announcement,
//   reminder,
// }

// TODO: Add notification scheduling
// Schedule reminders for:
// - Upcoming pickups
// - Pending deliveries
// - Missing POD uploads
// - Expiring documents

// TODO: Implement notification analytics
// Track:
// - Notification delivery rates
// - Open rates
// - Action completion rates
