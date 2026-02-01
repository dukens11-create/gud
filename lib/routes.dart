import 'package:flutter/material.dart';
import 'screens/admin/admin_home.dart';
import 'screens/admin/manage_drivers_screen.dart';
import 'screens/admin/create_load_screen.dart';
import 'screens/driver/driver_home.dart';
import 'screens/driver/earnings_screen.dart';
import 'screens/login_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/login': (context) => const LoginScreen(),
  '/admin': (context) => const AdminHome(),
  '/admin/drivers': (context) => const ManageDriversScreen(),
  '/admin/create-load': (context) => const CreateLoadScreen(),
  '/driver': (context) => const DriverHome(),
  '/driver/earnings': (context) => const EarningsScreen(),
};