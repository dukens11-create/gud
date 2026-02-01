# Quick Reference Guide (Demo Version)

## Important Concepts

### Demo Data

The application uses pre-configured mock data:

**3 Demo Loads:**
1. **LOAD-001**
   - Rate: $1,500.00
   - Status: assigned
   - Route: Los Angeles → San Francisco

2. **LOAD-002**
   - Rate: $1,200.00
   - Status: in_transit
   - Route: San Diego → Sacramento

3. **LOAD-003**
   - Rate: $950.00
   - Status: delivered
   - Route: Oakland → San Jose

### Load Status Types

The demo includes these status types:
- **assigned**: Load has been assigned
- **in_transit**: Load is currently being transported
- **delivered**: Load has been delivered (counted in earnings)

### User Roles

Two demo access modes:
- **Driver**: Views all loads and earnings
- **Admin**: Views all loads with driver information

## Common Operations

### Demo Login

1. Launch the app
2. Click "Demo Login as Driver" OR "Demo Login as Admin"
3. Instant access to dashboard (no authentication)

### Viewing Loads (Driver)

1. After demo login as driver
2. See list of all 3 loads
3. View details: load number, addresses, rate, status
4. Exit button returns to login

### Viewing Earnings (Driver)

1. From driver dashboard
2. (Currently accessible via routes, not yet linked in UI)
3. Shows total earnings from delivered loads
4. Calculation: Only delivered loads count ($950.00 total)

### Viewing Loads (Admin)

1. After demo login as admin
2. See list of all 3 loads
3. View details: load number, driver ID, status, rate
4. Exit button returns to login

## File Locations

### Core Files
- Entry Point: `lib/main.dart`
- App Widget: `lib/app.dart`
- Routes: `lib/routes.dart`

### Models
- Load: `lib/models/simple_load.dart`

### Services
- Mock Data: `lib/services/mock_data_service.dart`

### Screens
- Login: `lib/screens/login_screen.dart`
- Driver Home: `lib/screens/driver/driver_home.dart`
- Earnings: `lib/screens/driver/earnings_screen.dart`
- Admin Home: `lib/screens/admin/admin_home.dart`

### Widgets
- Loading: `lib/widgets/loading.dart`
- Button: `lib/widgets/app_button.dart`
- TextField: `lib/widgets/app_textfield.dart`

## Development Commands

### Running the App
```bash
flutter run
```

### Building for Release
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Clean build
flutter clean
flutter pub get
```

## Customization

### Adding More Demo Loads

Edit `lib/services/mock_data_service.dart`:

```dart
SimpleLoad(
  id: '4',
  loadNumber: 'LOAD-004',
  pickupAddress: 'Your pickup address',
  deliveryAddress: 'Your delivery address',
  rate: 1000.00,
  status: 'assigned', // or 'in_transit' or 'delivered'
  driverId: 'driver1',
  createdAt: DateTime.now(),
)
```

### Changing Colors

Edit `lib/app.dart`:

```dart
colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
// Change Colors.blue to your preferred color
```

## Demo Limitations

This demo version does NOT include:
- ❌ Real authentication
- ❌ Data persistence
- ❌ Backend integration
- ❌ User management
- ❌ Load creation/editing
- ❌ Photo uploads
- ❌ Real-time synchronization
- ❌ Status updates

For production use, you would need to:
1. Add backend service (Firebase, REST API, etc.)
2. Implement authentication
3. Add CRUD operations
4. Implement file uploads
5. Add proper state management

## Troubleshooting

### App won't build
```bash
flutter clean
flutter pub get
flutter run
```

### Import errors
Make sure all imports use relative paths correctly

### Demo data not showing
Check that `MockDataService.getDemoLoads()` is being called in screens
- Driver: `lib/models/driver.dart`
- Load: `lib/models/load.dart`
- POD: `lib/models/pod.dart`

### Services
- Auth: `lib/services/auth_service.dart`
- Firestore: `lib/services/firestore_service.dart`
- Storage: `lib/services/storage_service.dart`

### Admin Screens
- Dashboard: `lib/screens/admin/admin_home.dart`
- Manage Drivers: `lib/screens/admin/manage_drivers_screen.dart`
- Create Load: `lib/screens/admin/create_load_screen.dart`
- Load Detail: `lib/screens/admin/admin_load_detail.dart`

### Driver Screens
- Dashboard: `lib/screens/driver/driver_home.dart`
- Load Detail: `lib/screens/driver/driver_load_detail.dart`
- Upload POD: `lib/screens/driver/upload_pod_screen.dart`
- Earnings: `lib/screens/driver/earnings_screen.dart`

## Firestore Collections Structure

```
users/
  {userId}/
    - uid: string
    - email: string
    - role: string (admin|driver)

drivers/
  {driverId}/
    - name: string
    - phone: string
    - truckNumber: string
    - status: string (active|inactive)
    - userId: string (Firebase Auth UID)

loads/
  {loadId}/
    - loadNumber: string
    - driverId: string (Driver document ID)
    - driverName: string
    - pickupAddress: string
    - deliveryAddress: string
    - rate: number
    - status: string (assigned|picked_up|in_transit|delivered)
    - tripStartTime: timestamp
    - tripEndTime: timestamp
    - createdAt: timestamp
    
    pods/
      {podId}/
        - loadId: string
        - imageUrl: string
        - notes: string
        - uploadedAt: timestamp
```

## Firebase Storage Structure

```
pods/
  pod_{loadId}_{timestamp}.jpg
```

## Environment Variables

None required! All Firebase configuration is in:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

## Testing Tips

### Test as Admin
1. Login with admin credentials
2. Create a test driver
3. Create a test load assigned to that driver
4. View the load in admin dashboard
5. Test manual status updates

### Test as Driver
1. Login with driver credentials
2. Verify you only see your assigned loads
3. Update load status through the flow
4. Upload a POD photo
5. Check earnings screen

### Test Real-time Updates
1. Login on two devices (one admin, one driver)
2. Admin creates a load
3. Verify driver sees it immediately
4. Driver updates status
5. Verify admin sees update immediately

## Common Issues and Solutions

### "Permission denied" error
- Check Firebase Security Rules are deployed
- Verify user has correct role in Firestore
- Ensure driver document has correct userId

### POD upload fails
- Check Storage Security Rules
- Verify camera permissions in AndroidManifest.xml
- Ensure file is under 10MB

### Driver sees no loads
- Verify driver document exists in Firestore
- Check driver's userId matches Auth UID
- Verify loads have correct driverId (driver document ID, not userId)

### Real-time updates not working
- Check Firestore indexes are created
- Verify StreamBuilder is properly implemented
- Check internet connectivity

## Performance Tips

1. **Indexes**: Firestore will prompt to create indexes when needed
2. **Pagination**: Consider adding pagination for large load lists
3. **Image Compression**: Already configured to max 1920x1080 at 85% quality
4. **Offline Support**: Firestore automatically caches data

## Security Best Practices

1. Never commit `google-services.json` to git (already in .gitignore)
2. Use Firebase App Check in production
3. Enable Firebase Authentication rate limiting
4. Regular security rule audits
5. Monitor Firebase Console for suspicious activity
6. Use strong passwords for all accounts
7. Enable 2FA for Firebase Console access

## Maintenance

### Regular Tasks
- Monitor Firebase usage and costs
- Review security logs
- Update dependencies regularly
- Backup Firestore data
- Monitor error logs in Firebase Crashlytics (if implemented)

### Updating Dependencies
```bash
flutter pub upgrade
flutter pub outdated
```

### Clean Build
```bash
flutter clean
flutter pub get
flutter run
```
