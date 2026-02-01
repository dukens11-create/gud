import 'package:flutter/material.dart';
import '../../services/mock_data_service.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loads = MockDataService.getDemoLoads();
    final totalEarnings = loads
        .where((l) => l.status == 'delivered')
        .fold(0.0, (sum, load) => sum + load.rate);
    
    return Scaffold(
      appBar: AppBar(title: const Text('My Earnings')),
      body: Center(
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
      ),
    );
  }
}
