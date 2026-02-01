# GUD Express - Trucking Management App (Demo Version)

A comprehensive Flutter-based trucking management demo app for drivers and dispatchers with mock data.

## Features

### Driver Features
- View assigned loads
- Track earnings from completed loads
- Simple and intuitive interface

### Admin Features
- View all loads across all drivers
- Monitor load statuses
- Quick overview of operations

## Technology Stack

- **Frontend**: Flutter 3.0+
- **Backend**: Mock data service (no external dependencies)
- **Design**: Material Design 3

## Quick Start

### Prerequisites
- Flutter SDK 3.0.0+
- Android Studio or VS Code

### Basic Setup
1. Clone the repository
2. Run `flutter pub get`
3. Run `flutter run`

## Demo Accounts

This is a **demo version** with no authentication required:
- Click "Demo Login as Driver" to access the driver dashboard
- Click "Demo Login as Admin" to access the admin dashboard

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # Root widget
├── routes.dart               # Named routes configuration
├── models/                   # Data models
│   └── simple_load.dart
├── services/                 # Business logic layer
│   └── mock_data_service.dart
├── screens/                  # UI screens
│   ├── login_screen.dart
│   ├── driver/
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