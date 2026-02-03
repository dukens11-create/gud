FIREBASE CONFIGURATION REQUIRED
================================

To complete the iOS Firebase setup, you need to:

1. Go to Firebase Console (https://console.firebase.google.com)
2. Select your project
3. Click "Add app" → iOS
4. Enter Bundle ID: com.gudexpress.gud_app
5. Register app and download GoogleService-Info.plist
6. Place the downloaded file here: ios/Runner/GoogleService-Info.plist

The GoogleService-Info.plist file should be placed in this same directory
(ios/Runner/) alongside this README file.

IMPORTANT: Do not commit GoogleService-Info.plist to version control
as it contains sensitive Firebase configuration.

For more details, see:
- DEPLOYMENT_PRODUCTION.md
- FIREBASE_SETUP.md
