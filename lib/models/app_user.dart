class AppUser {
  final String uid;
  final String role; // 'admin' or 'driver'
  final String name;
  final String email;
  final String phone;
  final String truckNumber;
  final bool isActive;
  final DateTime createdAt;
  final String? profilePhotoUrl;
  final DateTime? lastUpdated;

  AppUser({
    required this.uid,
    required this.role,
    required this.name,
    required this.email,
    required this.phone,
    required this.truckNumber,
    this.isActive = true,
    DateTime? createdAt,
    this.profilePhotoUrl,
    this.lastUpdated,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'role': role,
    'name': name,
    'email': email,
    'phone': phone,
    'truckNumber': truckNumber,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'profilePhotoUrl': profilePhotoUrl,
    'lastUpdated': lastUpdated?.toIso8601String(),
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
      profilePhotoUrl: data['profilePhotoUrl'] as String?,
      lastUpdated: data['lastUpdated'] != null
          ? DateTime.parse(data['lastUpdated'] as String)
          : null,
    );
  }

  /// Create a copy with updated fields
  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? truckNumber,
    bool? isActive,
    String? profilePhotoUrl,
    DateTime? lastUpdated,
  }) {
    return AppUser(
      uid: uid,
      role: role,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      truckNumber: truckNumber ?? this.truckNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Get profile completion percentage
  double get profileCompletionPercentage {
    int completedFields = 0;
    int totalFields = 6;

    if (name.isNotEmpty) completedFields++;
    if (email.isNotEmpty) completedFields++;
    if (phone.isNotEmpty) completedFields++;
    if (truckNumber.isNotEmpty) completedFields++;
    if (profilePhotoUrl != null && profilePhotoUrl!.isNotEmpty) completedFields++;
    // Role is always filled, so count it
    completedFields++;

    return completedFields / totalFields;
  }
}
