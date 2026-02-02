import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_strategy/url_strategy.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Use path URL strategy (remove # from URLs)
  setPathUrlStrategy();
  
  // Initialize Firebase
  // For web, Firebase configuration should be added to web/index.html
  // or passed as FirebaseOptions here
  if (!kIsWeb) {
    await Firebase.initializeApp();
  } else {
    // For web, try to initialize, but continue even if it fails
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase initialization failed on web: $e');
      // App can continue - will need proper Firebase config in production
    }
  }
  
  runApp(const GUDApp());
}
