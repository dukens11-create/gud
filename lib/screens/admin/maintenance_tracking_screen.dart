import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/driver_extended_service.dart';
import '../../utils/datetime_utils.dart';

/// Helper function to format dates consistently
String _formatDate(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}

/// Truck Maintenance Tracking Screen
/// 
/// Features:
/// - View maintenance history
/// - Add maintenance records
/// - Track upcoming maintenance
/// - Filter by truck number
class MaintenanceTrackingScreen extends StatefulWidget {
  final String? truckNumber;

  const MaintenanceTrackingScreen({super.key, this.truckNumber});

  @override
  State<MaintenanceTrackingScreen> createState() =>
      _MaintenanceTrackingScreenState();
}

class _MaintenanceTrackingScreenState extends State<MaintenanceTrackingScreen>
    with SingleTickerProviderStateMixin {
  final _service = DriverExtendedService();
  late TabController _tabController;
  String? _selectedTruck;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedTruck = widget.truckNumber;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Tracking'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'History', icon: Icon(Icons.history)),
            Tab(text: 'Upcoming', icon: Icon(Icons.schedule)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryTab(),
          _buildUpcomingTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMaintenanceDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Record'),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_selectedTruck == null) {
      return _buildTruckSelector();
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.streamTruckMaintenance(_selectedTruck!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final records = snapshot.data ?? [];

        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.build_circle_outlined,
                    size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No maintenance records',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add maintenance records to track history',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildTruckHeader();
            }
            return _MaintenanceCard(record: records[index - 1]);
          },
        );
      },
    );
  }

  Widget _buildUpcomingTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _service.getUpcomingMaintenance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final records = snapshot.data ?? [];

        if (records.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No upcoming maintenance',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'All trucks are up to date',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            return _UpcomingMaintenanceCard(record: records[index]);
          },
        );
      },
    );
  }

  Widget _buildTruckSelector() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Select a truck',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter truck number to view maintenance history',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showTruckSelector,
              icon: const Icon(Icons.search),
              label: const Text('Enter Truck Number'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTruckHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.local_shipping, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Truck $_selectedTruck',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Maintenance History',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _showTruckSelector,
                child: const Text('Change'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTruckSelector() async {
    final controller = TextEditingController(text: _selectedTruck);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Truck Number'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Truck Number',
            hintText: 'e.g., TRK-001',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('SELECT'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _selectedTruck = result);
    }
  }

  Future<void> _showAddMaintenanceDialog() async {
    final truckController = TextEditingController(text: _selectedTruck);
    final typeController = TextEditingController();
    final costController = TextEditingController();
    final providerController = TextEditingController();
    final notesController = TextEditingController();
    DateTime serviceDate = DateTime.now();
    DateTime? nextServiceDue;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Maintenance Record'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: truckController,
                  decoration: const InputDecoration(
                    labelText: 'Truck Number *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: typeController,
                  decoration: const InputDecoration(
                    labelText: 'Maintenance Type *',
                    hintText: 'e.g., Oil Change, Tire Rotation',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: costController,
                  decoration: const InputDecoration(
                    labelText: 'Cost *',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Service Date'),
                  subtitle: Text(_formatDate(serviceDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: serviceDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => serviceDate = date);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Next Service Due'),
                  subtitle: Text(nextServiceDue != null
                      ? _formatDate(nextServiceDue!)
                      : 'Not set'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: nextServiceDue ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => nextServiceDue = date);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: providerController,
                  decoration: const InputDecoration(
                    labelText: 'Service Provider',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ADD'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        await _service.addMaintenanceRecord(
          driverId: '', // Will be populated from truck assignment
          truckNumber: truckController.text,
          maintenanceType: typeController.text,
          serviceDate: serviceDate,
          cost: double.parse(costController.text),
          nextServiceDue: nextServiceDue,
          serviceProvider:
              providerController.text.isEmpty ? null : providerController.text,
          notes: notesController.text.isEmpty ? null : notesController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maintenance record added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}

class _MaintenanceCard extends StatelessWidget {
  final Map<String, dynamic> record;

  const _MaintenanceCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final serviceDate = DateTimeUtils.parseDateTime(record['serviceDate']) ?? DateTime.now();
    final cost = (record['cost'] as num).toDouble();
    final type = record['maintenanceType'] as String;
    final provider = record['serviceProvider'] as String?;
    final notes = record['notes'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    type,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Text(
                  '\$${cost.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'Service Date',
              value: _formatDate(serviceDate),
            ),
            if (provider != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.business,
                label: 'Provider',
                value: provider,
              ),
            ],
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.notes,
                label: 'Notes',
                value: notes,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UpcomingMaintenanceCard extends StatelessWidget {
  final Map<String, dynamic> record;

  const _UpcomingMaintenanceCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final nextServiceDue =
        DateTimeUtils.parseDateTime(record['nextServiceDue']) ?? DateTime.now();
    final truckNumber = record['truckNumber'] as String;
    final maintenanceType = record['maintenanceType'] as String;
    final daysUntil = nextServiceDue.difference(DateTime.now()).inDays;

    final isUrgent = daysUntil <= 7;
    final color = isUrgent ? Colors.red : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(Icons.warning, color: color),
        ),
        title: Text(
          maintenanceType,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Truck: $truckNumber'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatDate(nextServiceDue),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$daysUntil days',
              style: TextStyle(
                color: color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
