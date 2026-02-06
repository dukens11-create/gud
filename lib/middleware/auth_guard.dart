import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/navigation_service.dart';
import '../services/analytics_service.dart';

/// Auth Guard Middleware
/// 
/// Protects routes by checking authentication and email verification status.
/// Redirects to appropriate screen if user is not authenticated or verified.
/// 
/// Usage:
/// ```dart
/// // In route definition
/// if (!await AuthGuard.checkAuth()) {
///   return; // User redirected to login
/// }
/// 
/// if (!await AuthGuard.checkEmailVerified()) {
///   return; // User redirected to email verification
/// }
/// ```
class AuthGuard {
  static final AuthService _authService = AuthService();

  /// Check if user is authenticated
  /// 
  /// Returns true if authenticated, false and redirects to login if not
  static Future<bool> checkAuth() async {
    final user = _authService.currentUser;
    
    if (user == null) {
      await AnalyticsService.instance.logEvent('auth_guard_failed', parameters: {
        'reason': 'not_authenticated',
      });
      
      NavigationService.showError('Please log in to continue');
      NavigationService.navigateToLogin();
      return false;
    }
    
    return true;
  }

  /// Check if user's email is verified
  /// 
  /// Returns true if verified, false and redirects to verification screen if not
  static Future<bool> checkEmailVerified() async {
    final user = _authService.currentUser;
    
    if (user == null) {
      return await checkAuth();
    }

    // Reload user data to get latest verification status
    await _authService.reloadUser();
    final updatedUser = _authService.currentUser;
    
    if (updatedUser != null && !updatedUser.emailVerified) {
      await AnalyticsService.instance.logEvent('auth_guard_failed', parameters: {
        'reason': 'email_not_verified',
      });
      
      NavigationService.showWarning('Please verify your email to continue');
      NavigationService.navigateToEmailVerification();
      return false;
    }
    
    return true;
  }

  /// Check both authentication and email verification
  /// 
  /// Returns true if both checks pass, false and redirects if either fails
  static Future<bool> checkAuthAndVerification() async {
    if (!await checkAuth()) {
      return false;
    }
    
    return await checkEmailVerified();
  }

  /// Check if user has specific role
  /// 
  /// Returns true if user has the required role, false otherwise
  static Future<bool> checkRole(String requiredRole) async {
    if (!await checkAuth()) {
      return false;
    }

    final user = _authService.currentUser;
    if (user == null) return false;

    try {
      // Get user role from custom claims
      final idTokenResult = await user.getIdTokenResult();
      final role = idTokenResult.claims?['role'] as String?;
      
      if (role != requiredRole) {
        await AnalyticsService.instance.logEvent('auth_guard_failed', parameters: {
          'reason': 'insufficient_role',
          'required_role': requiredRole,
          'user_role': role ?? 'none',
        });
        
        NavigationService.showError('You don\'t have permission to access this feature');
        return false;
      }
      
      return true;
    } catch (e) {
      print('❌ Error checking user role: $e');
      return false;
    }
  }

  /// Check if user is admin
  static Future<bool> checkAdmin() async {
    return await checkRole('admin');
  }

  /// Check if user is driver
  static Future<bool> checkDriver() async {
    return await checkRole('driver');
  }

  /// Check if user has any of the specified roles
  static Future<bool> checkAnyRole(List<String> allowedRoles) async {
    if (!await checkAuth()) {
      return false;
    }

    final user = _authService.currentUser;
    if (user == null) return false;

    try {
      final idTokenResult = await user.getIdTokenResult();
      final role = idTokenResult.claims?['role'] as String?;
      
      if (role == null || !allowedRoles.contains(role)) {
        await AnalyticsService.instance.logEvent('auth_guard_failed', parameters: {
          'reason': 'insufficient_role',
          'allowed_roles': allowedRoles.join(','),
          'user_role': role ?? 'none',
        });
        
        NavigationService.showError('You don\'t have permission to access this feature');
        return false;
      }
      
      return true;
    } catch (e) {
      print('❌ Error checking user roles: $e');
      return false;
    }
  }

  /// Verify session is still valid
  /// 
  /// Forces token refresh to ensure session hasn't expired
  static Future<bool> verifySession() async {
    if (!await checkAuth()) {
      return false;
    }

    try {
      final user = _authService.currentUser;
      if (user == null) return false;

      // Force token refresh to verify session
      await user.getIdToken(true);
      return true;
    } catch (e) {
      print('❌ Session verification failed: $e');
      
      await AnalyticsService.instance.logEvent('session_expired');
      NavigationService.showError('Your session has expired. Please log in again.');
      NavigationService.navigateToLogin();
      
      return false;
    }
  }
}

// TODO: Add session timeout tracking
// Track user inactivity:
// - Start timer on last user interaction
// - Warn user before timeout
// - Auto-logout on timeout
// - Store timeout preference in Remote Config

// TODO: Implement biometric re-authentication
// Add biometric check for sensitive operations:
// - Re-authenticate before critical actions
// - Configurable timeout for re-auth
// - Fallback to password if biometric fails

// TODO: Add offline mode support
// Handle auth checks when offline:
// - Cache auth state
// - Allow limited access offline
// - Sync when connection restored
// - Show offline indicator

// TODO: Implement custom permission system
// Create granular permissions:
// - Define custom permissions
// - Check multiple permissions
// - Role-based permission sets
// - Dynamic permission updates
