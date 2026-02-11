import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../services/analytics_service.dart';
import '../../services/driver_extended_service.dart';
import '../../models/load.dart';
import '../../models/driver_extended.dart';
import '../login_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final _firestoreService = FirestoreService();
  final _driverService = DriverExtendedService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';
  Timer? _debounce;
  DateTimeRange? _dateRange;
  String _sortBy = 'date'; // date, amount, driver, status
  bool _sortAscending = false;

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
    return _firestoreService.streamAllLoads().map((loads) {
      var filteredLoads = loads.where((load) {
        // Search filter - searches across load number, driver, and locations
        final matchesSearch = _searchQuery.isEmpty ||
            load.loadNumber.toLowerCase().contains(_searchQuery) ||
            load.driverId.toLowerCase().contains(_searchQuery) ||
            load.pickupAddress.toLowerCase().contains(_searchQuery) ||
            load.deliveryAddress.toLowerCase().contains(_searchQuery);

        // Status filter
        final matchesStatus = _statusFilter == 'all' || load.status == _statusFilter;

        // Date range filter
        bool matchesDateRange = true;
        if (_dateRange != null) {
          final loadDate = load.createdAt;
          matchesDateRange = loadDate.isAfter(_dateRange!.start.subtract(const Duration(days: 1))) &&
                             loadDate.isBefore(_dateRange!.end.add(const Duration(days: 1)));
        }

        return matchesSearch && matchesStatus && matchesDateRange;
      }).toList();

      // Sort loads
      filteredLoads.sort((a, b) {
        int comparison = 0;
        
        switch (_sortBy) {
          case 'date':
            comparison = a.createdAt.compareTo(b.createdAt);
            break;
          case 'amount':
            comparison = a.rate.compareTo(b.rate);
            break;
          case 'driver':
            comparison = a.driverId.compareTo(b.driverId);
            break;
          case 'status':
            comparison = a.status.compareTo(b.status);
            break;
        }

        return _sortAscending ? comparison : -comparison;
      });

      return filteredLoads;
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
          // Expiration alerts notification badge
          StreamBuilder<List<ExpirationAlert>>(
            stream: _driverService.streamExpirationAlerts(),
            builder: (context, snapshot) {
              final alertCount = snapshot.data?.length ?? 0;
              final criticalCount = snapshot.data
                      ?.where((alert) => alert.isCritical)
                      .length ??
                  0;
              
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    tooltip: 'Expiration Alerts',
                    onPressed: () {
                      Navigator.pushNamed(context, '/admin/expiration-alerts');
                    },
                  ),
                  if (alertCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: criticalCount > 0 ? Colors.red : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          alertCount > 99 ? '99+' : alertCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
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
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          // Expiration Alerts Summary Widget
          StreamBuilder<List<ExpirationAlert>>(
            stream: _driverService.streamExpirationAlerts(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }

              final alerts = snapshot.data!;
              final criticalCount = alerts.where((a) => a.isCritical).length;
              final warningCount = alerts.length - criticalCount;

              return Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: criticalCount > 0
                        ? [Colors.red.shade400, Colors.red.shade600]
                        : [Colors.orange.shade400, Colors.orange.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, '/admin/expiration-alerts');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            criticalCount > 0 ? Icons.error : Icons.warning,
                            color: Colors.white,
                            size: 40,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${alerts.length} Document${alerts.length != 1 ? 's' : ''} Expiring Soon',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (criticalCount > 0)
                                  Text(
                                    '$criticalCount critical (< 7 days)',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  )
                                else
                                  Text(
                                    '$warningCount warning${warningCount != 1 ? 's' : ''} (< 30 days)',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

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

          // Date Range and Sort Controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Date Range Picker
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _dateRange == null
                          ? 'Select Date Range'
                          : '${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDateRange: _dateRange,
                      );
                      if (picked != null) {
                        setState(() => _dateRange = picked);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Sort Dropdown
                DropdownButton<String>(
                  value: _sortBy,
                  icon: const Icon(Icons.sort),
                  underline: Container(),
                  items: const [
                    DropdownMenuItem(value: 'date', child: Text('Date')),
                    DropdownMenuItem(value: 'amount', child: Text('Amount')),
                    DropdownMenuItem(value: 'driver', child: Text('Driver')),
                    DropdownMenuItem(value: 'status', child: Text('Status')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sortBy = value);
                    }
                  },
                ),
                // Sort Direction Toggle
                IconButton(
                  icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                  onPressed: () {
                    setState(() => _sortAscending = !_sortAscending);
                  },
                  tooltip: _sortAscending ? 'Ascending' : 'Descending',
                ),
                // Clear Filters
                if (_statusFilter != 'all' || _dateRange != null || _searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_all),
                    onPressed: () {
                      setState(() {
                        _statusFilter = 'all';
                        _dateRange = null;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                    tooltip: 'Clear Filters',
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

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
                  // Show different messages based on active filters
                  String message;
                  String subtitle;
                  
                  if (_searchQuery.isNotEmpty) {
                    message = 'No loads match "${_searchController.text}"';
                    subtitle = 'Try adjusting your search terms';
                  } else if (_dateRange != null) {
                    message = 'No loads in selected date range';
                    subtitle = 'Try selecting a different date range';
                  } else if (_statusFilter != 'all') {
                    message = 'No $_statusFilter loads found';
                    subtitle = 'Try changing the status filter';
                  } else {
                    message = 'No loads yet';
                    subtitle = 'Create your first load to get started!';
                  }
                  
                  return Center(
                    child: Semantics(
                      label: message,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty || _statusFilter != 'all' || _dateRange != null
                                ? Icons.search_off
                                : Icons.inventory_2_outlined,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            message,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty || _statusFilter != 'all' || _dateRange != null) ...[
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.clear_all),
                              label: const Text('Clear All Filters'),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _statusFilter = 'all';
                                  _dateRange = null;
                                });
                              },
                            ),
                          ] else ...[
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Create New Load'),
                              onPressed: () {
                                Navigator.pushNamed(context, '/admin/create-load');
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

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 35, color: Colors.blue),
                ),
                SizedBox(height: 10),
                Text(
                  'Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Administrator',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Manage Drivers'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/drivers');
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_box),
            title: const Text('Create Load'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/create-load');
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Load History'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/load-history');
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt),
            title: const Text('Invoices'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/invoices');
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Expenses'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/expenses');
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Statistics'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/statistics');
            },
          ),
          ListTile(
            leading: const Icon(Icons.notification_important),
            title: const Text('Expiration Alerts'),
            trailing: StreamBuilder<List<ExpirationAlert>>(
              stream: _driverService.streamExpirationAlerts(),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                if (count == 0) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/expiration-alerts');
            },
          ),
          ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text('Document Verification'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/document-verification');
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Driver Performance'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/driver-performance');
            },
          ),
          ListTile(
            leading: const Icon(Icons.build),
            title: const Text('Maintenance Tracking'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/maintenance');
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export & Reports'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/export');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
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
    );
  }
}
