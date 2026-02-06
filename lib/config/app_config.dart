/// Application configuration management.
///
/// This file manages environment-specific configuration for the GUD Express app.
/// It uses a singleton pattern to ensure consistent configuration across the app.
library;

import 'environment.dart';

/// Application configuration singleton.
///
/// Provides environment-specific configuration values such as API endpoints,
/// Firebase project IDs, and app metadata.
///
/// Example usage:
/// ```dart
/// final config = AppConfig.instance;
/// print(config.apiBaseUrl); // Gets URL for current environment
/// ```
class AppConfig {
  AppConfig._internal();

  static final AppConfig _instance = AppConfig._internal();

  /// Gets the singleton instance of AppConfig.
  static AppConfig get instance => _instance;

  // App metadata
  /// The application name.
  static const String appName = 'GUD Express';

  /// The application version.
  ///
  /// This should be kept in sync with pubspec.yaml.
  static const String appVersion = '1.0.0';

  /// The application build number.
  static const int buildNumber = 1;

  // API endpoints by environment
  static const Map<Environment, String> _apiBaseUrls = {
    Environment.development: 'http://localhost:3000',
    Environment.staging: 'https://staging-api.gudexpress.com',
    Environment.production: 'https://api.gudexpress.com',
  };

  // Firebase project IDs by environment
  static const Map<Environment, String> _firebaseProjectIds = {
    Environment.development: 'gud-dev',
    Environment.staging: 'gud-staging',
    Environment.production: 'gud-prod',
  };

  // Firebase web API keys by environment
  static const Map<Environment, String> _firebaseWebApiKeys = {
    Environment.development: 'your-dev-web-api-key',
    Environment.staging: 'your-staging-web-api-key',
    Environment.production: 'your-prod-web-api-key',
  };

  // Storage bucket names by environment
  static const Map<Environment, String> _storageBuckets = {
    Environment.development: 'gud-dev.appspot.com',
    Environment.staging: 'gud-staging.appspot.com',
    Environment.production: 'gud-prod.appspot.com',
  };

  /// Gets the API base URL for the current environment.
  String get apiBaseUrl =>
      _apiBaseUrls[EnvironmentConfig.current] ?? _apiBaseUrls[Environment.development]!;

  /// Gets the Firebase project ID for the current environment.
  String get firebaseProjectId =>
      _firebaseProjectIds[EnvironmentConfig.current] ??
      _firebaseProjectIds[Environment.development]!;

  /// Gets the Firebase web API key for the current environment.
  String get firebaseWebApiKey =>
      _firebaseWebApiKeys[EnvironmentConfig.current] ??
      _firebaseWebApiKeys[Environment.development]!;

  /// Gets the storage bucket name for the current environment.
  String get storageBucket =>
      _storageBuckets[EnvironmentConfig.current] ??
      _storageBuckets[Environment.development]!;

  // API endpoint paths
  /// Base path for API version 1 endpoints.
  String get apiV1Path => '$apiBaseUrl/api/v1';

  /// Authentication endpoints.
  String get authEndpoint => '$apiV1Path/auth';

  /// User endpoints.
  String get userEndpoint => '$apiV1Path/users';

  /// Delivery endpoints.
  String get deliveryEndpoint => '$apiV1Path/deliveries';

  /// Invoice endpoints.
  String get invoiceEndpoint => '$apiV1Path/invoices';

  /// Expense endpoints.
  String get expenseEndpoint => '$apiV1Path/expenses';

  /// Statistics endpoints.
  String get statisticsEndpoint => '$apiV1Path/statistics';

  // Timeouts and limits
  /// Default timeout for API requests in seconds.
  static const int apiTimeoutSeconds = 30;

  /// Maximum file upload size in bytes (10MB).
  static const int maxFileUploadSize = 10 * 1024 * 1024;

  /// Maximum image size in bytes (5MB).
  static const int maxImageSize = 5 * 1024 * 1024;

  /// Pagination default page size.
  static const int defaultPageSize = 20;

  /// Maximum pagination page size.
  static const int maxPageSize = 100;

  // Feature toggles based on environment
  /// Whether to enable verbose logging.
  bool get enableLogging => EnvironmentConfig.isDebugEnvironment;

  /// Whether to enable Crashlytics reporting.
  bool get enableCrashlytics => EnvironmentConfig.isProduction;

  /// Whether to enable analytics.
  bool get enableAnalytics => EnvironmentConfig.isProduction;

  /// Whether to enable debug tools and overlays.
  bool get enableDebugTools => EnvironmentConfig.isDevelopment;

  /// Whether to enable performance monitoring.
  bool get enablePerformanceMonitoring => EnvironmentConfig.isProduction;

  /// Whether to show environment banner in app.
  bool get showEnvironmentBanner => !EnvironmentConfig.isProduction;

  // External service configuration
  /// Google Maps API key.
  ///
  /// In production, this should be loaded from secure storage or environment variables.
  String get googleMapsApiKey {
    switch (EnvironmentConfig.current) {
      case Environment.development:
        return 'dev-google-maps-api-key';
      case Environment.staging:
        return 'staging-google-maps-api-key';
      case Environment.production:
        return 'prod-google-maps-api-key';
    }
  }

  /// Stripe publishable key.
  String get stripePublishableKey {
    switch (EnvironmentConfig.current) {
      case Environment.development:
        return 'pk_test_dev_key';
      case Environment.staging:
        return 'pk_test_staging_key';
      case Environment.production:
        return 'pk_live_prod_key';
    }
  }

  /// Returns a debug-friendly string representation of the configuration.
  @override
  String toString() {
    return '''
AppConfig(
  environment: ${EnvironmentConfig.environmentName},
  apiBaseUrl: $apiBaseUrl,
  firebaseProjectId: $firebaseProjectId,
  enableLogging: $enableLogging,
  enableCrashlytics: $enableCrashlytics,
  appVersion: $appVersion
)''';
  }

  /// Initializes the app configuration.
  ///
  /// This should be called once during app startup.
  /// It can load configuration from environment variables or other sources.
  static Future<void> initialize({String? environmentString}) async {
    if (environmentString != null) {
      EnvironmentConfig.setEnvironmentFromString(environmentString);
    }

    // Additional initialization logic can be added here
    // For example, loading from secure storage, remote config, etc.
  }
}
