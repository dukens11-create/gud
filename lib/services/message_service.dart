import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message.dart';

/// Service for load-scoped chat messages.
///
/// Messages live at: `loads/{loadId}/messages/{messageId}`
///
/// Security is enforced by Firestore rules: only the admin and the load's
/// assigned driver can read or write messages for a given load.
class MessageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _messagesRef(String loadId) =>
      _db.collection('loads').doc(loadId).collection('messages');

  /// Stream all messages for a load, ordered oldest-first.
  Stream<List<MessageModel>> streamMessages(String loadId) {
    return _messagesRef(loadId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(MessageModel.fromDoc).toList());
  }

  /// Send a new message on the given load.
  ///
  /// [senderRole] must be either `'admin'` or `'driver'`.
  Future<void> sendMessage({
    required String loadId,
    required String text,
    required String senderRole,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message: 'User must be signed in to send messages',
      );
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    await _messagesRef(loadId).add({
      'senderId': user.uid,
      'senderRole': senderRole,
      'text': trimmed,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}
