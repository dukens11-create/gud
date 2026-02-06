import 'package:flutter/material.dart';
import '../services/notification_service.dart';

/// Notification Preferences Screen
/// 
/// Allows users to manage their notification settings:
/// - Enable/disable notifications by type
/// - View notification history
/// - Clear notification history
/// - Manage badge counts
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  final NotificationService _notificationService = NotificationService();
  late Map<NotificationType, bool> _preferences;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    _preferences = _notificationService.getAllNotificationPreferences();
    setState(() => _isLoading = false);
  }

  Future<void> _updatePreference(NotificationType type, bool value) async {
    setState(() {
      _preferences[type] = value;
    });

    await _notificationService.updateNotificationPreference(type, value);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_getNotificationTypeName(type)} notifications ${value ? 'enabled' : 'disabled'}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _getNotificationTypeName(NotificationType type) {
    switch (type) {
      case NotificationType.loadAssignment:
        return 'Load Assignment';
      case NotificationType.statusUpdate:
        return 'Status Update';
      case NotificationType.podEvent:
        return 'POD Event';
      case NotificationType.announcement:
        return 'Announcement';
      case NotificationType.reminder:
        return 'Reminder';
    }
  }

  String _getNotificationTypeDescription(NotificationType type) {
    switch (type) {
      case NotificationType.loadAssignment:
        return 'Get notified when a new load is assigned to you';
      case NotificationType.statusUpdate:
        return 'Get notified about load status changes';
      case NotificationType.podEvent:
        return 'Get notified about proof of delivery updates';
      case NotificationType.announcement:
        return 'Receive general announcements and news';
      case NotificationType.reminder:
        return 'Get reminders for pending tasks and deliveries';
    }
  }

  IconData _getNotificationTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.loadAssignment:
        return Icons.local_shipping;
      case NotificationType.statusUpdate:
        return Icons.update;
      case NotificationType.podEvent:
        return Icons.receipt_long;
      case NotificationType.announcement:
        return Icons.campaign;
      case NotificationType.reminder:
        return Icons.alarm;
    }
  }

  Future<void> _showClearHistoryDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Notification History'),
        content: const Text(
          'Are you sure you want to clear all notification history? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _notificationService.clearNotificationHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification history cleared')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Choose which notifications you want to receive',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ...NotificationType.values.map((type) {
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: SwitchListTile(
                      value: _preferences[type] ?? true,
                      onChanged: (value) => _updatePreference(type, value),
                      title: Row(
                        children: [
                          Icon(
                            _getNotificationTypeIcon(type),
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Text(_getNotificationTypeName(type)),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8, left: 36),
                        child: Text(
                          _getNotificationTypeDescription(type),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      secondary: _preferences[type] == true
                          ? const Icon(Icons.notifications_active, color: Colors.green)
                          : const Icon(Icons.notifications_off, color: Colors.grey),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _showClearHistoryDialog,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Clear Notification History'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await _notificationService.markAllNotificationsAsRead();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('All notifications marked as read')),
                            );
                          }
                        },
                        icon: const Icon(Icons.done_all),
                        label: const Text('Mark All as Read'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

/// Notification History Screen
/// 
/// Displays all past notifications received by the user
class NotificationHistoryScreen extends StatelessWidget {
  const NotificationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification History'),
      ),
      body: StreamBuilder<List<NotificationHistory>>(
        stream: notificationService.getNotificationHistory(limit: 100),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: notification.isRead
                        ? Colors.grey.shade300
                        : Theme.of(context).primaryColor,
                    child: Icon(
                      _getIconForType(notification.type),
                      color: notification.isRead ? Colors.grey : Colors.white,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(notification.body),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(notification.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  trailing: !notification.isRead
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.loadAssignment:
        return Icons.local_shipping;
      case NotificationType.statusUpdate:
        return Icons.update;
      case NotificationType.podEvent:
        return Icons.receipt_long;
      case NotificationType.announcement:
        return Icons.campaign;
      case NotificationType.reminder:
        return Icons.alarm;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
