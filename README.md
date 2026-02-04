# GUD Express - Trucking Management App (Demo Version)

## 🌐 Live Demo

**🚀 Try it now:** https://dukens11-create.github.io/gud/

### 📱 Install as Progressive Web App (PWA)

#### Android/Chrome
1. Visit the link above
2. Tap menu (⋮) → **"Install app"** or **"Add to Home Screen"**
3. The app will appear on your home screen like a native app!

#### iOS/Safari
1. Visit the link above
2. Tap Share (⎙) → **"Add to Home Screen"**
3. Tap **"Add"**
4. Launch from your home screen!

#### Desktop (Windows/Mac/Linux)
1. Visit the link above
2. Click the **install icon** (⊕) in the address bar
3. Click **"Install"**
4. The app opens in its own window!

### ✨ PWA Features
- ✅ Works offline after first visit
- ✅ Fast loading (cached assets)
- ✅ Installable on any device
- ✅ Automatic updates
- ✅ No app store required

---

A comprehensive Flutter-based trucking management app for drivers and dispatchers. This demo version uses mock data for easy testing.

## Features

### Driver Features
- View assigned loads with real-time updates
- Track load status (assigned, picked up, in transit, delivered)
- Track earnings from completed loads
- Simple and intuitive interface

### Admin Features
- View all loads across all drivers
- Monitor load statuses
- Quick overview of operations

## Demo Credentials

**Admin Account:**
- Email: admin@gud.com
- Password: admin123

**Driver Account:**
- Email: driver@gud.com
- Password: driver123

## Technology Stack

- **Frontend**: Flutter 3.0+
- **Design**: Material Design 3
- **Platforms**: Android, iOS, Web/PWA
- **Demo**: Mock data service (no backend required)

## Documentation

### 🚀 Just Built on CodeMagic?
- **[Quick Start After Build](./QUICKSTART_AFTER_BUILD.md)** ⚡ START HERE - 5-minute next steps
- **[Complete Post-CodeMagic Guide](./POST_CODEMAGIC_GUIDE.md)** 📖 Full deployment walkthrough (1000+ lines)

### 📱 Deployment & Distribution
- **[Deployment Guide](./DEPLOYMENT.md)** - Build and deploy instructions
- **[Production Deployment](./DEPLOYMENT_PRODUCTION.md)** - Production deployment with Firebase
- **[Firebase Setup](./FIREBASE_SETUP.md)** - Complete Firebase configuration

### 📚 Additional Guides
- **[Testing Guide](./TESTING_GUIDE.md)** - Testing procedures
- **[Quick Reference](./QUICK_REFERENCE.md)** - Quick start guide
- **[Architecture](./ARCHITECTURE.md)** - System architecture overview

## Development

### Build for web
```bash
flutter build web --release
```

### Run locally
```bash
flutter run -d chrome
```

### Prerequisites
- Flutter SDK 3.0.0+
- Android Studio or VS Code

### Basic Setup
1. Clone the repository
2. Run `flutter pub get`
3. Run `flutter run`

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # Root widget
├── routes.dart               # Named routes configuration
├── models/                   # Data models
│   ├── load.dart
│   ├── driver.dart
│   ├── expense.dart
│   ├── statistics.dart
│   ├── pod.dart
│   └── app_user.dart
├── services/                 # Business logic layer
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── expense_service.dart
│   ├── statistics_service.dart
│   └── storage_service.dart
├── screens/                  # UI screens
│   ├── login_screen.dart
│   ├── driver/
│   │   ├── driver_home.dart
│   │   ├── load_detail_screen.dart
│   │   ├── upload_pod_screen.dart
│   │   ├── earnings_screen.dart
│   │   └── driver_expenses_screen.dart
│   └── admin/
│       ├── admin_home.dart
│       ├── create_load_screen.dart
│       ├── manage_drivers_screen.dart
│       ├── expenses_screen.dart
│       ├── add_expense_screen.dart
│       └── statistics_screen.dart
│   │   ├── driver_home.dart
│   │   └── earnings_screen.dart
│   └── admin/
│       └── admin_home.dart
└── widgets/                  # Reusable widgets
    ├── app_button.dart
    ├── app_textfield.dart
    └── loading.dart
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.

## Support

For issues or questions, please create an issue in the GitHub repository.