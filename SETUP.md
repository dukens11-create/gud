# Firebase Setup Guide for GUD Express

## Prerequisites
- Flutter SDK installed
- Android Studio or VS Code with Flutter extensions
- A Google account

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: `gud-express`
4. Disable Google Analytics (optional)
5. Click "Create project"

## Step 2: Add Android App to Firebase

1. In Firebase Console, click the Android icon to add an Android app
2. Enter Android package name: `com.gudexpress.gud_app`
3. Enter app nickname: `GUD Express`
4. Click "Register app"
5. Download `google-services.json`
6. Place `google-services.json` in `android/app/` directory

## Step 3: Enable Firebase Services

### Enable Authentication
1. In Firebase Console, go to "Authentication"
2. Click "Get started"
3. Enable "Email/Password" sign-in method
4. Click "Save"

### Enable Firestore Database
1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (we'll add security rules later)
4. Select a location close to your users
5. Click "Enable"

### Enable Storage
1. In Firebase Console, go to "Storage"
2. Click "Get started"
3. Choose "Start in test mode"
4. Click "Done"

## Step 4: Configure Firebase Security Rules

### Firestore Rules
Go to Firestore Database > Rules and replace with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null;
    }
    
    match /drivers/{driverId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    match /loads/{loadId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin' ||
         resource.data.driverId == request.auth.uid);
      
      match /pods/{podId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && 
          get(/databases/$(database)/documents/loads/$(loadId)).data.driverId == request.auth.uid;
      }
    }
  }
}
```

### Storage Rules
Go to Storage > Rules and replace with:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /pods/{loadId}/{imageId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## Step 5: Create First Admin User

1. Go to Firestore Database in Firebase Console
2. Click "Start collection"
3. Collection ID: `users`
4. Add first document:
   - Document ID: (auto-generated or custom)
   - Fields:
     - `email` (string): `admin@gudexpress.com`
     - `role` (string): `admin`
     - `uid` (string): (leave empty for now)

5. Go to Authentication in Firebase Console
6. Click "Add user"
7. Email: `admin@gudexpress.com`
8. Password: Create a secure password
9. Click "Add user"
10. Copy the generated User UID
11. Go back to Firestore Database
12. Edit the user document you created
13. Update the `uid` field with the copied User UID
14. Also update the Document ID to match the User UID

## Step 6: Install Dependencies

```bash
cd gud
flutter pub get
```

## Step 7: Run the Application

### For Android
```bash
flutter run
```

### For iOS (requires Mac)
1. Open `ios/Runner.xcworkspace` in Xcode
2. Add `GoogleService-Info.plist` to the Runner folder
3. Run from Xcode or use `flutter run`

## Step 8: Test the Application

1. Launch the app
2. Login with admin credentials:
   - Email: `admin@gudexpress.com`
   - Password: (the password you created)
3. You should see the Admin Dashboard

## Creating Driver Accounts

### Option 1: Through Admin Panel
1. Login as admin
2. Click "Manage Drivers"
3. Add driver information (name, phone, truck number)
4. Note: This only creates driver profile, not login credentials

### Option 2: Create Auth User and Link to Driver
To create a driver user account:
1. In Firebase Console > Authentication, add a new user
2. In Firestore, create a document in `users` collection:
   - Document ID: (User UID from Authentication)
   - Fields:
     - `email`: driver email
     - `role`: `driver`
     - `uid`: (User UID)
3. Link this UID to a driver document by using it as `driverId` in loads

## Troubleshooting

### "Firebase not initialized" Error
- Ensure `google-services.json` is in `android/app/`
- Run `flutter clean` and `flutter pub get`
- Rebuild the app

### Authentication Errors
- Check Firebase Authentication is enabled
- Verify email/password provider is enabled
- Check user exists in Firebase Console

### Firestore Permission Errors
- Verify security rules are properly configured
- Ensure user document has correct `role` field
- Check user is authenticated

### Storage Upload Errors
- Verify Storage is enabled in Firebase
- Check storage rules allow authenticated uploads
- Ensure camera permission is granted on device

## Production Considerations

Before deploying to production:

1. **Update Security Rules**: Change from test mode to production rules
2. **Enable App Check**: Protect backend resources from abuse
3. **Set up proper signing**: Configure Android signing for release builds
4. **Environment Variables**: Store sensitive configuration securely
5. **Error Logging**: Implement Firebase Crashlytics
6. **Analytics**: Enable Google Analytics for insights
7. **Performance Monitoring**: Add Firebase Performance Monitoring

## Additional Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Flutter Documentation](https://flutter.dev/docs)
