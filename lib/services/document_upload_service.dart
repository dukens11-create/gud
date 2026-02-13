import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

/// Document Upload Service
/// 
/// Handles photo uploads for BOL (Bill of Lading) and POD (Proof of Delivery) documents.
/// Provides functionality to:
/// - Capture photos using camera
/// - Select photos from gallery
/// - Upload photos to Firebase Storage
/// - Update Firestore with photo URLs
/// - Delete photos from storage
class DocumentUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  /// Take photo using camera
  /// 
  /// Returns [File] if photo captured, null if cancelled
  Future<File?> takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (photo == null) return null;
    return File(photo.path);
  }

  /// Pick photo from gallery
  /// 
  /// Returns [File] if photo selected, null if cancelled
  Future<File?> pickFromGallery() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (photo == null) return null;
    return File(photo.path);
  }

  /// Upload BOL photo
  /// 
  /// Parameters:
  /// - [loadId]: Associated load ID
  /// - [driverId]: Driver ID for tracking
  /// - [photo]: Image file to upload
  /// - [onProgress]: Optional callback for upload progress (0.0 to 1.0)
  /// 
  /// Returns the public download URL
  Future<String> uploadBOL({
    required String loadId,
    required String driverId,
    required File photo,
    Function(double)? onProgress,
  }) async {
    return await _uploadPhoto(
      photo: photo,
      storagePath: 'loads/$loadId/bol',
      fileName: 'bol_${DateTime.now().millisecondsSinceEpoch}.jpg',
      onProgress: onProgress,
    );
  }

  /// Upload POD photo
  /// 
  /// Parameters:
  /// - [loadId]: Associated load ID
  /// - [driverId]: Driver ID for tracking
  /// - [photo]: Image file to upload
  /// - [onProgress]: Optional callback for upload progress (0.0 to 1.0)
  /// 
  /// Returns the public download URL
  Future<String> uploadPOD({
    required String loadId,
    required String driverId,
    required File photo,
    Function(double)? onProgress,
  }) async {
    return await _uploadPhoto(
      photo: photo,
      storagePath: 'loads/$loadId/pod',
      fileName: 'pod_${DateTime.now().millisecondsSinceEpoch}.jpg',
      onProgress: onProgress,
    );
  }

  /// Generic photo upload
  /// 
  /// Internal method for uploading photos to Firebase Storage
  Future<String> _uploadPhoto({
    required File photo,
    required String storagePath,
    required String fileName,
    Function(double)? onProgress,
  }) async {
    final ref = _storage.ref().child(storagePath).child(fileName);
    
    final uploadTask = ref.putFile(photo);
    
    // Track upload progress
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      final progress = snapshot.bytesTransferred / snapshot.totalBytes;
      onProgress?.call(progress);
    });
    
    await uploadTask;
    final downloadUrl = await ref.getDownloadURL();
    return downloadUrl;
  }

  /// Update load with BOL photo URL
  /// 
  /// Parameters:
  /// - [loadId]: Load document ID
  /// - [photoUrl]: Download URL of uploaded photo
  Future<void> updateLoadBOL({
    required String loadId,
    required String photoUrl,
  }) async {
    await _firestore.collection('loads').doc(loadId).update({
      'bolPhotoUrl': photoUrl,
      'bolUploadedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update load with POD photo URL
  /// 
  /// Parameters:
  /// - [loadId]: Load document ID
  /// - [photoUrl]: Download URL of uploaded photo
  Future<void> updateLoadPOD({
    required String loadId,
    required String photoUrl,
  }) async {
    await _firestore.collection('loads').doc(loadId).update({
      'podPhotoUrl': photoUrl,
      'podUploadedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete photo from storage
  /// 
  /// Parameters:
  /// - [photoUrl]: Full download URL of photo to delete
  /// 
  /// Silently handles errors (e.g., file not found)
  Future<void> deletePhoto(String photoUrl) async {
    try {
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();
    } catch (e) {
      // Silently handle deletion errors
      // File may not exist or network error occurred
    }
  }
}
