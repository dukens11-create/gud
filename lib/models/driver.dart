class Driver {
  final String id;
  final String name;
  final String phone;
  final String truckNumber;
  final String status; // 'available', 'on_trip', 'inactive'
  final double totalEarnings;
  final int completedLoads;
  final bool isActive;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.truckNumber,
    required this.status,
    this.totalEarnings = 0.0,
    this.completedLoads = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'truckNumber': truckNumber,
    'status': status,
    'totalEarnings': totalEarnings,
    'completedLoads': completedLoads,
    'isActive': isActive,
  };

  static Driver fromMap(String id, Map<String, dynamic> data) {
    final totalEarningsValue = data['totalEarnings'] ?? 0.0;
    return Driver(
      id: id,
      name: (data['name'] ?? '') as String,
      phone: (data['phone'] ?? '') as String,
      truckNumber: (data['truckNumber'] ?? '') as String,
      status: (data['status'] ?? 'available') as String,
      totalEarnings: totalEarningsValue is int 
          ? (totalEarningsValue as int).toDouble()
          : totalEarningsValue as double,
      completedLoads: (data['completedLoads'] ?? 0) as int,
      isActive: (data['isActive'] ?? true) as bool,
    );
  }
}
