FIREBASE CONFIGURATION FOR iOS
================================

The GoogleService-Info.plist file is already configured for the development
Firebase project (gud-express).

Current Configuration:
- Project ID: gud-express
- Bundle ID: com.gudexpress.gud_app
- Storage Bucket: gud-express.firebasestorage.app

This file is located at: ios/Runner/GoogleService-Info.plist

If you need to set up a different Firebase project (e.g., for production):

1. Go to Firebase Console (https://console.firebase.google.com)
2. Select your project or create a new one
3. Click "Add app" → iOS
4. Enter Bundle ID: com.gudexpress.gud_app
5. Register app and download GoogleService-Info.plist
6. Replace the file here: ios/Runner/GoogleService-Info.plist

NOTE: The current development configuration is committed to the repository.
For production deployments, ensure you use a separate Firebase project
with appropriate security rules.

For more details, see:
- DEPLOYMENT_PRODUCTION.md
- FIREBASE_SETUP.md
- ios/README.md
