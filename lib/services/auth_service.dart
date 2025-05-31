import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
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
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = result.user;
      if (user != null) {
        final userModel = UserModel(
          id: user.uid,
          name: name,
          email: email,
          phone: phone,
          role: role,
          department: department,
        );
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());
      }
      return user;
    } catch (e) {
      debugPrint('Register error: $e');
      rethrow;
    }
  }

  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      debugPrint('No user data found for ID: $userId');
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      rethrow;
    }
  }
}
