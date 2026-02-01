import 'package:flutter/material.dart';
import '../../services/mock_data_service.dart';
import '../../models/simple_load.dart';

class DriverHome extends StatelessWidget {
  const DriverHome({super.key});

  @override
  Widget build(BuildContext context) {
    final loads = MockDataService.getDemoLoads();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Loads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: loads.length,
        itemBuilder: (context, index) {
          final load = loads[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(load.status[0].toUpperCase()),
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
      ),
    );
  }
}
