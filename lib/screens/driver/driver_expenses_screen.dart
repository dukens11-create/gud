import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/expense_service.dart';
import '../../models/expense.dart';
import '../../services/mock_data_service.dart';

/// Driver expenses screen - View driver's expense history
class DriverExpensesScreen extends StatelessWidget {
  const DriverExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mockService = MockDataService();
    final currentUserId = mockService.currentUserId;
    
    // If no user is authenticated, show error state
    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Expenses'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Authentication required',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
              SizedBox(height: 8),
              Text(
                'Please log in to view your expenses',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final expenseService = ExpenseService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Expenses'),
      ),
      body: StreamBuilder<List<Expense>>(
        stream: expenseService.streamDriverExpenses(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading expenses: ${snapshot.error}'),
            );
          }

          final expenses = snapshot.data ?? [];

          if (expenses.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No expenses recorded',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your expenses will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Calculate total
          final total = expenses.fold<double>(
            0.0,
            (sum, expense) => sum + expense.amount,
          );

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Expenses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(_getCategoryIcon(expense.category)),
                        ),
                        title: Text(expense.description),
                        subtitle: Text(
                          '${expense.category} • ${DateFormat('MMM dd, yyyy').format(expense.date)}',
                        ),
                        trailing: Text(
                          '\$${expense.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fuel':
        return Icons.local_gas_station;
      case 'maintenance':
        return Icons.build;
      case 'tolls':
        return Icons.toll;
      case 'insurance':
        return Icons.shield;
      default:
        return Icons.receipt;
    }
  }
}
