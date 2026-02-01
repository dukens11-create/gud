import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_home.dart';
import 'screens/driver/driver_home.dart';
import 'widgets/loading.dart';
import 'routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GUD Express',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: appRoutes,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingScreen();
        }

        // Not authenticated
        if (!snapshot.hasData || snapshot.data == null) {
          return const LoginScreen();
        }

        // Authenticated - check role
        final user = snapshot.data!;
        return FutureBuilder<String>(
          future: FirestoreService().getUserRole(user.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingScreen();
            }

            if (roleSnapshot.hasError) {
              return const Scaffold(
                body: Center(
                  child: Text('Error loading user role'),
                ),
              );
            }

            final role = roleSnapshot.data ?? 'driver';
            if (role == 'admin') {
              return const AdminHome();
            } else {
              return const DriverHome();
            }
          },
        );
      },
    );
  }
}
