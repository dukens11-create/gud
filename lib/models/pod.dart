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
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  factory POD.fromMap(Map<String, dynamic> data, String id) {
    return POD(
      id: id,
      loadId: data['loadId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      notes: data['notes'] ?? '',
      uploadedAt: data['uploadedAt'] != null 
          ? DateTime.parse(data['uploadedAt']) 
          : DateTime.now(),
    );
  }
}
