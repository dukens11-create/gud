import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'routes.dart';
import 'services/firestore_service.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_home.dart';
import 'screens/driver/driver_home.dart';
import 'widgets/loading.dart';

class GUDApp extends StatelessWidget {
  const GUDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GUD Express',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      routes: routes,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingScreen();
          }
          final user = snap.data;
          if (user == null) return const LoginScreen();

          return FutureBuilder<String>(
            future: FirestoreService().getUserRole(user.uid),
            builder: (context, roleSnap) {
              if (!roleSnap.hasData) return const LoadingScreen();
              final role = roleSnap.data!;
              if (role == 'admin') return const AdminHome();
              return const DriverHome();
            },
          );
        },
      ),
    );
  }
}
