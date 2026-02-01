class POD {
  final String id;
  final String imageUrl;
  final DateTime uploadedAt;
  final String? notes;

  POD({
    required this.id,
    required this.imageUrl,
    required this.uploadedAt,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'uploadedAt': uploadedAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory POD.fromMap(Map<String, dynamic> map, String id) {
    return POD(
      id: id,
      imageUrl: map['imageUrl'] ?? '',
      uploadedAt: DateTime.parse(map['uploadedAt']),
      notes: map['notes'],
    );
  }
}
