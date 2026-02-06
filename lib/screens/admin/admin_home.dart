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
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            tooltip: 'Profile',
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
            tooltip: 'Sign Out',
          ),
        ],
      ),
      drawer: _buildDrawer(context),
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
            return const Center(
              child: Text('No loads yet. Create your first load!'),
            );
          }

          return ListView.builder(
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
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'map',
            onPressed: () => Navigator.pushNamed(context, '/admin/map'),
            child: const Icon(Icons.map),
            tooltip: 'Map Dashboard',
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'statistics',
            onPressed: () => Navigator.pushNamed(context, '/admin/statistics'),
            child: const Icon(Icons.bar_chart),
            tooltip: 'Statistics',
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'expenses',
            onPressed: () => Navigator.pushNamed(context, '/admin/expenses'),
            child: const Icon(Icons.receipt_long),
            tooltip: 'Expenses',
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'drivers',
            onPressed: () => Navigator.pushNamed(context, '/admin/drivers'),
            child: const Icon(Icons.people),
            tooltip: 'Drivers',
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'create-load',
            onPressed: () => Navigator.pushNamed(context, '/admin/create-load'),
            child: const Icon(Icons.add),
            tooltip: 'Create Load',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'GUD Express',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping),
            title: const Text('All Loads'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Load History'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/load-history');
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Invoices'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/invoices');
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export Data'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/export');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Manage Drivers'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/drivers');
            },
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Map Dashboard'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/map');
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Statistics'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/statistics');
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Expenses'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/expenses');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
    );
  }
}
