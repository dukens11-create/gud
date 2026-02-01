# GUD Express - Flutter MVP

This is a Flutter-based trucking management application for GUD Express with Firebase backend integration.

## Features

### Admin Features
- View all loads across all drivers
- Manage drivers (add, view)
- Create new loads and assign to drivers
- Monitor load status in real-time
- Update load status manually

### Driver Features
- View assigned loads
- Update load status (picked up, in transit, delivered)
- Start and end trips with timestamps
- Upload Proof of Delivery (POD) photos
- View earnings summary

## Tech Stack

- **Flutter** - Cross-platform mobile framework
- **Firebase Authentication** - User authentication
- **Cloud Firestore** - Real-time database
- **Firebase Storage** - Image storage for PODs

## Project Structure

```
lib/
├── main.dart              # App entry point
├── app.dart               # App configuration and routing
├── routes.dart            # Route definitions
├── models/                # Data models
│   ├── app_user.dart
│   ├── driver.dart
│   ├── load_model.dart
│   └── pod.dart
├── services/              # Business logic
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── storage_service.dart
├── screens/               # UI screens
│   ├── login_screen.dart
│   ├── admin/
│   │   ├── admin_home.dart
│   │   ├── admin_load_detail.dart
│   │   ├── create_load_screen.dart
│   │   └── manage_drivers_screen.dart
│   └── driver/
│       ├── driver_home.dart
│       ├── driver_load_detail.dart
│       ├── earnings_screen.dart
│       └── upload_pod_screen.dart
└── widgets/               # Reusable UI components
    ├── app_button.dart
    ├── app_text_field.dart
    └── loading.dart
```

## Setup Instructions

See [SETUP.md](SETUP.md) for detailed Firebase configuration and setup instructions.

## Firebase Security

See [FIREBASE_RULES.md](FIREBASE_RULES.md) for complete Firestore and Storage security rules.

## Getting Started

1. Clone the repository
2. Follow the setup instructions in SETUP.md
3. Run `flutter pub get`
4. Run `flutter run`

## Dependencies

- firebase_core: ^3.6.0
- firebase_auth: ^5.3.1
- cloud_firestore: ^5.4.4
- firebase_storage: ^12.3.4
- image_picker: ^1.1.2
- intl: ^0.19.0

## License

Proprietary - GUD Express