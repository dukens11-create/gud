import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../utils/datetime_utils.dart';

/// Live Map Dashboard for Admin
///
/// Displays real-time driver locations using flutter_map (OpenStreetMap):
/// - Shows currently active drivers (status: available / on_trip) with
///   colour-coded markers (green = available, blue = on trip).
/// - Shows recently off-duty drivers — those with status "inactive" whose
///   lastLocation.timestamp is within the last 10 minutes — with an orange
///   marker so admins can see drivers who just logged off.
/// - Streams location updates from Firestore in real-time using two parallel
///   subscriptions (active drivers + inactive drivers).
/// - Shows driver info cards on marker tap.
/// - No Google Maps API key or setup required.
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
///   "status": "available" | "on_trip" | "inactive" | ...,
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

  // Active driver location data: driverId → {lat, lng, ...driverDoc}
  final Map<String, Map<String, dynamic>> _driverData = {};

  // All inactive driver docs (status == 'inactive').
  // Filtered to a 10-minute window in [_recentlyOffDriverData].
  final Map<String, Map<String, dynamic>> _inactiveDriverData = {};

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

  // Drivers who logged out within this window are shown with an orange marker.
  static const Duration _recentlyOffThreshold = Duration(minutes: 10);

  // Active Firestore subscriptions
  StreamSubscription<QuerySnapshot>? _driversSubscription;
  StreamSubscription<QuerySnapshot>? _inactiveDriversSubscription;

  // Periodic timer that forces a re-render so the 10-minute window stays
  // accurate even when no new Firestore events arrive.
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _subscribeToDriverLocations();
    _subscribeToInactiveDrivers();
    // Refresh the 10-minute window filter every minute without a Firestore round-trip.
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      // Empty setState forces _recentlyOffDriverData to be recomputed with the
      // current time, keeping the 10-minute window accurate without an extra
      // Firestore round-trip.
      if (mounted) setState(() {});
    });
    unawaited(_debugActiveDriversQuery());
  }

  @override
  void dispose() {
    _driversSubscription?.cancel();
    _inactiveDriversSubscription?.cancel();
    _refreshTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------------

  /// Subscribe to active driver documents in Firestore and rebuild on change.
  ///
  /// Queries drivers where `active == true` so that all drivers marked as
  /// active are shown regardless of their status field value.  The stream
  /// fires on every Firestore change, keeping the map up-to-date in real time.
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
    // Use the `active` boolean field for real-time filtering of active drivers.
    _driversSubscription = _firestore
        .collection('drivers')
        .where('active', isEqualTo: true)
        .snapshots()
        .listen(
      (snapshot) {
        // Debug: log how many active drivers were returned and their data.
        // Wrapped in kDebugMode so sensitive driver data is never written to
        // production logs.
        if (kDebugMode) {
          debugPrint(
              '📊 [DEBUG] Active drivers fetched (active==true): ${snapshot.docs.length}');
          for (final doc in snapshot.docs) {
            debugPrint('📄 [DEBUG] Driver ${doc.id}: ${doc.data()}');
          }
        }
        setState(() {
          _isLoading = false;
          _errorMessage = null;
          _driverData.clear();
          for (final doc in snapshot.docs) {
            _driverData[doc.id] = doc.data();
          }
          // Dismiss the selected card if that driver is no longer in the list
          if (_selectedDriverId != null &&
              !_driverData.containsKey(_selectedDriverId) &&
              !_inactiveDriverData.containsKey(_selectedDriverId)) {
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

  /// Subscribe to inactive driver documents in Firestore.
  /// The 10-minute window filter is applied in [_recentlyOffDriverData].
  void _subscribeToInactiveDrivers() {
    _inactiveDriversSubscription?.cancel();
    // Query drivers with status == 'inactive' to detect recently logged-out
    // drivers.  The 10-minute window is applied client-side in
    // [_recentlyOffDriverData] because Firestore cannot filter on a nested
    // timestamp field.
    _inactiveDriversSubscription = _firestore
        .collection('drivers')
        .where('status', isEqualTo: 'inactive')
        .snapshots()
        .listen(
      (snapshot) {
        // Debug: log how many inactive drivers were returned.
        if (kDebugMode) {
          debugPrint(
              '📊 [DEBUG] Inactive drivers fetched (status==inactive): ${snapshot.docs.length}');
        }
        setState(() {
          _inactiveDriverData.clear();
          for (final doc in snapshot.docs) {
            _inactiveDriverData[doc.id] = doc.data();
          }
          // Dismiss the selected card if that driver is no longer in either list
          if (_selectedDriverId != null &&
              !_driverData.containsKey(_selectedDriverId) &&
              !_inactiveDriverData.containsKey(_selectedDriverId)) {
            _selectedDriverId = null;
          }
        });
      },
      onError: (Object error) {
        debugPrint('⚠️ AdminMapDashboard inactive-drivers stream error: $error');
      },
    );
  }

  /// Inactive drivers whose [lastLocation.timestamp] is within the last
  /// [_recentlyOffThreshold] (10 minutes).  These are shown with an orange
  /// marker so admins can see recently logged-out drivers.
  Map<String, Map<String, dynamic>> get _recentlyOffDriverData {
    final cutoff = DateTime.now().subtract(_recentlyOffThreshold);
    return Map.fromEntries(
      _inactiveDriverData.entries.where((entry) {
        final loc = entry.value['lastLocation'];
        if (loc == null) return false;
        final ts = loc['timestamp'];
        if (ts == null) return false;
        try {
          final dt = DateTimeUtils.parseDateTime(ts);
          return dt != null && dt.isAfter(cutoff);
        } catch (_) {
          return false;
        }
      }),
    );
  }

  /// Restart both Firestore subscriptions (called by the refresh button).
  void _refreshAll() {
    _subscribeToDriverLocations();
    _subscribeToInactiveDrivers();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Debug helper: queries `.collection('drivers').where('isActive', isEqualTo: true)`
  /// and prints the current user UID, the returned document count, and each
  /// document's data to the console.  Call from [initState] or any button to
  /// diagnose why active drivers may not appear on the dashboard.
  /// Only runs in debug builds ([kDebugMode]).
  Future<void> _debugActiveDriversQuery() async {
    if (!kDebugMode) return;
    debugPrint('🔍 [DEBUG] Running active-drivers query...');
    final uid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('🔑 [DEBUG] Current FirebaseAuth UID: $uid');
    try {
      final snapshot = await _firestore
          .collection('drivers')
          .where('isActive', isEqualTo: true)
          .get();
      debugPrint(
          '📊 [DEBUG] Active drivers (isActive==true) count: ${snapshot.docs.length}');
      for (final doc in snapshot.docs) {
        debugPrint('📄 [DEBUG] Driver ${doc.id}: ${doc.data()}');
      }
    } catch (e) {
      debugPrint('❌ [DEBUG] Error querying active drivers: $e');
    }
  }

  /// Returns the [LatLng] for a driver, or null if no location data exists.
  ///
  /// Supports two Firestore document shapes:
  ///   1. Top-level fields:  `{ "lat": 39.8, "lng": -98.5, ... }`
  ///   2. Nested sub-map:    `{ "lastLocation": { "lat": 39.8, "lng": -98.5 } }`
  /// The top-level fields are checked first; the nested map is used as a fallback.
  LatLng? _latLngForDriver(Map<String, dynamic> data) {
    // 1. Top-level lat/lng fields (some older driver documents use this shape).
    final topLat = data['lat'];
    final topLng = data['lng'];
    if (topLat != null && topLng != null) {
      return LatLng((topLat as num).toDouble(), (topLng as num).toDouble());
    }

    // 2. Nested lastLocation map (current standard shape).
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
      case 'on_trip':
        return Colors.blue;
      default:
        return Colors.red;
    }
  }

  /// Returns the marker colour for a recently off-duty driver.
  static const Color _recentlyOffMarkerColor = Colors.orange;

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

  List<Marker> _buildMarkers(Map<String, Map<String, dynamic>> recentlyOff) {
    final markers = <Marker>[];

    // Active drivers (available / on_trip)
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

    // Recently off-duty drivers (inactive, logged out within 10 minutes)
    for (final entry in recentlyOff.entries) {
      final driverId = entry.key;
      final data = entry.value;
      final point = _latLngForDriver(data);
      if (point == null) continue;

      markers.add(
        Marker(
          point: point,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => setState(() => _selectedDriverId = driverId),
            child: const Icon(
              Icons.location_off,
              color: _recentlyOffMarkerColor,
              size: 40,
            ),
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
    final data = _driverData[driverId] ?? _recentlyOffDriverData[driverId];
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

  Widget _buildDriverInfoCard(Map<String, Map<String, dynamic>> recentlyOff) {
    if (_selectedDriverId == null) return const SizedBox.shrink();

    final isRecentlyOff = recentlyOff.containsKey(_selectedDriverId);
    final driver = isRecentlyOff
        ? recentlyOff[_selectedDriverId]
        : _driverData[_selectedDriverId];

    if (driver == null) return const SizedBox.shrink();

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver['name'] as String? ?? 'Unknown Driver',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        if (isRecentlyOff)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: const Text(
                              'Recently Off-Duty',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedDriverId = null),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.local_shipping,
                  'Truck: ${driver['truckNumber'] ?? 'N/A'}'),
              _buildInfoRow(
                  Icons.phone, driver['phone'] as String? ?? 'N/A'),
              _buildInfoRow(
                isRecentlyOff ? Icons.logout : Icons.circle,
                isRecentlyOff
                    ? 'Status: Logged Out'
                    : 'Status: ${_formatStatus(driver['status'] as String?)}',
                statusColor: isRecentlyOff
                    ? Colors.orange
                    : _getStatusColor(driver['status'] as String?),
              ),
              if (lastUpdate != null)
                _buildInfoRow(
                  Icons.access_time,
                  isRecentlyOff
                      ? 'Logged out: ${_formatTime(lastUpdate)}'
                      : 'Last update: ${_formatTime(lastUpdate)}',
                ),
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
  // Map legend
  // ---------------------------------------------------------------------------

  Widget _buildLegend() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Legend',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            _buildLegendRow(Icons.location_pin, Colors.green, 'Available'),
            _buildLegendRow(Icons.location_pin, Colors.blue, 'On Trip'),
            _buildLegendRow(
                Icons.location_off, Colors.orange, 'Recently Off-Duty\n(< 10 min)'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendRow(IconData icon, Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Compute the recently-off map once per build to ensure a single
    // consistent cutoff time is used across markers, info card, and counters.
    final recentlyOff = _recentlyOffDriverData;
    final activeCount =
        _driverData.values.where((d) => _latLngForDriver(d) != null).length;
    final recentlyOffCount =
        recentlyOff.values.where((d) => _latLngForDriver(d) != null).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Driver Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
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
              MarkerLayer(markers: _buildMarkers(recentlyOff)),
            ],
          ),
          _buildDriverInfoCard(recentlyOff),
          // Stats card (top-right)
          Positioned(
            top: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$activeCount',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Text('Active', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    Text(
                      '$recentlyOffCount',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const Text('Recently Off',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
          // Legend (top-left)
          Positioned(
            top: 16,
            left: 16,
            child: _buildLegend(),
          ),
          // Loading indicator while waiting for the first snapshot
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          // Warning banner shown when loading is complete but no active drivers
          // were returned.  This helps admins distinguish between "no drivers
          // are active right now" and a misconfiguration or Firestore-rules issue.
          if (!_isLoading && _errorMessage == null && _driverData.isEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: Colors.orange.shade700,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.white),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'No active drivers found. '
                          'Verify that driver documents have active: true set in Firestore.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        tooltip: 'Retry',
                        onPressed: _refreshAll,
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
                        onPressed: _refreshAll,
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
