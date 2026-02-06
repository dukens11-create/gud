import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'routes.dart';
import 'screens/login_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/admin/admin_home.dart';
import 'screens/driver/driver_home.dart';
import 'services/auth_service.dart';

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
      routes: routes,
      home: const AuthWrapper(),
    );
  }
}

/// AuthWrapper handles authentication state and email verification
/// 
/// This widget checks:
/// 1. If user is logged in
/// 2. If user's email is verified
/// 3. User's role (admin or driver)
/// 
/// And routes them to the appropriate screen
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;

        // User not logged in - show login screen
        if (user == null) {
          return const LoginScreen();
        }

        // User logged in but email not verified - show verification screen
        if (!user.emailVerified) {
          return const EmailVerificationScreen();
        }

        // User logged in and verified - check role and route accordingly
        return FutureBuilder<String>(
          future: authService.getUserRole(user.uid),
          builder: (context, roleSnapshot) {
            // Show loading while fetching role
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Handle error fetching role
            if (roleSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error loading user role: ${roleSnapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await authService.signOut();
                        },
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Route based on role
            final role = roleSnapshot.data ?? 'driver';
            if (role == 'admin') {
              return const AdminHome();
            } else {
              // For drivers, we need to pass the driverId
              return DriverHome(driverId: user.uid);
            }
          },
        );
      },
    );
  }
}
