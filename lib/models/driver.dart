class Driver {
  final String id;
  final String name;
  final String phone;
  final String truckNumber;
  final String status; // active/inactive

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.truckNumber,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'truckNumber': truckNumber,
    'status': status,
  };

  static Driver fromMap(String id, Map<String, dynamic> data) => Driver(
    id: id,
    name: (data['name'] ?? '') as String,
    phone: (data['phone'] ?? '') as String,
    truckNumber: (data['truckNumber'] ?? '') as String,
    status: (data['status'] ?? 'active') as String,
  );
}