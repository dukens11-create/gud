import 'dart:io' show File;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Cloud storage service for managing file uploads and downloads.
/// 
/// Handles:
/// - Image selection from camera or gallery
/// - POD image uploads to Firebase Storage
/// - Image optimization (resize and compression)
/// - File deletion
class StorageService {
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  /// Pick an image from camera or gallery
  /// 
  /// Automatically optimizes the image:
  /// - Max dimensions: 1920x1080
  /// - Quality: 85%
  /// 
  /// Parameters:
  /// - [source]: ImageSource.camera or ImageSource.gallery
  /// 
  /// Returns [File] if image selected, null if cancelled
  Future<File?> pickImage({required ImageSource source}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      return null;
    }
  }

  /// Upload POD image to Firebase Storage
  /// 
  /// Stores images in 'pods/{loadId}/' directory with timestamp filename
  /// 
  /// Parameters:
  /// - [loadId]: Associated load ID for organizing storage
  /// - [file]: Image file to upload
  /// 
  /// Returns the public download URL of the uploaded image
  Future<String> uploadPodImage({
    required String loadId,
    required File file,
  }) async {
    final ref = _storage.ref().child('pods/$loadId/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  /// Delete a POD image from Firebase Storage
  /// 
  /// Parameters:
  /// - [imageUrl]: Full download URL of the image to delete
  /// 
  /// Silently handles errors (e.g., file not found)
  Future<void> deletePOD(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Handle error silently
    }
  }

  /// Upload profile photo to Firebase Storage
  /// 
  /// Stores images in 'profile_photos/{userId}.jpg'
  /// 
  /// Parameters:
  /// - [userId]: User ID for organizing storage
  /// - [imageFile]: Image file to upload
  /// 
  /// Returns the public download URL of the uploaded image
  Future<String> uploadProfilePhoto({
    required String userId,
    required File imageFile,
  }) async {
    final ref = _storage.ref().child('profile_photos/$userId.jpg');
    await ref.putFile(imageFile);
    return ref.getDownloadURL();
  }
}
