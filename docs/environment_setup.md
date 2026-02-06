# Environment Configuration Setup

This guide explains how to set up and use environment configuration in the GUD Express app.

## Overview

The GUD Express app uses environment variables to manage sensitive configuration data like API keys, Firebase credentials, and environment-specific settings. This approach:

- Keeps sensitive data out of version control
- Allows different configurations for development, staging, and production
- Makes it easy to rotate API keys without code changes
- Supports multiple developers with different credentials

## Quick Start

### 1. Create Your Environment File

Copy the example environment file:

```bash
cp .env.example .env
```

### 2. Fill in Your Credentials

Edit `.env` and replace the placeholder values with your actual credentials:

```env
# Firebase Configuration
FIREBASE_API_KEY=AIzaSyC...
FIREBASE_APP_ID=1:123456789:web:abc123
FIREBASE_MESSAGING_SENDER_ID=123456789
FIREBASE_PROJECT_ID=gud-express-prod
FIREBASE_STORAGE_BUCKET=gud-express-prod.appspot.com
FIREBASE_AUTH_DOMAIN=gud-express-prod.firebaseapp.com

# Google Maps API Key
GOOGLE_MAPS_API_KEY=AIzaSyD...

# Apple Sign In (iOS only)
APPLE_SERVICE_ID=com.gudexpress.signin

# Environment
ENVIRONMENT=development
```

### 3. Load Configuration in Your App

The environment configuration is automatically loaded at app startup. In your `main.dart`:

```dart
import 'package:gud_app/config/environment_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await EnvironmentConfig.load();
  
  // Validate required variables (optional but recommended)
  EnvironmentConfig.validate();
  
  runApp(MyApp());
}
```

## Using Environment Variables

### Access Configuration Values

```dart
import 'package:gud_app/config/environment_config.dart';

// Firebase configuration
final apiKey = EnvironmentConfig.firebaseApiKey;
final projectId = EnvironmentConfig.firebaseProjectId;

// Google Maps
final mapsKey = EnvironmentConfig.googleMapsApiKey;

// Environment checks
if (EnvironmentConfig.isDevelopment) {
  print('Running in development mode');
}
```

### Available Configuration Variables

#### Firebase
- `firebaseApiKey` - Firebase API key
- `firebaseAppId` - Firebase application ID
- `firebaseMessagingSenderId` - FCM sender ID
- `firebaseProjectId` - Firebase project ID
- `firebaseStorageBucket` - Cloud Storage bucket
- `firebaseAuthDomain` - Auth domain

#### Google Maps
- `googleMapsApiKey` - Google Maps API key

#### Apple Sign In
- `appleServiceId` - Apple service ID (iOS)

#### Environment
- `environment` - Current environment (development/staging/production)
- `isDevelopment` - Boolean check for development
- `isStaging` - Boolean check for staging
- `isProduction` - Boolean check for production

#### Optional
- `apiBaseUrl` - Custom API endpoint

## Multiple Environments

### Development Environment

```env
ENVIRONMENT=development
FIREBASE_PROJECT_ID=gud-express-dev
# ... other dev credentials
```

### Staging Environment

```env
ENVIRONMENT=staging
FIREBASE_PROJECT_ID=gud-express-staging
# ... other staging credentials
```

### Production Environment

```env
ENVIRONMENT=production
FIREBASE_PROJECT_ID=gud-express-prod
# ... other production credentials
```

## Security Best Practices

### DO ✅

1. **Always use `.env` for sensitive data**
   ```dart
   final apiKey = EnvironmentConfig.firebaseApiKey;
   ```

2. **Keep `.env` out of version control**
   - The `.env` file is already in `.gitignore`
   - Never commit actual credentials

3. **Use `.env.example` as a template**
   - Document all required variables
   - Use placeholder values
   - Safe to commit to version control

4. **Validate configuration on startup**
   ```dart
   EnvironmentConfig.validate(); // Throws if required vars missing
   ```

5. **Rotate API keys regularly**
   - Update `.env` file
   - No code changes needed

### DON'T ❌

1. **Never hardcode API keys in source code**
   ```dart
   // ❌ BAD
   const apiKey = 'AIzaSyC...';
   
   // ✅ GOOD
   final apiKey = EnvironmentConfig.firebaseApiKey;
   ```

2. **Never commit `.env` to version control**
   - Check `.gitignore` includes `*.env`
   - Review commits before pushing

3. **Never log sensitive data in production**
   ```dart
   // ❌ BAD
   print('API Key: ${EnvironmentConfig.firebaseApiKey}');
   
   // ✅ GOOD
   if (EnvironmentConfig.isDevelopment) {
     print('Debug info: ...');
   }
   ```

## Troubleshooting

### Error: Missing required environment variables

**Problem**: App throws exception on startup about missing variables.

**Solution**: 
1. Ensure `.env` file exists in project root
2. Check all required variables are set
3. Verify no typos in variable names
4. Run `EnvironmentConfig.validate()` to see which variables are missing

### Error: Unable to load asset .env

**Problem**: Flutter can't find the `.env` file.

**Solution**:
1. Ensure `.env` is in the project root directory (not in `lib/`)
2. Check `pubspec.yaml` includes `.env` in assets:
   ```yaml
   flutter:
     assets:
       - .env
   ```
3. Run `flutter clean` and rebuild

### Environment variables are empty

**Problem**: All `EnvironmentConfig` getters return empty strings.

**Solution**:
1. Call `await EnvironmentConfig.load()` before accessing variables
2. Ensure `.env` file has correct format (no quotes around values)
3. Check file encoding is UTF-8

### Different values in Android vs iOS

**Problem**: Environment variables work on one platform but not another.

**Solution**:
1. Run `flutter clean`
2. Delete build folders: `rm -rf build/ ios/build/ android/build/`
3. Rebuild: `flutter pub get && flutter run`

## CI/CD Integration

### GitHub Actions

Store secrets as GitHub repository secrets:

```yaml
- name: Create .env file
  run: |
    echo "FIREBASE_API_KEY=${{ secrets.FIREBASE_API_KEY }}" > .env
    echo "GOOGLE_MAPS_API_KEY=${{ secrets.GOOGLE_MAPS_API_KEY }}" >> .env
    echo "ENVIRONMENT=production" >> .env
```

### Codemagic

Add environment variables in Codemagic settings:

```yaml
environment:
  vars:
    FIREBASE_API_KEY: $FIREBASE_API_KEY
    GOOGLE_MAPS_API_KEY: $GOOGLE_MAPS_API_KEY
```

## Testing

### Unit Tests

Mock environment configuration in tests:

```dart
setUp(() {
  // Mock environment for testing
  TestWidgetsFlutterBinding.ensureInitialized();
});

test('should use correct API key', () {
  // Test with mocked environment
});
```

### Integration Tests

Use test-specific `.env` file:

```dart
await dotenv.load(fileName: '.env.test');
```

## Additional Resources

- [Flutter dotenv package](https://pub.dev/packages/flutter_dotenv)
- [12-Factor App Configuration](https://12factor.net/config)
- [Firebase Security Best Practices](https://firebase.google.com/docs/projects/api-keys)
- [Google Maps API Key Best Practices](https://developers.google.com/maps/api-key-best-practices)

## Support

For issues or questions:
1. Check this documentation
2. Review `.env.example` for required variables
3. Consult the team's internal documentation
4. Contact the development team
