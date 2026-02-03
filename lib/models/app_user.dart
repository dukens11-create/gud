class AppUser {
  final String uid;
  final String role; // 'admin' or 'driver'
  final String name;
  final String email;
  final String phone;
  final String truckNumber;
  final bool isActive;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.role,
    required this.name,
    required this.email,
    required this.phone,
    required this.truckNumber,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'role': role,
    'name': name,
    'email': email,
    'phone': phone,
    'truckNumber': truckNumber,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
  };

  static AppUser fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      role: (data['role'] ?? 'driver') as String,
      name: (data['name'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      phone: (data['phone'] ?? '') as String,
      truckNumber: (data['truckNumber'] ?? '') as String,
      isActive: (data['isActive'] ?? true) as bool,
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt'] as String)
          : null,
    );
  }
}
