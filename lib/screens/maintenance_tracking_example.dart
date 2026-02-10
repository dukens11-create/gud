import 'package:flutter/material.dart';
import 'maintenance_tracking.dart';

/// Example implementation showing how to use MaintenanceQueryService.
/// 
/// This file demonstrates various usage patterns for the maintenance
/// tracking queries including displaying history, upcoming maintenance,
/// and filtering by truck number.
class MaintenanceTrackingExample extends StatefulWidget {
  const MaintenanceTrackingExample({super.key});

  @override
  State<MaintenanceTrackingExample> createState() =>
      _MaintenanceTrackingExampleState();
}

class _MaintenanceTrackingExampleState
    extends State<MaintenanceTrackingExample> {
  final MaintenanceQueryService _service = MaintenanceQueryService();
  String? _selectedTruckNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Tracking Example'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Example 1: Display all historical maintenance
              _buildHistoryExample(),
              const SizedBox(height: 24),

              // Example 2: Display upcoming maintenance
              _buildUpcomingExample(),
              const SizedBox(height: 24),

              // Example 3: Display maintenance for specific truck
              _buildTruckSpecificExample(),
              const SizedBox(height: 24),

              // Example 4: Display maintenance statistics
              _buildStatsExample(),
            ],
          ),
        ),
      ),
    );
  }

  /// Example 1: Stream all historical maintenance records
  Widget _buildHistoryExample() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historical Maintenance Records',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Using streamMaintenanceHistory() to show completed services',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            // Stream historical records in real-time
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.streamMaintenanceHistory(limit: 5),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final records = snapshot.data ?? [];

                if (records.isEmpty) {
                  return const Text('No historical maintenance records found');
                }

                return Column(
                  children: records
                      .map((record) => _buildMaintenanceListTile(record))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Example 2: Display upcoming maintenance with async/await
  Widget _buildUpcomingExample() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming Maintenance (Next 30 Days)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Using getUpcomingMaintenance() with daysAhead filter',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            // Use FutureBuilder for one-time fetch
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _service.getUpcomingMaintenance(
                daysAhead: 30,
                limit: 5,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final records = snapshot.data ?? [];

                if (records.isEmpty) {
                  return const Text('No upcoming maintenance scheduled');
                }

                return Column(
                  children: records
                      .map((record) => _buildMaintenanceListTile(record))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Example 3: Display maintenance for a specific truck
  Widget _buildTruckSpecificExample() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Truck-Specific Maintenance',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _selectTruck(),
                  child: Text(_selectedTruckNumber ?? 'Select Truck'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Using streamAllMaintenance() with truckNumber filter',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (_selectedTruckNumber != null)
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _service.streamAllMaintenance(
                  truckNumber: _selectedTruckNumber,
                  limit: 5,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  final records = snapshot.data ?? [];

                  if (records.isEmpty) {
                    return Text(
                        'No maintenance records for $_selectedTruckNumber');
                  }

                  return Column(
                    children: records
                        .map((record) => _buildMaintenanceListTile(record))
                        .toList(),
                  );
                },
              )
            else
              const Text('Select a truck to view its maintenance records'),
          ],
        ),
      ),
    );
  }

  /// Example 4: Display maintenance statistics
  Widget _buildStatsExample() {
    if (_selectedTruckNumber == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maintenance Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Using getMaintenanceStats() for $_selectedTruckNumber',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: _service.getMaintenanceStats(_selectedTruckNumber!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                final stats = snapshot.data ?? {};

                return Column(
                  children: [
                    _buildStatRow('Total Records', '${stats['totalCount']}'),
                    _buildStatRow('Total Cost',
                        '\$${(stats['totalCost'] as double).toStringAsFixed(2)}'),
                    _buildStatRow('Upcoming', '${stats['upcomingCount']}'),
                    if (stats['mostRecentDate'] != null)
                      _buildStatRow(
                        'Most Recent',
                        _formatDate(stats['mostRecentDate'] as DateTime),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method to build a maintenance record list tile
  Widget _buildMaintenanceListTile(Map<String, dynamic> record) {
    final serviceDate =
        (record['serviceDate'] as dynamic).toDate() as DateTime;
    final cost = (record['cost'] as num).toDouble();
    final type = record['maintenanceType'] as String;
    final truckNumber = record['truckNumber'] as String;

    return ListTile(
      leading: const Icon(Icons.build),
      title: Text(type),
      subtitle: Text('$truckNumber - ${_formatDate(serviceDate)}'),
      trailing: Text(
        '\$${cost.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  /// Helper method to build a stat row
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  /// Helper method to format dates
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Helper method to select a truck
  Future<void> _selectTruck() async {
    // Get list of trucks with maintenance
    final trucks = await _service.getTruckNumbersWithMaintenance();

    if (trucks.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No trucks with maintenance records found'),
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    // Show selection dialog
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Truck'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: trucks.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(trucks[index]),
                onTap: () => Navigator.pop(context, trucks[index]),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
        ],
      ),
    );

    if (selected != null) {
      setState(() => _selectedTruckNumber = selected);
    }
  }
}

/// Additional example: Using the typed MaintenanceRecord class
/// 
/// This shows how to use the MaintenanceRecord class for type-safe access
class MaintenanceRecordExample extends StatelessWidget {
  final MaintenanceQueryService _service = MaintenanceQueryService();

  MaintenanceRecordExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Typed Maintenance Records'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _service.getAllMaintenance(limit: 20),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final recordMaps = snapshot.data ?? [];

          // Convert to typed MaintenanceRecord objects
          final records = recordMaps
              .map((data) => MaintenanceRecord.fromMap(data['id'], data))
              .toList();

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return _buildTypedMaintenanceCard(record);
            },
          );
        },
      ),
    );
  }

  Widget _buildTypedMaintenanceCard(MaintenanceRecord record) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              record.isHistory ? Colors.grey : Colors.blue,
          child: Icon(
            record.isHistory ? Icons.history : Icons.schedule,
            color: Colors.white,
          ),
        ),
        title: Text(record.maintenanceType),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Truck: ${record.truckNumber}'),
            Text('Date: ${_formatDate(record.serviceDate)}'),
            if (record.daysUntilService > 0)
              Text('Due in: ${record.daysUntilService} days',
                  style: TextStyle(
                    color: record.daysUntilService <= 7
                        ? Colors.red
                        : Colors.orange,
                  )),
            if (record.isNextServiceDue)
              const Text('⚠️ Next service due soon!',
                  style: TextStyle(color: Colors.red)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${record.cost.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (record.serviceProvider != null)
              Text(
                record.serviceProvider!,
                style: const TextStyle(fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
