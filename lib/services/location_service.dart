import 'package:geolocator/geolocator.dart';

/// Location service for GPS positioning and location permissions.
/// 
/// Provides:
/// - Current location retrieval
/// - Location permission management
/// - Location service status checking
/// - Position data formatting for Firestore
/// 
/// Requires:
/// - Location permissions in AndroidManifest.xml and Info.plist
/// - Geolocator package
class LocationService {
  /// Check if device location services are enabled
  /// 
  /// Returns true if GPS is enabled, false otherwise
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check and request location permissions
  /// 
  /// Handles permission flow:
  /// 1. Checks current permission status
  /// 2. Requests permission if denied
  /// 3. Returns false if permanently denied
  /// 
  /// Returns true if permission granted, false otherwise
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    
    return true;
  }

  /// Get current GPS position with high accuracy
  /// 
  /// Automatically handles:
  /// - Location service enabled check
  /// - Permission request
  /// - Position retrieval with high accuracy
  /// 
  /// Returns [Position] if successful, null if:
  /// - Location services disabled
  /// - Permission denied
  /// - Error occurred
  Future<Position?> getCurrentLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    // Check and request permissions
    bool hasPermission = await requestLocationPermission();
    if (!hasPermission) {
      return null;
    }

    try {
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return position;
    } catch (e) {
      return null;
    }
  }

  /// Convert Position to Firestore-compatible map
  /// 
  /// Returns a map with:
  /// - lat: Latitude
  /// - lng: Longitude  
  /// - timestamp: ISO 8601 string
  /// - accuracy: Accuracy in meters
  /// 
  /// Throws [ArgumentError] if position.timestamp is null
  Map<String, dynamic> positionToMap(Position position) {
    if (position.timestamp == null) {
      throw ArgumentError('Position timestamp cannot be null');
    }
    return {
      'lat': position.latitude,
      'lng': position.longitude,
      'timestamp': position.timestamp!.toIso8601String(),
      'accuracy': position.accuracy,
    };
  }
}
