import '../models/driver.dart';
import '../models/load.dart';

/// Mock data service for offline mode (no Firebase)
/// Provides sample data for testing the app functionality
class MockDataService {
  static final MockDataService _instance = MockDataService._internal();
  factory MockDataService() => _instance;
  MockDataService._internal();

  // Sample user state
  String? _currentUserId;
  String? _currentUserRole;
  String? _currentUserName;

  // Mock data
  final List<LoadModel> _mockLoads = [
    LoadModel(
      id: 'load-001',
      loadNumber: 'LOAD-001',
      driverId: 'driver-uid-001',
      driverName: 'John Driver',
      pickupAddress: '123 Pickup St, Los Angeles, CA 90001',
      deliveryAddress: '456 Delivery Ave, San Francisco, CA 94102',
      rate: 2500.00,
      miles: 380,
      status: 'assigned',
      notes: 'Fragile cargo - handle with care',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      createdBy: 'admin-uid-001',
    ),
    LoadModel(
      id: 'load-002',
      loadNumber: 'LOAD-002',
      driverId: 'driver-uid-001',
      driverName: 'John Driver',
      pickupAddress: '789 Start Blvd, San Diego, CA 92101',
      deliveryAddress: '321 End Road, Portland, OR 97201',
      rate: 3200.00,
      miles: 950,
      status: 'in_transit',
      notes: 'Time sensitive delivery',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      createdBy: 'admin-uid-001',
      pickedUpAt: DateTime.now().subtract(const Duration(hours: 12)),
      tripStartAt: DateTime.now().subtract(const Duration(hours: 11)),
    ),
    LoadModel(
      id: 'load-003',
      loadNumber: 'LOAD-003',
      driverId: 'driver-uid-001',
      driverName: 'John Driver',
      pickupAddress: '555 Origin Way, Seattle, WA 98101',
      deliveryAddress: '777 Destination Dr, Phoenix, AZ 85001',
      rate: 2800.00,
      miles: 1420,
      status: 'delivered',
      notes: 'Standard delivery',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      createdBy: 'admin-uid-001',
      pickedUpAt: DateTime.now().subtract(const Duration(days: 3)),
      tripStartAt: DateTime.now().subtract(const Duration(days: 3)),
      deliveredAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  final List<Driver> _mockDrivers = [
    Driver(
      id: 'driver-uid-001',
      name: 'John Driver',
      phone: '555-0123',
      truckNumber: 'TRK-001',
      status: 'available',
      totalEarnings: 8500.00,
      completedLoads: 5,
      isActive: true,
    ),
  ];

  // Authentication methods
  Future<Map<String, String>?> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    
    // Mock data service is for offline development only
    // No hardcoded credentials for production use
    throw Exception('Authentication requires Firebase connection');
  }

  Future<void> signOut() async {
    _currentUserId = null;
    _currentUserRole = null;
    _currentUserName = null;
  }

  String? get currentUserId => _currentUserId;
  String? get currentUserRole => _currentUserRole;
  String? get currentUserName => _currentUserName;
  bool get isAuthenticated => _currentUserId != null;

  // User role
  Future<String> getUserRole(String userId) async {
    if (userId == 'admin-uid-001') return 'admin';
    return 'driver';
  }

  // Drivers
  Future<List<Driver>> getDrivers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_mockDrivers);
  }

  Stream<List<Driver>> streamDrivers() {
    return Stream.value(_mockDrivers);
  }

  Future<Driver?> getDriver(String driverId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockDrivers.firstWhere(
      (d) => d.id == driverId,
      orElse: () => _mockDrivers.first,
    );
  }

  /// Add a new driver
  Future<void> addDriver({
    required String name,
    required String phone,
    required String truckNumber,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newDriver = Driver(
      id: 'driver-uid-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      truckNumber: truckNumber,
      status: 'available',
      totalEarnings: 0.0,
      completedLoads: 0,
      isActive: true,
    );
    _mockDrivers.add(newDriver);
  }

  /// Update an existing driver
  Future<void> updateDriver({
    required String driverId,
    String? name,
    String? phone,
    String? truckNumber,
    String? status,
    bool? isActive,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockDrivers.indexWhere((d) => d.id == driverId);
    if (index != -1) {
      final driver = _mockDrivers[index];
      _mockDrivers[index] = Driver(
        id: driver.id,
        name: name ?? driver.name,
        phone: phone ?? driver.phone,
        truckNumber: truckNumber ?? driver.truckNumber,
        status: status ?? driver.status,
        totalEarnings: driver.totalEarnings,
        completedLoads: driver.completedLoads,
        isActive: isActive ?? driver.isActive,
      );
    }
  }

  /// Delete a driver
  Future<void> deleteDriver(String driverId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockDrivers.removeWhere((d) => d.id == driverId);
  }

  // Loads
  Future<List<LoadModel>> getAllLoads() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_mockLoads);
  }

  Stream<List<LoadModel>> streamAllLoads() {
    return Stream.value(_mockLoads);
  }

  Future<List<LoadModel>> getDriverLoads(String driverId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockLoads.where((load) => load.driverId == driverId).toList();
  }

  Stream<List<LoadModel>> streamDriverLoads(String driverId) {
    return Stream.value(
      _mockLoads.where((load) => load.driverId == driverId).toList(),
    );
  }

  Future<LoadModel?> getLoad(String loadId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockLoads.firstWhere((load) => load.id == loadId);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateLoadStatus({
    required String loadId,
    required String status,
    DateTime? pickedUpAt,
    DateTime? tripStartAt,
    DateTime? deliveredAt,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockLoads.indexWhere((load) => load.id == loadId);
    if (index != -1) {
      final load = _mockLoads[index];
      _mockLoads[index] = LoadModel(
        id: load.id,
        loadNumber: load.loadNumber,
        driverId: load.driverId,
        driverName: load.driverName,
        pickupAddress: load.pickupAddress,
        deliveryAddress: load.deliveryAddress,
        rate: load.rate,
        miles: load.miles,
        status: status,
        notes: load.notes,
        createdAt: load.createdAt,
        createdBy: load.createdBy,
        pickedUpAt: pickedUpAt ?? load.pickedUpAt,
        tripStartAt: tripStartAt ?? load.tripStartAt,
        deliveredAt: deliveredAt ?? load.deliveredAt,
      );
    }
  }

  // Earnings
  Future<double> getDriverEarnings(String driverId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockLoads
        .where((load) => load.driverId == driverId && load.status == 'delivered')
        .fold<double>(0.0, (sum, load) => sum + load.rate);
  }

  Stream<double> streamDriverEarnings(String driverId) {
    final earnings = _mockLoads
        .where((load) => load.driverId == driverId && load.status == 'delivered')
        .fold<double>(0.0, (sum, load) => sum + load.rate);
    return Stream.value(earnings);
  }

  // Dashboard stats
  Stream<Map<String, dynamic>> streamDashboardStats() {
    return Stream.value({
      'totalLoads': _mockLoads.length,
      'assignedLoads': _mockLoads.where((l) => l.status == 'assigned').length,
      'inTransitLoads': _mockLoads.where((l) => l.status == 'in_transit').length,
      'deliveredLoads': _mockLoads.where((l) => l.status == 'delivered').length,
      'totalRevenue': _mockLoads.fold<double>(0.0, (sum, load) => sum + load.rate),
    });
  }

  Future<int> getDriverCompletedLoads(String driverId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockLoads
        .where((load) => load.driverId == driverId && 
               (load.status == 'delivered' || load.status == 'completed'))
        .length;
  }
}
