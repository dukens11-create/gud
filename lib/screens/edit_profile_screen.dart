import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../services/profile_service.dart';
import '../widgets/app_textfield.dart';
import '../widgets/app_button.dart';

/// Profile editing screen
/// 
/// Features:
/// - Form with text fields for name, email, phone, truck number
/// - Form validation
/// - Save button
/// - Cancel button
/// - Success/error feedback
class EditProfileScreen extends StatefulWidget {
  final AppUser user;

  const EditProfileScreen({
    super.key,
    required this.user,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _truckNumberController;

  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
    _truckNumberController = TextEditingController(text: widget.user.truckNumber);

    // Listen for changes
    _nameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _truckNumberController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _truckNumberController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    setState(() {
      _hasChanges = _nameController.text != widget.user.name ||
          _emailController.text != widget.user.email ||
          _phoneController.text != widget.user.phone ||
          _truckNumberController.text != widget.user.truckNumber;
    });
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? _validateTruckNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Truck number is required';
    }
    if (value.trim().length < 2) {
      return 'Truck number must be at least 2 characters';
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes to save')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      final success = await _profileService.updateProfile(
        userId: user.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        truckNumber: _truckNumberController.text.trim(),
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update profile'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Do you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Full Name',
                        controller: _nameController,
                        validator: _validateName,
                        keyboardType: TextInputType.name,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Email Address',
                        controller: _emailController,
                        validator: _validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Changing your email will update your login credentials',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Phone Number',
                        controller: _phoneController,
                        validator: _validatePhone,
                        keyboardType: TextInputType.phone,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Truck Number',
                        controller: _truckNumberController,
                        validator: _validateTruckNumber,
                        keyboardType: TextInputType.text,
                        enabled: !_isLoading,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Save Changes',
                onPressed: _saveProfile,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              if (_hasChanges) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[800], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You have unsaved changes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
