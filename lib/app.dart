import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'routes.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_home.dart';
import 'screens/driver/driver_home.dart';
import 'services/firestore_service.dart';
import 'widgets/loading.dart';

class GUDApp extends StatelessWidget {
  const GUDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GUD Express Trucking Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      routes: routes,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingScreen();
          }
          
          if (snapshot.hasData) {
            // User is logged in, determine role
            return FutureBuilder<String>(
              future: FirestoreService().getUserRole(snapshot.data!.uid),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingScreen();
                }
                
                if (roleSnapshot.hasData) {
                  final role = roleSnapshot.data!;
                  if (role == 'admin') {
                    return const AdminHome();
                  } else {
                    return DriverHome(driverId: snapshot.data!.uid);
                  }
                }
                
                return const LoginScreen();
              },
            );
          }
          
          return const LoginScreen();
        },
      ),
    );
  }
}
