import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/analytics_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_textfield.dart';
import 'admin/admin_home.dart';
import 'driver/driver_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Log screen view
    AnalyticsService.instance.logScreenView(screenName: 'login');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      
      // Sign in with Firebase Authentication
      final userCredential = await _authService.signIn(
        email,
        _passwordController.text,
      );
      
      if (!mounted) return;
      
      // Get the user ID - if null, we're in offline mode
      final uid = userCredential?.user?.uid;
      
      // Query Firestore for isAdmin field
      bool isAdmin = false;
      String role = 'driver';
      
      if (uid != null) {
        // Online mode - query Firestore
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          
          if (userDoc.exists) {
            isAdmin = userDoc.data()?['isAdmin'] ?? false;
            role = userDoc.data()?['role'] ?? (isAdmin ? 'admin' : 'driver');
          }
        } catch (e) {
          debugPrint('Error fetching user document: $e');
          // If Firestore query fails, default to false
          isAdmin = false;
        }
      } else {
        // Offline/demo mode - use email-based check
        // This matches the offline authentication logic in AuthService
        isAdmin = (email == 'admin@gud.com');
        role = isAdmin ? 'admin' : 'driver';
      }
      
      // Log successful login
      await AnalyticsService.instance.logEvent('login_success', parameters: {
        'method': 'email',
        'user_role': role,
      });
      
      // Set user properties
      if (uid != null) {
        await AnalyticsService.instance.setUserId(uid);
        await AnalyticsService.instance.setUserProperty(
          name: 'user_role',
          value: role,
        );
      }
      
      if (!mounted) return;
      
      // Navigate based on isAdmin field
      if (isAdmin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminHome()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DriverHome(driverId: uid ?? email),
          ),
        );
      }
    } catch (e) {
      // Log failed login
      await AnalyticsService.instance.logEvent('login_failed', parameters: {
        'error': e.toString(),
      });
      
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('firebase_auth/', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', width: 120, height: 120),
              const SizedBox(height: 24),
              const Text(
                'GUD Express',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Demo Mode',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demo Credentials:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Admin: admin@gud.com / admin123'),
                    Text('Driver: driver@gud.com / driver123'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              AppTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _passwordController,
                label: 'Password',
                isPassword: true,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/password-reset'),
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              _isLoading
                  ? const CircularProgressIndicator()
                  : AppButton(
                      label: 'Sign In',
                      onPressed: _signIn,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
