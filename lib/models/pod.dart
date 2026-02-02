import 'package:cloud_firestore/cloud_firestore.dart';

class POD {
  final String id;
  final String loadId;
  final String imageUrl;
  final DateTime uploadedAt;
  final String notes;
  final String uploadedBy;

  POD({
    required this.id,
    required this.loadId,
    required this.imageUrl,
    required this.uploadedAt,
    required this.notes,
    required this.uploadedBy,
  });

  Map<String, dynamic> toMap() => {
    'loadId': loadId,
    'imageUrl': imageUrl,
    'uploadedAt': Timestamp.fromDate(uploadedAt),
    'notes': notes,
    'uploadedBy': uploadedBy,
  };

  static POD fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return POD(
      id: doc.id,
      loadId: (d['loadId'] ?? '') as String,
      imageUrl: (d['imageUrl'] ?? '') as String,
      uploadedAt: (d['uploadedAt'] as Timestamp).toDate(),
      notes: (d['notes'] ?? '') as String,
      uploadedBy: (d['uploadedBy'] ?? '') as String,
    );
  }
}
