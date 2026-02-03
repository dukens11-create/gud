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

## 📸 Screenshots

### Mobile Views

<table>
  <tr>
    <td><img src="screenshots/mobile/login.png" width="200" alt="Login Screen"/></td>
    <td><img src="screenshots/mobile/driver-dashboard.png" width="200" alt="Driver Dashboard"/></td>
    <td><img src="screenshots/mobile/admin-dashboard.png" width="200" alt="Admin Dashboard"/></td>
  </tr>
  <tr>
    <td align="center"><b>Login</b></td>
    <td align="center"><b>Driver Dashboard</b></td>
    <td align="center"><b>Admin Dashboard</b></td>
  </tr>
</table>

<table>
  <tr>
    <td><img src="screenshots/mobile/upload-pod.png" width="200" alt="Upload POD"/></td>
    <td><img src="screenshots/mobile/admin-statistics.png" width="200" alt="Statistics"/></td>
    <td><img src="screenshots/mobile/admin-expenses.png" width="200" alt="Expenses"/></td>
  </tr>
  <tr>
    <td align="center"><b>Upload POD</b></td>
    <td align="center"><b>Statistics</b></td>
    <td align="center"><b>Expense Tracking</b></td>
  </tr>
</table>

### Desktop Views

<table>
  <tr>
    <td><img src="screenshots/desktop/admin-dashboard-desktop.png" width="400" alt="Desktop Admin Dashboard"/></td>
    <td><img src="screenshots/desktop/statistics-desktop.png" width="400" alt="Desktop Statistics"/></td>
  </tr>
  <tr>
    <td align="center"><b>Admin Dashboard (Desktop)</b></td>
    <td align="center"><b>Statistics Dashboard (Desktop)</b></td>
  </tr>
</table>

> 📱 **Note**: Screenshots will be added after initial deployment. See [Screenshot Guide](screenshots/README.md) for details.

---

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