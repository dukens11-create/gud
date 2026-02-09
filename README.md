# GUD Express - Trucking Management App

[![Build AAB](https://github.com/dukens11-create/gud/actions/workflows/build-aab.yml/badge.svg)](https://github.com/dukens11-create/gud/actions/workflows/build-aab.yml)
[![Flutter CI/CD](https://github.com/dukens11-create/gud/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/dukens11-create/gud/actions/workflows/flutter_ci.yml)

**GUD Express** is a comprehensive trucking management application built with Flutter, designed to streamline operations for trucking companies, drivers, and dispatchers.

## 📱 App Version
- **Version**: 2.1.0+2
- **Flutter SDK**: >=3.0.0 <4.0.0
- **Platform**: Android, iOS, Web

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.0.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / Xcode (for mobile development)
- Firebase account (for backend services)

### Installation

```bash
# Clone the repository
git clone https://github.com/dukens11-create/gud.git
cd gud

# Install dependencies
flutter pub get

# Run the app
flutter run
```

## 🏗️ Building for Production

### Android App Bundle (AAB)

#### Automated Build via GitHub Actions
The easiest way to build a signed AAB is through GitHub Actions:

1. **Setup**: Follow the [GitHub Actions AAB Guide](GITHUB_ACTIONS_AAB_GUIDE.md)
2. **Trigger**: Create a version tag or manually trigger the workflow
3. **Download**: Get the built AAB from Actions artifacts

See [GITHUB_ACTIONS_AAB_GUIDE.md](GITHUB_ACTIONS_AAB_GUIDE.md) for detailed instructions.

#### Local Build
For local builds, see [AAB_BUILD_GUIDE.md](AAB_BUILD_GUIDE.md)

## 📚 Documentation

- **[GitHub Actions AAB Guide](GITHUB_ACTIONS_AAB_GUIDE.md)** - Automated AAB builds with GitHub Actions
- **[AAB Build Guide](AAB_BUILD_GUIDE.md)** - Local AAB build instructions
- **[Deployment Guide](DEPLOYMENT.md)** - Deployment instructions
- **[Firebase Setup](FIREBASE_SETUP.md)** - Firebase configuration
- **[Architecture](ARCHITECTURE.md)** - App architecture overview

## 🔧 Development

### Project Structure
```
lib/
├── main.dart              # App entry point
├── models/                # Data models
├── screens/               # UI screens
├── services/              # Business logic & APIs
├── widgets/               # Reusable widgets
└── utils/                 # Utility functions

android/                   # Android-specific code
ios/                       # iOS-specific code
web/                       # Web-specific code
test/                      # Unit & widget tests
integration_test/          # Integration tests
```

### Running Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# With coverage
flutter test --coverage
```

### Code Quality
```bash
# Analyze code
flutter analyze

# Format code
dart format .
```

## 🔐 Security

- **Keystore Management**: Never commit keystore files or passwords
- **Secrets**: Use GitHub Secrets for CI/CD credentials
- **Dependencies**: Regularly update dependencies for security patches

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is proprietary software owned by GUD Express.

## 🆘 Support

For issues, questions, or contributions:
- Open an issue in the GitHub repository
- Contact the development team

---

**Last Updated**: February 2026