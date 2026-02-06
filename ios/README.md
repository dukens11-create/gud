# iOS Setup for GUD Express

## Prerequisites
- macOS with Xcode 14.0 or later
- CocoaPods installed (`sudo gem install cocoapods`)
- Active Apple Developer account
- Firebase project with iOS app configured

## Setup Steps

### 1. Firebase Configuration
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project (or create a new one)
3. Add an iOS app to your Firebase project
4. Use bundle identifier: `com.gud.express`
5. Download `GoogleService-Info.plist`
6. Replace the placeholder file at `ios/Runner/GoogleService-Info.plist` with your downloaded file

### 2. Install Dependencies
```bash
cd ios
pod install
cd ..
```

### 3. Configure Signing
1. Open `ios/Runner.xcworkspace` in Xcode (NOT .xcodeproj)
2. Select the Runner target
3. Go to "Signing & Capabilities"
4. Select your development team
5. Xcode will automatically create provisioning profiles

### 4. Enable Capabilities
In Xcode, under "Signing & Capabilities", add:
- **Push Notifications**: For receiving FCM messages
- **Background Modes**: Enable "Location updates", "Background fetch", "Remote notifications"
- **Sign in with Apple**: (Optional) For Apple Sign-In support

### 5. Build and Run
```bash
flutter run -d ios
# or
flutter build ios
```

## Push Notifications Setup

### APNs Authentication Key (Recommended)
1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to Certificates, Identifiers & Profiles > Keys
3. Create a new key and enable "Apple Push Notifications service (APNs)"
4. Download the .p8 key file
5. In Firebase Console, go to Project Settings > Cloud Messaging > Apple app configuration
6. Upload your APNs Auth Key (.p8 file) with Key ID and Team ID
7. This key never expires and works for all apps in your team

### APNs Certificate (Legacy Alternative)
If you prefer using certificates instead of auth keys:
1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to Certificates, Identifiers & Profiles > Certificates
3. Create an APNs certificate for your app
4. Download the certificate and export as .p12
5. Upload to Firebase Console under Project Settings > Cloud Messaging

## Troubleshooting

### Pod Install Fails
```bash
cd ios
pod repo update
pod install --repo-update
cd ..
```

### Signing Issues
- Make sure you have a valid Apple Developer account
- Check that your bundle identifier matches in Xcode and Firebase
- Try "Automatically manage signing" in Xcode

### Firebase Not Working
- Verify `GoogleService-Info.plist` is properly configured
- Check that the file is included in the Xcode project
- Rebuild the app after changing Firebase configuration

### Location Not Working
- Check that location permissions are properly added to Info.plist
- Request location permissions in your Dart code before using location features
- Test on a real device (location doesn't work well in simulator)

## Building for Release

### App Store
```bash
flutter build ios --release
```

Then open `ios/Runner.xcworkspace` in Xcode and:
1. Select "Any iOS Device" as the build target
2. Product > Archive
3. Upload to App Store Connect

### TestFlight
After archiving, use Xcode's Organizer to upload to TestFlight for beta testing.

## Important Notes
- Always test on real iOS devices, not just simulator
- Location tracking requires real device
- Push notifications require real device
- Camera/photo library require real device
- Minimum iOS version: 13.0
