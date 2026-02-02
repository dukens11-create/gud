import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../services/expense_service.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final firestoreService = FirestoreService();
    final expenseService = ExpenseService();

    return Scaffold(
      appBar: AppBar(title: const Text('My Earnings')),
      body: FutureBuilder<List<double>>(
        future: Future.wait([
          firestoreService.getDriverEarnings(userId),
          expenseService.getDriverTotalExpenses(userId),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final totalEarnings = snapshot.data?[0] ?? 0.0;
          final totalExpenses = snapshot.data?[1] ?? 0.0;
          final netEarnings = totalEarnings - totalExpenses;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.attach_money, size: 100, color: Colors.green),
                const SizedBox(height: 24),
                
                // Gross earnings
                const Text(
                  'Gross Earnings',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Text(
                  '\$${totalEarnings.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                
                // Expenses
                const Text(
                  'Total Expenses',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Text(
                  '\$${totalExpenses.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 24),
                
                const Divider(indent: 50, endIndent: 50),
                const SizedBox(height: 24),
                
                // Net earnings
                const Text(
                  'Net Earnings',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${netEarnings.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: netEarnings >= 0 ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 32),
                
                // View expenses button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/driver/expenses');
                  },
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('View My Expenses'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
