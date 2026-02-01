import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

class GUDApp extends StatelessWidget {
  const GUDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GUD Express',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const LoginScreen(),
    );
  }
}
