import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/onboarding_screen.dart';

import 'screens/admin/admin_home.dart';
import 'screens/admin/manage_drivers_screen.dart';
import 'screens/admin/create_load_screen.dart';
import 'screens/admin/expenses_screen.dart';
import 'screens/admin/add_expense_screen.dart';
import 'screens/admin/statistics_screen.dart';
import 'screens/admin/document_verification_screen.dart';
import 'screens/admin/driver_performance_dashboard.dart';
import 'screens/admin/maintenance_tracking_screen.dart';
import 'screens/admin/expiration_alerts_screen.dart';
import 'screens/admin/manage_trucks_screen.dart';
import 'screens/admin/ifta_report_screen.dart';

import 'screens/driver/driver_home.dart';
import 'screens/driver/earnings_screen.dart';
import 'screens/driver/driver_expenses_screen.dart';
import 'screens/driver/add_driver_expense_screen.dart';

// Profile management screens
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/profile_photo_screen.dart';

// Settings and configuration
import 'screens/settings_screen.dart';
import 'screens/notification_preferences_screen.dart';

// Invoice management screens
import 'screens/invoice_management_screen.dart';
import 'screens/invoice_detail_screen.dart';
import 'screens/create_invoice_screen.dart';

// Additional screens
import 'screens/load_history_screen.dart';
import 'screens/password_reset_screen.dart';
import 'screens/export_screen.dart';
import 'screens/payment_dashboard_screen.dart';

final Map<String, WidgetBuilder> routes = {
  '/login': (_) => const LoginScreen(),
  '/admin': (_) => const AdminHome(),
  '/admin/drivers': (_) => const ManageDriversScreen(),
  '/admin/trucks': (_) => const ManageTrucksScreen(),
  '/admin/create-load': (_) => const CreateLoadScreen(),
  '/admin/expenses': (_) => const ExpensesScreen(),
  '/admin/add-expense': (_) => const AddExpenseScreen(),
  '/admin/statistics': (_) => const StatisticsScreen(),
  '/admin/document-verification': (_) => const DocumentVerificationScreen(),
  '/admin/driver-performance': (_) => const DriverPerformanceDashboard(),
  '/admin/maintenance': (_) => const MaintenanceTrackingScreen(),
  '/admin/expiration-alerts': (_) => const ExpirationAlertsScreen(),
  '/admin/ifta': (_) => const IftaReportScreen(),
  '/driver/earnings': (_) => const EarningsScreen(),
  '/driver/expenses': (_) => const DriverExpensesScreen(),
  '/driver/add-expense': (_) => const AddDriverExpenseScreen(),
  '/payments': (_) => const PaymentDashboardScreen(),
  
  // Profile routes
  '/profile': (_) => const ProfileScreen(),
  '/profile/edit': (_) => const EditProfileScreen(),
  '/profile/photo': (_) => const ProfilePhotoScreen(),
  
  // Settings routes
  '/settings': (_) => const SettingsScreen(),
  '/notification-preferences': (_) => const NotificationPreferencesScreen(),
  
  // Invoice routes
  '/invoices': (_) => const InvoiceManagementScreen(),
  '/invoices/create': (_) => const CreateInvoiceScreen(),
  
  // Additional routes
  '/load-history': (_) => const LoadHistoryScreen(),
  '/password-reset': (_) => const PasswordResetScreen(),
  '/export': (_) => const ExportScreen(),
  '/email-verification': (_) => const EmailVerificationScreen(),
  '/onboarding': (context) {
    // Extract user role from arguments if provided
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userRole = args?['userRole'] as String? ?? 'driver';
    return OnboardingScreen(userRole: userRole);
  },
};
