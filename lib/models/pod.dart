import 'package:cloud_firestore/cloud_firestore.dart';

class POD {
  final String id;
  final String loadId;
  final String imageUrl;
  final String notes;
  final DateTime uploadedAt;

  POD({
    required this.id,
    required this.loadId,
    required this.imageUrl,
    required this.notes,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'loadId': loadId,
      'imageUrl': imageUrl,
      'notes': notes,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }

  factory POD.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return POD(
      id: doc.id,
      loadId: data['loadId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      notes: data['notes'] ?? '',
      uploadedAt: data['uploadedAt'] != null ? (data['uploadedAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }
}
