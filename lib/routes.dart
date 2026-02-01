import 'package:your_project/screens/admin_home.dart';
import 'package:your_project/screens/manage_drivers_screen.dart';
import 'package:your_project/screens/create_load_screen.dart';
import 'package:your_project/screens/admin_load_detail.dart';
import 'package:your_project/screens/driver_home.dart';
import 'package:your_project/screens/driver_load_detail.dart';
import 'package:your_project/screens/earnings_screen.dart';
import 'package:your_project/screens/login_screen.dart';

final Map<String, Widget Function(BuildContext)> appRoutes = {
  '/login': (context) => LoginScreen(),
  '/admin': (context) => AdminHome(),
  '/admin/drivers': (context) => ManageDriversScreen(),
  '/admin/create-load': (context) => CreateLoadScreen(),
  '/driver': (context) => DriverHome(),
  '/driver/earnings': (context) => EarningsScreen(),
};
