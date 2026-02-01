import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload POD image
  Future<String> uploadPODImage(File imageFile, String loadId) async {
    try {
      final fileName = 'pod_${loadId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('pods').child(fileName);
      
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }
}
