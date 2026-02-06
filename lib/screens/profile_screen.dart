import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/app_user.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../widgets/profile_photo_widget.dart';
import '../widgets/loading.dart';
import 'edit_profile_screen.dart';
import 'profile_photo_screen.dart';
import 'login_screen.dart';

/// Profile viewing screen
/// 
/// Displays:
/// - User's profile photo
/// - User information (name, email, phone, truck number)
/// - Profile completion indicator
/// - User statistics (total loads, completed loads, member since)
/// - Edit profile button
/// - Logout button
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  
  AppUser? _currentUser;
  Map<String, dynamic>? _userStats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'No user logged in';
          _isLoading = false;
        });
        return;
      }

      final profile = await _profileService.getCurrentUserProfile();
      final stats = await _profileService.getUserStatistics(user.uid);

      if (mounted) {
        setState(() {
          _currentUser = profile;
          _userStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _navigateToEditProfile() async {
    if (_currentUser == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(user: _currentUser!),
      ),
    );

    if (result == true) {
      _loadUserProfile();
    }
  }

  Future<void> _navigateToProfilePhoto() async {
    if (_currentUser == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePhotoScreen(user: _currentUser!),
      ),
    );

    if (result == true) {
      _loadUserProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Loading()
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadUserProfile,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildProfileCompletion(),
                        const SizedBox(height: 24),
                        _buildUserInfo(),
                        const SizedBox(height: 24),
                        _buildStatistics(),
                        const SizedBox(height: 24),
                        _buildActions(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _navigateToProfilePhoto,
            child: ProfilePhotoWidget(
              photoUrl: _currentUser?.profilePhotoUrl,
              userName: _currentUser?.name ?? '',
              size: ProfilePhotoSize.large,
              showEditButton: true,
              onEditPressed: _navigateToProfilePhoto,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentUser?.name ?? 'Unknown User',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            _currentUser?.email ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _currentUser?.role == 'admin'
                  ? Colors.purple[100]
                  : Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _currentUser?.role == 'admin' ? 'ADMIN' : 'DRIVER',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _currentUser?.role == 'admin'
                    ? Colors.purple[800]
                    : Colors.blue[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCompletion() {
    final completion = _currentUser?.profileCompletionPercentage ?? 0.0;
    final percentage = (completion * 100).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profile Completion',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: completion,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    completion >= 0.8
                        ? Colors.green
                        : completion >= 0.5
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
              ),
              if (completion < 1.0) ...[
                const SizedBox(height: 8),
                Text(
                  'Complete your profile to unlock all features',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Column(
          children: [
            _buildInfoTile(
              icon: Icons.person,
              label: 'Name',
              value: _currentUser?.name ?? 'Not set',
            ),
            const Divider(height: 1),
            _buildInfoTile(
              icon: Icons.email,
              label: 'Email',
              value: _currentUser?.email ?? 'Not set',
            ),
            const Divider(height: 1),
            _buildInfoTile(
              icon: Icons.phone,
              label: 'Phone',
              value: _currentUser?.phone ?? 'Not set',
            ),
            const Divider(height: 1),
            _buildInfoTile(
              icon: Icons.local_shipping,
              label: 'Truck Number',
              value: _currentUser?.truckNumber ?? 'Not set',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    if (_userStats == null) return const SizedBox.shrink();

    final memberSince = _userStats!['memberSince'] as DateTime?;
    final memberSinceText = memberSince != null
        ? DateFormat('MMM yyyy').format(memberSince)
        : 'Unknown';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      label: 'Total Loads',
                      value: '${_userStats!['totalLoads']}',
                      icon: Icons.inventory_2,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      label: 'Completed',
                      value: '${_userStats!['completedLoads']}',
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                label: 'Member Since',
                value: memberSinceText,
                icon: Icons.calendar_today,
                color: Colors.purple,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _navigateToEditProfile,
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
