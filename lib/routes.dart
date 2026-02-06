import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/password_reset_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/profile_photo_screen.dart';
import 'screens/notification_preferences_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/load_history_screen.dart';
import 'screens/export_screen.dart';
import 'screens/invoice_management_screen.dart';
import 'screens/invoice_detail_screen.dart';

import 'screens/admin/admin_home.dart';
import 'screens/admin/manage_drivers_screen.dart';
import 'screens/admin/create_load_screen.dart';
import 'screens/admin/expenses_screen.dart';
import 'screens/admin/add_expense_screen.dart';
import 'screens/admin/statistics_screen.dart';
import 'screens/admin/admin_map_dashboard_screen.dart';

import 'screens/driver/driver_home.dart';
import 'screens/driver/earnings_screen.dart';
import 'screens/driver/driver_expenses_screen.dart';
import 'screens/driver/load_detail_screen.dart';
import 'screens/driver/upload_pod_screen.dart';

final Map<String, WidgetBuilder> routes = {
  // Authentication & Onboarding
  '/': (_) => const LoginScreen(),
  '/login': (_) => const LoginScreen(),
  '/onboarding': (_) => const OnboardingScreen(userRole: 'driver'),
  '/password-reset': (_) => const PasswordResetScreen(),
  
  // Profile & Settings
  '/profile': (_) => const ProfileScreen(),
  '/profile/edit': (_) => const EditProfileScreen(),
  '/profile/photo': (_) => const ProfilePhotoScreen(),
  '/settings': (_) => const SettingsScreen(),
  '/settings/notifications': (_) => const NotificationPreferencesScreen(),
  
  // Data Management
  '/load-history': (_) => const LoadHistoryScreen(),
  '/export': (_) => const ExportScreen(),
  '/invoices': (_) => const InvoiceManagementScreen(),
  
  // Admin Routes
  '/admin': (_) => const AdminHome(),
  '/admin-home': (_) => const AdminHome(),
  '/admin/drivers': (_) => const ManageDriversScreen(),
  '/admin/create-load': (_) => const CreateLoadScreen(),
  '/admin/expenses': (_) => const ExpensesScreen(),
  '/admin/add-expense': (_) => const AddExpenseScreen(),
  '/admin/statistics': (_) => const StatisticsScreen(),
  '/admin/map': (_) => const AdminMapDashboardScreen(),
  
  // Driver Routes
  '/driver-home': (_) => const DriverHome(driverId: ''),
  '/driver/earnings': (_) => const EarningsScreen(),
  '/driver/expenses': (_) => const DriverExpensesScreen(),
};
