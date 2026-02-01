import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_shipping, size: 100, color: Colors.blue),
              const SizedBox(height: 24),
              const Text('GUD Express', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/driver'),
                child: const Text('Demo Login as Driver'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/admin'),
                child: const Text('Demo Login as Admin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
