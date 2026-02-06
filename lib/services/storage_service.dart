import 'dart:io' show File;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  /// Pick image from camera or gallery
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
      print('❌ Error picking image: $e');
      return null;
    }
  }

  /// Compress image file
  Future<File?> compressImage(File file, {int quality = 85}) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: 1920,
        minHeight: 1080,
      );

      if (result == null) return file; // Return original if compression fails
      return File(result.path);
    } catch (e) {
      print('❌ Error compressing image: $e');
      return file; // Return original file if compression fails
    }
  }

  /// Upload profile photo
  Future<String?> uploadProfilePhoto({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // Compress image before upload
      final compressedFile = await compressImage(imageFile, quality: 90);
      if (compressedFile == null) {
        print('❌ Failed to compress profile photo');
        return null;
      }

      // Create reference with user ID and timestamp
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('profiles/$userId/$fileName');

      // Upload file
      await ref.putFile(compressedFile);

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      print('✅ Profile photo uploaded: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading profile photo: $e');
      return null;
    }
  }

  /// Upload POD image
  Future<String> uploadPodImage({
    required String loadId,
    required File file,
  }) async {
    final ref = _storage.ref().child('pods/$loadId/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  /// Delete POD image
  Future<void> deletePOD(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('✅ POD deleted from storage');
    } catch (e) {
      print('❌ Error deleting POD: $e');
    }
  }

  /// Delete file from storage by URL
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      print('✅ File deleted from storage');
    } catch (e) {
      print('❌ Error deleting file: $e');
    }
  }

  /// Upload document (for future use)
  Future<String?> uploadDocument({
    required String userId,
    required File file,
    required String documentType,
  }) async {
    try {
      final fileName = '${documentType}_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
      final ref = _storage.ref().child('documents/$userId/$fileName');

      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      
      print('✅ Document uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading document: $e');
      return null;
    }
  }

  /// Get file metadata
  Future<FullMetadata?> getFileMetadata(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      return await ref.getMetadata();
    } catch (e) {
      print('❌ Error getting file metadata: $e');
      return null;
    }
  }

  /// Get file size in MB
  Future<double?> getFileSizeMB(String fileUrl) async {
    try {
      final metadata = await getFileMetadata(fileUrl);
      if (metadata == null) return null;
      return (metadata.size ?? 0) / (1024 * 1024);
    } catch (e) {
      print('❌ Error getting file size: $e');
      return null;
    }
  }
}

