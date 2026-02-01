class SimpleLoad {
  final String id;
  final String loadNumber;
  final String pickupAddress;
  final String deliveryAddress;
  final double rate;
  final String status;
  final String driverId;
  final DateTime createdAt;
  
  SimpleLoad({
    required this.id,
    required this.loadNumber,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.rate,
    required this.status,
    required this.driverId,
    required this.createdAt,
  });
}
