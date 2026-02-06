/// Environment configuration for the GUD Express application.
///
/// This file defines different deployment environments and provides
/// utilities to check the current environment.
library;

/// Deployment environments for the application.
enum Environment {
  /// Development environment - for local development and testing.
  development,

  /// Staging environment - for pre-production testing.
  staging,

  /// Production environment - for live users.
  production,
}

/// Global environment configuration.
class EnvironmentConfig {
  EnvironmentConfig._();

  /// The current environment the app is running in.
  ///
  /// Default is development. This should be set during app initialization
  /// based on build configuration or environment variables.
  static Environment _currentEnvironment = Environment.development;

  /// Gets the current environment.
  static Environment get current => _currentEnvironment;

  /// Sets the current environment.
  ///
  /// This should be called once during app initialization.
  static void setEnvironment(Environment environment) {
    _currentEnvironment = environment;
  }

  /// Sets the environment from a string value.
  ///
  /// Useful for loading from environment variables or build configs.
  /// Defaults to development if the string doesn't match any environment.
  static void setEnvironmentFromString(String environmentString) {
    switch (environmentString.toLowerCase()) {
      case 'development':
      case 'dev':
        _currentEnvironment = Environment.development;
        break;
      case 'staging':
      case 'stage':
        _currentEnvironment = Environment.staging;
        break;
      case 'production':
      case 'prod':
        _currentEnvironment = Environment.production;
        break;
      default:
        _currentEnvironment = Environment.development;
    }
  }

  /// Returns true if the app is running in development environment.
  static bool get isDevelopment => _currentEnvironment == Environment.development;

  /// Returns true if the app is running in staging environment.
  static bool get isStaging => _currentEnvironment == Environment.staging;

  /// Returns true if the app is running in production environment.
  static bool get isProduction => _currentEnvironment == Environment.production;

  /// Returns true if the app is running in a non-production environment.
  static bool get isDebugEnvironment =>
      _currentEnvironment == Environment.development ||
      _currentEnvironment == Environment.staging;

  /// Gets a human-readable name for the current environment.
  static String get environmentName {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.production:
        return 'Production';
    }
  }
}
