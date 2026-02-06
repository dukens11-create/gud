import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration service for managing API keys and environment variables.
/// 
/// This service loads configuration from the .env file and provides
/// type-safe access to environment variables throughout the application.
/// 
/// Usage:
/// ```dart
/// await EnvironmentConfig.load();
/// final apiKey = EnvironmentConfig.firebaseApiKey;
/// ```
class EnvironmentConfig {
  /// Load environment variables from .env file
  /// 
  /// Call this method in main() before runApp()
  /// ```dart
  /// await EnvironmentConfig.load();
  /// ```
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  // Firebase Configuration
  
  /// Firebase API Key for authentication and services
  static String get firebaseApiKey => 
      dotenv.env['FIREBASE_API_KEY'] ?? '';

  /// Firebase Application ID
  static String get firebaseAppId => 
      dotenv.env['FIREBASE_APP_ID'] ?? '';

  /// Firebase Cloud Messaging Sender ID
  static String get firebaseMessagingSenderId => 
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';

  /// Firebase Project ID
  static String get firebaseProjectId => 
      dotenv.env['FIREBASE_PROJECT_ID'] ?? '';

  /// Firebase Storage Bucket name
  static String get firebaseStorageBucket => 
      dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';

  /// Firebase Auth Domain
  static String get firebaseAuthDomain => 
      dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '';

  // Google Maps Configuration
  
  /// Google Maps API Key for location services
  static String get googleMapsApiKey => 
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  // Apple Sign In Configuration
  
  /// Apple Service ID for Sign in with Apple (iOS)
  static String get appleServiceId => 
      dotenv.env['APPLE_SERVICE_ID'] ?? '';

  // Environment Settings
  
  /// Current environment (development, staging, or production)
  static String get environment => 
      dotenv.env['ENVIRONMENT'] ?? 'development';

  /// Check if running in development environment
  static bool get isDevelopment => environment == 'development';

  /// Check if running in staging environment
  static bool get isStaging => environment == 'staging';

  /// Check if running in production environment
  static bool get isProduction => environment == 'production';

  // Optional: API Endpoints
  
  /// Base URL for custom API endpoints
  static String get apiBaseUrl => 
      dotenv.env['API_BASE_URL'] ?? '';

  /// Validate that all required environment variables are set
  /// 
  /// Throws an exception if any required variables are missing
  /// In production, this will prevent the app from starting with invalid config
  static void validate() {
    final required = {
      'FIREBASE_API_KEY': firebaseApiKey,
      'FIREBASE_APP_ID': firebaseAppId,
      'FIREBASE_PROJECT_ID': firebaseProjectId,
      'GOOGLE_MAPS_API_KEY': googleMapsApiKey,
    };

    final missing = <String>[];
    required.forEach((key, value) {
      if (value.isEmpty) {
        missing.add(key);
      }
    });

    if (missing.isNotEmpty) {
      final errorMessage = 
        'Missing required environment variables: ${missing.join(', ')}\n'
        'Please check your .env file and ensure all required variables are set.';
      
      // In production, throw a fatal error
      if (isProduction) {
        throw Exception(
          '🚨 PRODUCTION BUILD ERROR 🚨\n'
          '$errorMessage\n\n'
          'Production builds MUST have all environment variables configured.\n'
          'Please create a .env file from .env.production template.'
        );
      } else {
        // In development, just warn
        print('⚠️ WARNING: $errorMessage');
      }
    }
  }

  /// Get all environment variables as a map (for debugging)
  /// 
  /// Note: Only use in development. Never expose in production.
  static Map<String, String> getAllVariables() {
    if (!isDevelopment) {
      throw Exception('getAllVariables() can only be called in development');
    }
    return dotenv.env;
  }
}
