FIREBASE CONFIGURATION FOR iOS
================================

⚠️ IMPORTANT: PLACEHOLDER VALUES DETECTED
The current GoogleService-Info.plist file contains PLACEHOLDER values that 
will cause Firebase services to FAIL on iOS devices.

You MUST replace this file with valid configuration from Firebase Console
before building for iOS.

Current Issues:
- CLIENT_ID: Contains "placeholder" instead of real OAuth client ID
- REVERSED_CLIENT_ID: Contains "placeholder" instead of real reversed client ID
- GOOGLE_APP_ID: Contains "placeholder" instead of real iOS app ID

Quick Fix:
==========
1. Download the correct GoogleService-Info.plist from Firebase Console
   URL: https://console.firebase.google.com/project/gud-express/settings/general
   
2. Replace: ios/Runner/GoogleService-Info.plist

3. Validate: ./scripts/validate_firebase_ios.sh

Project Information:
====================
- Project ID: gud-express
- Bundle ID: com.gudexpress.gud_app
- Storage Bucket: gud-express.firebasestorage.app
- Project Number: 750390855294

Detailed Setup Instructions:
============================
See docs/FIREBASE_IOS_SETUP.md for complete step-by-step instructions including:
- How to register iOS app in Firebase Console
- How to download the correct configuration
- How to validate your configuration
- Troubleshooting common issues

Template File:
==============
A template file is available at: ios/Runner/GoogleService-Info.plist.template
This shows the structure but should NOT be used for actual builds.

For More Information:
=====================
- docs/FIREBASE_IOS_SETUP.md - Complete iOS Firebase setup guide
- FIREBASE_SETUP.md - General Firebase setup
- README.md - Main project documentation
