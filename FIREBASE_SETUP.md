# Firebase Setup Guide

This guide will help you set up Firebase for the GUD Express Trucking Management App.

## ⚠️ Critical iOS Configuration Notice

**If you're developing for iOS**, the current Firebase configuration file contains **placeholder values** that will cause the app to fail. You must configure iOS Firebase properly before building.

**📱 iOS Developers**: See **[iOS Firebase Setup Guide](docs/FIREBASE_IOS_SETUP.md)** for complete instructions.

**Quick validation**: Run `./scripts/validate_firebase_ios.sh` to check your iOS configuration.

---

## Prerequisites

- Google Account
- Flutter SDK installed
- Android Studio (for Android development)
- Xcode (for iOS development)

## Step 1: Create Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add Project"** or **"Create a Project"**
3. Enter project name: `GUD Express` (or your preferred name)
4. Accept terms and click **Continue**
5. (Optional) Enable Google Analytics
6. Click **Create Project**
7. Wait for project creation to complete

## Step 2: Register Android App

1. In the Firebase Console, click the **Android icon** to add an Android app
2. Enter your Android package name: `com.gudexpress.gud_app`
3. (Optional) Add a nickname: `GUD Android App`
4. Click **Register App**

## Step 3: Download google-services.json

1. Download the `google-services.json` file from the Firebase Console
2. Place it in your project at: `android/app/google-services.json`

```bash
# Example placement:
gud/
└── android/
    └── app/
        └── google-services.json  # <-- Place here
```

## Step 3B: Register iOS App (Critical!)

**⚠️ iOS developers must complete this step!**

The iOS app requires proper Firebase configuration. The current `ios/Runner/GoogleService-Info.plist` contains placeholder values that will NOT work.

### Quick iOS Setup

1. In the Firebase Console, click the **iOS icon** (🍎) to add an iOS app
2. Enter iOS bundle ID: `com.gudexpress.gud_app`
3. (Optional) Add a nickname: `GUD iOS App`
4. Click **Register App**
5. Download `GoogleService-Info.plist`
6. Replace the placeholder file:
   ```bash
   # Replace placeholder with actual configuration
   cp /path/to/downloaded/GoogleService-Info.plist ios/Runner/GoogleService-Info.plist
   ```
7. Validate the configuration:
   ```bash
   ./scripts/validate_firebase_ios.sh
   ```

### Complete iOS Instructions

For detailed step-by-step instructions with troubleshooting, see:
- **[iOS Firebase Setup Guide](docs/FIREBASE_IOS_SETUP.md)** - Complete iOS configuration guide

## Step 4: Enable Firebase Services

### 4.1 Enable Authentication

1. In Firebase Console, go to **Build** → **Authentication**
2. Click **Get Started**
3. Click on **Email/Password** in the Sign-in method tab
4. Enable **Email/Password** authentication
5. Click **Save**

### 4.2 Enable Cloud Firestore

1. In Firebase Console, go to **Build** → **Firestore Database**
2. Click **Create Database**
3. Choose **Start in production mode** (we'll add rules next)
4. Select your Cloud Firestore location (choose closest to your users)
5. Click **Enable**

### 4.3 Enable Firebase Storage

1. In Firebase Console, go to **Build** → **Storage**
2. Click **Get Started**
3. Choose **Start in production mode**
4. Select your Storage location
5. Click **Done**

## Step 5: Configure Firestore Security Rules

1. Go to **Firestore Database** → **Rules** tab
2. Replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    function isDriver() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'driver';
    }
    
    // Users collection - users can read their own data, admins can read/write
    match /users/{userId} {
      allow read: if isAuthenticated() && (request.auth.uid == userId || isAdmin());
      allow write: if isAdmin();
    }
    
    // Drivers collection - admins can read/write, drivers can read their own
    match /drivers/{driverId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    // Loads collection - admins full access, drivers read their own
    match /loads/{loadId} {
      allow read: if isAuthenticated() && 
                     (isAdmin() || resource.data.driverId == request.auth.uid);
      allow write: if isAdmin();
      
      // POD subcollection
      match /pods/{podId} {
        allow read: if isAuthenticated();
        allow write: if isAuthenticated() && 
                        (isAdmin() || get(/databases/$(database)/documents/loads/$(loadId)).data.driverId == request.auth.uid);
      }
    }
  }
}
```

3. Click **Publish**

## Step 6: Configure Storage Security Rules

1. Go to **Storage** → **Rules** tab
2. Replace the default rules with:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // POD images - authenticated users can upload, all can read
    match /pods/{loadId}/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

3. Click **Publish**

## Step 7: Create First Admin User

You need to manually create the first admin user in Firebase Console:

### 7.1 Create Authentication User

1. Go to **Authentication** → **Users** tab
2. Click **Add User**
3. Enter email: `admin@gudexpress.com` (or your admin email)
4. Enter a strong password
5. Click **Add User**
6. Copy the **User UID** (you'll need this)

### 7.2 Create User Document in Firestore

1. Go to **Firestore Database** → **Data** tab
2. Click **Start Collection**
3. Collection ID: `users`
4. Click **Next**
5. Document ID: Paste the **User UID** you copied
6. Add the following fields:

| Field | Type | Value |
|-------|------|-------|
| role | string | admin |
| name | string | Admin User |
| phone | string | +1234567890 |
| truckNumber | string | N/A |
| createdAt | timestamp | (click "Use current date/time") |

7. Click **Save**

## Step 8: Run the App

1. Ensure `google-services.json` is in place
2. Install dependencies:

```bash
flutter pub get
```

3. Run the app:

```bash
flutter run
```

4. Log in with your admin credentials

## Step 9: Create Drivers (Using the App)

1. Log in as admin
2. Tap the **People icon** (Manage Drivers)
3. Fill in the driver form:
   - Email (e.g., `driver@gudexpress.com`)
   - Password
   - Name
   - Phone
   - Truck Number
4. Click **Create Driver**
5. Driver can now log in with their credentials

## Step 10: Create Loads (Using the App)

1. Log in as admin
2. Tap the **Plus icon** (Create Load)
3. Fill in load details:
   - Load Number (e.g., `LOAD-001`)
   - Pickup Address
   - Delivery Address
   - Rate ($)
   - Select an available driver
4. Click **Create Load**
5. Load is now visible to the assigned driver

## Testing

### Test as Admin:
1. Log in with admin credentials
2. Verify you can see the Admin Dashboard
3. Create a driver
4. Create a load and assign it to the driver

### Test as Driver:
1. Log out
2. Log in with driver credentials
3. Verify you see the Driver Dashboard
4. Verify you can see your assigned loads
5. Check earnings (should be $0 initially)

## Troubleshooting

### Common Issues

#### Android Issues

**"Firebase not initialized"**
- Ensure `google-services.json` is in `android/app/`
- Run `flutter clean && flutter pub get`

**App crashes on startup (Android)**
- Check Firebase configuration in `build.gradle` files
- Verify package name matches in Firebase Console and `build.gradle`

#### iOS Issues

**"Firebase not configured" or authentication fails on iOS**
- ⚠️ **Most common issue**: Using placeholder values in `GoogleService-Info.plist`
- Run validation: `./scripts/validate_firebase_ios.sh`
- See [iOS Firebase Setup Guide](docs/FIREBASE_IOS_SETUP.md) for fix

**iOS app crashes on startup**
- Verify `GoogleService-Info.plist` exists at `ios/Runner/GoogleService-Info.plist`
- Check file contains no "placeholder" text
- Clean and rebuild: `flutter clean && cd ios && pod install && cd ..`

**Authentication works on Android but not iOS**
- This is the classic placeholder value issue
- Download correct `GoogleService-Info.plist` from Firebase Console
- Replace the file at `ios/Runner/GoogleService-Info.plist`
- Validate: `./scripts/validate_firebase_ios.sh`

#### General Issues

**"User not found" or permission denied**
- Verify the user document exists in Firestore
- Check that the `role` field is set correctly

**Security rules error**
- Verify security rules are published
- Check that timestamps use `request.time` not `request.timestamp`

### Getting Help

- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/firebase+flutter)

## Next Steps

Once Firebase is set up and working:

1. **Customize the app** with your branding
2. **Add more features** like POD upload functionality
3. **Set up production** Firebase project (separate from development)
4. **Configure CI/CD** for automated builds
5. **Deploy to App Store** and Google Play

## Security Best Practices

- ✅ Use strong passwords for all users
- ✅ Enable 2FA for your Firebase account
- ✅ Keep `google-services.json` secure (don't commit to public repos)
- ✅ Use separate Firebase projects for development and production
- ✅ Regularly review Firestore security rules
- ✅ Monitor Firebase usage and set billing alerts
- ✅ Backup Firestore data regularly

## Production Checklist

Before going live:

- [ ] Create separate production Firebase project
- [ ] Review and test security rules thoroughly
- [ ] Set up Firestore indexes for queries
- [ ] Configure billing alerts
- [ ] Set up monitoring and alerts
- [ ] Test on real devices
- [ ] Perform security audit
- [ ] Set up backup strategy
- [ ] Document incident response plan

---

**Congratulations!** 🎉 Your Firebase backend is now ready for the GUD Express app.
