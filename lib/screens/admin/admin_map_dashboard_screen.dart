import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../utils/datetime_utils.dart';

/// Live Map Dashboard for Admin
/// 
/// Displays real-time driver locations on Google Maps:
/// - Shows all active drivers with markers
/// - Updates locations in real-time
/// - Shows driver info cards on marker tap
/// - Filters drivers by status
/// - Tracks driver routes (optional)
/// 
/// Setup Requirements:
/// 1. Enable Google Maps API in Google Cloud Console
/// 2. Add API keys to Android/iOS configurations
/// 3. Enable required Google Maps APIs (Maps SDK, Geocoding, etc.)
/// 
/// TODO: Add driver route history display
/// TODO: Implement cluster markers for multiple drivers
/// TODO: Add traffic layer toggle
/// TODO: Implement driver search and filtering
/// TODO: Add distance calculations and ETAs
class AdminMapDashboardScreen extends StatefulWidget {
  const AdminMapDashboardScreen({super.key});

  @override
  State<AdminMapDashboardScreen> createState() => _AdminMapDashboardScreenState();
}

class _AdminMapDashboardScreenState extends State<AdminMapDashboardScreen> {
  GoogleMapController? _mapController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Map markers for drivers
  final Map<String, Marker> _markers = {};
  
  // Driver data
  final Map<String, Map<String, dynamic>> _driverData = {};
  
  // Selected driver
  String? _selectedDriverId;
  
  // Map camera position
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(39.8283, -98.5795), // Center of USA
    zoom: 4,
  );

  // Stream subscriptions
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _loadDriverLocations();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  /// Load and stream driver locations
  void _loadDriverLocations() {
    // Stream all active drivers
    final driversStream = _firestore
        .collection('drivers')
        .where('status', whereIn: ['available', 'on_duty', 'in_transit'])
        .snapshots();

    final subscription = driversStream.listen((snapshot) {
      setState(() {
        _markers.clear();
        _driverData.clear();

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final driverId = doc.id;
          
          // Store driver data
          _driverData[driverId] = data;

          // Create marker if driver has location
          final lastLocation = data['lastLocation'];
          if (lastLocation != null && 
              lastLocation['lat'] != null && 
              lastLocation['lng'] != null) {
            
            final marker = Marker(
              markerId: MarkerId(driverId),
              position: LatLng(
                lastLocation['lat'].toDouble(),
                lastLocation['lng'].toDouble(),
              ),
              infoWindow: InfoWindow(
                title: data['name'] ?? 'Unknown Driver',
                snippet: 'Truck: ${data['truckNumber'] ?? 'N/A'}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                _getMarkerColor(data['status']),
              ),
              onTap: () => _onMarkerTapped(driverId),
            );

            _markers[driverId] = marker;
          }
        }
      });

      // Center map on first driver if available
      if (_markers.isNotEmpty && _mapController != null) {
        final firstMarker = _markers.values.first;
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(firstMarker.position, 10),
        );
      }
    });

    _subscriptions.add(subscription);
  }

  /// Get marker color based on driver status
  double _getMarkerColor(String? status) {
    switch (status) {
      case 'available':
        return BitmapDescriptor.hueGreen;
      case 'on_duty':
        return BitmapDescriptor.hueBlue;
      case 'in_transit':
        return BitmapDescriptor.hueOrange;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  /// Handle marker tap
  void _onMarkerTapped(String driverId) {
    setState(() {
      _selectedDriverId = driverId;
    });
  }

  /// Build driver info card
  Widget _buildDriverInfoCard() {
    if (_selectedDriverId == null || !_driverData.containsKey(_selectedDriverId)) {
      return const SizedBox.shrink();
    }

    final driver = _driverData[_selectedDriverId]!;
    final lastLocation = driver['lastLocation'];
    
    DateTime? lastUpdate;
    if (lastLocation?['timestamp'] != null) {
      try {
        lastUpdate = DateTimeUtils.parseDateTime(lastLocation['timestamp']);
      } catch (e) {
        // Handle parse error
      }
    }

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    driver['name'] ?? 'Unknown Driver',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _selectedDriverId = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.local_shipping, 'Truck: ${driver['truckNumber'] ?? 'N/A'}'),
              _buildInfoRow(Icons.phone, driver['phone'] ?? 'N/A'),
              _buildInfoRow(
                Icons.circle,
                'Status: ${_formatStatus(driver['status'])}',
                statusColor: _getStatusColor(driver['status']),
              ),
              if (lastUpdate != null)
                _buildInfoRow(
                  Icons.access_time,
                  'Last update: ${_formatTime(lastUpdate)}',
                ),
              if (lastLocation?['accuracy'] != null)
                _buildInfoRow(
                  Icons.my_location,
                  'Accuracy: ${lastLocation['accuracy'].toStringAsFixed(0)}m',
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _centerOnDriver(_selectedDriverId!),
                      icon: const Icon(Icons.my_location),
                      label: const Text('Center'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _viewDriverDetails(_selectedDriverId!),
                      icon: const Icon(Icons.info),
                      label: const Text('Details'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: statusColor ?? Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatStatus(String? status) {
    if (status == null) return 'Unknown';
    return status.split('_').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'on_duty':
        return Colors.blue;
      case 'in_transit':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _centerOnDriver(String driverId) {
    final marker = _markers[driverId];
    if (marker != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(marker.position, 15),
      );
    }
  }

  void _viewDriverDetails(String driverId) {
    // TODO: Navigate to driver details screen
    print('View details for driver: $driverId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Driver Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDriverLocations,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Show filter dialog
            },
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            markers: Set<Marker>.of(_markers.values),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
          ),
          _buildDriverInfoCard(),
          Positioned(
            top: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(
                      '${_markers.length}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Active Drivers',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// TODO: Add map controls
// - Toggle traffic layer
// - Toggle satellite view
// - Show/hide driver names
// - Filter by status
// - Search drivers

// TODO: Implement driver route history
// Show breadcrumb trail of recent locations
// Display route polylines
// Show stops and waypoints

// TODO: Add clustering for many drivers
// Use marker clustering when zoomed out
// Show driver count in cluster
// Expand cluster on zoom

// TODO: Implement geofence visualization
// Show pickup/delivery zone circles
// Highlight active geofences
// Display geofence events

// TODO: Add distance and ETA calculations
// Calculate distance from driver to destination
// Show estimated time of arrival
// Display route optimization suggestions

// TODO: Implement heat map layer
// Show driver density
// Highlight busy areas
// Visualize coverage gaps

// TODO: Add real-time notifications
// Alert when driver enters/exits zones
// Notify on location updates
// Show connection status
