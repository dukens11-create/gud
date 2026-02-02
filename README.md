# GUD Express - Trucking Management App

A comprehensive Flutter-based trucking management system for drivers and dispatchers with Firebase backend.

## 📦 Download APK

**🚀 [DOWNLOAD APK NOW](https://github.com/dukens11-create/gud/actions/runs/21572746265)** ⬅️ Click here!

Or see [DOWNLOAD_APK.md](DOWNLOAD_APK.md) for detailed download instructions.

---

## Features

### Driver Features
- View assigned loads in real-time
- Update load status (picked up, in transit, delivered)
- Start and end trips with timestamps
- Upload Proof of Delivery (POD) photos
- Track earnings from completed loads
- Real-time load updates

### Admin Features
- View all loads across all drivers
- Create and assign loads to drivers
- Manage driver profiles
- Monitor load statuses
- Manual load status updates

## Technology Stack

- **Frontend**: Flutter 3.0+
- **Backend**: Firebase
  - Authentication
  - Firestore Database
  - Cloud Storage
- **State Management**: Stream-based with StreamBuilder
- **Design**: Material Design 3

## Quick Start

See [SETUP.md](SETUP.md) for detailed setup instructions.

### Prerequisites
- Flutter SDK 3.0.0+
- Firebase account
- Android Studio or VS Code

### Basic Setup
1. Clone the repository
2. Create a Firebase project
3. Download and place `google-services.json` in `android/app/`
4. Run `flutter pub get`
5. Create admin user in Firebase Console
6. Run `flutter run`

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # Root widget with auth wrapper
├── routes.dart               # Named routes configuration
├── models/                   # Data models
│   ├── app_user.dart
│   ├── driver.dart
│   ├── load.dart
│   └── pod.dart
├── services/                 # Business logic layer
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── storage_service.dart
├── screens/                  # UI screens
│   ├── login_screen.dart
│   ├── driver/
│   │   ├── driver_home.dart
│   │   ├── driver_load_detail.dart
│   │   ├── upload_pod_screen.dart
│   │   └── earnings_screen.dart
│   └── admin/
│       ├── admin_home.dart
│       ├── manage_drivers_screen.dart
│       ├── create_load_screen.dart
│       └── admin_load_detail.dart
└── widgets/                  # Reusable widgets
    ├── app_button.dart
    ├── app_textfield.dart
    └── loading.dart
```

## Documentation

- [Setup Instructions](SETUP.md) - Complete setup guide
- [Firebase Rules](FIREBASE_RULES.md) - Security rules for Firestore and Storage

## Security

The app implements comprehensive Firebase Security Rules:
- Role-based access control (admin/driver)
- Drivers can only access their assigned loads
- Secure POD photo uploads
- Authenticated access required for all operations

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.

## Support

For issues or questions, please create an issue in the GitHub repository.