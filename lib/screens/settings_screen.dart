import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/analytics_service.dart';
import 'login_screen.dart';

/// Settings Screen - Central hub for app configuration
/// 
/// Provides access to:
/// - Account settings (profile, password)
/// - Notifications preferences
/// - Data & Reports (history, invoices, exports)
/// - App settings (theme, language, about)
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  User? _currentUser;
  String _userRole = 'driver';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    AnalyticsService.instance.logScreenView(screenName: 'settings');
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      final role = await _authService.getUserRole(user.uid);
      setState(() {
        _currentUser = user;
        _userRole = role;
      });
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        await AnalyticsService.instance.logEvent('signout_from_settings');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // User Info Header
          if (_currentUser != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      _currentUser!.email?[0].toUpperCase() ?? 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser!.email ?? 'User',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _userRole == 'admin' ? Colors.blue : Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _userRole.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Account Section
          _buildSectionHeader('Account'),
          _buildSettingsTile(
            icon: Icons.person,
            title: 'Profile',
            subtitle: 'View and edit your profile',
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          _buildSettingsTile(
            icon: Icons.edit,
            title: 'Edit Profile',
            subtitle: 'Update your information',
            onTap: () => Navigator.pushNamed(context, '/profile/edit'),
          ),
          _buildSettingsTile(
            icon: Icons.photo_camera,
            title: 'Profile Photo',
            subtitle: 'Change your profile picture',
            onTap: () => Navigator.pushNamed(context, '/profile/photo'),
          ),
          _buildSettingsTile(
            icon: Icons.lock,
            title: 'Change Password',
            subtitle: 'Update your password',
            onTap: () => Navigator.pushNamed(context, '/password-reset'),
          ),

          const Divider(),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          _buildSettingsTile(
            icon: Icons.notifications,
            title: 'Notification Preferences',
            subtitle: 'Manage your notification settings',
            onTap: () => Navigator.pushNamed(context, '/notification-preferences'),
          ),

          const Divider(),

          // Data & Reports Section
          _buildSectionHeader('Data & Reports'),
          _buildSettingsTile(
            icon: Icons.history,
            title: 'Load History',
            subtitle: 'View past loads and deliveries',
            onTap: () => Navigator.pushNamed(context, '/load-history'),
          ),
          if (_userRole == 'admin')
            _buildSettingsTile(
              icon: Icons.receipt,
              title: 'Invoices',
              subtitle: 'Manage invoices and billing',
              onTap: () => Navigator.pushNamed(context, '/invoices'),
            ),
          _buildSettingsTile(
            icon: Icons.file_download,
            title: 'Export Data',
            subtitle: 'Export your data to CSV/PDF',
            onTap: () => Navigator.pushNamed(context, '/export'),
          ),
          _buildSettingsTile(
            icon: Icons.attach_money,
            title: 'Earnings',
            subtitle: 'View your earnings history',
            onTap: () => Navigator.pushNamed(context, '/driver/earnings'),
          ),
          _buildSettingsTile(
            icon: Icons.receipt_long,
            title: 'Expenses',
            subtitle: 'Track your expenses',
            onTap: () => Navigator.pushNamed(context, '/driver/expenses'),
          ),

          const Divider(),

          // App Settings Section
          _buildSectionHeader('App Settings'),
          _buildSettingsTile(
            icon: Icons.palette,
            title: 'Theme',
            subtitle: 'Light or Dark mode (Coming soon)',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Theme settings coming soon')),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'Change app language (Coming soon)',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language settings coming soon')),
              );
            },
          ),
          _buildSettingsTile(
            icon: Icons.info,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () => _showAboutDialog(),
          ),

          const Divider(),

          // Sign Out
          _buildSettingsTile(
            icon: Icons.exit_to_app,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            onTap: _signOut,
            textColor: Colors.red,
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

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Theme.of(context).primaryColor),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'GUD Express',
      applicationVersion: '2.1.0',
      applicationIcon: const Icon(Icons.local_shipping, size: 48),
      children: [
        const Text(
          'GUD Express is a comprehensive trucking management application '
          'designed to streamline logistics operations.',
        ),
        const SizedBox(height: 16),
        const Text(
          '© 2024 GUD Express. All rights reserved.',
        ),
      ],
    );
  }
}
