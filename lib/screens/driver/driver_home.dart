import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/mock_data_service.dart';
import '../../services/location_service.dart';
import '../../services/firestore_service.dart';
import '../../services/analytics_service.dart';
import '../../services/driver_extended_service.dart';
import '../../models/load.dart';
import '../../models/driver_extended.dart';
import 'load_detail_screen.dart';
import '../login_screen.dart';

class DriverHome extends StatefulWidget {
  final String driverId;
  
  const DriverHome({super.key, required this.driverId});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();
  final DriverExtendedService _driverService = DriverExtendedService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all';
  Timer? _debounce;
  bool _isSendingLocation = false;

  @override
  void initState() {
    super.initState();
    // Log screen view
    AnalyticsService.instance.logScreenView(screenName: 'driver_home');
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
    final mockService = MockDataService();
    return mockService.streamDriverLoads(widget.driverId).map((loads) {
      return loads.where((load) {
        // Search filter
        final matchesSearch = _searchQuery.isEmpty ||
            load.loadNumber.toLowerCase().contains(_searchQuery) ||
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
      'screen': 'driver_home',
      'filter': filter,
    });
  }

  Future<void> _sendLocation() async {
    setState(() {
      _isSendingLocation = true;
    });

    try {
      // Get current location
      final position = await _locationService.getCurrentLocation();

      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get location. Please enable location services and grant permission.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Update driver location in Firestore
      await _firestoreService.updateDriverLocation(
        driverId: widget.driverId,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: position.timestamp ?? DateTime.now(),
        accuracy: position.accuracy,
      );

      // Log location update
      await AnalyticsService.instance.logEvent('location_updated', parameters: {
        'driver_id': widget.driverId,
        'accuracy': position.accuracy,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mockService = MockDataService();

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: const Text('My Loads'),
        ),
        actions: [
          // Expiration alerts notification badge
          StreamBuilder<List<ExpirationAlert>>(
            stream: _driverService.streamDriverExpirationAlerts(widget.driverId),
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
                    tooltip: 'My Expiration Alerts',
                    onPressed: () {
                      _showExpirationAlertsDialog();
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onSelected: (value) {
              switch (value) {
                case 'earnings':
                  Navigator.pushNamed(context, '/driver/earnings');
                  break;
                case 'expenses':
                  Navigator.pushNamed(context, '/driver/expenses');
                  break;
                case 'history':
                  Navigator.pushNamed(context, '/load-history');
                  break;
                case 'export':
                  Navigator.pushNamed(context, '/export');
                  break;
                case 'settings':
                  Navigator.pushNamed(context, '/settings');
                  break;
                case 'profile':
                  Navigator.pushNamed(context, '/profile');
                  break;
                case 'logout':
                  mockService.signOut().then((_) {
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  });
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'earnings',
                child: Row(
                  children: [
                    Icon(Icons.attach_money),
                    SizedBox(width: 8),
                    Text('My Earnings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'expenses',
                child: Row(
                  children: [
                    Icon(Icons.receipt_long),
                    SizedBox(width: 8),
                    Text('My Expenses'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 8),
                    Text('Load History'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download),
                    SizedBox(width: 8),
                    Text('Export My Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Expiration Alerts Banner
          StreamBuilder<List<ExpirationAlert>>(
            stream: _driverService.streamDriverExpirationAlerts(widget.driverId),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }

              final alerts = snapshot.data!;
              final criticalCount = alerts.where((a) => a.isCritical).length;

              return Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: criticalCount > 0
                      ? Colors.red.shade50
                      : Colors.orange.shade50,
                  border: Border.all(
                    color: criticalCount > 0
                        ? Colors.red.shade300
                        : Colors.orange.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showExpirationAlertsDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            criticalCount > 0 ? Icons.error : Icons.warning,
                            color: criticalCount > 0
                                ? Colors.red.shade700
                                : Colors.orange.shade700,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  criticalCount > 0
                                      ? '⚠️ Urgent: Document${criticalCount != 1 ? 's' : ''} Expiring Soon!'
                                      : '📄 Document Expiration Notice',
                                  style: TextStyle(
                                    color: criticalCount > 0
                                        ? Colors.red.shade900
                                        : Colors.orange.shade900,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  criticalCount > 0
                                      ? '$criticalCount document${criticalCount != 1 ? 's' : ''} expiring in less than 7 days'
                                      : '${alerts.length} document${alerts.length != 1 ? 's' : ''} expiring within 30 days',
                                  style: TextStyle(
                                    color: criticalCount > 0
                                        ? Colors.red.shade700
                                        : Colors.orange.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: criticalCount > 0
                                ? Colors.red.shade700
                                : Colors.orange.shade700,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Send Location button at the top
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Semantics(
              label: _isSendingLocation ? 'Sending location, please wait' : 'Send your current location',
              button: true,
              enabled: !_isSendingLocation,
              child: ElevatedButton.icon(
                onPressed: _isSendingLocation ? null : _sendLocation,
                icon: _isSendingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(_isSendingLocation ? 'Sending...' : 'Send Location'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search loads by number or location...',
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

          const SizedBox(height: 12),

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

          // Loads list
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
                      : 'No loads assigned yet.';
                  
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
                  label: 'List of ${loads.length} assigned loads',
                  child: ListView.builder(
                    itemCount: loads.length,
                    itemBuilder: (context, index) {
                      final load = loads[index];
                      return Semantics(
                        label: 'Load ${load.loadNumber}, from ${load.pickupAddress} to ${load.deliveryAddress}, rate ${load.rate} dollars, status ${load.status}. Tap to view details.',
                        button: true,
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            onTap: () {
                              AnalyticsService.instance.logSelectContent(
                                contentType: 'load',
                                itemId: load.loadNumber,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoadDetailScreen(load: load),
                                ),
                              );
                            },
                            leading: ExcludeSemantics(
                              child: CircleAvatar(
                                backgroundColor: _getStatusColor(load.status),
                                child: Text(
                                  load.status.isNotEmpty ? load.status[0].toUpperCase() : 'L',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            title: Text(
                              load.loadNumber,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('From: ${load.pickupAddress}'),
                                Text('To: ${load.deliveryAddress}'),
                                const SizedBox(height: 4),
                                Text(
                                  'Rate: \$${load.rate.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            trailing: ExcludeSemantics(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(load.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  load.status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
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

  void _showExpirationAlertsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notification_important, color: Colors.orange),
            SizedBox(width: 8),
            Text('Document Expiration Alerts'),
          ],
        ),
        content: StreamBuilder<List<ExpirationAlert>>(
          stream: _driverService.streamDriverExpirationAlerts(widget.driverId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text(
                    'All your documents are up to date!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              );
            }

            final alerts = snapshot.data!;
            alerts.sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));

            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  final color = alert.isCritical ? Colors.red : Colors.orange;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: color.withOpacity(0.3), width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    alert.daysRemaining.toString(),
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'days',
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  alert.type.displayName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Expires: ${_formatDate(alert.expiryDate)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (alert.status != AlertStatus.acknowledged)
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline),
                              color: Colors.green,
                              tooltip: 'Mark as read',
                              onPressed: () async {
                                await _driverService.acknowledgeExpirationAlert(
                                  alertId: alert.id,
                                  userId: widget.driverId,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Alert acknowledged'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
