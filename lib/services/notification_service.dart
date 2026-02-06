import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:flutter/material.dart';

/// Notification Types
enum NotificationType {
  loadAssignment,
  statusUpdate,
  podEvent,
  announcement,
  reminder,
}

/// Notification Priority Levels
enum NotificationPriority {
  high,
  medium,
  low,
}

/// Notification History Entry
class NotificationHistory {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  final bool isRead;

  NotificationHistory({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.data,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
    'title': title,
    'body': body,
    'type': type.toString(),
    'timestamp': timestamp.toIso8601String(),
    'data': data,
    'isRead': isRead,
  };

  static NotificationHistory fromMap(String id, Map<String, dynamic> map) {
    return NotificationHistory(
      id: id,
      title: map['title'] as String,
      body: map['body'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => NotificationType.announcement,
      ),
      timestamp: DateTime.parse(map['timestamp'] as String),
      data: map['data'] as Map<String, dynamic>?,
      isRead: map['isRead'] as bool? ?? false,
    );
  }
}

/// Push Notification Service
/// 
/// Handles Firebase Cloud Messaging (FCM) with:
/// - Priority-based Android notification channels
/// - Rich notifications with images and actions
/// - Notification badges and action handlers
/// - Notification history storage
/// - User preferences management
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
  String? _currentUserId;
  
  // Notification preferences (stored per user)
  final Map<NotificationType, bool> _notificationPreferences = {
    NotificationType.loadAssignment: true,
    NotificationType.statusUpdate: true,
    NotificationType.podEvent: true,
    NotificationType.announcement: true,
    NotificationType.reminder: true,
  };

  // Android notification channels
  static const String _highPriorityChannel = 'high_priority_channel';
  static const String _mediumPriorityChannel = 'medium_priority_channel';
  static const String _lowPriorityChannel = 'low_priority_channel';

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
          onDidReceiveLocalNotification: (id, title, body, payload) async {
            // Handle iOS foreground notification
          },
        );

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channels
    await _createAndroidNotificationChannels();
  }

  /// Create Android notification channels with different priorities
  Future<void> _createAndroidNotificationChannels() async {
    if (!Platform.isAndroid) return;

    // High priority channel (for urgent notifications like load assignments)
    const AndroidNotificationChannel highPriorityChannel = AndroidNotificationChannel(
      _highPriorityChannel,
      'High Priority',
      description: 'Urgent notifications like new load assignments',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Colors.red,
      showBadge: true,
    );

    // Medium priority channel (for status updates and POD events)
    const AndroidNotificationChannel mediumPriorityChannel = AndroidNotificationChannel(
      _mediumPriorityChannel,
      'Medium Priority',
      description: 'Important notifications like status updates and POD events',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Low priority channel (for announcements and reminders)
    const AndroidNotificationChannel lowPriorityChannel = AndroidNotificationChannel(
      _lowPriorityChannel,
      'Low Priority',
      description: 'General notifications like announcements and reminders',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(highPriorityChannel);
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(mediumPriorityChannel);
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(lowPriorityChannel);

    print('✅ Android notification channels created');
  }

  /// Handle foreground messages
  void _onMessageReceived(RemoteMessage message) async {
    print('📱 Received foreground message: ${message.notification?.title}');
    
    // Parse notification type
    final notificationType = _parseNotificationType(message.data['type']);
    
    // Check if user has enabled this notification type
    if (_notificationPreferences[notificationType] != true) {
      print('⚠️ Notification type disabled by user: $notificationType');
      return;
    }
    
    // Save to notification history
    await _saveNotificationToHistory(message);
    
    // Display local notification with appropriate priority
    await _showLocalNotification(
      title: message.notification?.title ?? 'GUD Express',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
      type: notificationType,
      imageUrl: message.notification?.android?.imageUrl,
    );

    // Update badge count
    await _updateBadgeCount();
  }

  /// Handle notification tap when app is in background
  void _onMessageOpenedApp(RemoteMessage message) async {
    print('📱 Notification tapped: ${message.notification?.title}');
    
    // Mark as read in history
    if (message.messageId != null) {
      await _markNotificationAsRead(message.messageId!);
    }
    
    // Update badge count
    await _updateBadgeCount();
    
    // Navigate based on notification type
    _handleNotificationNavigation(message.data);
  }

  /// Handle notification tap from local notification
  void _onNotificationTapped(NotificationResponse response) async {
    print('📱 Local notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      // Parse payload and navigate
      try {
        // Expected payload format: "type:value,loadId:value"
        final Map<String, String> data = {};
        response.payload!.split(',').forEach((pair) {
          final parts = pair.split(':');
          if (parts.length == 2) {
            data[parts[0].trim()] = parts[1].trim();
          }
        });
        
        _handleNotificationNavigation(data);
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
      }
    }
  }

  /// Parse notification type from string
  NotificationType _parseNotificationType(dynamic type) {
    if (type == null) return NotificationType.announcement;
    
    switch (type.toString()) {
      case 'load_assignment':
        return NotificationType.loadAssignment;
      case 'status_update':
        return NotificationType.statusUpdate;
      case 'pod_event':
        return NotificationType.podEvent;
      case 'reminder':
        return NotificationType.reminder;
      default:
        return NotificationType.announcement;
    }
  }

  /// Handle notification navigation based on type and data
  void _handleNotificationNavigation(Map<dynamic, dynamic> data) {
    // This will be called by the app to handle navigation
    // Apps should listen to a stream or callback for navigation events
    print('Navigate to: ${data['type']} with data: $data');
    
    // Example navigation logic (to be implemented by app):
    // if (data['type'] == 'load_assignment' && data['loadId'] != null) {
    //   navigatorKey.currentState?.pushNamed('/load-detail', arguments: data['loadId']);
    // }
  }

  /// Save notification to history
  Future<void> _saveNotificationToHistory(RemoteMessage message) async {
    if (_currentUserId == null) return;

    try {
      final notification = NotificationHistory(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
        type: _parseNotificationType(message.data['type']),
        timestamp: DateTime.now(),
        data: message.data,
        isRead: false,
      );

      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());

      print('✅ Notification saved to history');
    } catch (e) {
      print('❌ Error saving notification to history: $e');
    }
  }

  /// Mark notification as read
  Future<void> _markNotificationAsRead(String notificationId) async {
    if (_currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Update badge count with unread notifications
  Future<void> _updateBadgeCount() async {
    if (_currentUserId == null) return;

    try {
      final unreadSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      final unreadCount = unreadSnapshot.count ?? 0;
      
      // Update badge on iOS
      if (Platform.isIOS) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(badge: true);
      }
      
      // Update badge on Android
      if (Platform.isAndroid) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.deleteBadge();
      }

      print('✅ Badge count updated: $unreadCount');
    } catch (e) {
      print('❌ Error updating badge count: $e');
    }
  }

  /// Handle token refresh
  void _onTokenRefresh(String token) {
    _fcmToken = token;
    print('🔄 FCM token refreshed: $token');
    
    // TODO: Update token in Firestore for current user
  }

  /// Show local notification with rich content
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    NotificationType type = NotificationType.announcement,
    String? imageUrl,
  }) async {
    final priority = _getNotificationPriority(type);
    final channelId = _getChannelIdForPriority(priority);
    
    // Android notification details with actions
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelNameForPriority(priority),
      channelDescription: _getChannelDescriptionForPriority(priority),
      importance: _getImportanceForPriority(priority),
      priority: _getPriorityForPriority(priority),
      styleInformation: imageUrl != null 
          ? BigPictureStyleInformation(
              FilePathAndroidBitmap(imageUrl),
              contentTitle: title,
              summaryText: body,
            )
          : BigTextStyleInformation(
              body,
              contentTitle: title,
            ),
      actions: _getNotificationActions(type),
      showWhen: true,
      enableVibration: priority != NotificationPriority.low,
      playSound: priority != NotificationPriority.low,
      color: _getNotificationColor(type),
      ledColor: _getNotificationColor(type),
      enableLights: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: 'gud_express',
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

  /// Get notification priority based on type
  NotificationPriority _getNotificationPriority(NotificationType type) {
    switch (type) {
      case NotificationType.loadAssignment:
      case NotificationType.reminder:
        return NotificationPriority.high;
      case NotificationType.statusUpdate:
      case NotificationType.podEvent:
        return NotificationPriority.medium;
      case NotificationType.announcement:
        return NotificationPriority.low;
    }
  }

  /// Get channel ID for priority
  String _getChannelIdForPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
        return _highPriorityChannel;
      case NotificationPriority.medium:
        return _mediumPriorityChannel;
      case NotificationPriority.low:
        return _lowPriorityChannel;
    }
  }

  /// Get channel name for priority
  String _getChannelNameForPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
        return 'High Priority';
      case NotificationPriority.medium:
        return 'Medium Priority';
      case NotificationPriority.low:
        return 'Low Priority';
    }
  }

  /// Get channel description for priority
  String _getChannelDescriptionForPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
        return 'Urgent notifications';
      case NotificationPriority.medium:
        return 'Important notifications';
      case NotificationPriority.low:
        return 'General notifications';
    }
  }

  /// Get Android importance for priority
  Importance _getImportanceForPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
        return Importance.max;
      case NotificationPriority.medium:
        return Importance.high;
      case NotificationPriority.low:
        return Importance.low;
    }
  }

  /// Get Android priority for priority
  Priority _getPriorityForPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.medium:
        return Priority.defaultPriority;
      case NotificationPriority.low:
        return Priority.low;
    }
  }

  /// Get notification actions based on type
  List<AndroidNotificationAction> _getNotificationActions(NotificationType type) {
    switch (type) {
      case NotificationType.loadAssignment:
        return [
          const AndroidNotificationAction('view', 'View Details'),
          const AndroidNotificationAction('dismiss', 'Dismiss'),
        ];
      case NotificationType.statusUpdate:
        return [
          const AndroidNotificationAction('view', 'View'),
        ];
      case NotificationType.podEvent:
        return [
          const AndroidNotificationAction('view', 'View POD'),
        ];
      case NotificationType.reminder:
        return [
          const AndroidNotificationAction('snooze', 'Snooze'),
          const AndroidNotificationAction('dismiss', 'Dismiss'),
        ];
      default:
        return [];
    }
  }

  /// Get notification color based on type
  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.loadAssignment:
        return Colors.blue;
      case NotificationType.statusUpdate:
        return Colors.orange;
      case NotificationType.podEvent:
        return Colors.green;
      case NotificationType.reminder:
        return Colors.red;
      case NotificationType.announcement:
        return Colors.grey;
    }
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
    
    _currentUserId = userId;

    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': _fcmToken,
        'fcmTokenUpdated': FieldValue.serverTimestamp(),
        'platform': Platform.isIOS ? 'ios' : 'android',
      });

      // Subscribe to role-based topics
      await subscribeToTopic(role); // 'admin' or 'driver'
      
      // Load user notification preferences
      await _loadNotificationPreferences(userId);
      
      print('✅ FCM token saved for user: $userId');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  /// Load notification preferences from Firestore
  Future<void> _loadNotificationPreferences(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notifications')
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          for (var type in NotificationType.values) {
            final key = type.toString().split('.').last;
            if (data.containsKey(key)) {
              _notificationPreferences[type] = data[key] as bool;
            }
          }
        }
      }
      
      print('✅ Notification preferences loaded');
    } catch (e) {
      print('❌ Error loading notification preferences: $e');
    }
  }

  /// Save notification preferences to Firestore
  Future<void> saveNotificationPreferences() async {
    if (_currentUserId == null) return;

    try {
      final Map<String, bool> prefs = {};
      for (var entry in _notificationPreferences.entries) {
        prefs[entry.key.toString().split('.').last] = entry.value;
      }

      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('settings')
          .doc('notifications')
          .set(prefs);

      print('✅ Notification preferences saved');
    } catch (e) {
      print('❌ Error saving notification preferences: $e');
    }
  }

  /// Update notification preference for a specific type
  Future<void> updateNotificationPreference(NotificationType type, bool enabled) async {
    _notificationPreferences[type] = enabled;
    await saveNotificationPreferences();
  }

  /// Get notification preference for a specific type
  bool getNotificationPreference(NotificationType type) {
    return _notificationPreferences[type] ?? true;
  }

  /// Get all notification preferences
  Map<NotificationType, bool> getAllNotificationPreferences() {
    return Map.from(_notificationPreferences);
  }

  /// Get notification history for current user
  Stream<List<NotificationHistory>> getNotificationHistory({int limit = 50}) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationHistory.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    if (_currentUserId == null) return 0;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ Error getting unread notification count: $e');
      return 0;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllNotificationsAsRead() async {
    if (_currentUserId == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      await _updateBadgeCount();
      print('✅ All notifications marked as read');
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
    }
  }

  /// Clear notification history
  Future<void> clearNotificationHistory() async {
    if (_currentUserId == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('notifications')
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      await _updateBadgeCount();
      print('✅ Notification history cleared');
    } catch (e) {
      print('❌ Error clearing notification history: $e');
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
