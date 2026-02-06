import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/analytics_service.dart';

/// Profile Photo Screen - Manage profile photo
/// 
/// Actions:
/// - Take photo with camera
/// - Choose from gallery
/// - Remove photo
class ProfilePhotoScreen extends StatefulWidget {
  const ProfilePhotoScreen({super.key});

  @override
  State<ProfilePhotoScreen> createState() => _ProfilePhotoScreenState();
}

class _ProfilePhotoScreenState extends State<ProfilePhotoScreen> {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final ImagePicker _imagePicker = ImagePicker();
  
  String? _currentPhotoUrl;
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentPhoto();
    AnalyticsService.instance.logScreenView(screenName: 'profile_photo');
  }

  Future<void> _loadCurrentPhoto() async {
    // TODO: Load current photo URL from Firestore user document
    // For now, using placeholder
    setState(() {
      _currentPhotoUrl = null;
    });
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (photo != null) {
        await _uploadPhoto(File(photo.path));
      }
    } catch (e) {
      _showError('Error taking photo: $e');
    }
  }

  Future<void> _chooseFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadPhoto(File(image.path));
      }
    } catch (e) {
      _showError('Error choosing photo: $e');
    }
  }

  Future<void> _uploadPhoto(File imageFile) async {
    setState(() => _isUploading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Upload to Firebase Storage
      final photoUrl = await _storageService.uploadProfilePhoto(
        userId: user.uid,
        imageFile: imageFile,
      );

      if (mounted) {
        await AnalyticsService.instance.logEvent('profile_photo_updated');
        
        setState(() {
          _currentPhotoUrl = photoUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error uploading photo: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _removePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text('Are you sure you want to remove your profile photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      
      try {
        // TODO: Remove photo from storage and update Firestore
        await AnalyticsService.instance.logEvent('profile_photo_removed');
        
        setState(() {
          _currentPhotoUrl = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo removed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        _showError('Error removing photo: $e');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Photo'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Current Photo Display
              Stack(
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    backgroundImage: _currentPhotoUrl != null
                        ? NetworkImage(_currentPhotoUrl!)
                        : null,
                    child: _currentPhotoUrl == null
                        ? Icon(
                            Icons.person,
                            size: 80,
                            color: Theme.of(context).primaryColor,
                          )
                        : null,
                  ),
                  if (_isUploading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 48),

              // Take Photo Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                  onPressed: _isUploading ? null : _takePhoto,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Choose from Gallery Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Choose from Gallery'),
                  onPressed: _isUploading ? null : _chooseFromGallery,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Remove Photo Button (if photo exists)
              if (_currentPhotoUrl != null)
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                    onPressed: _isUploading || _isLoading ? null : _removePhoto,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // Info Text
              Text(
                'Photos should be square and at least 400x400 pixels',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
