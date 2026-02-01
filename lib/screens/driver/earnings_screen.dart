import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/driver.dart';
import '../../widgets/loading.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Earnings'),
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

          return FutureBuilder<double>(
            future: firestoreService.calculateDriverEarnings(driver.id),
            builder: (context, earningsSnapshot) {
              if (earningsSnapshot.connectionState == ConnectionState.waiting) {
                return const LoadingScreen();
              }

              if (earningsSnapshot.hasError) {
                return Center(
                  child: Text('Error: ${earningsSnapshot.error}'),
                );
              }

              final earnings = earningsSnapshot.data ?? 0.0;

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet,
                        size: 80,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Total Earnings',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '\$${earnings.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'This represents your total earnings from all delivered loads.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
