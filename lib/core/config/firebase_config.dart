import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

class FirebaseConfig {
  static bool _isFirebaseReady = false;

  static bool get isFirebaseReady => _isFirebaseReady;

  /// Attempts to initialize Firebase.
  /// If credentials or configuration are absent, gracefully falls back to Dev Mock mode.
  static Future<void> initialize() async {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      // If placeholder values are detected, skip to mock mode
      if (options.apiKey == 'TODO_REPLACE_WITH_FIREBASE_API_KEY') {
        debugPrint('[Cuong Tran Notes] Firebase placeholder keys detected. Falling back to Dev Mock mode.');
        _isFirebaseReady = false;
        return;
      }

      await Firebase.initializeApp(
        options: options,
      );
      _isFirebaseReady = true;
      debugPrint('[Cuong Tran Notes] Firebase initialized successfully.');
    } catch (e, stack) {
      debugPrint('[Cuong Tran Notes] Firebase initialization skipped or failed ($e). Using Dev Mock mode.');
      if (kDebugMode) {
        debugPrint(stack.toString());
      }
      _isFirebaseReady = false;
    }
  }
}
