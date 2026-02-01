import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_home.dart';
import 'screens/driver/driver_home.dart';
import 'screens/driver/earnings_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/login': (context) => const LoginScreen(),
  '/admin': (context) => const AdminHome(),
  '/driver': (context) => const DriverHome(),
  '/driver/earnings': (context) => const EarningsScreen(),
};