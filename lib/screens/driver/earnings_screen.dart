import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('My Earnings')),
      body: FutureBuilder<double>(
        future: firestoreService.getDriverEarnings(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final totalEarnings = snapshot.data ?? 0.0;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.attach_money, size: 100, color: Colors.green),
                const SizedBox(height: 24),
                Text(
                  '\$${totalEarnings.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const Text('Total Earnings', style: TextStyle(fontSize: 20)),
              ],
            ),
          );
        },
      ),
    );
  }
}
