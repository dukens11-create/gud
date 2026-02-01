# Firebase Configuration Placeholder

⚠️ **IMPORTANT**: Before running the app, you MUST add your Firebase configuration files:

## Required Files

### For Android
1. Download `google-services.json` from Firebase Console
2. Place it in: `android/app/google-services.json`

### For iOS (if building for iOS)
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place it in: `ios/Runner/GoogleService-Info.plist`

## Getting the Configuration Files

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create a new one)
3. Click the gear icon > Project settings
4. Scroll down to "Your apps"
5. Click on your Android app (or add one if not exists)
6. Download `google-services.json`
7. Place the file in the location mentioned above

## Without These Files

The app will not compile or run. Firebase requires these configuration files to connect your app to your Firebase project.

See [SETUP.md](../SETUP.md) for complete setup instructions.
