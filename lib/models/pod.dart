import 'package:cloud_firestore/cloud_firestore.dart';

class POD {
  final String id;
  final String imageUrl;
  final DateTime uploadedAt;
  final String notes;

  POD({
    required this.id,
    required this.imageUrl,
    required this.uploadedAt,
    required this.notes,
  });

  Map<String, dynamic> toMap() => {
    'imageUrl': imageUrl,
    'uploadedAt': Timestamp.fromDate(uploadedAt),
    'notes': notes,
  };

  static POD fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return POD(
      id: doc.id,
      imageUrl: (d['imageUrl'] ?? '') as String,
      uploadedAt: (d['uploadedAt'] as Timestamp).toDate(),
      notes: (d['notes'] ?? '') as String,
    );
  }
}