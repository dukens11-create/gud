import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/load.dart';
import '../../models/driver.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/loading.dart';
import 'driver_load_detail.dart';

class DriverHome extends StatelessWidget {
  const DriverHome({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Loads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () {
              Navigator.pushNamed(context, '/driver/earnings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
      body: FutureBuilder<Driver?>(
        future: firestoreService.getDriverByUserId(userId),
        builder: (context, driverSnapshot) {
          if (driverSnapshot.connectionState == ConnectionState.waiting) {
            return const LoadingScreen();
          }

          if (!driverSnapshot.hasData || driverSnapshot.data == null) {
            return const Center(
              child: Text('No driver profile found'),
            );
          }

          final driver = driverSnapshot.data!;

          return StreamBuilder<List<LoadModel>>(
            stream: firestoreService.streamDriverLoads(driver.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingScreen();
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final loads = snapshot.data ?? [];

              if (loads.isEmpty) {
                return const Center(
                  child: Text('No loads assigned'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: loads.length,
                itemBuilder: (context, index) {
                  final load = loads[index];
                  return _LoadCard(
                    load: load,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DriverLoadDetail(load: load),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _LoadCard extends StatelessWidget {
  final LoadModel load;
  final VoidCallback onTap;

  const _LoadCard({
    required this.load,
    required this.onTap,
  });

  Color _getStatusColor() {
    switch (load.status) {
      case 'assigned':
        return Colors.blue;
      case 'picked_up':
        return Colors.orange;
      case 'in_transit':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Load #${load.loadNumber}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      load.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Pickup: ${load.pickupAddress}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.flag, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Delivery: ${load.deliveryAddress}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Rate:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${load.rate.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
