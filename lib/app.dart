import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:your_project/services/firestore_service.dart';
import 'loading_screen.dart';
import 'admin_home.dart';
import 'driver_home.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingScreen();
        }
        if (snapshot.hasData) {
          // User is signed in
          return FutureBuilder<String>(
            future: FirestoreService().getUserRole(snapshot.data!.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return LoadingScreen();
              }
              if (roleSnapshot.hasData) {
                // Check user role and route accordingly
                if (roleSnapshot.data == 'admin') {
                  return AdminHome();
                } else {
                  return DriverHome();
                }
              }
              return LoadingScreen(); // In case of error 
            },
          );
        }
        // User is not signed in, navigate to LoginScreen or similar
        return LoginScreen();
      },
    );
  }
}