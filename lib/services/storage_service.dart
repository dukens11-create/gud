import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;
  final _imagePicker = ImagePicker();

  /// Pick an image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Pick an image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Upload POD image with progress tracking
  Future<String> uploadPodImage({
    required String loadId,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final Reference ref = _storage.ref().child('pods/$loadId/$fileName');
    
    final UploadTask uploadTask = ref.putFile(file);

    // Track upload progress
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    // Wait for upload to complete
    await uploadTask;
    
    // Get and return download URL
    return await ref.getDownloadURL();
  }

  /// Delete an image from storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Silently handle deletion errors (image might not exist)
      // In production, consider logging this error
    }
  }

  /// Upload profile image
  Future<String> uploadProfileImage({
    required String userId,
    required File file,
    void Function(double progress)? onProgress,
  }) async {
    final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final Reference ref = _storage.ref().child('profiles/$userId/$fileName');
    
    final UploadTask uploadTask = ref.putFile(file);

    // Track upload progress
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    await uploadTask;
    return await ref.getDownloadURL();
  }
}
