part of 'app_routes.dart';

import 'package:flutter/material.dart';

class AppRoutes {
  static const String home = '/home';
  static const String settings = '/settings';

  static Map<String, WidgetBuilder> get routes {
    return <String, WidgetBuilder>{
      home: (context) => HomeScreen(),
      settings: (context) => SettingsScreen(),
    };
  }
}