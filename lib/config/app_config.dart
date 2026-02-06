import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'environment.dart';

/// Application configuration loader
/// 
/// Loads configuration from .env files and validates required settings
/// Use as a singleton: AppConfig.instance
class AppConfig {
  // Singleton pattern
  static final AppConfig _instance = AppConfig._internal();
  static AppConfig get instance => _instance;
  factory AppConfig() => _instance;
  AppConfig._internal();

  bool _initialized = false;

  /// Check if configuration is initialized
  bool get isInitialized => _initialized;

  /// Initialize app configuration
  /// Load .env file based on environment
  Future<void> initialize({Environment? environment}) async {
    // Determine which .env file to load
    String envFile = '.env.development';
    
    if (environment != null) {
      switch (environment) {
        case Environment.development:
          envFile = '.env.development';
          EnvironmentConfig.setEnvironment(Environment.development);
          break;
        case Environment.staging:
          envFile = '.env.staging';
          EnvironmentConfig.setEnvironment(Environment.staging);
          break;
        case Environment.production:
          envFile = '.env.production';
          EnvironmentConfig.setEnvironment(Environment.production);
          break;
      }
    } else {
      // Auto-detect based on build mode
      const bool isProduction = bool.fromEnvironment('dart.vm.product');
      if (isProduction) {
        envFile = '.env.production';
        EnvironmentConfig.setEnvironment(Environment.production);
      }
    }

    try {
      // Load .env file
      await dotenv.load(fileName: envFile);
      _initialized = true;
      
      // Validate configuration
      validateConfig();
      
      print('✅ Configuration loaded from $envFile');
      print('Environment: ${EnvironmentConfig.current.environmentName}');
    } catch (e) {
      print('⚠️ Warning: Could not load $envFile, using defaults: $e');
      _initialized = true; // Continue with defaults
    }
  }

  /// Validate required configuration
  void validateConfig() {
    final missingKeys = <String>[];

    // Check critical configuration keys
    final criticalKeys = [
      'FIREBASE_PROJECT_ID',
      'GOOGLE_MAPS_API_KEY',
    ];

    for (var key in criticalKeys) {
      if (!dotenv.env.containsKey(key) || dotenv.env[key]!.isEmpty) {
        missingKeys.add(key);
      }
    }

    if (missingKeys.isNotEmpty && EnvironmentConfig.isProduction) {
      throw ConfigurationException(
        'Missing critical configuration keys: ${missingKeys.join(", ")}',
      );
    }

    if (missingKeys.isNotEmpty) {
      print('⚠️ Warning: Missing configuration keys: ${missingKeys.join(", ")}');
    }
  }

  // Getters for configuration values with fallbacks

  /// Firebase API Key
  String get firebaseApiKey => 
      dotenv.env['FIREBASE_API_KEY'] ?? 
      EnvironmentConfig.current.firebaseProjectId;

  /// Firebase Project ID
  String get firebaseProjectId => 
      dotenv.env['FIREBASE_PROJECT_ID'] ?? 
      EnvironmentConfig.current.firebaseProjectId;

  /// Firebase Storage Bucket
  String get firebaseStorageBucket => 
      dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? 
      EnvironmentConfig.current.firebaseStorageBucket;

  /// Firebase Messaging Sender ID
  String get firebaseMessagingSenderId => 
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';

  /// Firebase App ID
  String get firebaseAppId => 
      dotenv.env['FIREBASE_APP_ID'] ?? '';

  /// Google Maps API Key
  String get googleMapsApiKey => 
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 
      EnvironmentConfig.current.googleMapsApiKey;

  /// API Base URL
  String get apiBaseUrl => 
      dotenv.env['API_BASE_URL'] ?? 
      EnvironmentConfig.current.apiBaseUrl;

  /// API Timeout
  int get apiTimeout => 
      int.tryParse(dotenv.env['API_TIMEOUT'] ?? '') ?? 
      EnvironmentConfig.current.apiTimeout;

  /// Enable Analytics
  bool get enableAnalytics => 
      dotenv.env['ENABLE_ANALYTICS']?.toLowerCase() == 'true' ||
      EnvironmentConfig.current.enableAnalytics;

  /// Enable Crash Reporting
  bool get enableCrashReporting => 
      dotenv.env['ENABLE_CRASH_REPORTING']?.toLowerCase() == 'true' ||
      EnvironmentConfig.current.enableCrashReporting;

  /// Enable Debug Mode
  bool get enableDebugMode => 
      dotenv.env['ENABLE_DEBUG_MODE']?.toLowerCase() == 'true' ||
      EnvironmentConfig.current.debugMode;

  /// App Name
  String get appName => 
      dotenv.env['APP_NAME'] ?? 
      EnvironmentConfig.current.appName;

  /// Get all configuration as a map (for debugging)
  Map<String, dynamic> toMap() {
    return {
      'firebaseProjectId': firebaseProjectId,
      'firebaseStorageBucket': firebaseStorageBucket,
      'googleMapsApiKey': googleMapsApiKey.substring(0, 10) + '...', // Redact
      'apiBaseUrl': apiBaseUrl,
      'apiTimeout': apiTimeout,
      'enableAnalytics': enableAnalytics,
      'enableCrashReporting': enableCrashReporting,
      'enableDebugMode': enableDebugMode,
      'appName': appName,
      'environment': EnvironmentConfig.current.environmentName,
    };
  }

  @override
  String toString() {
    return 'AppConfig${toMap()}';
  }
}

/// Configuration exception
class ConfigurationException implements Exception {
  final String message;
  ConfigurationException(this.message);

  @override
  String toString() => 'ConfigurationException: $message';
}
