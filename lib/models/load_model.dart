class LoadModel {
  final String id;
  final String loadNumber;
  final String driverId;
  final String pickupAddress;
  final String deliveryAddress;
  final double rate;
  final String status;
  final DateTime? tripStartTime;
  final DateTime? tripEndTime;
  final double? miles;

  LoadModel({
    required this.id,
    required this.loadNumber,
    required this.driverId,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.rate,
    this.status = 'assigned',
    this.tripStartTime,
    this.tripEndTime,
    this.miles,
  });

  Map<String, dynamic> toMap() {
    return {
      'loadNumber': loadNumber,
      'driverId': driverId,
      'pickupAddress': pickupAddress,
      'deliveryAddress': deliveryAddress,
      'rate': rate,
      'status': status,
      'tripStartTime': tripStartTime?.toIso8601String(),
      'tripEndTime': tripEndTime?.toIso8601String(),
      'miles': miles,
    };
  }

  factory LoadModel.fromMap(Map<String, dynamic> map, String id) {
    return LoadModel(
      id: id,
      loadNumber: map['loadNumber'] ?? '',
      driverId: map['driverId'] ?? '',
      pickupAddress: map['pickupAddress'] ?? '',
      deliveryAddress: map['deliveryAddress'] ?? '',
      rate: (map['rate'] ?? 0).toDouble(),
      status: map['status'] ?? 'assigned',
      tripStartTime: map['tripStartTime'] != null 
          ? DateTime.parse(map['tripStartTime']) 
          : null,
      tripEndTime: map['tripEndTime'] != null 
          ? DateTime.parse(map['tripEndTime']) 
          : null,
      miles: map['miles']?.toDouble(),
    );
  }
}
