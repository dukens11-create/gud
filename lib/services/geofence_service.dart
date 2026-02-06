import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Geofencing Service
/// 
/// Manages geofences for pickup and delivery locations.
/// Automatically triggers actions when drivers enter/exit zones:
/// - Auto-update load status on arrival
/// - Send notifications
/// - Log location events
/// 
/// Setup Requirements:
/// 1. Add geofence_service dependency
/// 2. Configure background location permissions
/// 3. Set up Firestore triggers for geofence events
/// 
/// TODO: Integrate geofence_service package for production
/// TODO: Implement battery-efficient monitoring
/// TODO: Add geofence persistence across app restarts
/// TODO: Implement geofence analytics and reporting
class GeofenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, _GeofenceConfig> _activeGeofences = {};
  Timer? _monitoringTimer;

  // Configuration
  static const double defaultRadius = 200.0; // meters
  static const Duration monitoringInterval = Duration(seconds: 30);

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

    print('✅ Delivery geofence created: $geofenceId');
    return geofenceId;
  }

  /// Start monitoring geofences for a driver
  Future<void> startMonitoring(String driverId) async {
    print('🔍 Starting geofence monitoring for driver: $driverId');

    // Load active geofences from Firestore
    await _loadActiveGeofences(driverId);

    // Start periodic monitoring
    _monitoringTimer?.cancel();
    _monitoringTimer = Timer.periodic(
      monitoringInterval,
      (_) => _checkGeofences(driverId),
    );

    // TODO: Use geofence_service package for production
    // Example:
    // GeofenceService.instance.setup(
    //   interval: 5000,
    //   accuracy: 100,
    //   loiteringDelayMs: 60000,
    //   statusChangeDelayMs: 10000,
    //   useActivityRecognition: true,
    //   allowMockLocations: false,
    //   printDevLog: false,
    //   geofenceRadiusSortType: GeofenceRadiusSortType.DESC
    // );
  }

  /// Stop monitoring geofences
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    print('✅ Geofence monitoring stopped');
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

    // Trigger automatic actions based on geofence type
    if (geofence.type == GeofenceType.pickup) {
      await _handlePickupArrival(geofence.loadId, driverId);
    } else if (geofence.type == GeofenceType.delivery) {
      await _handleDeliveryArrival(geofence.loadId, driverId);
    }

    // TODO: Send push notification to driver
    // "You've arrived at the pickup location for Load #123"
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

    // TODO: Implement exit actions if needed
    // For example: Alert if driver leaves delivery location without completing POD
  }

  /// Handle driver arrival at pickup location
  Future<void> _handlePickupArrival(String loadId, String driverId) async {
    try {
      // Automatically update load status to "picked_up"
      await _firestore.collection('loads').doc(loadId).update({
        'status': 'picked_up',
        'pickedUpAt': FieldValue.serverTimestamp(),
      });

      print('✅ Load $loadId marked as picked up');
      
      // Store geofence event for tracking
      await _firestore.collection('geofenceEvents').add({
        'loadId': loadId,
        'driverId': driverId,
        'type': 'pickup_arrival',
        'status': 'picked_up',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // NOTE: Push notifications handled by NotificationService
      // Would integrate with notification_service.dart in production
    } catch (e) {
      print('❌ Error handling pickup arrival: $e');
    }
  }

  /// Handle driver arrival at delivery location
  Future<void> _handleDeliveryArrival(String loadId, String driverId) async {
    try {
      // Automatically update load status to "in_transit" (at delivery location)
      await _firestore.collection('loads').doc(loadId).update({
        'status': 'in_transit',
        'arrivedAtDeliveryAt': FieldValue.serverTimestamp(),
      });

      print('✅ Load $loadId marked as at delivery location');
      
      // Store geofence event for tracking
      await _firestore.collection('geofenceEvents').add({
        'loadId': loadId,
        'driverId': driverId,
        'type': 'delivery_arrival',
        'status': 'at_delivery',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // NOTE: Push notifications for POD upload handled by NotificationService
      // Would integrate with notification_service.dart in production
    } catch (e) {
      print('❌ Error handling delivery arrival: $e');
    }
  }

  /// Remove geofence
  Future<void> removeGeofence(String geofenceId) async {
    _activeGeofences.remove(geofenceId);
    
    await _firestore.collection('geofences').doc(geofenceId).update({
      'active': false,
      'deactivatedAt': FieldValue.serverTimestamp(),
    });

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

/// Geofence types
enum GeofenceType {
  pickup,
  delivery,
}

// TODO: Add geofence analytics dashboard
// Track:
// - Average time in pickup/delivery zones
// - Number of entries/exits
// - False positive rate
// - Battery impact metrics

// TODO: Implement smart geofence sizing
// Adjust radius based on:
// - Location accuracy
// - Urban vs rural areas
// - Traffic conditions
// - Time of day

// TODO: Add compound geofences
// Support multiple zones for large facilities:
// - Warehouse loading dock
// - Parking area
// - Security checkpoint

// TODO: Implement geofence sharing
// Allow admins to:
// - Create reusable location templates
// - Share geofences across loads
// - Manage location database
