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
  static const double approachingRadius = 500.0; // meters - for "approaching" notifications
  static const double arrivedRadius = 100.0; // meters - for "arrived" status
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

        // Multi-radius detection
        bool isApproaching = distance <= approachingRadius && distance > arrivedRadius;
        bool isArrived = distance <= arrivedRadius;
        bool isInside = distance <= geofence.radius; // Standard radius check

        // Handle approaching zone (500m)
        if (isApproaching && !geofence.isApproaching) {
          await _onGeofenceApproaching(driverId, geofence, position, distance);
          geofence.isApproaching = true;
        } else if (!isApproaching && geofence.isApproaching) {
          geofence.isApproaching = false;
        }

        // Handle arrival zone (100m)
        if (isArrived && !geofence.isArrived) {
          await _onGeofenceArrived(driverId, geofence, position);
          geofence.isArrived = true;
        } else if (!isArrived && geofence.isArrived) {
          geofence.isArrived = false;
        }

        // Handle standard entry/exit events
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

  /// Handle driver approaching geofence (500m radius)
  Future<void> _onGeofenceApproaching(
    String driverId,
    _GeofenceConfig geofence,
    Position position,
    double distance,
  ) async {
    print('🎯 Driver approaching ${geofence.type.name} geofence: ${geofence.id} (${distance.toStringAsFixed(0)}m away)');

    // Log event to Firestore
    await _firestore.collection('geofenceEvents').add({
      'geofenceId': geofence.id,
      'loadId': geofence.loadId,
      'driverId': driverId,
      'type': 'approaching',
      'geofenceType': geofence.type.name,
      'distance': distance,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Send notification about approaching
    print('📱 Send "approaching" notification to driver and admin');
  }

  /// Handle driver arrived at geofence (100m radius)
  Future<void> _onGeofenceArrived(
    String driverId,
    _GeofenceConfig geofence,
    Position position,
  ) async {
    print('🎯 Driver arrived at ${geofence.type.name} geofence: ${geofence.id}');

    // Log event to Firestore
    await _firestore.collection('geofenceEvents').add({
      'geofenceId': geofence.id,
      'loadId': geofence.loadId,
      'driverId': driverId,
      'type': 'arrived',
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

    print('📱 Send "arrived" notification to driver and admin');
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
      // Automatically update load status to "at_pickup"
      await _firestore.collection('loads').doc(loadId).update({
        'status': 'at_pickup',
        'pickupArrivalTime': FieldValue.serverTimestamp(),
        'lastStatusUpdate': FieldValue.serverTimestamp(),
      });

      print('✅ Load $loadId marked as at pickup location');
      
      // Send notification to driver with next steps
      final driverDoc = await _firestore.collection('users').doc(driverId).get();
      final driverData = driverDoc.data();
      
      if (driverData != null && driverData['fcmToken'] != null) {
        // Notification will be sent via Cloud Function
        print('📱 Pickup arrival notification will be sent to driver');
      }
      
      // Log the geofence event for analytics
      await _firestore.collection('geofenceEvents').add({
        'loadId': loadId,
        'driverId': driverId,
        'eventType': 'pickup_arrival',
        'statusChange': 'at_pickup',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error handling pickup arrival: $e');
    }
  }

  /// Handle driver arrival at delivery location
  Future<void> _handleDeliveryArrival(String loadId, String driverId) async {
    try {
      // Automatically update load status to "at_delivery"
      await _firestore.collection('loads').doc(loadId).update({
        'status': 'at_delivery',
        'deliveryArrivalTime': FieldValue.serverTimestamp(),
        'lastStatusUpdate': FieldValue.serverTimestamp(),
      });

      print('✅ Load $loadId marked as at delivery location');
      
      // Send notification to driver to upload POD
      final driverDoc = await _firestore.collection('users').doc(driverId).get();
      final driverData = driverDoc.data();
      
      if (driverData != null && driverData['fcmToken'] != null) {
        // Notification will be sent via Cloud Function
        print('📱 Delivery arrival notification will be sent to driver');
      }
      
      // Log the geofence event for analytics
      await _firestore.collection('geofenceEvents').add({
        'loadId': loadId,
        'driverId': driverId,
        'eventType': 'delivery_arrival',
        'statusChange': 'at_delivery',
        'timestamp': FieldValue.serverTimestamp(),
      });
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
  bool isApproaching;
  bool isArrived;

  _GeofenceConfig({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.type,
    required this.loadId,
    this.isInside = false,
    this.isApproaching = false,
    this.isArrived = false,
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
