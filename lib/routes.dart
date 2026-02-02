import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

import 'screens/admin/admin_home.dart';
import 'screens/admin/manage_drivers_screen.dart';
import 'screens/admin/create_load_screen.dart';

import 'screens/driver/driver_home.dart';
import 'screens/driver/earnings_screen.dart';
import 'screens/driver/driver_load_detail.dart';
import 'screens/driver/upload_pod_screen.dart';

import 'models/load.dart';

final Map<String, WidgetBuilder> routes = {
  '/login': (_) => const LoginScreen(),
  '/admin': (_) => const AdminHome(),
  '/admin/drivers': (_) => const ManageDriversScreen(),
  '/admin/create-load': (_) => const CreateLoadScreen(),
  '/driver': (_) => const DriverHome(),
  '/driver/earnings': (_) => const EarningsScreen(),
};

/// Route generator for routes that require arguments
Route<dynamic>? onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/driver/load-detail':
      final load = settings.arguments as LoadModel;
      return MaterialPageRoute(
        builder: (_) => DriverLoadDetailScreen(load: load),
      );
    
    case '/driver/upload-pod':
      final loadId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (_) => UploadPodScreen(loadId: loadId),
      );
    
    default:
      return null;
  }
}
