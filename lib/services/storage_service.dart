import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  Future<String> uploadPodImage({
    required String loadId,
    required File file,
  }) async {
    final ref = _storage.ref().child('pods/[38;5;11m$loadId[39m/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}