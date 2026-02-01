# GUD Express - Setup Instructions

This guide will walk you through setting up the GUD Express trucking management application.

## Prerequisites

- Flutter SDK (version 3.0.0 or higher)
- Android Studio or Xcode for mobile development
- A Google/Firebase account
- Git

## Step 1: Clone the Repository

```bash
git clone https://github.com/dukens11-create/gud.git
cd gud
```

## Step 2: Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or "Create a project"
3. Enter project name: `gud-express` (or your preferred name)
4. Follow the prompts to complete project creation

## Step 3: Enable Firebase Services

In your Firebase Console:

1. **Enable Authentication**
   - Navigate to Build → Authentication
   - Click "Get started"
   - Enable "Email/Password" sign-in method

2. **Enable Firestore Database**
   - Navigate to Build → Firestore Database
   - Click "Create database"
   - Start in **test mode** initially (we'll add security rules later)
   - Choose a location close to your users

3. **Enable Firebase Storage**
   - Navigate to Build → Storage
   - Click "Get started"
   - Start in **test mode** initially
   - Use the default location

## Step 4: Register Your Android App

1. In Firebase Console, click the Android icon to add an Android app
2. Android package name: `com.gudexpress.gud_app`
3. App nickname: `GUD Express` (optional)
4. Debug signing certificate SHA-1: (optional for now, required for some features)
5. Click "Register app"
6. Download the `google-services.json` file
7. Place `google-services.json` in `android/app/` directory

```bash
# The file should be at:
# android/app/google-services.json
```

## Step 5: Register Your iOS App (Optional)

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
