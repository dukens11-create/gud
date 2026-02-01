import 'package:flutter/material.dart';
import '../../services/mock_data_service.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    final loads = MockDataService.getDemoLoads();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
              title: Text(load.loadNumber),
              subtitle: Text('Driver ID: ${load.driverId} - Status: ${load.status}'),
              trailing: Text('\$${load.rate.toStringAsFixed(2)}'),
            ),
          );
        },
      ),
    );
  }
}
