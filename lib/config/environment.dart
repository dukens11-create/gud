/// Environment configurations for the GUD Express app
/// 
/// Supports three environments:
/// - Development: Local testing and development
/// - Staging: Pre-production testing
/// - Production: Live production environment

/// Environment types
enum Environment {
  development,
  staging,
  production,
}

/// Environment configuration
class EnvironmentConfig {
  final Environment environment;
  final String apiBaseUrl;
  final String firebaseProjectId;
  final String firebaseStorageBucket;
  final String googleMapsApiKey;
  final bool enableAnalytics;
  final bool enableCrashReporting;
  final bool debugMode;
  final int apiTimeout;
  final String appName;

  const EnvironmentConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.firebaseProjectId,
    required this.firebaseStorageBucket,
    required this.googleMapsApiKey,
    this.enableAnalytics = true,
    this.enableCrashReporting = true,
    this.debugMode = false,
    this.apiTimeout = 30000,
    this.appName = 'GUD Express',
  });

  /// Development environment configuration
  static const EnvironmentConfig development = EnvironmentConfig(
    environment: Environment.development,
    apiBaseUrl: 'http://localhost:5001',
    firebaseProjectId: 'gud-express-dev',
    firebaseStorageBucket: 'gud-express-dev.appspot.com',
    googleMapsApiKey: 'YOUR_DEV_GOOGLE_MAPS_API_KEY',
    enableAnalytics: false,
    enableCrashReporting: false,
    debugMode: true,
    apiTimeout: 60000, // Longer timeout for debugging
    appName: 'GUD Express (Dev)',
  );

  /// Staging environment configuration
  static const EnvironmentConfig staging = EnvironmentConfig(
    environment: Environment.staging,
    apiBaseUrl: 'https://api-staging.gud-express.com',
    firebaseProjectId: 'gud-express-staging',
    firebaseStorageBucket: 'gud-express-staging.appspot.com',
    googleMapsApiKey: 'YOUR_STAGING_GOOGLE_MAPS_API_KEY',
    enableAnalytics: true,
    enableCrashReporting: true,
    debugMode: false,
    apiTimeout: 45000,
    appName: 'GUD Express (Staging)',
  );

  /// Production environment configuration
  static const EnvironmentConfig production = EnvironmentConfig(
    environment: Environment.production,
    apiBaseUrl: 'https://api.gud-express.com',
    firebaseProjectId: 'gud-express-prod',
    firebaseStorageBucket: 'gud-express-prod.appspot.com',
    googleMapsApiKey: 'YOUR_PROD_GOOGLE_MAPS_API_KEY',
    enableAnalytics: true,
    enableCrashReporting: true,
    debugMode: false,
    apiTimeout: 30000,
    appName: 'GUD Express',
  );

  /// Current environment - defaults to production
  /// Override this at app startup based on build configuration
  static EnvironmentConfig _current = production;

  /// Get current environment configuration
  static EnvironmentConfig get current => _current;

  /// Set current environment
  static void setEnvironment(Environment env) {
    switch (env) {
      case Environment.development:
        _current = development;
        break;
      case Environment.staging:
        _current = staging;
        break;
      case Environment.production:
        _current = production;
        break;
    }
  }

  /// Get current environment enum
  static Environment getCurrentEnvironment() {
    return _current.environment;
  }

  /// Check if running in development
  static bool get isDevelopment => _current.environment == Environment.development;

  /// Check if running in staging
  static bool get isStaging => _current.environment == Environment.staging;

  /// Check if running in production
  static bool get isProduction => _current.environment == Environment.production;

  /// Check if debug mode is enabled
  static bool get isDebugMode => _current.debugMode;

  /// Get environment name as string
  String get environmentName {
    switch (environment) {
      case Environment.development:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.production:
        return 'Production';
    }
  }

  @override
  String toString() {
    return '''
EnvironmentConfig(
  environment: $environmentName,
  apiBaseUrl: $apiBaseUrl,
  firebaseProjectId: $firebaseProjectId,
  enableAnalytics: $enableAnalytics,
  enableCrashReporting: $enableCrashReporting,
  debugMode: $debugMode
)''';
  }
}
