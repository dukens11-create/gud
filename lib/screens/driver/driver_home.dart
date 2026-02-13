import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../services/location_service.dart';
import '../../services/firestore_service.dart';
import '../../services/analytics_service.dart';
import '../../services/navigation_service.dart';
import '../../services/driver_extended_service.dart';
import '../../services/mock_data_service.dart';
import '../../services/truck_service.dart';
import '../../models/load.dart';
import '../../models/driver_extended.dart';
import '../../models/truck.dart';
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
  final TruckService _truckService = TruckService();
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

  /// Get filtered loads using Firestore queries instead of in-memory filtering
  /// 
  /// This method uses server-side filtering for better performance and scalability.
  /// It queries Firestore with the authenticated driver's UID to show only their loads.
  /// 
  /// **IMPORTANT**: Queries with status filter require a Firestore composite index.
  /// If you encounter an index error, follow these steps:
  /// 1. Check the console output for the index creation link
  /// 2. Click the link or go to Firebase Console > Firestore > Indexes
  /// 3. Create a composite index with: driverId + status + createdAt
  /// 4. Wait for index to build (2-5 minutes)
  /// 
  /// The required index is defined in firestore.indexes.json and can be deployed using:
  /// `firebase deploy --only firestore:indexes`
  /// 
  /// **Debug Steps**:
  /// 1. Check console logs starting with 🔍, 📊, or ❌ for query details
  /// 2. Verify widget.driverId matches your Firebase Auth UID
  /// 3. Verify status filter value (in_transit, not in-transit)
  /// 4. Check Firestore console to see if loads exist with your driverId
  /// 5. Verify Firestore security rules allow reading loads
  Stream<List<LoadModel>> _getFilteredLoads() {
    print('🔍 Getting filtered loads - Status filter: $_statusFilter, Driver ID: ${widget.driverId}');
    
    // DEBUG: Log current user Firebase Auth UID
    print('🆔 Current user Firebase Auth UID: ${widget.driverId}');
    print('🔍 Querying Firestore for loads with driverId == ${widget.driverId}');
    
    try {
      // Use Firestore query for status filtering (more efficient than in-memory)
      if (_statusFilter != 'all') {
        print('📊 Using Firestore query with status filter: $_statusFilter');
        return _firestoreService
            .streamDriverLoadsByStatus(
              driverId: widget.driverId,
              status: _statusFilter,
            )
            .map((loads) {
              print('✅ Received ${loads.length} loads from Firestore with status $_statusFilter');
              return _applySearchFilter(loads);
            })
            .handleError((error) {
              print('❌ Error in filtered loads stream: $error');
              
              // Check for common error types
              if (error.toString().contains('permission') || error.toString().contains('PERMISSION_DENIED')) {
                print('⚠️  Permission error - driver may not have access to these loads');
                print('   Check: Firestore rules allow driver ${widget.driverId} to read loads');
              }
              if (error.toString().contains('index')) {
                print('⚠️  Index error - composite index may be missing or still building');
                print('   Run: firebase deploy --only firestore:indexes');
              }
              
              throw error;
            });
      } else {
        // For 'all' status, get all driver loads
        print('📊 Using Firestore query for all loads (no status filter)');
        return _firestoreService
            .streamDriverLoads(widget.driverId)
            .map((loads) {
              print('✅ Received ${loads.length} total loads from Firestore');
              return _applySearchFilter(loads);
            })
            .handleError((error) {
              print('❌ Error in all loads stream: $error');
              
              // Check for common error types
              if (error.toString().contains('permission') || error.toString().contains('PERMISSION_DENIED')) {
                print('⚠️  Permission error - driver may not have access to these loads');
                print('   Check: Firestore rules allow driver ${widget.driverId} to read loads');
              }
              if (error.toString().contains('index')) {
                print('⚠️  Index error - composite index may be missing or still building');
              }
              
              throw error;
            });
      }
    } catch (e) {
      print('❌ Error setting up filtered loads stream: $e');
      rethrow;
    }
  }

  /// Apply search filter to loads (in-memory for text search)
  /// 
  /// Search is kept in-memory because full-text search in Firestore
  /// requires additional setup and is better handled client-side for small result sets
  List<LoadModel> _applySearchFilter(List<LoadModel> loads) {
    if (_searchQuery.isEmpty) {
      return loads;
    }

    final filtered = loads.where((load) {
      return load.loadNumber.toLowerCase().contains(_searchQuery) ||
          load.pickupAddress.toLowerCase().contains(_searchQuery) ||
          load.deliveryAddress.toLowerCase().contains(_searchQuery);
    }).toList();
    
    print('🔎 Search filter applied: ${filtered.length} loads match "$_searchQuery"');
    return filtered;
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

          // Truck Information Card
          StreamBuilder<Truck?>(
            stream: _truckService.getTruckByDriverIdStream(widget.driverId),
            builder: (context, snapshot) {
              // Handle error state
              if (snapshot.hasError) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Error loading truck info. Please try again later.',
                          style: TextStyle(fontSize: 14, color: Colors.red.shade900),
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              if (snapshot.hasData && snapshot.data != null) {
                final truck = snapshot.data!;
                return Semantics(
                  label: 'Assigned truck: ${truck.truckNumber}, ${truck.displayInfo}, Status: ${truck.statusDisplayName}',
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.local_shipping,
                              size: 32,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  truck.truckNumber,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  truck.displayInfo,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildTruckStatusBadge(truck.status),
                        ],
                      ),
                    ),
                  ),
                ),
                );
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                // Show placeholder card during loading to prevent layout shift
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 56,
                            height: 56,
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Loading truck info...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                // No truck assigned - show info message
                return Semantics(
                  label: 'No truck assigned. Contact admin to get a truck assignment.',
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No truck assigned yet. Contact admin.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                );
              }
            },
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
                  label: const Text('Pending'),
                  selected: _statusFilter == 'pending',
                  onSelected: (_) => _onFilterChanged('pending'),
                  avatar: _statusFilter == 'pending' 
                      ? const Icon(Icons.check, size: 18) 
                      : const Icon(Icons.schedule, size: 18, color: Colors.orange),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Accepted'),
                  selected: _statusFilter == 'accepted',
                  onSelected: (_) => _onFilterChanged('accepted'),
                  avatar: _statusFilter == 'accepted' 
                      ? const Icon(Icons.check, size: 18) 
                      : const Icon(Icons.check_circle, size: 18, color: Colors.green),
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
                  selected: _statusFilter == 'in_transit',
                  onSelected: (_) => _onFilterChanged('in_transit'),
                  avatar: _statusFilter == 'in_transit' ? const Icon(Icons.check, size: 18) : null,
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
                // Enhanced error handling with specific messages for index errors
                if (snapshot.hasError) {
                  print('❌ Error in StreamBuilder: ${snapshot.error}');
                  
                  final errorMessage = snapshot.error.toString();
                  final isIndexError = errorMessage.contains('index') || 
                                     errorMessage.contains('requires an index');
                  
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isIndexError ? Icons.error_outline : Icons.error,
                            size: 64,
                            color: isIndexError ? Colors.orange : Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isIndexError 
                                ? 'Firestore Index Required' 
                                : 'Error Loading Loads',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isIndexError
                                ? 'A database index needs to be created for this query to work.\n\nStatus filter: $_statusFilter'
                                : 'An error occurred while loading your loads.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (isIndexError) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade300),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'What\'s happening?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'The database needs to be configured to support this filter. '
                                    'Please contact your system administrator or wait a few minutes and try again.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            onPressed: () {
                              setState(() {}); // Force rebuild
                            },
                          ),
                          if (!isIndexError) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                // Show full error in dialog
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Error Details'),
                                    content: SingleChildScrollView(
                                      child: Text(errorMessage),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text('View Details'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final loads = snapshot.data ?? [];

                if (loads.isEmpty) {
                  // Show different messages based on filters with helpful debug info
                  String message;
                  String debugInfo = '';
                  
                  if (_searchQuery.isNotEmpty && _statusFilter != 'all') {
                    message = 'No loads found matching your search and status filter';
                    debugInfo = 'Try clearing the search or changing the status filter.';
                  } else if (_searchQuery.isNotEmpty) {
                    message = 'No loads found matching "$_searchQuery"';
                    debugInfo = 'Try a different search term or clear the search.';
                  } else if (_statusFilter != 'all') {
                    message = 'No loads with status "$_statusFilter"';
                    debugInfo = 'Loads with this status haven\'t been assigned yet.';
                  } else {
                    message = 'No loads assigned yet';
                    debugInfo = 'Your administrator will assign loads to you.';
                  }
                  
                  // Log empty state for debugging
                  print('ℹ️  Empty state: $message');
                  print('   Driver ID: ${widget.driverId}');
                  print('   Status Filter: $_statusFilter');
                  print('   Search Query: ${_searchQuery.isEmpty ? "(none)" : _searchQuery}');
                  
                  return Center(
                    child: Semantics(
                      label: message,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isNotEmpty ? Icons.search_off : Icons.assignment_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            message,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (debugInfo.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32.0),
                              child: Text(
                                debugInfo,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
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
                        label: 'Load ${load.loadNumber.isNotEmpty ? load.loadNumber : "Unknown"}, from ${load.pickupAddress.isNotEmpty ? load.pickupAddress : "Unknown"} to ${load.deliveryAddress.isNotEmpty ? load.deliveryAddress : "Unknown"}, rate ${load.rate} dollars, status ${load.status}. Tap to view details.',
                        button: true,
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            children: [
                              ListTile(
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
                                  load.loadNumber.isNotEmpty ? load.loadNumber : 'Unknown Load',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('From: ${load.pickupAddress.isNotEmpty ? load.pickupAddress : "Unknown"}'),
                                    Text('To: ${load.deliveryAddress.isNotEmpty ? load.deliveryAddress : "Unknown"}'),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          'Rate: \$${load.rate.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const Spacer(),
                                        // Document status indicators
                                        if (load.bolPhotoUrl != null)
                                          Tooltip(
                                            message: 'BOL Uploaded',
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade100,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Icon(
                                                Icons.description,
                                                size: 16,
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                          ),
                                        if (load.bolPhotoUrl != null && load.podPhotoUrl != null)
                                          const SizedBox(width: 4),
                                        if (load.podPhotoUrl != null)
                                          Tooltip(
                                            message: 'POD Uploaded',
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade100,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Icon(
                                                Icons.check_box,
                                                size: 16,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                          ),
                                      ],
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
                                      load.status.isNotEmpty ? load.status : 'unknown',
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
                              // Add Delivered button if load is not already delivered
                              if (load.status != 'delivered')
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        try {
                                          await _firestoreService.markLoadAsDelivered(load.id);
                                          if (mounted) {
                                            NavigationService.showSuccess('Load marked as delivered');
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            NavigationService.showError('Error marking load as delivered: $e');
                                          }
                                        }
                                      },
                                      icon: const Icon(Icons.check_circle),
                                      label: const Text('Mark as Delivered'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
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
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'assigned':
        return Colors.blue;
      case 'in_transit':
        return Colors.purple;
      case 'delivered':
        return Colors.green.shade700;
      case 'declined':
        return Colors.red;
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
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Build status badge for truck status
  Widget _buildTruckStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status) {
      case 'available':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        displayText = 'Available';
        break;
      case 'in_use':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        displayText = 'In Use';
        break;
      case 'maintenance':
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        displayText = 'Maintenance';
        break;
      case 'inactive':
        backgroundColor = Colors.grey.shade300;
        textColor = Colors.grey.shade800;
        displayText = 'Inactive';
        break;
      default:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
