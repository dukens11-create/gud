import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

import 'screens/admin/admin_home.dart';
import 'screens/admin/manage_drivers_screen.dart';
import 'screens/admin/create_load_screen.dart';
import 'screens/admin/expenses_screen.dart';
import 'screens/admin/add_expense_screen.dart';
import 'screens/admin/statistics_screen.dart';

import 'screens/driver/driver_home.dart';
import 'screens/driver/earnings_screen.dart';
import 'screens/driver/driver_expenses_screen.dart';

final Map<String, WidgetBuilder> routes = {
  '/login': (_) => const LoginScreen(),
  '/admin': (_) => const AdminHome(),
  '/admin/drivers': (_) => const ManageDriversScreen(),
  '/admin/create-load': (_) => const CreateLoadScreen(),
  '/admin/expenses': (_) => const ExpensesScreen(),
  '/admin/add-expense': (_) => const AddExpenseScreen(),
  '/admin/statistics': (_) => const StatisticsScreen(),
  '/driver/earnings': (_) => const EarningsScreen(),
  '/driver/expenses': (_) => const DriverExpensesScreen(),
};
