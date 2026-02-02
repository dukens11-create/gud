# GUD Express - Trucking Management App

## 🌐 Live Demo

**Try it now:** https://dukens11-create.github.io/gud/

### Install as PWA
- **Mobile**: Visit link, tap "Add to Home Screen"
- **Desktop**: Visit link, click install icon in address bar

---

A comprehensive Flutter-based trucking management app for drivers and dispatchers with full Firebase backend integration.

## Features

### Driver Features
- 📱 View assigned loads in real-time
- 🚛 Start and complete trips with mileage tracking
- 📸 Upload Proof of Delivery (POD) with camera integration
- 💰 Track earnings from completed loads
- 🔔 Real-time load updates via Firestore
- 📍 View pickup and delivery locations
- ⏱️ Trip time tracking

### Admin Features
- 📊 Dashboard with real-time load overview
- 👥 Create and manage driver accounts
- 📦 Create and assign loads to drivers
- 💼 Monitor all load statuses across the fleet
- 📈 Track driver performance and earnings
- 🔍 Search and filter loads

## Technology Stack

- **Frontend**: Flutter 3.0+
- **Backend**: Firebase
  - Authentication (Email/Password)
  - Cloud Firestore (Real-time database)
  - Firebase Storage (Image uploads)
- **Design**: Material Design 3
- **Platforms**: Android, iOS, Web/PWA
- **Image Handling**: Image Picker with camera/gallery support

## 🌐 Web App / PWA

**Live Demo**: https://dukens11-create.github.io/gud/

### Install as PWA
- **Android/Chrome**: Visit the link, tap menu (⋮) → "Install app"
- **iOS/Safari**: Visit the link, tap Share (⎙) → "Add to Home Screen"

### Build Locally
```bash
flutter build web --release
# Output: build/web/
```

For detailed deployment instructions, see [PWA Deployment Guide](docs/PWA_DEPLOYMENT.md).

## Quick Start

### Prerequisites
- Flutter SDK 3.0.0+
- Android Studio or VS Code
- Firebase account (free tier available)

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/dukens11-create/gud.git
   cd gud
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   
   **Option A: Using FlutterFire CLI (Recommended)**
   ```bash
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configure Firebase
   flutterfire configure
   ```
   
   **Option B: Manual Setup**
   - Follow the detailed instructions in [FIREBASE_SETUP.md](FIREBASE_SETUP.md)

4. **Run the app**
   ```bash
   flutter run
   ```

For complete Firebase setup instructions, see [FIREBASE_SETUP.md](FIREBASE_SETUP.md).

## Demo Accounts

For testing, you can create accounts with these roles:

**Admin Account:**
- Email: admin@gud.com
- Password: admin123
- Access: Full admin dashboard, create loads, manage drivers

**Driver Account:**
- Email: driver@gud.com  
- Password: driver123
- Access: View assigned loads, upload PODs, track earnings

**Note:** You'll need to create these accounts in your Firebase project first.

## Project Structure

```
lib/
├── main.dart                     # App entry point with Firebase init
├── app.dart                      # Root widget with auth state management
├── routes.dart                   # Named routes configuration
├── firebase_options.dart         # Firebase configuration
├── models/                       # Data models
│   ├── app_user.dart            # User model
│   ├── load.dart                # Load model with Firestore serialization
│   ├── pod.dart                 # Proof of Delivery model
│   └── driver.dart              # Driver model
├── services/                     # Business logic layer
│   ├── auth_service.dart        # Firebase Authentication
│   ├── firestore_service.dart   # Firestore database operations
│   └── storage_service.dart     # Firebase Storage for images
├── screens/                      # UI screens
│   ├── login_screen.dart        # Login with email/password
│   ├── driver/
│   │   ├── driver_home.dart          # Driver dashboard
│   │   ├── driver_load_detail.dart   # Load details & actions
│   │   ├── upload_pod_screen.dart    # POD upload with camera
│   │   └── earnings_screen.dart      # Earnings tracking
│   └── admin/
│       ├── admin_home.dart           # Admin dashboard
│       ├── create_load_screen.dart   # Create & assign loads
│       └── manage_drivers_screen.dart # Driver management
└── widgets/                      # Reusable widgets
    ├── app_button.dart
    ├── app_textfield.dart
    └── loading.dart
```

## Documentation

- [FIREBASE_SETUP.md](FIREBASE_SETUP.md) - Complete Firebase setup guide
- [FIREBASE_RULES.md](FIREBASE_RULES.md) - Firestore and Storage security rules
- [STORAGE_RULES.txt](STORAGE_RULES.txt) - Firebase Storage rules (deployable)
- [PWA Deployment Guide](docs/PWA_DEPLOYMENT.md) - Web/PWA deployment

## Security

This app implements comprehensive security:
- ✅ Firebase Authentication with email/password
- ✅ Role-based access control (admin/driver)
- ✅ Firestore security rules
- ✅ Firebase Storage security rules
- ✅ Client-side validation
- ✅ Secure password reset

See [FIREBASE_RULES.md](FIREBASE_RULES.md) for detailed security configuration.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.

## Support

For issues or questions, please create an issue in the GitHub repository.