# Phase 8 Integration Guide

Quick guide for integrating the new Phase 8 features into your app.

## Quick Start

### 1. Initialize Services (in main.dart)

```dart
import 'package:gud_app/services/offline_service.dart';
import 'package:gud_app/services/sync_service.dart';
import 'package:gud_app/services/geofence_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize offline and sync services
  final offlineService = OfflineService();
  await offlineService.initialize();
  
  final syncService = SyncService();
  await syncService.initialize();
  
  runApp(MyApp());
}
```

### 2. Add Offline Indicator to Main Layout

```dart
import 'package:gud_app/widgets/offline_indicator.dart';

// In your main scaffold or app layout:
Scaffold(
  body: Column(
    children: [
      const OfflineIndicator(), // Auto-shows when offline or syncing
      Expanded(
        child: YourMainContent(),
      ),
    ],
  ),
)
```

### 3. Show Onboarding on First Launch

```dart
import 'package:gud_app/screens/onboarding_screen.dart';

// In your initial route logic:
Future<Widget> getInitialScreen() async {
  // Check if user is authenticated
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return LoginScreen();
  }
  
  // Check if onboarding should be shown
  if (await shouldShowOnboarding()) {
    // Get user role from Firestore
    final role = await getUserRole(user.uid);
    return OnboardingScreen(userRole: role);
  }
  
  return HomeScreen();
}
```

### 4. Setup Geofencing for Loads

```dart
import 'package:gud_app/services/geofence_service.dart';

// When creating/assigning a load:
final geofenceService = GeofenceService();

// Create geofences for pickup and delivery
await geofenceService.createPickupGeofence(
  loadId: load.id,
  latitude: load.pickupLocation.latitude,
  longitude: load.pickupLocation.longitude,
  radius: 200, // meters
);

await geofenceService.createDeliveryGeofence(
  loadId: load.id,
  latitude: load.deliveryLocation.latitude,
  longitude: load.deliveryLocation.longitude,
  radius: 200,
);

// Start monitoring for driver
await geofenceService.startMonitoring(driverId);
```

## Usage Patterns

### Handling Offline Operations

```dart
import 'package:gud_app/services/offline_service.dart';

final offlineService = OfflineService();

Future<void> updateLoad(String loadId, Map<String, dynamic> data) async {
  if (offlineService.isOnline) {
    // Direct update
    await FirebaseFirestore.instance
        .collection('loads')
        .doc(loadId)
        .update(data);
  } else {
    // Queue for later
    await offlineService.queueOperation(
      operationType: 'update',
      collection: 'loads',
      documentId: loadId,
      data: data,
    );
    
    // Show user feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved offline. Will sync when online.')),
    );
  }
}
```

### Monitoring Connectivity

```dart
import 'package:gud_app/services/offline_service.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final offlineService = OfflineService();
  StreamSubscription<bool>? _subscription;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _subscription = offlineService.connectivityStream.listen((isOnline) {
      setState(() {
        _isOnline = isOnline;
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_isOnline ? 'Online' : 'Offline');
  }
}
```

### Displaying Sync Progress

```dart
import 'package:gud_app/services/sync_service.dart';

class SyncProgressWidget extends StatelessWidget {
  final syncService = SyncService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncProgress>(
      stream: syncService.syncProgressStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox.shrink();
        
        final progress = snapshot.data!;
        
        if (progress.status == SyncStatus.syncing) {
          return LinearProgressIndicator(
            value: progress.progress,
          );
        }
        
        return SizedBox.shrink();
      },
    );
  }
}
```

### Caching Critical Data

```dart
import 'package:gud_app/services/offline_service.dart';

final offlineService = OfflineService();

// Cache load data for offline access
Future<void> cacheLoad(String loadId, Map<String, dynamic> loadData) async {
  await offlineService.cacheData(
    id: loadId,
    type: 'loads',
    data: loadData,
    expiresIn: Duration(hours: 24), // Cache for 24 hours
  );
}

// Retrieve cached load
Future<Map<String, dynamic>?> getLoad(String loadId) async {
  if (offlineService.isOnline) {
    // Fetch from Firestore
    final doc = await FirebaseFirestore.instance
        .collection('loads')
        .doc(loadId)
        .get();
    return doc.data();
  } else {
    // Get from cache
    return await offlineService.getCachedData(
      id: loadId,
      type: 'loads',
    );
  }
}
```

## Battery Optimization

Enable battery-optimized mode for geofencing when needed:

```dart
final geofenceService = GeofenceService();

// Enable battery optimization (checks every 2 minutes instead of 30 seconds)
geofenceService.setBatteryOptimization(true);

// Or in settings screen:
SwitchListTile(
  title: Text('Battery Saver Mode'),
  subtitle: Text('Reduces GPS checks to save battery'),
  value: _batteryOptimized,
  onChanged: (value) {
    setState(() {
      _batteryOptimized = value;
    });
    geofenceService.setBatteryOptimization(value);
  },
);
```

## Troubleshooting

### Sync Not Working
```dart
// Check sync status
final status = await syncService.getSyncStatus();
print('Pending operations: ${status['pending_operations']}');
print('Is online: ${status['is_online']}');
print('Is syncing: ${status['is_syncing']}');

// Force manual sync
await syncService.forceSyncNow();
```

### Clear Offline Data
```dart
// Clear all offline data (useful for logout)
await offlineService.clearAllData();
```

### View Storage Statistics
```dart
final stats = await offlineService.getStorageStats();
print('Cached items: ${stats['cached_items']}');
print('Pending operations: ${stats['pending_operations']}');
print('Unresolved conflicts: ${stats['unresolved_conflicts']}');
```

## Testing Tips

1. **Test Offline Mode:**
   - Enable airplane mode
   - Perform operations
   - Verify queue count increases
   - Disable airplane mode
   - Verify automatic sync

2. **Test Geofencing:**
   - Use Android Studio location emulator
   - Set coordinates near geofence
   - Verify entry/exit events fire
   - Check Firestore for event logs

3. **Test Onboarding:**
   - Call `resetOnboarding()` to clear completion
   - Restart app
   - Verify onboarding shows
   - Complete onboarding
   - Verify it doesn't show again

## Common Issues

### Issue: Geofences not persisting after restart
**Solution:** Ensure `_loadGeofencesFromLocal()` is called in `startMonitoring()`

### Issue: Sync not triggering automatically
**Solution:** Verify `SyncService.initialize()` is called and connectivity listener is active

### Issue: Cache expiring too quickly
**Solution:** Adjust `expiresIn` duration when calling `cacheData()`

### Issue: Onboarding shows every time
**Solution:** Check SharedPreferences key 'onboarding_complete' is being set

## Best Practices

1. **Always initialize services in main()** before runApp()
2. **Dispose subscriptions** in widget dispose methods
3. **Cache frequently accessed data** to improve offline experience
4. **Show user feedback** when operations are queued offline
5. **Test with actual devices** for realistic geofencing behavior
6. **Monitor analytics** to understand offline usage patterns
7. **Handle conflicts gracefully** with user-friendly resolution UI
8. **Clean up expired cache** periodically to manage storage

## Performance Tips

1. Use battery optimization for geofencing when accuracy isn't critical
2. Set appropriate cache expiration times (don't cache forever)
3. Queue batch operations instead of individual updates
4. Clear completed operations periodically
5. Limit cached data to essential information
6. Use connectivity stream efficiently (don't create multiple subscriptions)

## Security Notes

1. ✅ All Firestore operations respect security rules
2. ✅ SQLite database is sandboxed per user
3. ✅ No sensitive data logged to console in production
4. ⚠️ Consider adding encryption for cached sensitive data
5. ⚠️ Validate all data before syncing to Firestore

## Next Steps

1. Implement your app-specific conflict resolution UI
2. Add background sync capability for better UX
3. Consider adding data encryption for sensitive cached data
4. Monitor sync performance and optimize as needed
5. Gather user feedback on offline experience
