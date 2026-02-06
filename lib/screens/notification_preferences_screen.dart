import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/analytics_service.dart';

/// Notification Preferences Screen - Manage notification settings
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  bool _loadUpdates = true;
  bool _deliveryAlerts = true;
  bool _podReminders = true;
  bool _earningsUpdates = true;
  bool _systemNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    AnalyticsService.instance.logScreenView(screenName: 'notification_preferences');
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loadUpdates = prefs.getBool('notif_load_updates') ?? true;
      _deliveryAlerts = prefs.getBool('notif_delivery_alerts') ?? true;
      _podReminders = prefs.getBool('notif_pod_reminders') ?? true;
      _earningsUpdates = prefs.getBool('notif_earnings_updates') ?? true;
      _systemNotifications = prefs.getBool('notif_system') ?? true;
      _emailNotifications = prefs.getBool('notif_email') ?? true;
      _smsNotifications = prefs.getBool('notif_sms') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    
    await AnalyticsService.instance.logEvent('notification_preference_changed', parameters: {
      'preference': key,
      'value': value.toString(),
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notification Preferences')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('App Notifications'),
          _buildSwitchTile(
            title: 'Load Updates',
            subtitle: 'Get notified about new loads and assignments',
            value: _loadUpdates,
            onChanged: (value) {
              setState(() => _loadUpdates = value);
              _savePreference('notif_load_updates', value);
            },
          ),
          _buildSwitchTile(
            title: 'Delivery Alerts',
            subtitle: 'Alerts for delivery status changes',
            value: _deliveryAlerts,
            onChanged: (value) {
              setState(() => _deliveryAlerts = value);
              _savePreference('notif_delivery_alerts', value);
            },
          ),
          _buildSwitchTile(
            title: 'POD Reminders',
            subtitle: 'Reminders to submit proof of delivery',
            value: _podReminders,
            onChanged: (value) {
              setState(() => _podReminders = value);
              _savePreference('notif_pod_reminders', value);
            },
          ),
          _buildSwitchTile(
            title: 'Earnings Updates',
            subtitle: 'Notifications about earnings and payments',
            value: _earningsUpdates,
            onChanged: (value) {
              setState(() => _earningsUpdates = value);
              _savePreference('notif_earnings_updates', value);
            },
          ),
          _buildSwitchTile(
            title: 'System Notifications',
            subtitle: 'Important system messages and updates',
            value: _systemNotifications,
            onChanged: (value) {
              setState(() => _systemNotifications = value);
              _savePreference('notif_system', value);
            },
          ),
          const Divider(),
          _buildSectionHeader('Delivery Methods'),
          _buildSwitchTile(
            title: 'Email Notifications',
            subtitle: 'Receive notifications via email',
            value: _emailNotifications,
            onChanged: (value) {
              setState(() => _emailNotifications = value);
              _savePreference('notif_email', value);
            },
          ),
          _buildSwitchTile(
            title: 'SMS Notifications',
            subtitle: 'Receive notifications via text message (Coming soon)',
            value: _smsNotifications,
            onChanged: (value) {
              setState(() => _smsNotifications = value);
              _savePreference('notif_sms', value);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('SMS notifications coming soon!'),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}
