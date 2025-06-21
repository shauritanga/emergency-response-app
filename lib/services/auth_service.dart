import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../utils/auth_error_handler.dart';
import '../utils/network_utils.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signIn(String email, String password) async {
    try {
      // Check network connectivity before attempting sign in
      final hasConnection = await NetworkUtils.hasInternetConnection();
      if (!hasConnection) {
        throw const NetworkException(
          'No internet connection. Please check your network and try again.',
        );
      }

      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result.user;
    } catch (e) {
      debugPrint('Sign in error: $e');
      // Re-throw with user-friendly error message
      throw Exception(AuthErrorHandler.getErrorMessage(e));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<User?> register(
    String name,
    String email,
    String password,
    String? phone,
    String role, {
    String? department,
  }) async {
    try {
      // Check network connectivity before attempting registration
      final hasConnection = await NetworkUtils.hasInternetConnection();
      if (!hasConnection) {
        throw const NetworkException(
          'No internet connection. Please check your network and try again.',
        );
      }

      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = result.user;
      if (user != null) {
        final userModel = UserModel(
          id: user.uid,
          name: name.trim(),
          email: email.trim(),
          phone: phone?.trim(),
          role: role,
          department: department,
        );

        // Save user data to Firestore with retry mechanism
        await NetworkUtils.retryOperation(
          () => _firestore
              .collection('users')
              .doc(user.uid)
              .set(userModel.toMap()),
          maxRetries: 3,
        );
      }
      return user;
    } catch (e) {
      debugPrint('Register error: $e');
      // Re-throw with user-friendly error message
      throw Exception(AuthErrorHandler.getErrorMessage(e));
    }
  }

  Future<UserModel?> getUserData(String userId) async {
    try {
      // Use retry mechanism for better reliability
      final doc = await NetworkUtils.retryOperation(
        () => _firestore.collection('users').doc(userId).get(),
        maxRetries: 3,
      );

      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      debugPrint('No user data found for ID: $userId');
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      // Re-throw with user-friendly error message
      throw Exception(AuthErrorHandler.getErrorMessage(e));
    }
  }
}
