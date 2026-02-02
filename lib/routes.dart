import 'package:flutter/material.dart';
import 'package:your_app/screens/manage_drivers_screen.dart';
import 'package:your_app/screens/create_load_screen.dart';

class Routes {
  static const String manageDrivers = '/admin/drivers';
  static const String createLoad = '/admin/create-load';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case manageDrivers:
        return MaterialPageRoute(builder: (_) => ManageDriversScreen());
      case createLoad:
        return MaterialPageRoute(builder: (_) => CreateLoadScreen());
      default:
        return MaterialPageRoute(builder: (_) => UnknownScreen());
    }
  }
}