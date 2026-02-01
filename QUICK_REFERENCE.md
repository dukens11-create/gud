# GUD Express - Quick Reference Guide

## Installation & Setup

### Initial Setup
```bash
# Clone repository
git clone <repository-url>
cd gud

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Firebase Configuration Required
Before running, ensure you have:
1. `android/app/google-services.json` (from Firebase Console)
2. Admin user created in Firestore
3. Firebase services enabled (Auth, Firestore, Storage)

See [SETUP.md](SETUP.md) for detailed instructions.

## Common Commands

### Development
```bash
# Run app in debug mode
flutter run

# Run on specific device
flutter devices
flutter run -d <device-id>

# Hot reload (press 'r' in terminal while app is running)
# Hot restart (press 'R' in terminal while app is running)

# Clean build
flutter clean
flutter pub get
flutter run
```

### Analysis
```bash
# Analyze code
flutter analyze

# Format code
flutter format lib/

# Check for outdated dependencies
flutter pub outdated
```

### Build
```bash
# Build APK (debug)
flutter build apk --debug

# Build APK (release)
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

## Application Flow

### Admin Workflow
1. Login with admin credentials
2. **Manage Drivers**: Add new drivers to the system
3. **Create Load**: Assign loads to drivers
4. **Monitor Loads**: View all loads and their statuses
5. **Update Status**: Manually change load status if needed

### Driver Workflow
1. Login with driver credentials
2. **View Assigned Loads**: See loads assigned to you
3. **Update Status**: Mark load as picked up
4. **Start Trip**: Record trip start time
5. **End Trip**: Record trip end time and miles
6. **Upload POD**: Take photo of proof of delivery
7. **View Earnings**: Check total earnings from delivered loads

## Data Models

### User
- `uid`: String (Firebase Auth UID)
- `email`: String
- `role`: String ("admin" or "driver")

### Driver
- `id`: String (Firestore document ID)
- `name`: String
- `phone`: String
- `truckNumber`: String
- `status`: String (default: "available")

### Load
- `id`: String (Firestore document ID)
- `loadNumber`: String
- `driverId`: String
- `pickupAddress`: String
- `deliveryAddress`: String
- `rate`: Double
- `status`: String (assigned, picked_up, in_transit, delivered)
- `tripStartTime`: DateTime (optional)
- `tripEndTime`: DateTime (optional)
- `miles`: Double (optional)

### POD (Proof of Delivery)
- `id`: String (Firestore document ID)
- `imageUrl`: String
- `uploadedAt`: DateTime
- `notes`: String (optional)

## Load Status Flow

```
assigned → picked_up → in_transit → delivered
```

- **assigned**: Load created and assigned to driver
- **picked_up**: Driver marked load as picked up
- **in_transit**: Driver started trip (timestamp recorded)
- **delivered**: Driver ended trip (timestamp and miles recorded)

## Firebase Collections Structure

```
firestore/
├── users/
│   └── {userId}/
│       ├── email
│       ├── role
│       └── uid
│
├── drivers/
│   └── {driverId}/
│       ├── name
│       ├── phone
│       ├── truckNumber
│       └── status
│
└── loads/
    └── {loadId}/
        ├── loadNumber
        ├── driverId
        ├── pickupAddress
        ├── deliveryAddress
        ├── rate
        ├── status
        ├── tripStartTime
        ├── tripEndTime
        ├── miles
        └── pods/
            └── {podId}/
                ├── imageUrl
                ├── uploadedAt
                └── notes

storage/
└── pods/
    └── {loadId}/
        └── {timestamp}.jpg
```

## Troubleshooting

### Build Errors

**"Task :app:processDebugGoogleServices FAILED"**
- Missing `google-services.json`
- Place file in `android/app/google-services.json`

**"Execution failed for task ':app:checkDebugAarMetadata'"**
- Run `flutter clean`
- Delete `android/.gradle`
- Run `flutter pub get`
- Try building again

### Runtime Errors

**"Firebase not initialized"**
- Ensure `Firebase.initializeApp()` is called in `main.dart`
- Check `google-services.json` is present

**"Permission denied" on Firestore**
- Check security rules in Firebase Console
- Verify user is authenticated
- Verify user document has correct `role` field

**"User not found" when logging in**
- Create user in Firebase Console > Authentication
- Create corresponding document in Firestore > users collection

**Camera not working**
- Check camera permission in AndroidManifest.xml
- Grant permission when prompted on device
- Ensure device/emulator has camera access

### Development Issues

**Hot reload not working**
- Try hot restart (capital R)
- Sometimes full restart is needed
- Check for syntax errors

**Changes not reflecting**
- Run `flutter clean`
- Stop app completely
- Rebuild and run

## API Keys & Security

### Important Security Notes
- Never commit `google-services.json` to public repositories
- Never commit API keys or credentials
- Use `.gitignore` to exclude sensitive files
- Use environment variables for configuration in production

### Files to Keep Private
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- Any files containing API keys or secrets

## Performance Tips

### Optimizing Build Size
```bash
# Build with code shrinking
flutter build apk --release --shrink

# Analyze app size
flutter build apk --release --analyze-size
```

### Debugging Performance
```bash
# Run with performance overlay
flutter run --profile

# Enable DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

## Common Modifications

### Change App Name
- Update `android/app/src/main/AndroidManifest.xml`: `android:label`
- Update `pubspec.yaml`: `name`

### Change Package Name
- Update `android/app/build.gradle`: `applicationId`
- Update `android/app/src/main/AndroidManifest.xml`: `package`
- Rename Kotlin package directories
- Update imports in `MainActivity.kt`

### Change App Icon
- Replace icons in `android/app/src/main/res/mipmap-*/`
- Use `flutter_launcher_icons` package for easy icon generation

### Add New Dependency
```bash
# Add to pubspec.yaml
flutter pub add <package_name>

# Or manually edit pubspec.yaml and run
flutter pub get
```

## Useful Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Material Design](https://material.io/design)
- [FlutterFire](https://firebase.flutter.dev/)

## Support

For issues or questions:
1. Check [SETUP.md](SETUP.md) for setup instructions
2. Check [TESTING.md](TESTING.md) for testing procedures
3. Review Firebase Console for configuration issues
4. Check Flutter/Firebase documentation
