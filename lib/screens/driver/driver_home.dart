import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/load.dart';

class DriverHome extends StatelessWidget {
  const DriverHome({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final firestoreService = FirestoreService();
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Loads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_money),
            onPressed: () => Navigator.pushNamed(context, '/driver/earnings'),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<LoadModel>>(
        stream: firestoreService.streamDriverLoads(userId),
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
          );
        },
      ),
    );
  }
}
