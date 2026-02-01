# Quick Reference Guide

## Important Concepts

### User ID vs Driver ID

The application uses two different IDs:

1. **User ID (userId)** - Firebase Authentication UID
   - Used for authentication
   - Stored in `users` collection as document ID
   - Stored in `drivers` collection as `userId` field

2. **Driver ID (driverId)** - Firestore document ID from drivers collection
   - Used for load assignments
   - Stored in `loads` collection as `driverId` field

**Example Flow:**
```
1. User logs in → Firebase Auth returns UID (e.g., "abc123")
2. App queries drivers collection: WHERE userId == "abc123"
3. Gets driver document with ID (e.g., "driver001")
4. App queries loads: WHERE driverId == "driver001"
```

### Load Status Flow

Loads progress through these statuses:

```
assigned → picked_up → in_transit → delivered
```

- **assigned**: Admin created and assigned the load
- **picked_up**: Driver marked as picked up
- **in_transit**: Driver started the trip (tripStartTime set)
- **delivered**: Driver ended the trip (tripEndTime set)

### Roles

Two user roles:
- **admin**: Full access to all features
- **driver**: Limited to their assigned loads

## Common Operations

### Creating a Driver (Admin)

1. Create Firebase Auth user (get UID)
2. Create Firestore user document with role='driver'
3. In app: Admin → Manage Drivers → Add Driver (use UID as User ID)

### Assigning a Load (Admin)

1. Admin → Create Load
2. Select driver from dropdown (automatically populated)
3. Fill in load details
4. Load is created with status='assigned'

### Updating Load Status (Driver)

1. Driver views load in their home screen
2. Opens load detail
3. Clicks status update button
4. Status updates in Firestore
5. Real-time updates visible to admin and driver

### Uploading POD (Driver)

1. Load must be in 'in_transit' or 'delivered' status
2. Driver clicks "Upload POD"
3. Captures photo with camera
4. Adds optional notes
5. Photo uploads to Firebase Storage
6. POD document created in Firestore subcollection

## File Locations

### Models
- User: `lib/models/app_user.dart`
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
