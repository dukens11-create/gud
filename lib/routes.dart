import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

import 'screens/admin/admin_home.dart';
import 'screens/admin/manage_drivers_screen.dart';
import 'screens/admin/create_load_screen.dart';

import 'screens/driver/driver_home.dart';
import 'screens/driver/earnings_screen.dart';

final Map<String, WidgetBuilder> routes = {
  '/login': (_) => const LoginScreen(),
  '/admin': (_) => const AdminHome(),
  '/admin/drivers': (_) => const ManageDriversScreen(),
  '/admin/create-load': (_) => const CreateLoadScreen(),
  '/driver': (_) => const DriverHome(),
  '/driver/earnings': (_) => const EarningsScreen(),
};
