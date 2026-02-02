class AppUser {
  final String uid;
  final String role; // 'admin' or 'driver'
  final String name;
  final String phone;
  final String truckNumber;

  AppUser({
    required this.uid,
    required this.role,
    required this.name,
    required this.phone,
    required this.truckNumber,
  });

  Map<String, dynamic> toMap() => {
    'role': role,
    'name': name,
    'phone': phone,
    'truckNumber': truckNumber,
  };

  static AppUser fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      role: (data['role'] ?? 'driver') as String,
      name: (data['name'] ?? '') as String,
      phone: (data['phone'] ?? '') as String,
      truckNumber: (data['truckNumber'] ?? '') as String,
    );
  }
}
