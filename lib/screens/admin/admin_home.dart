import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/mock_data_service.dart';
import '../../services/analytics_service.dart';
import '../../models/load.dart';
import '../login_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final mockService = MockDataService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Log screen view
    AnalyticsService.instance.logScreenView(screenName: 'admin_home');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query.toLowerCase();
      });
      
      // Log search event
      if (query.isNotEmpty) {
        AnalyticsService.instance.logSearch(query);
      }
    });
  }

  Stream<List<LoadModel>> _getFilteredLoads() {
    return mockService.streamAllLoads().map((loads) {
      return loads.where((load) {
        // Search filter
        final matchesSearch = _searchQuery.isEmpty ||
            load.loadNumber.toLowerCase().contains(_searchQuery) ||
            load.driverId.toLowerCase().contains(_searchQuery) ||
            load.pickupAddress.toLowerCase().contains(_searchQuery) ||
            load.deliveryAddress.toLowerCase().contains(_searchQuery);

        // Status filter
        final matchesStatus = _statusFilter == 'all' || load.status == _statusFilter;

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _statusFilter = filter;
    });
    
    // Log filter usage
    AnalyticsService.instance.logEvent('filter_used', parameters: {
      'screen': 'admin_home',
      'filter': filter,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: const Text('Admin Dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Sign out',
            onPressed: () async {
              await mockService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search loads by number, driver, or location...',
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

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _statusFilter == 'all',
                  onSelected: (_) => _onFilterChanged('all'),
                  avatar: _statusFilter == 'all' ? const Icon(Icons.check, size: 18) : null,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Assigned'),
                  selected: _statusFilter == 'assigned',
                  onSelected: (_) => _onFilterChanged('assigned'),
                  avatar: _statusFilter == 'assigned' ? const Icon(Icons.check, size: 18) : null,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('In Transit'),
                  selected: _statusFilter == 'in-transit',
                  onSelected: (_) => _onFilterChanged('in-transit'),
                  avatar: _statusFilter == 'in-transit' ? const Icon(Icons.check, size: 18) : null,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Delivered'),
                  selected: _statusFilter == 'delivered',
                  onSelected: (_) => _onFilterChanged('delivered'),
                  avatar: _statusFilter == 'delivered' ? const Icon(Icons.check, size: 18) : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Load List
          Expanded(
            child: StreamBuilder<List<LoadModel>>(
              stream: _getFilteredLoads(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final loads = snapshot.data ?? [];

                if (loads.isEmpty) {
                  // Show different messages based on filters
                  final message = _searchQuery.isNotEmpty || _statusFilter != 'all'
                      ? 'No loads found matching your criteria'
                      : 'No loads yet. Create your first load!';
                  
                  return Center(
                    child: Semantics(
                      label: message,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            message,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty || _statusFilter != 'all') ...[
                            const SizedBox(height: 16),
                            TextButton.icon(
                              icon: const Icon(Icons.clear_all),
                              label: const Text('Clear Filters'),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _statusFilter = 'all';
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return Semantics(
                  label: 'List of ${loads.length} loads',
                  child: ListView.builder(
                    itemCount: loads.length,
                    itemBuilder: (context, index) {
                      final load = loads[index];
                      return Semantics(
                        label: 'Load ${load.loadNumber}, driver ${load.driverId}, status ${load.status}, rate ${load.rate} dollars',
                        button: true,
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(
                              load.loadNumber,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Driver: ${load.driverId}'),
                                Text('${load.pickupAddress} → ${load.deliveryAddress}'),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${load.rate.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(load.status),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    load.status,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'statistics',
            onPressed: () => Navigator.pushNamed(context, '/admin/statistics'),
            tooltip: 'View statistics',
            child: const Icon(Icons.bar_chart),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'expenses',
            onPressed: () => Navigator.pushNamed(context, '/admin/expenses'),
            tooltip: 'View expenses',
            child: const Icon(Icons.receipt_long),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'drivers',
            onPressed: () => Navigator.pushNamed(context, '/admin/drivers'),
            tooltip: 'Manage drivers',
            child: const Icon(Icons.people),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'create-load',
            onPressed: () => Navigator.pushNamed(context, '/admin/create-load'),
            tooltip: 'Create new load',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return Colors.blue;
      case 'in-transit':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
