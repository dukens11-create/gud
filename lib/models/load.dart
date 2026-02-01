class LoadModel {
  final String id;
  final String loadNumber;
  final String driverId;
  final String driverName;
  final String pickupAddress;
  final String deliveryAddress;
  final double rate;
  final String status; // 'assigned', 'picked_up', 'in_transit', 'delivered'
  final DateTime? tripStartTime;
  final DateTime? tripEndTime;
  final DateTime createdAt;

  LoadModel({
    required this.id,
    required this.loadNumber,
    required this.driverId,
    required this.driverName,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.rate,
    required this.status,
    this.tripStartTime,
    this.tripEndTime,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'loadNumber': loadNumber,
      'driverId': driverId,
      'driverName': driverName,
      'pickupAddress': pickupAddress,
      'deliveryAddress': deliveryAddress,
      'rate': rate,
      'status': status,
      'tripStartTime': tripStartTime?.toIso8601String(),
      'tripEndTime': tripEndTime?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LoadModel.fromMap(Map<String, dynamic> data, String id) {
    return LoadModel(
      id: id,
      loadNumber: data['loadNumber'] ?? '',
      driverId: data['driverId'] ?? '',
      driverName: data['driverName'] ?? '',
      pickupAddress: data['pickupAddress'] ?? '',
      deliveryAddress: data['deliveryAddress'] ?? '',
      rate: (data['rate'] ?? 0).toDouble(),
      status: data['status'] ?? 'assigned',
      tripStartTime: data['tripStartTime'] != null 
          ? DateTime.parse(data['tripStartTime']) 
          : null,
      tripEndTime: data['tripEndTime'] != null 
          ? DateTime.parse(data['tripEndTime']) 
          : null,
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt']) 
          : DateTime.now(),
    );
  }

  LoadModel copyWith({
    String? id,
    String? loadNumber,
    String? driverId,
    String? driverName,
    String? pickupAddress,
    String? deliveryAddress,
    double? rate,
    String? status,
    DateTime? tripStartTime,
    DateTime? tripEndTime,
    DateTime? createdAt,
  }) {
    return LoadModel(
      id: id ?? this.id,
      loadNumber: loadNumber ?? this.loadNumber,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      rate: rate ?? this.rate,
      status: status ?? this.status,
      tripStartTime: tripStartTime ?? this.tripStartTime,
      tripEndTime: tripEndTime ?? this.tripEndTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
