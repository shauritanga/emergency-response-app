// File: lib/services/supabase_auth_bridge.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final supabaseAuthBridgeProvider = Provider<SupabaseAuthBridge>(
  (ref) => SupabaseAuthBridge(),
);

class SupabaseAuthBridge {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;

  /// Initialize Supabase authentication bridge
  static Future<void> initialize() async {
    try {
      // Listen to Firebase auth state changes
      _firebaseAuth.authStateChanges().listen((
        firebase_auth.User? firebaseUser,
      ) {
        if (firebaseUser != null) {
          // User signed in with Firebase, authenticate with Supabase
          _authenticateWithSupabase(firebaseUser);
        } else {
          // User signed out from Firebase, sign out from Supabase
          _signOutFromSupabase();
        }
      });

      // If user is already signed in with Firebase, authenticate with Supabase
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        await _authenticateWithSupabase(currentUser);
      }
    } catch (e) {
      debugPrint('Error initializing Supabase auth bridge: $e');
    }
  }

  /// Authenticate with Supabase using Firebase user info
  static Future<void> _authenticateWithSupabase(
    firebase_auth.User firebaseUser,
  ) async {
    try {
      // Check if already authenticated with Supabase
      final supabaseUser = _supabase.auth.currentUser;
      if (supabaseUser != null) {
        debugPrint('Already authenticated with Supabase');
        return;
      }

      // Option 1: Use anonymous authentication (simplest)
      await _supabase.auth.signInAnonymously();
      debugPrint(
        'Authenticated with Supabase anonymously for Firebase user: ${firebaseUser.uid}',
      );

      // Option 2: Alternative - Create a custom JWT (more complex but more secure)
      // await _authenticateWithCustomJWT(firebaseUser);
    } catch (e) {
      debugPrint('Error authenticating with Supabase: $e');
      // Fallback: try anonymous auth
      try {
        await _supabase.auth.signInAnonymously();
        debugPrint('Fallback: Authenticated with Supabase anonymously');
      } catch (fallbackError) {
        debugPrint('Fallback authentication failed: $fallbackError');
      }
    }
  }

  /// Sign out from Supabase
  static Future<void> _signOutFromSupabase() async {
    try {
      await _supabase.auth.signOut();
      debugPrint('Signed out from Supabase');
    } catch (e) {
      debugPrint('Error signing out from Supabase: $e');
    }
  }

  /// Alternative: Authenticate with custom JWT (more advanced)
  /// This method is commented out as it's not currently used
  /// Uncomment and implement if you need custom JWT authentication
  /*
  static Future<void> _authenticateWithCustomJWT(firebase_auth.User firebaseUser) async {
    try {
      // This requires setting up a custom JWT endpoint
      // You would need to create an endpoint that:
      // 1. Verifies the Firebase token
      // 2. Creates a Supabase JWT with the Firebase user info
      // 3. Returns the Supabase JWT

      // Get Firebase ID token
      final idToken = await firebaseUser.getIdToken();

      // Call your custom endpoint to get Supabase JWT
      // final response = await http.post(
      //   Uri.parse('YOUR_CUSTOM_JWT_ENDPOINT'),
      //   headers: {'Authorization': 'Bearer $idToken'},
      // );
      //
      // final supabaseJWT = response.body;
      // await _supabase.auth.setSession(supabaseJWT);

      debugPrint('Custom JWT authentication not implemented yet');
    } catch (e) {
      debugPrint('Error with custom JWT authentication: $e');
    }
  }
  */

  /// Get current authentication status
  static bool get isAuthenticated {
    return _supabase.auth.currentUser != null;
  }

  /// Get current Supabase user
  static User? get currentSupabaseUser {
    return _supabase.auth.currentUser;
  }

  /// Get current Firebase user
  static firebase_auth.User? get currentFirebaseUser {
    return _firebaseAuth.currentUser;
  }

  /// Manual authentication trigger (useful for testing)
  static Future<void> ensureAuthenticated() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null && !isAuthenticated) {
      await _authenticateWithSupabase(firebaseUser);
    }
  }

  /// Check if storage operations are available
  static Future<bool> canAccessStorage() async {
    try {
      if (!isAuthenticated) {
        await ensureAuthenticated();
      }

      // Test storage access
      await _supabase.storage.listBuckets();
      return true;
    } catch (e) {
      debugPrint('Storage access check failed: $e');
      return false;
    }
  }
}
