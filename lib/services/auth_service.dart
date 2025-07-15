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
    User? user;
    try {
      // Check network connectivity before attempting registration
      final hasConnection = await NetworkUtils.hasInternetConnection();
      if (!hasConnection) {
        throw const NetworkException(
          'No internet connection. Please check your network and try again.',
        );
      }

      // Step 1: Create Firebase Auth user
      debugPrint('Creating Firebase Auth user for: $email');
      try {
        final result = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        user = result.user;
        debugPrint('Auth result received, user: ${user?.uid}');
      } catch (authError) {
        debugPrint('Firebase Auth error: $authError');
        if (authError is FirebaseAuthException) {
          debugPrint('Auth error code: ${authError.code}');
          debugPrint('Auth error message: ${authError.message}');
        }
        rethrow;
      }

      if (user != null) {
        debugPrint('Firebase Auth user created successfully: ${user.uid}');

        // Step 2: Create user model with tracking fields
        final userModel = UserModel(
          id: user.uid,
          name: name.trim(),
          email: email.trim(),
          phone: phone?.trim(),
          role: role,
          status: 'active', // Default to active
          department: department,
          isOnline: true, // User is online when they register
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastSeen: DateTime.now(),
        );

        debugPrint('Attempting to save user data to Firestore...');
        debugPrint('User data: ${userModel.toMap()}');

        // Step 3: Save user data to Firestore with detailed error handling
        try {
          debugPrint(
            'Writing to Firestore collection: users, document: ${user.uid}',
          );
          debugPrint('Data being written: ${userModel.toMap()}');
          debugPrint("===================================================");

          // Direct write without retry mechanism for better error visibility
          final userData = userModel.toMap();
          userData['createdAt'] = FieldValue.serverTimestamp();
          userData['updatedAt'] = FieldValue.serverTimestamp();
          userData['lastSeen'] = FieldValue.serverTimestamp();

          await _firestore.collection('users').doc(user.uid).set(userData);

          debugPrint('Firestore write operation completed');

          // Step 4: Verify the document was created
          debugPrint('Verifying document creation...');
          final doc = await _firestore.collection('users').doc(user.uid).get();
          if (doc.exists) {
            debugPrint('✅ SUCCESS: User document exists in Firestore');
            debugPrint('Document data: ${doc.data()}');
          } else {
            debugPrint(
              '❌ CRITICAL ERROR: User document not found after write operation',
            );

            // Try to list all documents in users collection to debug
            try {
              final snapshot = await _firestore.collection('users').get();
              debugPrint(
                'Total documents in users collection: ${snapshot.docs.length}',
              );
              for (final doc in snapshot.docs) {
                debugPrint('Found document: ${doc.id}');
              }
            } catch (listError) {
              debugPrint('Failed to list users collection: $listError');
            }

            throw Exception(
              'Failed to verify user document creation in Firestore',
            );
          }
        } catch (firestoreError) {
          debugPrint('❌ FIRESTORE ERROR: $firestoreError');
          debugPrint('Error type: ${firestoreError.runtimeType}');

          if (firestoreError is FirebaseException) {
            debugPrint('Firebase error code: ${firestoreError.code}');
            debugPrint('Firebase error message: ${firestoreError.message}');
            debugPrint('Firebase error plugin: ${firestoreError.plugin}');
          }

          // Clean up the Firebase Auth user if Firestore write fails
          try {
            await user.delete();
            debugPrint(
              'Cleaned up Firebase Auth user due to Firestore failure',
            );
          } catch (deleteError) {
            debugPrint('Failed to clean up Firebase Auth user: $deleteError');
          }

          // Re-throw with specific Firestore error information
          if (firestoreError is FirebaseException) {
            if (firestoreError.code == 'permission-denied') {
              throw Exception(
                'Permission denied: Unable to create user profile. Please contact support.',
              );
            } else if (firestoreError.code == 'unavailable') {
              throw Exception(
                'Database temporarily unavailable. Please try again later.',
              );
            }
          }

          throw Exception(
            'Failed to create user profile: ${firestoreError.toString()}',
          );
        }
      }
      return user;
    } catch (e) {
      debugPrint('Register error: $e');

      // If we have a user but registration failed, clean up
      if (user != null && e.toString().contains('Firestore')) {
        try {
          await user.delete();
          debugPrint(
            'Cleaned up Firebase Auth user due to registration failure',
          );
        } catch (deleteError) {
          debugPrint('Failed to clean up Firebase Auth user: $deleteError');
        }
      }

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

  /// Create missing user document for existing Firebase Auth user
  Future<void> createMissingUserDocument({
    required String name,
    required String email,
    String role = 'citizen',
    String? phone,
    String? department,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }

      debugPrint('Creating missing user document for: ${currentUser.uid}');

      final userModel = UserModel(
        id: currentUser.uid,
        name: name,
        email: email,
        phone: phone,
        role: role,
        status: 'active',
        department: department,
        isOnline: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastSeen: DateTime.now(),
      );

      debugPrint('User data: ${userModel.toMap()}');

      final userData = userModel.toMap();
      userData['createdAt'] = FieldValue.serverTimestamp();
      userData['updatedAt'] = FieldValue.serverTimestamp();
      userData['lastSeen'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(currentUser.uid).set(userData);

      debugPrint('✅ User document created successfully');

      // Verify the document
      final doc =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (doc.exists) {
        debugPrint('✅ User document verified in Firestore');
      } else {
        debugPrint('❌ User document not found after creation');
      }
    } catch (e) {
      debugPrint('❌ Failed to create user document: $e');
      rethrow;
    }
  }

  /// Test Firestore connectivity and permissions
  Future<void> testFirestoreConnection() async {
    try {
      debugPrint('🔍 Testing Firestore connection...');

      // Test 1: Basic connectivity
      await _firestore.enableNetwork();
      debugPrint('✅ Firestore network enabled');

      // Test 2: Check current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ No authenticated user for Firestore test');
        return;
      }

      debugPrint('👤 Current user: ${currentUser.uid}');

      // Test 3: Try to write a test document
      debugPrint('📝 Testing write permissions...');
      final testData = {
        'test': true,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': currentUser.uid,
      };

      await _firestore.collection('users').doc(currentUser.uid).set(testData);

      debugPrint('✅ Test write successful');

      // Test 4: Verify the write
      final doc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (doc.exists) {
        debugPrint('✅ Test document verified');
        debugPrint('📄 Document data: ${doc.data()}');
      } else {
        debugPrint('❌ Test document not found after write');
      }
    } catch (e) {
      debugPrint('❌ Firestore test failed: $e');
      if (e is FirebaseException) {
        debugPrint('🔥 Firebase error code: ${e.code}');
        debugPrint('🔥 Firebase error message: ${e.message}');
      }
    }
  }
}
