import 'package:flutter/material.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Management'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No expenses recorded',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'This feature is disabled in demo mode',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense tracking is disabled in demo mode'),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category || 
                                    (category == 'All' && _selectedCategory == null);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category == 'All' ? null : category;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Expenses list
          Expanded(
            child: StreamBuilder<List<Expense>>(
              stream: _expenseService.streamAllExpenses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var expenses = snapshot.data ?? [];
                
                // Apply category filter
                if (_selectedCategory != null) {
                  expenses = expenses.where((e) => e.category == _selectedCategory).toList();
                }

                if (expenses.isEmpty) {
                  return const Center(
                    child: Text('No expenses yet. Add your first expense!'),
                  );
                }

                // Calculate total
                final total = expenses.fold(0.0, (sum, e) => sum + e.amount);

                return Column(
                  children: [
                    // Total card
                    Card(
                      margin: const EdgeInsets.all(8),
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
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
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Expenses list
                    Expanded(
                      child: ListView.builder(
                        itemCount: expenses.length,
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getCategoryColor(expense.category),
                                child: Icon(
                                  _getCategoryIcon(expense.category),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(expense.description),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(expense.category.toUpperCase()),
                                  Text(dateFormat.format(expense.date)),
                                ],
                              ),
                              trailing: Text(
                                '\$${expense.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              onTap: () => _showExpenseDetails(expense),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddExpenseScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterDialog() {
    // Future enhancement: Add date range filter, driver filter
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Additional filters coming soon!')),
    );
  }

  void _showExpenseDetails(Expense expense) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Expense Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Amount', '\$${expense.amount.toStringAsFixed(2)}'),
            _buildDetailRow('Category', expense.category.toUpperCase()),
            _buildDetailRow('Description', expense.description),
            _buildDetailRow('Date', dateFormat.format(expense.date)),
            if (expense.driverId != null)
              _buildDetailRow('Driver ID', expense.driverId!),
            if (expense.loadId != null)
              _buildDetailRow('Load ID', expense.loadId!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Expense'),
                  content: const Text('Are you sure you want to delete this expense?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              
              if (confirmed == true && context.mounted) {
                await _expenseService.deleteExpense(expense.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Expense deleted')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'fuel':
        return Colors.orange;
      case 'maintenance':
        return Colors.red;
      case 'tolls':
        return Colors.purple;
      case 'insurance':
        return Colors.blue;
      default:
        return Colors.grey;
    }
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
        return Icons.attach_money;
    }
  }
}
