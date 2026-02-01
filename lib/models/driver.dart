class Driver {
  final String id;
  final String name;
  final String phone;
  final String truckNumber;
  final String status; // 'active' or 'inactive'
  final String userId;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.truckNumber,
    required this.status,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'truckNumber': truckNumber,
      'status': status,
      'userId': userId,
    };
  }

  factory Driver.fromMap(Map<String, dynamic> map, String docId) {
    return Driver(
      id: docId,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      truckNumber: map['truckNumber'] ?? '',
      status: map['status'] ?? 'active',
      userId: map['userId'] ?? '',
    );
  }
}
