# GUD Express - Setup Instructions (Demo Version)

This guide will walk you through setting up the GUD Express demo application.

## Prerequisites

- Flutter SDK (version 3.0.0 or higher)
- Android Studio or VS Code for mobile development
- Git

## Step 1: Clone the Repository

```bash
git clone https://github.com/dukens11-create/gud.git
cd gud
```

## Step 2: Install Dependencies

```bash
flutter pub get
```

## Step 3: Run the Application

### For Development

```bash
flutter run
```

### For Android Release Build

```bash
flutter build apk --release
```

The APK will be available at: `build/app/outputs/flutter-apk/app-release.apk`

### For Android App Bundle

```bash
flutter build appbundle --release
```

The AAB will be available at: `build/app/outputs/bundle/release/app-release.aab`

## Using the Demo Application

This is a **demo version** that uses mock data and requires no backend setup:

1. **Launch the app** - You'll see the login screen
2. **Demo Login as Driver** - Click this button to access the driver dashboard
3. **Demo Login as Admin** - Click this button to access the admin dashboard

### Demo Data

The application includes 3 pre-configured demo loads:

- **LOAD-001**: $1,500.00 - Assigned
- **LOAD-002**: $1,200.00 - In Transit
- **LOAD-003**: $950.00 - Delivered

### Features Available

**Driver Dashboard:**
- View all assigned loads
- See pickup and delivery addresses
- Check load rates and status
- View total earnings (from delivered loads)

**Admin Dashboard:**
- View all loads in the system
- Monitor driver assignments
- Check load statuses
- Review load rates

## Development

### Code Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # Root widget
├── routes.dart               # Named routes
├── models/
│   └── simple_load.dart     # Load data model
├── services/
│   └── mock_data_service.dart  # Mock data provider
├── screens/
│   ├── login_screen.dart    # Demo login
│   ├── driver/
│   │   ├── driver_home.dart
│   │   └── earnings_screen.dart
│   └── admin/
│       └── admin_home.dart
└── widgets/                  # Reusable UI components
```

### Running Tests

```bash
flutter test
```

### Code Analysis

```bash
flutter analyze
```

## Troubleshooting

### Common Issues

**Issue**: Dependencies not found
**Solution**: Run `flutter pub get`

**Issue**: Build fails
**Solution**: Run `flutter clean` then `flutter pub get`

**Issue**: App doesn't launch
**Solution**: Ensure your device/emulator is running and detected with `flutter devices`

## Next Steps

This demo version is designed for evaluation and demonstration purposes. For production use, you would need to:

1. Integrate a backend service (Firebase, REST API, etc.)
2. Implement proper authentication
3. Add real-time data synchronization
4. Implement user management
5. Add proof of delivery upload functionality
6. Implement proper state management

## Support

For issues or questions, please create an issue in the GitHub repository.
3. App nickname: `GUD Express` (optional)
4. Debug signing certificate SHA-1: (optional for now, required for some features)
5. Click "Register app"
6. Download the `google-services.json` file
7. Place `google-services.json` in `android/app/` directory

```bash
# The file should be at:
# android/app/google-services.json
```

## iOS Code Signing Setup

> **⚠️ TODO for each developer:** Apple code signing requires your personal Apple Developer account and cannot be committed to source control. Follow these steps on your Mac before building for a real device.

### Prerequisites

- A Mac running macOS with Xcode installed (Xcode 14+)
- An [Apple Developer account](https://developer.apple.com/account) (free accounts can deploy to personal devices; paid accounts required for App Store distribution)

### Step 1: Open the Xcode Workspace

Always open the **workspace** file, never the `.xcodeproj` directly:

```bash
open ios/Runner.xcworkspace
```

Or in Xcode: **File → Open…** and select `ios/Runner.xcworkspace`.

### Step 2: Sign in with Your Apple ID

1. In Xcode, go to **Xcode → Settings → Accounts** (or ⌘,)
2. Click **+** in the bottom-left corner
3. Select **Apple ID** and click **Continue**
4. Sign in with your Apple ID credentials

### Step 3: Select a Development Team

1. In the Xcode Project Navigator (left sidebar), select **Runner** (the blue icon at the top)
2. Select the **Runner** target under **TARGETS**
3. Click the **Signing & Capabilities** tab
4. Ensure **Automatically manage signing** is checked ✓
5. Under **Team**, select your Apple Developer team from the dropdown

> **TODO:** Replace the placeholder `DEVELOPMENT_TEAM` value in `ios/Runner.xcodeproj/project.pbxproj` with your actual 10-character Team ID (e.g. `ABCDE12345`), or let Xcode manage it automatically via the UI above.

### Step 4: Register Your Device (for real device builds)

1. Connect your iPhone/iPad via USB
2. In Xcode, go to **Window → Devices and Simulators** (⇧⌘2)
3. If prompted, click **Register Device** to add your device to your Apple Developer account

### Step 5: Build and Run

```bash
# Build for iOS simulator
flutter run

# Build for a connected real device
flutter build ios
```

Or press **⌘R** in Xcode to build and run directly on a connected device.

### Troubleshooting Code Signing

| Error | Solution |
|-------|----------|
| `No accounts with iTunes Connect access` | Sign in to Xcode → Settings → Accounts |
| `No certificate for team` | Xcode → Settings → Accounts → Manage Certificates → + (Apple Development) |
| `Provisioning profile doesn't include the entitlement` | In Signing & Capabilities, click the refresh icon next to the provisioning profile |
| `Could not find any available provisioning profiles` | Ensure your device is registered (Step 4) and re-select your team |
| `Signing requires a development team` | Complete Step 3 above |

For CI/CD signing setup, see [ios/CODE_SIGNING_SETUP.md](ios/CODE_SIGNING_SETUP.md).



If you plan to support iOS:

1. In Firebase Console, click the iOS icon to add an iOS app
2. iOS bundle ID: `com.gudexpress.gudApp`
3. App nickname: `GUD Express` (optional)
4. Click "Register app"
5. Download the `GoogleService-Info.plist` file
6. Place it in `ios/Runner/` directory (you may need to create the ios folder structure)

## Step 6: Install Flutter Dependencies

```bash
flutter pub get
```

This will install all required packages:
- firebase_core
- firebase_auth
- cloud_firestore
- firebase_storage
- image_picker
- intl

## Step 7: Configure Firebase Security Rules

1. Go to Firestore Database → Rules
2. Copy the Firestore rules from `FIREBASE_RULES.md`
3. Paste and publish the rules

4. Go to Storage → Rules
5. Copy the Storage rules from `FIREBASE_RULES.md`
6. Paste and publish the rules

## Step 8: Create First Admin User

Since we need an admin user to manage the system, you'll need to create one manually:

### Option A: Using Firebase Console (Recommended)

1. **Create Authentication User**
   - Go to Authentication → Users
   - Click "Add user"
   - Email: `admin@gudexpress.com` (or your preferred email)
   - Password: Choose a secure password
   - Click "Add user"
   - Copy the User UID (you'll need this)

2. **Create Firestore User Document**
   - Go to Firestore Database → Data
   - Click "Start collection"
   - Collection ID: `users`
   - Click "Next"
   - Document ID: Paste the User UID you copied
   - Add fields:
     - `uid` (string): Paste the User UID
     - `email` (string): `admin@gudexpress.com`
     - `role` (string): `admin`
   - Click "Save"

### Option B: Using Flutter App (Requires code modification)

Temporarily modify the login screen to include a sign-up option, create the admin account, then remove the sign-up option.

## Step 9: Run the Application

### For Android:

```bash
# Connect your Android device or start an emulator
flutter devices

# Run the app
flutter run
```

### For iOS (macOS only):

```bash
# Open iOS simulator or connect iPhone
flutter devices

# Run the app
flutter run
```

## Step 10: First Login and Usage

1. Launch the app
2. Login with your admin credentials
3. You should see the Admin Dashboard

### Creating Driver Accounts

1. **Create Firebase Auth Account for Driver**
   - Go to Firebase Console → Authentication → Users
   - Click "Add user"
   - Enter driver's email and password
   - Copy the User UID

2. **Create User Document**
   - Go to Firestore Database → users collection
   - Add document with the User UID
   - Fields:
     - `uid`: User UID
     - `email`: driver email
     - `role`: `driver`

3. **Create Driver Profile**
   - In the app, go to "Manage Drivers"
   - Fill in the form:
     - Name: Driver's full name
     - Phone: Driver's phone number
     - Truck Number: Truck identification
     - User ID: Paste the Firebase User UID
   - Click "Add Driver"

4. **Driver can now log in** with their email and password

### Creating Loads

1. From Admin Dashboard, click "Create Load"
2. Fill in:
   - Load Number
   - Select Driver from dropdown
   - Pickup Address
   - Delivery Address
   - Rate
3. Click "Create Load"
4. The load will appear in both admin view and driver's view

## Troubleshooting

### "Firebase not initialized" error
- Make sure `google-services.json` is in the correct location
- Run `flutter clean` and `flutter pub get`
- Rebuild the app

### "Permission denied" errors
- Check that Firebase Security Rules are properly configured
- Verify user has correct role in Firestore
- Check that user is authenticated

### Image picker not working
- For Android: Ensure camera permissions are in AndroidManifest.xml
- For iOS: Add camera and photo library permissions to Info.plist

### Build errors
- Run `flutter clean`
- Delete `android/build` and `android/app/build` folders
- Run `flutter pub get`
- Rebuild

## Production Deployment

Before deploying to production:

1. **Update Firebase Security Rules** - Ensure they're properly restrictive
2. **Enable App Check** - Protect your Firebase resources
3. **Set up proper signing** - For Android and iOS releases
4. **Environment Variables** - Consider using different Firebase projects for dev/staging/prod
5. **Error Tracking** - Set up Firebase Crashlytics
6. **Analytics** - Configure Firebase Analytics

## Support

For issues or questions:
- Create an issue in the GitHub repository
- Check Firebase documentation: https://firebase.google.com/docs
- Check Flutter documentation: https://flutter.dev/docs

## Next Steps

- Customize the app colors and branding
- Add more features as needed
- Set up automated backups for Firestore
- Implement push notifications for load updates
- Add more detailed analytics
