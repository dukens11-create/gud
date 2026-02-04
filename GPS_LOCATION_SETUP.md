# GPS Location Tracking Setup Guide

This guide provides instructions for the GPS location tracking feature implemented for drivers in the GUD Express mobile app.

## Overview

Drivers can now send their real-time GPS location to Firestore via a "Send Location" button on their home screen. This location data is stored in the driver's Firestore document and can be viewed by admins.

## What's Implemented

### 1. Dependencies
- **geolocator** (v10.1.0): GPS location tracking package for Flutter

### 2. Platform Permissions

#### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

#### iOS (Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to your location to track your position while delivering loads</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs access to your location to track your position during deliveries</string>
```

### 3. Data Model

The `Driver` model now includes a `lastLocation` field:
```dart
final Map<String, dynamic>? lastLocation; // {lat, lng, timestamp, accuracy}
```

### 4. Location Service

A new `LocationService` class handles:
- Checking if location services are enabled
- Requesting location permissions
- Getting the current GPS position
- Converting Position to a Firestore-compatible map

### 5. Firestore Integration

New method in `FirestoreService`:
```dart
Future<void> updateDriverLocation({
  required String driverId,
  required double latitude,
  required double longitude,
  required DateTime timestamp,
  double? accuracy,
}) async {
  await _db.collection('drivers').doc(driverId).update({
    'lastLocation': {
      'lat': latitude,
      'lng': longitude,
      'timestamp': timestamp.toIso8601String(),
      if (accuracy != null) 'accuracy': accuracy,
    },
  });
}
```

### 6. User Interface

The driver home screen now includes a "Send Location" button that:
- Shows a loading indicator while fetching location
- Requests location permissions if not granted
- Sends location to Firestore
- Displays success/error messages via SnackBar

## Firestore Data Structure

Location data is stored in the driver document:

```json
{
  "drivers/{driverId}": {
    "name": "John Doe",
    "phone": "555-0123",
    "truckNumber": "TRK-001",
    "status": "available",
    "lastLocation": {
      "lat": 37.7749,
      "lng": -122.4194,
      "timestamp": "2026-02-04T06:00:00.000Z",
      "accuracy": 5.0
    }
  }
}
```

## Usage

### For Drivers
1. Open the mobile app
2. Log in as a driver
3. On the home screen, tap the "Send Location" button
4. Grant location permissions when prompted
5. Your location will be sent to Firestore and a success message will appear

### For Admins
To view driver locations, query the driver document in Firestore:
```dart
final driver = await FirestoreService().getDriver(driverId);
if (driver?.lastLocation != null) {
  final lat = driver!.lastLocation!['lat'];
  final lng = driver!.lastLocation!['lng'];
  final timestamp = driver!.lastLocation!['timestamp'];
  print('Driver location: $lat, $lng at $timestamp');
}
```

## Future Enhancements

This implementation provides the foundation for more advanced location tracking features:

### 1. Background Location Tracking
To track driver location continuously in the background:
- Add `background_location` package or use `geolocator`'s background tracking
- Add background location permissions to Android manifest:
  ```xml
  <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
  ```
- Add background modes to iOS Info.plist:
  ```xml
  <key>UIBackgroundModes</key>
  <array>
    <string>location</string>
  </array>
  ```

### 2. Periodic Location Updates
Automatically send location at regular intervals:
```dart
// Example implementation
Timer.periodic(Duration(minutes: 5), (timer) async {
  final position = await LocationService().getCurrentLocation();
  if (position != null) {
    await FirestoreService().updateDriverLocation(
      driverId: driverId,
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp ?? DateTime.now(),
      accuracy: position.accuracy,
    );
  }
});
```

### 3. Map View Integration
Display driver locations on a map:
- Add `google_maps_flutter` or `flutter_map` package
- Create an admin map view showing all active drivers
- Show driver route history

### 4. Geofencing
Trigger actions when drivers enter/exit specific areas:
- Add `geofence_service` package
- Set up geofences around pickup/delivery locations
- Automatically update load status based on geofence events

### 5. Real-time Location Streaming
Stream location updates to admins in real-time:
- Use Firestore real-time listeners
- Update map markers as driver locations change
- Show driver movement in real-time on admin dashboard

## Testing

### Manual Testing
1. Run the app on a physical device (location doesn't work reliably in simulators)
2. Log in as a driver
3. Tap "Send Location" button
4. Check Firestore console to verify location data was saved

### Simulator Testing (Limited)
- iOS Simulator: Use Debug > Location menu to simulate locations
- Android Emulator: Use Extended Controls > Location to set coordinates

## Troubleshooting

### Location Permission Denied
- **iOS**: User must grant permission in Settings > Privacy > Location Services
- **Android**: User must grant permission in Settings > Apps > GUD Express > Permissions

### Location Services Disabled
- User must enable Location Services in device settings

### Accuracy Issues
- GPS accuracy depends on device hardware and environment
- Indoor locations may have poor accuracy
- Consider using only locations with accuracy < 50 meters for critical operations

## Security Considerations

1. **Permission Requests**: Always check and request permissions before accessing location
2. **Privacy**: Location data is sensitive - ensure proper access controls in Firestore rules
3. **Data Minimization**: Only store necessary location data
4. **User Consent**: Ensure drivers understand location tracking policies

## Firestore Security Rules

Update your Firestore rules to control access to location data:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /drivers/{driverId} {
      // Drivers can update their own location
      allow update: if request.auth != null 
        && request.auth.uid == driverId 
        && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['lastLocation']);
      
      // Admins can read all driver locations
      allow read: if request.auth != null 
        && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

## Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  geolocator: ^10.1.0
```

Run:
```bash
flutter pub get
```

## Code Examples

### Get Current Location
```dart
final locationService = LocationService();
final position = await locationService.getCurrentLocation();

if (position != null) {
  print('Latitude: ${position.latitude}');
  print('Longitude: ${position.longitude}');
  print('Accuracy: ${position.accuracy}m');
}
```

### Save Location to Firestore
```dart
final firestoreService = FirestoreService();
await firestoreService.updateDriverLocation(
  driverId: 'driver123',
  latitude: 37.7749,
  longitude: -122.4194,
  timestamp: DateTime.now(),
  accuracy: 5.0,
);
```

### Check Permission Status
```dart
final locationService = LocationService();
final hasPermission = await locationService.requestLocationPermission();
if (!hasPermission) {
  // Show message to user about enabling location permissions
}
```

## Support

For issues or questions:
1. Check device location settings
2. Verify permissions are granted in app settings
3. Check Firestore console for data
4. Review device logs for error messages
