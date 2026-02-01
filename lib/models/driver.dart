class Driver {
  final String id;
  final String name;
  final String phone;
  final String truckNumber;
  final String status;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.truckNumber,
    this.status = 'available',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'truckNumber': truckNumber,
      'status': status,
    };
  }

  factory Driver.fromMap(Map<String, dynamic> map, String id) {
    return Driver(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      truckNumber: map['truckNumber'] ?? '',
      status: map['status'] ?? 'available',
    );
  }
}
