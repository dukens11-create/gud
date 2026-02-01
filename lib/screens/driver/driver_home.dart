import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/load_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import 'driver_load_detail.dart';

class DriverHome extends StatelessWidget {
  const DriverHome({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_money),
            onPressed: () => Navigator.pushNamed(context, '/driver/earnings'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<LoadModel>>(
        stream: FirestoreService().streamDriverLoads(userId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final loads = snap.data!;
          if (loads.isEmpty) {
            return const Center(child: Text('No loads assigned'));
          }

          return ListView.builder(
            itemCount: loads.length,
            itemBuilder: (context, index) {
              final load = loads[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('Load #${load.loadNumber}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${load.status}'),
                      Text('From: ${load.pickupAddress}'),
                      Text('To: ${load.deliveryAddress}'),
                      Text('Rate: \$${load.rate.toStringAsFixed(2)}'),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DriverLoadDetail(load: load),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
