import 'package:flutter/material.dart';

/// Navigation Service
/// 
/// Provides global navigation key for navigating without BuildContext.
/// Essential for push notifications, deep linking, and background services.
/// 
/// Usage:
/// ```dart
/// // In MaterialApp
/// MaterialApp(
///   navigatorKey: NavigationService.navigatorKey,
///   ...
/// )
/// 
/// // Navigate without context
/// NavigationService.navigateTo('/load-detail', arguments: {'loadId': '123'});
/// ```
class NavigationService {
  // Global navigation key
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Get the current navigator state
  static NavigatorState? get navigator => navigatorKey.currentState;

  /// Get the current context
  static BuildContext? get context => navigatorKey.currentContext;

  /// Navigate to a named route
  static Future<T?>? navigateTo<T>(String routeName, {Object? arguments}) {
    return navigator?.pushNamed<T>(routeName, arguments: arguments);
  }

  /// Navigate to a named route and remove all previous routes
  static Future<T?>? navigateToAndClear<T>(String routeName, {Object? arguments}) {
    return navigator?.pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Replace current route with a new route
  static Future<T?>? replaceTo<T, TO>(String routeName, {Object? arguments}) {
    return navigator?.pushReplacementNamed<T, TO>(routeName, arguments: arguments);
  }

  /// Go back to previous route
  static void goBack<T>([T? result]) {
    navigator?.pop<T>(result);
  }

  /// Check if can go back
  static bool canGoBack() {
    return navigator?.canPop() ?? false;
  }

  /// Navigate to load detail screen
  static void navigateToLoadDetail(String loadId) {
    navigateTo('/load-detail', arguments: {'loadId': loadId});
  }

  /// Navigate to driver home
  static void navigateToDriverHome() {
    navigateTo('/driver-home');
  }

  /// Navigate to admin home
  static void navigateToAdminHome() {
    navigateTo('/admin-home');
  }

  /// Navigate to email verification screen
  static void navigateToEmailVerification() {
    navigateTo('/email-verification');
  }

  /// Navigate to login screen
  static void navigateToLogin() {
    navigateToAndClear('/login');
  }

  /// Show a snackbar message
  static void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context!);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: backgroundColor,
        action: action,
      ),
    );
  }

  /// Show success message
  static void showSuccess(String message) {
    showSnackBar(message, backgroundColor: Colors.green);
  }

  /// Show error message
  static void showError(String message) {
    showSnackBar(message, backgroundColor: Colors.red);
  }

  /// Show info message
  static void showInfo(String message) {
    showSnackBar(message, backgroundColor: Colors.blue);
  }

  /// Show warning message
  static void showWarning(String message) {
    showSnackBar(message, backgroundColor: Colors.orange);
  }

  /// Show a dialog
  static Future<T?> showDialogBox<T>({
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context!,
      barrierDismissible: barrierDismissible,
      builder: (context) => child,
    );
  }

  /// Show a confirmation dialog
  static Future<bool> showConfirmation({
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    final result = await showDialogBox<bool>(
      child: AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => goBack(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => goBack(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// TODO: Add deep link handling
// Implement universal links and app links:
// - Parse incoming URLs
// - Extract route and parameters
// - Navigate to appropriate screen
// - Handle authentication requirements

// TODO: Implement navigation stack management
// Track navigation history:
// - Store navigation breadcrumbs
// - Allow navigation to specific point in history
// - Clear specific routes from stack

// TODO: Add navigation analytics
// Track user navigation patterns:
// - Most visited screens
// - Navigation paths
// - Drop-off points
// - Time spent on screens

// TODO: Implement route guards
// Add middleware for route protection:
// - Check authentication status
// - Verify user role/permissions
// - Redirect to appropriate screen
// - Show loading or error states
