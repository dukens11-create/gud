import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/truck.dart';
import '../../services/truck_service.dart';
import '../../services/navigation_service.dart';

/// Manage Trucks Screen - Comprehensive truck management functionality
/// 
/// Features:
/// - List view with status badges
/// - Search and filter
/// - Add/Edit trucks
/// - Soft delete with confirmation
/// - View assigned driver
class ManageTrucksScreen extends StatefulWidget {
  const ManageTrucksScreen({super.key});

  @override
  State<ManageTrucksScreen> createState() => _ManageTrucksScreenState();
}

/// Minimum year for truck manufacturing date
const int _minTruckYear = 1990;

class _ManageTrucksScreenState extends State<ManageTrucksScreen> {
  final _truckService = TruckService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _sortBy = 'truckNumber'; // truckNumber, make, year
  bool _showInactive = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Trucks'),
        actions: [
          IconButton(
            icon: Icon(_showInactive ? Icons.visibility : Icons.visibility_off),
            tooltip: _showInactive ? 'Hide Inactive' : 'Show Inactive',
            onPressed: () {
              setState(() => _showInactive = !_showInactive);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by truck number, make, model, or plate...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _statusFilter == 'all',
                  onSelected: (_) => setState(() => _statusFilter = 'all'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Available'),
                  selected: _statusFilter == 'available',
                  onSelected: (_) => setState(() => _statusFilter = 'available'),
                  avatar: const Icon(Icons.check_circle, size: 18, color: Colors.green),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('In Use'),
                  selected: _statusFilter == 'in_use',
                  onSelected: (_) => setState(() => _statusFilter = 'in_use'),
                  avatar: const Icon(Icons.local_shipping, size: 18, color: Colors.blue),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Maintenance'),
                  selected: _statusFilter == 'maintenance',
                  onSelected: (_) => setState(() => _statusFilter = 'maintenance'),
                  avatar: const Icon(Icons.build, size: 18, color: Colors.orange),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Sort options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Sort by: '),
                DropdownButton<String>(
                  value: _sortBy,
                  underline: Container(),
                  items: const [
                    DropdownMenuItem(value: 'truckNumber', child: Text('Truck Number')), 
                    DropdownMenuItem(value: 'make', child: Text('Make')), 
                    DropdownMenuItem(value: 'year', child: Text('Year')), 
                  ], 
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sortBy = value);
                    }
                  },
                ),
              ],
            ),
          ),

          const Divider(),

          // Truck list
          Expanded(
            child: StreamBuilder<List<Truck>>(
              stream: _truckService.streamTrucks(includeInactive: _showInactive),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 60, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                var trucks = snapshot.data ?? [];

                // Apply filters
                trucks = trucks.where((truck) {
                  // Search filter
                  if (_searchQuery.isNotEmpty) {
                    final matchesSearch = truck.truckNumber.toLowerCase().contains(_searchQuery) ||
                        truck.make.toLowerCase().contains(_searchQuery) ||
                        truck.model.toLowerCase().contains(_searchQuery) ||
                        truck.plateNumber.toLowerCase().contains(_searchQuery) ||
                        truck.vin.toLowerCase().contains(_searchQuery);
                    if (!matchesSearch) return false;
                  }

                  // Status filter
                  if (_statusFilter != 'all' && truck.status != _statusFilter) {
                    return false;
                  }

                  return true;
                }).toList();

                // Sort trucks
                trucks.sort((a, b) {
                  switch (_sortBy) {
                    case 'make':
                      return a.make.compareTo(b.make);
                    case 'year':
                      return b.year.compareTo(a.year);
                    case 'truckNumber':
                    default:
                      return a.truckNumber.compareTo(b.truckNumber);
                  }
                });

                if (trucks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_shipping, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'No trucks found' : 'No matching trucks',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Add your first truck to get started'
                              : 'Try adjusting your search or filters',
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
                  itemCount: trucks.length,
                  itemBuilder: (context, index) {
                    final truck = trucks[index];
                    return _TruckCard(
                      truck: truck,
                      onTap: () => _showEditTruckDialog(truck),
                      onDelete: () => _confirmDeleteTruck(truck),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTruckDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Truck'),
      ),
    );
  }

  Future<void> _showAddTruckDialog() async {
    final truckNumber = await _truckService.generateNextTruckNumber();
    
    if (!mounted) return;
    
    await _showTruckDialog(
      title: 'Add New Truck',
      initialTruckNumber: truckNumber,
    );
  }

  Future<void> _showEditTruckDialog(Truck truck) async {
    await _showTruckDialog(
      title: 'Edit Truck',
      truck: truck,
    );
  }

  Future<void> _showTruckDialog({
    required String title,
    Truck? truck,
    String? initialTruckNumber,
  }) async {
    final truckNumberController = TextEditingController(
      text: truck?.truckNumber ?? initialTruckNumber ?? '',
    );
    final vinController = TextEditingController(text: truck?.vin ?? '');
    final makeController = TextEditingController(text: truck?.make ?? '');
    final modelController = TextEditingController(text: truck?.model ?? '');
    final plateController = TextEditingController(text: truck?.plateNumber ?? '');
    final notesController = TextEditingController(text: truck?.notes ?? '');
    
    int selectedYear = truck?.year ?? DateTime.now().year;
    String selectedStatus = truck?.status ?? 'available';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: truckNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Truck Number *',
                    hintText: 'TRK-001',
                    border: OutlineInputBorder(),
                  ),
                  enabled: truck == null, // Can't change truck number after creation
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: vinController,
                  decoration: const InputDecoration(
                    labelText: 'VIN *',
                    hintText: 'Vehicle Identification Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: makeController,
                  decoration: const InputDecoration(
                    labelText: 'Make *',
                    hintText: 'Freightliner, Volvo, etc.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: modelController,
                  decoration: const InputDecoration(
                    labelText: 'Model *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedYear,
                  decoration: const InputDecoration(
                    labelText: 'Year *',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(
                    DateTime.now().year - _minTruckYear + 1,
                    (index) {
                      final year = DateTime.now().year - index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    },
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedYear = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: plateController,
                  decoration: const InputDecoration(
                    labelText: 'Plate Number *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'available',
                      child: Text('Available'),
                    ),
                    DropdownMenuItem(
                      value: 'in_use',
                      child: Text('In Use'),
                    ),
                    DropdownMenuItem(
                      value: 'maintenance',
                      child: Text('Maintenance'),
                    ),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text('Inactive'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedStatus = value);
                    }
                  },
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
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Validate
                if (truckNumberController.text.trim().isEmpty ||
                    vinController.text.trim().isEmpty ||
                    makeController.text.trim().isEmpty ||
                    modelController.text.trim().isEmpty ||
                    plateController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all required fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Validate truck number format
                if (!_truckService.validateTruckNumberFormat(
                    truckNumberController.text.trim())) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid truck number format. Use TRK-XXX (e.g., TRK-001)'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );

    if (result == true && mounted) {
      try {
        final now = DateTime.now();
        final newTruck = Truck(
          id: truck?.id ?? '',
          truckNumber: truckNumberController.text.trim(),
          vin: vinController.text.trim(),
          make: makeController.text.trim(),
          model: modelController.text.trim(),
          year: selectedYear,
          plateNumber: plateController.text.trim(),
          status: selectedStatus,
          assignedDriverId: truck?.assignedDriverId,
          assignedDriverName: truck?.assignedDriverName,
          notes: notesController.text.trim().isEmpty 
              ? null 
              : notesController.text.trim(),
          createdAt: truck?.createdAt ?? now,
          updatedAt: now,
        );

        if (truck == null) {
          // Create new truck
          await _truckService.createTruck(newTruck);
          if (mounted) {
            NavigationService.showSuccess('Truck added successfully');
          }
        } else {
          // Update existing truck
          await _truckService.updateTruck(truck.id, newTruck);
          if (mounted) {
            NavigationService.showSuccess('Truck updated successfully');
          }
        }
      } catch (e) {
        if (mounted) {
          NavigationService.showError('Error: $e');
        }
      }
    }

    // Dispose controllers
    truckNumberController.dispose();
    vinController.dispose();
    makeController.dispose();
    modelController.dispose();
    plateController.dispose();
    notesController.dispose();
  }

  Future<void> _confirmDeleteTruck(Truck truck) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Truck'),
        content: Text(
          'Are you sure you want to delete ${truck.truckNumber}?
\n'
          'This will set the truck status to inactive. The truck will no longer appear in lists.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _truckService.deleteTruck(truck.id);
        if (mounted) {
          NavigationService.showSuccess('Truck deleted successfully');
        }
      } catch (e) {
        if (mounted) {
          NavigationService.showError('Error deleting truck: $e');
        }
      }
    }
  }
}

/// Widget for displaying a truck card
class _TruckCard extends StatelessWidget {
  final Truck truck;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TruckCard({
    required this.truck,
    required this.onTap,
    required this.onDelete,
  });

  Color _getStatusColor() {
    switch (truck.status) {
      case 'available':
        return Colors.green;
      case 'in_use':
        return Colors.blue;
      case 'maintenance':
        return Colors.orange;
      case 'inactive':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (truck.status) {
      case 'available':
        return Icons.check_circle;
      case 'in_use':
        return Icons.local_shipping;
      case 'maintenance':
        return Icons.build;
      case 'inactive':
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(truck.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        onDelete();
        return false; // Don't auto-dismiss, let the dialog handle it
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_shipping,
                      size: 32,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            truck.truckNumber,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            truck.displayInfo,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getStatusColor()),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(),
                            size: 16,
                            color: _getStatusColor(),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            truck.statusDisplayName,
                            style: TextStyle(
                              color: _getStatusColor(),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InfoRow(
                        icon: Icons.confirmation_number,
                        label: 'VIN',
                        value: truck.vin,
                      ),
                    ),
                    Expanded(
                      child: _InfoRow(
                        icon: Icons.calendar_today,
                        label: 'Year',
                        value: truck.year.toString(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.credit_card,
                  label: 'Plate',
                  value: truck.plateNumber,
                ),
                if (truck.assignedDriverName != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Driver: ${truck.assignedDriverName}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (truck.notes != null && truck.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    truck.notes!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
}

/// Widget for displaying info rows
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
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}