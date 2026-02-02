import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'routes.dart' as app_routes;
import 'screens/login_screen.dart';
import 'screens/admin/admin_home.dart';
import 'screens/driver/driver_home.dart';
import 'services/firestore_service.dart';

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
      routes: app_routes.routes,
      onGenerateRoute: app_routes.onGenerateRoute,
      home: const AuthWrapper(),
    );
  }
}

/// Wrapper to handle authentication state and role-based routing
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // User is not logged in
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // User is logged in, determine their role
        final user = snapshot.data!;
        return FutureBuilder<String>(
          future: FirestoreService().getUserRole(user.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (roleSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Error: ${roleSnapshot.error}'),
                ),
              );
            }

            // Route based on user role
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
