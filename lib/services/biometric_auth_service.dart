import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Biometric Authentication Service
/// 
/// Handles fingerprint and face ID authentication:
/// - Check device biometric capabilities
/// - Authenticate with biometrics
/// - Manage biometric preferences
/// - Handle authentication errors
class BiometricAuthService {
  static final BiometricAuthService _instance = BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  
  static const String _biometricEnabledKey = 'biometric_auth_enabled';
  
  /// Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } on PlatformException catch (e) {
      print('❌ Error checking biometric availability: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print('❌ Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticate({
    String reason = 'Please authenticate to access GUD Express',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        print('⚠️ Biometric authentication not available');
        return false;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: false, // Allow PIN/pattern fallback
        ),
      );

      if (didAuthenticate) {
        print('✅ Biometric authentication successful');
      } else {
        print('⚠️ Biometric authentication failed');
      }

      return didAuthenticate;
    } on PlatformException catch (e) {
      print('❌ Error during biometric authentication: $e');
      
      // Handle specific error codes
      switch (e.code) {
        case 'NotAvailable':
          print('⚠️ Biometric authentication not available on this device');
          break;
        case 'NotEnrolled':
          print('⚠️ No biometrics enrolled on this device');
          break;
        case 'LockedOut':
          print('⚠️ Too many failed attempts. Biometrics temporarily locked');
          break;
        case 'PermanentlyLockedOut':
          print('⚠️ Too many failed attempts. Biometrics permanently locked');
          break;
        case 'PasscodeNotSet':
          print('⚠️ Device passcode not set');
          break;
        default:
          print('⚠️ Unknown biometric error: ${e.code}');
      }
      
      return false;
    } catch (e) {
      print('❌ Unexpected error during biometric authentication: $e');
      return false;
    }
  }

  /// Check if biometric authentication is enabled for this app
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      print('❌ Error checking biometric enabled status: $e');
      return false;
    }
  }

  /// Enable biometric authentication
  Future<bool> enableBiometric() async {
    try {
      // First verify biometrics are available
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        print('⚠️ Cannot enable biometric auth: not available');
        return false;
      }

      // Verify with biometric authentication
      final authenticated = await authenticate(
        reason: 'Please authenticate to enable biometric login',
      );

      if (!authenticated) {
        print('⚠️ Biometric authentication failed');
        return false;
      }

      // Save preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, true);
      
      print('✅ Biometric authentication enabled');
      return true;
    } catch (e) {
      print('❌ Error enabling biometric authentication: $e');
      return false;
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometric() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, false);
      print('✅ Biometric authentication disabled');
    } catch (e) {
      print('❌ Error disabling biometric authentication: $e');
    }
  }

  /// Get human-readable biometric type name
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
    }
  }

  /// Get user-friendly biometric availability message
  Future<String> getBiometricStatusMessage() async {
    try {
      final isAvailable = await isBiometricAvailable();
      
      if (!isAvailable) {
        return 'Biometric authentication is not available on this device';
      }

      final biometrics = await getAvailableBiometrics();
      
      if (biometrics.isEmpty) {
        return 'No biometric methods are enrolled. Please set up Face ID or Fingerprint in your device settings';
      }

      final biometricNames = biometrics
          .map((type) => getBiometricTypeName(type))
          .join(', ');
      
      return 'Available: $biometricNames';
    } catch (e) {
      return 'Unable to check biometric status';
    }
  }

  /// Stop biometric authentication (cancel ongoing authentication)
  Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
      print('✅ Biometric authentication stopped');
    } catch (e) {
      print('❌ Error stopping biometric authentication: $e');
    }
  }

  /// Check if user has enrolled biometrics
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final biometrics = await getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (e) {
      print('❌ Error checking enrolled biometrics: $e');
      return false;
    }
  }
}
