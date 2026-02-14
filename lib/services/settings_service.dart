import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Settings Service for managing application configuration
/// 
/// Provides methods for reading and updating app settings stored in Firestore.
/// Settings are stored in a 'settings' collection with a single document 'app_config'.
/// 
/// **Security**: Only admin users can update settings. All users can read settings.
/// 
/// **Key Settings:**
/// - driverCommissionRate: Percentage of load rate that drivers receive (0.0 - 1.0)
/// 
/// Example Firestore structure:
/// ```
/// settings/
///   app_config/
///     driverCommissionRate: 0.85 (85%)
///     updatedAt: timestamp
///     updatedBy: admin-user-id
/// ```
class SettingsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Document ID for app configuration settings
  static const String APP_CONFIG_DOC_ID = 'app_config';
  
  /// Default commission rate (85%) if not set in Firestore
  static const double DEFAULT_COMMISSION_RATE = 0.85;

  /// Verify user is authenticated
  void _requireAuth() {
    if (_auth.currentUser == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message: 'User must be signed in to access settings',
      );
    }
  }

  /// Get the current driver commission rate
  /// 
  /// Returns the commission rate as a decimal (0.85 = 85%)
  /// If no rate is configured, returns the default (0.85)
  /// 
  /// This method is public and can be called by any authenticated user.
  Future<double> getDriverCommissionRate() async {
    _requireAuth();

    try {
      final doc = await _db
          .collection('settings')
          .doc(APP_CONFIG_DOC_ID)
          .get();

      if (!doc.exists) {
        print('⚠️ Settings document does not exist, using default rate: ${DEFAULT_COMMISSION_RATE * 100}%');
        return DEFAULT_COMMISSION_RATE;
      }

      final data = doc.data();
      if (data == null || !data.containsKey('driverCommissionRate')) {
        print('⚠️ Commission rate not configured, using default: ${DEFAULT_COMMISSION_RATE * 100}%');
        return DEFAULT_COMMISSION_RATE;
      }

      final rate = (data['driverCommissionRate'] as num).toDouble();
      print('✅ Current commission rate: ${(rate * 100).toStringAsFixed(1)}%');
      return rate;
    } catch (e) {
      print('❌ Error fetching commission rate: $e');
      print('   Using default rate: ${DEFAULT_COMMISSION_RATE * 100}%');
      return DEFAULT_COMMISSION_RATE;
    }
  }

  /// Update the driver commission rate (admin only)
  /// 
  /// Parameters:
  /// - [rate]: New commission rate as a decimal (0.0 - 1.0)
  ///   Example: 0.85 = 85%, 0.90 = 90%
  /// 
  /// **Validation:**
  /// - Rate must be between 0.0 and 1.0
  /// - User must be authenticated
  /// 
  /// **Note:** This should only be called by admin users. 
  /// Add role-based security rules in Firestore to enforce this.
  /// 
  /// Throws [ArgumentError] if rate is invalid
  /// Throws [FirebaseAuthException] if user is not authenticated
  Future<void> updateDriverCommissionRate(double rate) async {
    _requireAuth();

    // Validate rate
    if (rate < 0.0 || rate > 1.0) {
      throw ArgumentError(
        'Commission rate must be between 0.0 and 1.0 (0% - 100%). Got: $rate'
      );
    }

    final currentUser = _auth.currentUser!;
    final percentage = (rate * 100).toStringAsFixed(1);

    print('🔧 Updating driver commission rate to $percentage%');
    print('   Updated by: ${currentUser.uid}');

    try {
      await _db
          .collection('settings')
          .doc(APP_CONFIG_DOC_ID)
          .set({
        'driverCommissionRate': rate,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': currentUser.uid,
      }, SetOptions(merge: true));

      print('✅ Commission rate updated successfully to $percentage%');
    } catch (e) {
      print('❌ Error updating commission rate: $e');
      rethrow;
    }
  }

  /// Get all app settings
  /// 
  /// Returns a map of all settings or an empty map if none exist
  Future<Map<String, dynamic>> getAllSettings() async {
    _requireAuth();

    try {
      final doc = await _db
          .collection('settings')
          .doc(APP_CONFIG_DOC_ID)
          .get();

      if (!doc.exists) {
        print('⚠️ Settings document does not exist');
        return {};
      }

      return doc.data() ?? {};
    } catch (e) {
      print('❌ Error fetching settings: $e');
      return {};
    }
  }

  /// Initialize default settings (call once on app first launch)
  /// 
  /// Creates the settings document with default values if it doesn't exist.
  /// This is safe to call multiple times - it won't overwrite existing settings.
  Future<void> initializeDefaultSettings() async {
    _requireAuth();

    try {
      final doc = await _db
          .collection('settings')
          .doc(APP_CONFIG_DOC_ID)
          .get();

      if (doc.exists) {
        print('✅ Settings already initialized');
        return;
      }

      print('📝 Initializing default settings...');
      
      await _db
          .collection('settings')
          .doc(APP_CONFIG_DOC_ID)
          .set({
        'driverCommissionRate': DEFAULT_COMMISSION_RATE,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser!.uid,
      });

      print('✅ Default settings initialized (commission rate: ${DEFAULT_COMMISSION_RATE * 100}%)');
    } catch (e) {
      print('❌ Error initializing settings: $e');
      rethrow;
    }
  }

  /// Stream settings changes in real-time
  /// 
  /// Useful for updating UI when admin changes settings
  Stream<Map<String, dynamic>> streamSettings() {
    return _db
        .collection('settings')
        .doc(APP_CONFIG_DOC_ID)
        .snapshots()
        .map((doc) => doc.data() ?? {});
  }

  /// Stream commission rate changes in real-time
  /// 
  /// Emits the current commission rate whenever it changes
  Stream<double> streamCommissionRate() {
    return streamSettings().map((settings) {
      if (settings.containsKey('driverCommissionRate')) {
        return (settings['driverCommissionRate'] as num).toDouble();
      }
      return DEFAULT_COMMISSION_RATE;
    });
  }
}