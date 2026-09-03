import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FirebaseService {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _isInitialized = true;
      debugPrint('Firebase initialized successfully.');
    } catch (e) {
      // In test/demo environment or missing native google-services.json, fallback gracefully
      _isInitialized = false;
      debugPrint('Firebase initialization notice: $e');
      debugPrint('Running in Hybrid/Demo-Ready Mode with mock fallback data.');
    }
  }
}
