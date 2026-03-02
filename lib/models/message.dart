import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/datetime_utils.dart';

/// Represents a chat message on a specific load/order.
///
/// Messages are stored as a subcollection under each load document:
/// `loads/{loadId}/messages/{messageId}`
///
/// Only the admin and the load's assigned driver can read or write messages
/// for a given load (enforced via Firestore security rules).
class MessageModel {
  final String id;
  final String senderId;
  final String senderRole; // 'admin' or 'driver'
  final String text;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'senderRole': senderRole,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  static MessageModel fromDoc(DocumentSnapshot doc) {
    final data = doc.data();
    if (data == null) {
      throw FormatException('Message document ${doc.id} has no data');
    }
    return fromMap(doc.id, data as Map<String, dynamic>);
  }

  static MessageModel fromMap(String id, Map<String, dynamic> d) {
    return MessageModel(
      id: id,
      senderId: (d['senderId'] ?? '') as String,
      senderRole: (d['senderRole'] ?? 'driver') as String,
      text: (d['text'] ?? '') as String,
      createdAt: DateTimeUtils.parseDateTime(d['createdAt']),
    );
  }
}
