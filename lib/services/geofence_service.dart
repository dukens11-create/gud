import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/analytics_service.dart';

/// Geofencing Service
/// 
/// Manages geofences for pickup and delivery locations with:
/// - Battery-efficient monitoring
/// - Geofence persistence across app restarts
/// - Automatic load status updates
/// - Event logging and analytics
/// - Configurable monitoring intervals
class GeofenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService();
  final Map<String, _GeofenceConfig> _activeGeofences = {};
  Timer? _monitoringTimer;
  String? _currentDriverId;
  bool _isBatteryOptimized = false;

  // Configuration
  static const double defaultRadius = 200.0; // meters
  static const Duration monitoringInterval = Duration(seconds: 30);
  static const Duration batteryOptimizedInterval = Duration(minutes: 2);
  static const String prefsKeyPrefix = 'geofence_';

  /// Configure battery optimization
  void setBatteryOptimization(bool enabled) {
    _isBatteryOptimized = enabled;
    if (_monitoringTimer != null && _currentDriverId != null) {
      // Restart monitoring with new interval
      stopMonitoring();
      startMonitoring(_currentDriverId!);
    }
  }

  /// Create geofence for a load's pickup location
  Future<String> createPickupGeofence({
    required String loadId,
    required double latitude,
    required double longitude,
    double radius = defaultRadius,
  }) async {
    final geofenceId = 'pickup_$loadId';
    
    final geofence = _GeofenceConfig(
      id: geofenceId,
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      type: GeofenceType.pickup,
      loadId: loadId,
    );

    _activeGeofences[geofenceId] = geofence;
    
    // Save to Firestore
    await _firestore.collection('geofences').doc(geofenceId).set({
      'id': geofenceId,
      'loadId': loadId,
      'type': 'pickup',
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Persist to local storage
    await _saveGeofenceToLocal(geofence);

    // Log to analytics
    await _analytics.logCustomEvent('geofence_created', parameters: {
      'geofence_id': geofenceId,
      'type': 'pickup',
      'load_id': loadId,
    });

    print('✅ Pickup geofence created: $geofenceId');
    return geofenceId;
  }

  /// Create geofence for a load's delivery location
  Future<String> createDeliveryGeofence({
    required String loadId,
    required double latitude,
    required double longitude,
    double radius = defaultRadius,
  }) async {
    final geofenceId = 'delivery_$loadId';
    
    final geofence = _GeofenceConfig(
      id: geofenceId,
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      type: GeofenceType.delivery,
      loadId: loadId,
    );

    _activeGeofences[geofenceId] = geofence;
    
    // Save to Firestore
    await _firestore.collection('geofences').doc(geofenceId).set({
      'id': geofenceId,
      'loadId': loadId,
      'type': 'delivery',
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Persist to local storage
    await _saveGeofenceToLocal(geofence);

    // Log to analytics
    await _analytics.logCustomEvent('geofence_created', parameters: {
      'geofence_id': geofenceId,
      'type': 'delivery',
      'load_id': loadId,
    });

    print('✅ Delivery geofence created: $geofenceId');
    return geofenceId;
  }

  /// Start monitoring geofences for a driver
  Future<void> startMonitoring(String driverId) async {
    _currentDriverId = driverId;
    print('🔍 Starting geofence monitoring for driver: $driverId');

    // Load persisted geofences first
    await _loadGeofencesFromLocal();
    
    // Load active geofences from Firestore
    await _loadActiveGeofences(driverId);

    // Start periodic monitoring with battery optimization
    _monitoringTimer?.cancel();
    final interval = _isBatteryOptimized ? batteryOptimizedInterval : monitoringInterval;
    _monitoringTimer = Timer.periodic(
      interval,
      (_) => _checkGeofences(driverId),
    );

    print('✅ Monitoring started with ${_isBatteryOptimized ? "battery-optimized" : "normal"} interval');
  }

  /// Stop monitoring geofences
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    _currentDriverId = null;
    print('✅ Geofence monitoring stopped');
  }

  /// Save geofence to local storage for persistence
  Future<void> _saveGeofenceToLocal(_GeofenceConfig geofence) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$prefsKeyPrefix${geofence.id}';
      final data = '${geofence.latitude},${geofence.longitude},${geofence.radius},${geofence.type.name},${geofence.loadId}';
      await prefs.setString(key, data);
    } catch (e) {
      print('❌ Error saving geofence to local storage: $e');
    }
  }

  /// Load geofences from local storage
  Future<void> _loadGeofencesFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(prefsKeyPrefix));
      
      for (final key in keys) {
        final geofenceId = key.substring(prefsKeyPrefix.length);
        final data = prefs.getString(key);
        
        if (data != null) {
          final parts = data.split(',');
          if (parts.length == 5) {
            _activeGeofences[geofenceId] = _GeofenceConfig(
              id: geofenceId,
              latitude: double.parse(parts[0]),
              longitude: double.parse(parts[1]),
              radius: double.parse(parts[2]),
              type: parts[3] == 'pickup' ? GeofenceType.pickup : GeofenceType.delivery,
              loadId: parts[4],
            );
          }
        }
      }
      
      print('✅ Loaded ${_activeGeofences.length} geofences from local storage');
    } catch (e) {
      print('❌ Error loading geofences from local storage: $e');
    }
  }

  /// Load active geofences for driver's assigned loads
  Future<void> _loadActiveGeofences(String driverId) async {
    try {
      // Get driver's active loads
      final loadsSnapshot = await _firestore
          .collection('loads')
          .where('driverId', isEqualTo: driverId)
          .where('status', whereIn: ['assigned', 'in_transit'])
          .get();

      // Load geofences for each active load
      for (final loadDoc in loadsSnapshot.docs) {
        final loadId = loadDoc.id;
        
        final geofencesSnapshot = await _firestore
            .collection('geofences')
            .where('loadId', isEqualTo: loadId)
            .where('active', isEqualTo: true)
            .get();

        for (final geoDoc in geofencesSnapshot.docs) {
          final data = geoDoc.data();
          _activeGeofences[data['id']] = _GeofenceConfig(
            id: data['id'],
            latitude: data['latitude'],
            longitude: data['longitude'],
            radius: data['radius'],
            type: data['type'] == 'pickup' 
                ? GeofenceType.pickup 
                : GeofenceType.delivery,
            loadId: data['loadId'],
          );
        }
      }

      print('✅ Loaded ${_activeGeofences.length} active geofences');
    } catch (e) {
      print('❌ Error loading geofences: $e');
    }
  }

  /// Check if driver is inside any geofences
  Future<void> _checkGeofences(String driverId) async {
    try {
      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Check each active geofence
      for (final entry in _activeGeofences.entries) {
        final geofence = entry.value;
        
        // Calculate distance to geofence center
        double distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          geofence.latitude,
          geofence.longitude,
        );

        bool isInside = distance <= geofence.radius;

        // Check for entry/exit events
        if (isInside && !geofence.isInside) {
          await _onGeofenceEnter(driverId, geofence, position);
          geofence.isInside = true;
        } else if (!isInside && geofence.isInside) {
          await _onGeofenceExit(driverId, geofence, position);
          geofence.isInside = false;
        }
      }
    } catch (e) {
      print('❌ Error checking geofences: $e');
    }
  }

  /// Handle geofence entry event
  Future<void> _onGeofenceEnter(
    String driverId,
    _GeofenceConfig geofence,
    Position position,
  ) async {
    print('🎯 Driver entered ${geofence.type.name} geofence: ${geofence.id}');

    // Log event to Firestore
    await _firestore.collection('geofenceEvents').add({
      'geofenceId': geofence.id,
      'loadId': geofence.loadId,
      'driverId': driverId,
      'type': 'enter',
      'geofenceType': geofence.type.name,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Log to analytics
    await _analytics.logGeofenceEntry(
      loadId: geofence.loadId,
      geofenceType: geofence.type.name,
    );

    // Trigger automatic actions based on geofence type
    if (geofence.type == GeofenceType.pickup) {
      await _handlePickupArrival(geofence.loadId, driverId);
    } else if (geofence.type == GeofenceType.delivery) {
      await _handleDeliveryArrival(geofence.loadId, driverId);
    }
  }

  /// Handle geofence exit event
  Future<void> _onGeofenceExit(
    String driverId,
    _GeofenceConfig geofence,
    Position position,
  ) async {
    print('🎯 Driver exited ${geofence.type.name} geofence: ${geofence.id}');

    // Log event to Firestore
    await _firestore.collection('geofenceEvents').add({
      'geofenceId': geofence.id,
      'loadId': geofence.loadId,
      'driverId': driverId,
      'type': 'exit',
      'geofenceType': geofence.type.name,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Log to analytics
    await _analytics.logGeofenceExit(
      loadId: geofence.loadId,
      geofenceType: geofence.type.name,
    );
  }

  /// Handle driver arrival at pickup location
  Future<void> _handlePickupArrival(String loadId, String driverId) async {
    try {
      // Automatically update load status to "at_pickup"
      await _firestore.collection('loads').doc(loadId).update({
        'status': 'at_pickup',
        'pickupArrivalTime': FieldValue.serverTimestamp(),
      });

      print('✅ Load $loadId marked as at pickup location');
      
      // Log to analytics
      await _analytics.logLoadStatusChanged(
        loadId: loadId,
        oldStatus: 'in_transit',
        newStatus: 'at_pickup',
      );
    } catch (e) {
      print('❌ Error handling pickup arrival: $e');
      await _analytics.logError(error: 'Geofence pickup arrival error: $e');
    }
  }

  /// Handle driver arrival at delivery location
  Future<void> _handleDeliveryArrival(String loadId, String driverId) async {
    try {
      // Automatically update load status to "at_delivery"
      await _firestore.collection('loads').doc(loadId).update({
        'status': 'at_delivery',
        'deliveryArrivalTime': FieldValue.serverTimestamp(),
      });

      print('✅ Load $loadId marked as at delivery location');
      
      // Log to analytics
      await _analytics.logLoadStatusChanged(
        loadId: loadId,
        oldStatus: 'in_transit',
        newStatus: 'at_delivery',
      );
    } catch (e) {
      print('❌ Error handling delivery arrival: $e');
      await _analytics.logError(error: 'Geofence delivery arrival error: $e');
    }
  }

  /// Remove geofence
  Future<void> removeGeofence(String geofenceId) async {
    _activeGeofences.remove(geofenceId);
    
    await _firestore.collection('geofences').doc(geofenceId).update({
      'active': false,
      'deactivatedAt': FieldValue.serverTimestamp(),
    });

    // Remove from local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$prefsKeyPrefix$geofenceId');

    print('✅ Geofence removed: $geofenceId');
  }

  /// Remove all geofences for a load
  Future<void> removeLoadGeofences(String loadId) async {
    final pickupId = 'pickup_$loadId';
    final deliveryId = 'delivery_$loadId';
    
    await removeGeofence(pickupId);
    await removeGeofence(deliveryId);
  }

  /// Get geofence events for a load
  Future<List<Map<String, dynamic>>> getLoadGeofenceEvents(String loadId) async {
    final snapshot = await _firestore
        .collection('geofenceEvents')
        .where('loadId', isEqualTo: loadId)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Clean up resources
  void dispose() {
    stopMonitoring();
  }
}

/// Geofence configuration
class _GeofenceConfig {
  final String id;
  final double latitude;
  final double longitude;
  final double radius;
  final GeofenceType type;
  final String loadId;
  bool isInside;

  _GeofenceConfig({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.type,
    required this.loadId,
    this.isInside = false,
  });
}

enum GeofenceType {
  pickup,
  delivery,
}
