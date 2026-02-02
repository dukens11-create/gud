import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/load.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final firestoreService = FirestoreService();
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<LoadModel>>(
        stream: firestoreService.streamAllLoads(),
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
            heroTag: 'drivers',
            onPressed: () => Navigator.pushNamed(context, '/admin/drivers'),
            child: const Icon(Icons.people),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'create-load',
            onPressed: () => Navigator.pushNamed(context, '/admin/create-load'),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
