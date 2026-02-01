import '../models/simple_load.dart';

class MockDataService {
  static List<SimpleLoad> getDemoLoads() {
    return [
      SimpleLoad(
        id: '1',
        loadNumber: 'LOAD-001',
        pickupAddress: '123 Main St, Los Angeles, CA',
        deliveryAddress: '456 Oak Ave, San Francisco, CA',
        rate: 1500.00,
        status: 'assigned',
        driverId: 'driver1',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      SimpleLoad(
        id: '2',
        loadNumber: 'LOAD-002',
        pickupAddress: '789 Pine Rd, San Diego, CA',
        deliveryAddress: '321 Elm St, Sacramento, CA',
        rate: 1200.00,
        status: 'in_transit',
        driverId: 'driver1',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      SimpleLoad(
        id: '3',
        loadNumber: 'LOAD-003',
        pickupAddress: '555 Market St, Oakland, CA',
        deliveryAddress: '888 Bay St, San Jose, CA',
        rate: 950.00,
        status: 'delivered',
        driverId: 'driver1',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }
}
