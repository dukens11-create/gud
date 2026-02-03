import 'package:flutter/material.dart';
import '../../services/mock_data_service.dart';
import '../../models/load.dart';
import 'load_detail_screen.dart';
import '../login_screen.dart';

class DriverHome extends StatelessWidget {
  final String driverId;
  
  const DriverHome({super.key, required this.driverId});

  @override
  Widget build(BuildContext context) {
    final mockService = MockDataService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Loads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () => Navigator.pushNamed(context, '/driver/expenses'),
          ),
          IconButton(
            icon: const Icon(Icons.attach_money),
            onPressed: () => Navigator.pushNamed(context, '/driver/earnings'),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await mockService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<LoadModel>>(
        stream: mockService.streamDriverLoads(driverId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final loads = snapshot.data ?? [];

          if (loads.isEmpty) {
            return const Center(
              child: Text('No loads assigned yet.'),
            );
          }

          return ListView.builder(
            itemCount: loads.length,
            itemBuilder: (context, index) {
              final load = loads[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoadDetailScreen(load: load),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    child: Text(load.status.isNotEmpty ? load.status[0].toUpperCase() : 'L'),
                  ),
                  title: Text(load.loadNumber),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('From: ${load.pickupAddress}'),
                      Text('To: ${load.deliveryAddress}'),
                      Text('Rate: \$${load.rate.toStringAsFixed(2)}'),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(load.status),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
