import 'dart:io' show File;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js_util' if (dart.library.io) 'js_util_stub.dart' show jsify;

class StorageService {
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

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

  Future<String> uploadPodImage({
    required String loadId,
    required File file,
  }) async {
    final ref = _storage.ref().child('pods/$loadId/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<void> deletePOD(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Handle error silently
    }
  }
}
