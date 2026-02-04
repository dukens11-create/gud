import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check and request location permissions
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

  /// Get current position
  /// Returns null if location service is disabled or permission denied
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

  /// Convert Position to a map for Firestore storage
  /// Throws an error if position.timestamp is null
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
