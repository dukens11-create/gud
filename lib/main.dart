import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_strategy/url_strategy.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Use path URL strategy (remove # from URLs)
  setPathUrlStrategy();
  
  await Firebase.initializeApp();
  runApp(const GUDApp());
}
