import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Use path URL strategy for clean URLs on web
  usePathUrlStrategy();
  
  // Validate Firebase configuration
  _validateFirebaseConfig();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const GUDApp());
}

/// Validate that demo Firebase credentials are not being used in production
void _validateFirebaseConfig() {
  const demoApiKey = 'AIzaSyDemoKey_ReplaceWithActualKey';
  
  // Check if demo API key is still in use
  if (DefaultFirebaseOptions.currentPlatform.apiKey == demoApiKey) {
    debugPrint('⚠️  WARNING: Using demo Firebase configuration!');
    debugPrint('⚠️  Please run "flutterfire configure" to set up real Firebase credentials.');
    debugPrint('⚠️  The app may not work correctly with demo credentials.');
  }
}
