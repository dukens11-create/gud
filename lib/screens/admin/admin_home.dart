import 'package:flutter/material.dart';
import '../../services/mock_data_service.dart';
import '../../models/load.dart';
import '../login_screen.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    final mockService = MockDataService();

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: const Text('Admin Dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Sign out',
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
        stream: mockService.streamAllLoads(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final loads = snapshot.data ?? [];

          if (loads.isEmpty) {
            return Center(
              child: Semantics(
                label: 'No loads available. Create your first load using the add button.',
                child: const Text('No loads yet. Create your first load!'),
              ),
            );
          }

          return Semantics(
            label: 'List of ${loads.length} loads',
            child: ListView.builder(
              itemCount: loads.length,
              itemBuilder: (context, index) {
                final load = loads[index];
                return Semantics(
                  label: 'Load ${load.loadNumber}, driver ${load.driverId}, status ${load.status}, rate ${load.rate} dollars',
                  button: true,
                  child: Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(load.loadNumber),
                      subtitle: Text('Driver ID: ${load.driverId} - Status: ${load.status}'),
                      trailing: Text('\$${load.rate.toStringAsFixed(2)}'),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'statistics',
            onPressed: () => Navigator.pushNamed(context, '/admin/statistics'),
            tooltip: 'View statistics',
            child: const Icon(Icons.bar_chart),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'expenses',
            onPressed: () => Navigator.pushNamed(context, '/admin/expenses'),
            tooltip: 'View expenses',
            child: const Icon(Icons.receipt_long),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'drivers',
            onPressed: () => Navigator.pushNamed(context, '/admin/drivers'),
            tooltip: 'Manage drivers',
            child: const Icon(Icons.people),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'create-load',
            onPressed: () => Navigator.pushNamed(context, '/admin/create-load'),
            tooltip: 'Create new load',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
