import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/analytics_service.dart';
import '../models/app_user.dart';

/// Profile Screen - Display user profile information
/// 
/// Shows:
/// - Profile photo
/// - Name, email, phone
/// - Role badge
/// - Statistics (loads completed, earnings, etc.)
/// - Action buttons (Edit Profile, Change Photo)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  User? _currentUser;
  AppUser? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    AnalyticsService.instance.logScreenView(screenName: 'profile');
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _authService.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          setState(() {
            _currentUser = user;
            _userData = AppUser.fromMap(user.uid, doc.data()!);
            _isLoading = false;
          });
        } else {
          setState(() {
            _currentUser = user;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Profile',
            onPressed: () async {
              await Navigator.pushNamed(context, '/profile/edit');
              _loadUserData(); // Reload after editing
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            
            // Profile Photo
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    _userData?.name.isNotEmpty == true
                        ? _userData!.name[0].toUpperCase()
                        : _currentUser?.email?[0].toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontSize: 48,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/profile/photo');
                        _loadUserData();
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Name
            Text(
              _userData?.name ?? 'User',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // Role Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _userData?.role == 'admin' ? Colors.blue : Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _userData?.role.toUpperCase() ?? 'USER',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Contact Information
            _buildInfoSection(
              title: 'Contact Information',
              children: [
                _buildInfoTile(
                  icon: Icons.email,
                  label: 'Email',
                  value: _currentUser?.email ?? 'Not set',
                ),
                if (_userData?.phone.isNotEmpty == true)
                  _buildInfoTile(
                    icon: Icons.phone,
                    label: 'Phone',
                    value: _userData!.phone,
                  ),
              ],
            ),

            // Driver-specific info
            if (_userData?.role == 'driver' && _userData?.truckNumber.isNotEmpty == true)
              _buildInfoSection(
                title: 'Vehicle Information',
                children: [
                  _buildInfoTile(
                    icon: Icons.local_shipping,
                    label: 'Truck Number',
                    value: _userData!.truckNumber,
                  ),
                ],
              ),

            // Statistics Cards (Placeholder)
            _buildInfoSection(
              title: 'Statistics',
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Loads',
                          value: '0',
                          icon: Icons.assignment,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Earnings',
                          value: '\$0',
                          icon: Icons.attach_money,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/profile/edit');
                        _loadUserData();
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Change Photo'),
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/profile/photo');
                        _loadUserData();
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(label),
      subtitle: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
