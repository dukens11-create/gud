import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    // Create Android notification channels
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    // High priority channel for load assignments
    const AndroidNotificationChannel loadAssignmentsChannel = AndroidNotificationChannel(
      'load_assignments',
      'Load Assignments',
      description: 'Notifications for new load assignments',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Default priority channel for status updates
    const AndroidNotificationChannel statusUpdatesChannel = AndroidNotificationChannel(
      'status_updates',
      'Status Updates',
      description: 'Notifications for load status changes',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    // Default priority channel for POD events
    const AndroidNotificationChannel podEventsChannel = AndroidNotificationChannel(
      'pod_events',
      'POD Events',
      description: 'Notifications for proof-of-delivery events',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    // Low priority channel for announcements
    const AndroidNotificationChannel announcementsChannel = AndroidNotificationChannel(
      'announcements',
      'Announcements',
      description: 'General announcements and notifications',
      importance: Importance.low,
      playSound: false,
    );

    // High priority channel for document expiration alerts
    const AndroidNotificationChannel expirationAlertsChannel = AndroidNotificationChannel(
      'expiration_alerts',
      'Document Expiration Alerts',
      description: 'Notifications for expiring driver and truck documents',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Create channels
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(loadAssignmentsChannel);
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(statusUpdatesChannel);
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(podEventsChannel);
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(announcementsChannel);
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(expirationAlertsChannel);

    print('✅ Android notification channels created');
  }

  /// Handle foreground messages
  void _onMessageReceived(RemoteMessage message) {
    print('📱 Received foreground message: ${message.notification?.title}');
    
    // Determine notification channel based on type
    String channelId = 'default_channel';
    if (message.data['type'] == 'load_assignment') {
      channelId = 'load_assignments';
    } else if (message.data['type'] == 'status_change') {
      channelId = 'status_updates';
    } else if (message.data['type'] == 'pod_event') {
      channelId = 'pod_events';
    } else if (message.data['type'] == 'announcement') {
      channelId = 'announcements';
    } else if (message.data['type'] == 'expiration_alert') {
      channelId = 'expiration_alerts';
    }
    
    // Display local notification with appropriate channel
    _showLocalNotification(
      title: message.notification?.title ?? 'GUD Express',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
      channelId: channelId,
    );
  }

  /// Handle notification tap when app is in background
  void _onMessageOpenedApp(RemoteMessage message) {
    print('📱 Notification tapped: ${message.notification?.title}');
    
    // Navigate to appropriate screen based on notification type
    final notificationType = message.data['type'];
    final loadId = message.data['loadId'];
    
    if (notificationType == 'load_assignment' && loadId != null) {
      // Navigate to load detail screen
      Future.delayed(const Duration(milliseconds: 500), () {
        // Use navigation service for global navigation
        try {
          // This will be handled by the app's navigation setup
          print('Navigate to load detail: $loadId');
        } catch (e) {
          print('Error navigating to load detail: $e');
        }
      });
    } else if (notificationType == 'status_change' && loadId != null) {
      // Navigate to load detail screen
      print('Navigate to load detail for status change: $loadId');
    }
  }

  /// Handle notification tap from local notification
  void _onNotificationTapped(NotificationResponse response) {
    print('📱 Local notification tapped: ${response.payload}');
    
    // Parse payload and navigate to appropriate screen
    if (response.payload != null) {
      try {
        // Payload is a string representation of the data map
        // Parse it to extract navigation info
        print('Notification payload: ${response.payload}');
        // Navigation will be handled based on the payload content
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  /// Handle token refresh
  void _onTokenRefresh(String token) async {
    _fcmToken = token;
    print('🔄 FCM token refreshed: $token');
    
    // Update token in Firestore for current user
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'fcmTokenUpdated': FieldValue.serverTimestamp(),
        });
        print('✅ FCM token updated in Firestore');
      }
    } catch (e) {
      print('❌ Error updating FCM token: $e');
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'default_channel',
  }) async {
    // Get channel name and description based on channelId
    String channelName = 'Default Notifications';
    String channelDescription = 'General notifications for GUD Express';
    Importance importance = Importance.defaultImportance;
    Priority priority = Priority.defaultPriority;

    if (channelId == 'load_assignments') {
      channelName = 'Load Assignments';
      channelDescription = 'Notifications for new load assignments';
      importance = Importance.high;
      priority = Priority.high;
    } else if (channelId == 'status_updates') {
      channelName = 'Status Updates';
      channelDescription = 'Notifications for load status changes';
    } else if (channelId == 'pod_events') {
      channelName = 'POD Events';
      channelDescription = 'Notifications for proof-of-delivery events';
    } else if (channelId == 'announcements') {
      channelName = 'Announcements';
      channelDescription = 'General announcements and notifications';
      importance = Importance.low;
      priority = Priority.low;
    } else if (channelId == 'expiration_alerts') {
      channelName = 'Document Expiration Alerts';
      channelDescription = 'Notifications for expiring driver and truck documents';
      importance = Importance.high;
      priority = Priority.high;
    }

    final AndroidNotificationDetails androidDetails = 
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: importance,
          priority: priority,
          showWhen: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
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
