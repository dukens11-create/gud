import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import 'storage_service.dart';
import 'dart:io';

/// Profile Service
/// 
/// Handles user profile operations:
/// - Fetch user profile
/// - Update user profile
/// - Upload profile photo
/// - Delete profile photo
/// - Manage profile completeness
class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();

  /// Get current user profile
  Future<AppUser?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    return getUserProfile(user.uid);
  }

  /// Get user profile by ID
  Future<AppUser?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) {
        print('⚠️ User profile not found: $userId');
        return null;
      }

      return AppUser.fromMap(userId, doc.data()!);
    } catch (e) {
      print('❌ Error fetching user profile: $e');
      return null;
    }
  }

  /// Stream user profile changes
  Stream<AppUser?> streamUserProfile(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return AppUser.fromMap(userId, snapshot.data()!);
        });
  }

  /// Update user profile
  Future<bool> updateProfile({
    required String userId,
    String? name,
    String? email,
    String? phone,
    String? truckNumber,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email;
      if (phone != null) updates['phone'] = phone;
      if (truckNumber != null) updates['truckNumber'] = truckNumber;

      await _firestore.collection('users').doc(userId).update(updates);

      // Update email in Firebase Auth if changed
      if (email != null && _auth.currentUser != null) {
        try {
          await _auth.currentUser!.updateEmail(email);
        } catch (e) {
          print('⚠️ Could not update email in Firebase Auth: $e');
          // Continue anyway as Firestore was updated
        }
      }

      print('✅ Profile updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating profile: $e');
      return false;
    }
  }

  /// Upload profile photo
  Future<String?> uploadProfilePhoto({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // Upload to Firebase Storage
      final photoUrl = await _storageService.uploadProfilePhoto(
        userId: userId,
        imageFile: imageFile,
      );

      if (photoUrl == null) {
        print('❌ Failed to upload profile photo');
        return null;
      }

      // Update profile photo URL in Firestore
      await _firestore.collection('users').doc(userId).update({
        'profilePhotoUrl': photoUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('✅ Profile photo uploaded successfully');
      return photoUrl;
    } catch (e) {
      print('❌ Error uploading profile photo: $e');
      return null;
    }
  }

  /// Delete profile photo
  Future<bool> deleteProfilePhoto(String userId) async {
    try {
      // Get current photo URL
      final profile = await getUserProfile(userId);
      if (profile?.profilePhotoUrl == null) {
        print('⚠️ No profile photo to delete');
        return true;
      }

      // Delete from Firebase Storage
      await _storageService.deleteFile(profile!.profilePhotoUrl!);

      // Remove photo URL from Firestore
      await _firestore.collection('users').doc(userId).update({
        'profilePhotoUrl': FieldValue.delete(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('✅ Profile photo deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting profile photo: $e');
      return false;
    }
  }

  /// Get default avatar URL or initials
  String getDefaultAvatar(String name) {
    if (name.isEmpty) return 'https://ui-avatars.com/api/?name=User&background=0D8ABC&color=fff';
    
    // Generate avatar with user initials
    final initials = name.split(' ').map((part) => part[0]).take(2).join('');
    return 'https://ui-avatars.com/api/?name=$initials&background=0D8ABC&color=fff&size=200';
  }

  /// Calculate profile completion percentage
  Future<double> getProfileCompletionPercentage(String userId) async {
    final profile = await getUserProfile(userId);
    if (profile == null) return 0.0;

    return profile.profileCompletionPercentage;
  }

  /// Get missing profile fields
  Future<List<String>> getMissingProfileFields(String userId) async {
    final profile = await getUserProfile(userId);
    if (profile == null) return ['All fields'];

    final List<String> missingFields = [];

    if (profile.name.isEmpty) missingFields.add('Name');
    if (profile.email.isEmpty) missingFields.add('Email');
    if (profile.phone.isEmpty) missingFields.add('Phone');
    if (profile.truckNumber.isEmpty) missingFields.add('Truck Number');
    if (profile.profilePhotoUrl == null || profile.profilePhotoUrl!.isEmpty) {
      missingFields.add('Profile Photo');
    }

    return missingFields;
  }

  /// Check if profile is complete
  Future<bool> isProfileComplete(String userId) async {
    final percentage = await getProfileCompletionPercentage(userId);
    return percentage >= 0.8; // 80% or more is considered complete
  }

  /// Update display name in Firebase Auth
  Future<bool> updateDisplayName(String displayName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await user.updateDisplayName(displayName);
      print('✅ Display name updated in Firebase Auth');
      return true;
    } catch (e) {
      print('❌ Error updating display name: $e');
      return false;
    }
  }

  /// Deactivate user account (soft delete)
  Future<bool> deactivateAccount(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': false,
        'deactivatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Account deactivated');
      return true;
    } catch (e) {
      print('❌ Error deactivating account: $e');
      return false;
    }
  }

  /// Reactivate user account
  Future<bool> reactivateAccount(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': true,
        'deactivatedAt': FieldValue.delete(),
        'reactivatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Account reactivated');
      return true;
    } catch (e) {
      print('❌ Error reactivating account: $e');
      return false;
    }
  }

  /// Get user statistics (for profile dashboard)
  Future<Map<String, dynamic>> getUserStatistics(String userId) async {
    try {
      // This would typically aggregate data from various collections
      // For now, return basic stats structure
      
      // Get total loads (if driver)
      final loadsSnapshot = await _firestore
          .collection('loads')
          .where('driverId', isEqualTo: userId)
          .count()
          .get();

      // Get completed loads
      final completedLoadsSnapshot = await _firestore
          .collection('loads')
          .where('driverId', isEqualTo: userId)
          .where('status', isEqualTo: 'delivered')
          .count()
          .get();

      return {
        'totalLoads': loadsSnapshot.count,
        'completedLoads': completedLoadsSnapshot.count,
        'profileCompletion': await getProfileCompletionPercentage(userId),
        'memberSince': (await getUserProfile(userId))?.createdAt,
      };
    } catch (e) {
      print('❌ Error fetching user statistics: $e');
      return {
        'totalLoads': 0,
        'completedLoads': 0,
        'profileCompletion': 0.0,
        'memberSince': DateTime.now(),
      };
    }
  }
}
