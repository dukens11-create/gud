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
    'uploadedAt': uploadedAt.toIso8601String(),
    'notes': notes,
    'uploadedBy': uploadedBy,
  };

  static POD fromDoc(DocumentSnapshot doc) {
    return fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  static POD fromMap(String id, Map<String, dynamic> d) {
    return POD(
      id: id,
      loadId: (d['loadId'] ?? '') as String,
      imageUrl: (d['imageUrl'] ?? '') as String,
      uploadedAt: DateTime.parse(d['uploadedAt'] as String),
      notes: (d['notes'] ?? '') as String,
      uploadedBy: (d['uploadedBy'] ?? '') as String,
    );
  }
}
