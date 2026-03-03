import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../utils/datetime_utils.dart';

/// Live Map Dashboard for Admin
///
/// Displays real-time driver locations using flutter_map (OpenStreetMap):
/// - Shows all active drivers with colour-coded markers
/// - Streams location updates from Firestore in real-time
/// - Shows driver info cards on marker tap
/// - No Google Maps API key or setup required
///
/// Dependencies:
///   flutter_map: ^8.2.2  (pub.dev/packages/flutter_map)
///   latlong2: ^0.9.1     (pub.dev/packages/latlong2)
///   cloud_firestore: (already in project)
///
/// Firestore data shape expected on each driver document:
/// ```
/// {
///   "name": "John Doe",
///   "truckNumber": "T-42",
///   "phone": "+1 555-0100",
///   "status": "available" | "on_duty" | "in_transit" | ...,
///   "lastLocation": {
///     "lat": 39.8,
///     "lng": -98.5,
///     "accuracy": 10.0,          // optional, metres
///     "timestamp": <Timestamp>   // optional
///   }
/// }
/// ```
///
/// Navigation:
///   Named route '/admin/map' defined in lib/routes.dart.
///   Accessible from the Admin Home drawer under "Live Driver Map".
///   Only reachable after admin login (routing enforced by LoginScreen).
class AdminMapDashboardScreen extends StatefulWidget {
  const AdminMapDashboardScreen({super.key});

  @override
  State<AdminMapDashboardScreen> createState() => _AdminMapDashboardScreenState();
}

class _AdminMapDashboardScreenState extends State<AdminMapDashboardScreen> {
  final MapController _mapController = MapController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Driver location data: driverId → {lat, lng, ...driverDoc}
  final Map<String, Map<String, dynamic>> _driverData = {};

  // Selected driver id for the info card
  String? _selectedDriverId;

  // True while waiting for the first Firestore snapshot
  bool _isLoading = true;

  // Non-null when the Firestore stream last emitted an error
  String? _errorMessage;

  // Initial map centre (geographic centre of the contiguous USA)
  static const LatLng _initialCenter = LatLng(39.8283, -98.5795);
  static const double _initialZoom = 4.0;

  // Package name used as the OSM tile layer user-agent identifier
  static const String _tileUserAgent = 'com.gudexpress.app';

  // Active Firestore subscription
  StreamSubscription<QuerySnapshot>? _driversSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToDriverLocations();
  }

  @override
  void dispose() {
    _driversSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------------

  /// Subscribe to active driver documents in Firestore and rebuild on change.
  void _subscribeToDriverLocations() {
    _driversSubscription?.cancel();
    // Clear stale data and reset selection immediately so the UI reflects
    // that a fresh load is in progress.
    setState(() {
      _driverData.clear();
      _selectedDriverId = null;
      _isLoading = true;
      _errorMessage = null;
    });
    _driversSubscription = _firestore
        .collection('drivers')
        .where('status', whereIn: ['available', 'on_duty', 'in_transit'])
        .snapshots()
        .listen(
      (snapshot) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
          _driverData.clear();
          for (final doc in snapshot.docs) {
            _driverData[doc.id] = doc.data();
          }
          // Dismiss the selected card if that driver is no longer in the list
          if (_selectedDriverId != null &&
              !_driverData.containsKey(_selectedDriverId)) {
            _selectedDriverId = null;
          }
        });
      },
      onError: (Object error) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not load driver locations. '
              'Check your connection and retry.';
        });
        debugPrint('⚠️ AdminMapDashboard stream error: $error');
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns the [LatLng] for a driver, or null if no location data exists.
  LatLng? _latLngForDriver(Map<String, dynamic> data) {
    final loc = data['lastLocation'];
    if (loc == null) return null;
    final lat = loc['lat'];
    final lng = loc['lng'];
    if (lat == null || lng == null) return null;
    return LatLng((lat as num).toDouble(), (lng as num).toDouble());
  }

  /// Returns the icon colour for a driver's status.
  Color _markerColor(String? status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'on_duty':
        return Colors.blue;
      case 'in_transit':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String _formatStatus(String? status) {
    if (status == null) return 'Unknown';
    return status.split('_').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '').join(' ').trim();
  }

  Color _getStatusColor(String? status) => _markerColor(status);

  String _formatTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ---------------------------------------------------------------------------
  // Map marker list
  // ---------------------------------------------------------------------------

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    for (final entry in _driverData.entries) {
      final driverId = entry.key;
      final data = entry.value;
      final point = _latLngForDriver(data);
      if (point == null) continue;

      final color = _markerColor(data['status'] as String?);
      markers.add(
        Marker(
          point: point,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => setState(() => _selectedDriverId = driverId),
            child: Icon(Icons.location_pin, color: color, size: 40),
          ),
        ),
      );
    }
    return markers;
  }

  // ---------------------------------------------------------------------------
  // UI helpers
  // ---------------------------------------------------------------------------

  void _centerOnDriver(String driverId) {
    final data = _driverData[driverId];
    if (data == null) return;
    final point = _latLngForDriver(data);
    if (point != null) {
      _mapController.move(point, 15.0);
    }
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: statusColor ?? Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: statusColor)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Driver info card (shown when a marker is tapped)
  // ---------------------------------------------------------------------------

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
      } catch (_) {
        // Ignore parse errors
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
                    driver['name'] as String? ?? 'Unknown Driver',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedDriverId = null),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.local_shipping, 'Truck: ${driver['truckNumber'] ?? 'N/A'}'),
              _buildInfoRow(Icons.phone, driver['phone'] as String? ?? 'N/A'),
              _buildInfoRow(
                Icons.circle,
                'Status: ${_formatStatus(driver['status'] as String?)}',
                statusColor: _getStatusColor(driver['status'] as String?),
              ),
              if (lastUpdate != null)
                _buildInfoRow(Icons.access_time, 'Last update: ${_formatTime(lastUpdate)}'),
              if (lastLocation?['accuracy'] != null)
                _buildInfoRow(
                  Icons.my_location,
                  'Accuracy: ${(lastLocation['accuracy'] as num).toStringAsFixed(0)}m',
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final markerCount = _driverData.values
        .where((d) => _latLngForDriver(d) != null)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Driver Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _subscribeToDriverLocations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _initialCenter,
              initialZoom: _initialZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: _tileUserAgent,
              ),
              MarkerLayer(markers: _buildMarkers()),
            ],
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
                      '$markerCount',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Active Drivers', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          // Loading indicator while waiting for the first snapshot
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          // Error banner shown when the Firestore stream emits an error
          if (_errorMessage != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: Colors.red.shade700,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        tooltip: 'Retry',
                        onPressed: _subscribeToDriverLocations,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        tooltip: 'Dismiss',
                        onPressed: () =>
                            setState(() => _errorMessage = null),
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
