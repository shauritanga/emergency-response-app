import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lib/models/user.dart';

/// Debug script to test registration and Firestore write operations
class RegistrationDebugger {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test Firestore write permissions and operations
  static Future<void> debugRegistration() async {
    print('🔍 Starting Registration Debug...');
    
    try {
      // Test 1: Check Firestore connection
      print('\n📡 Testing Firestore connection...');
      await _firestore.enableNetwork();
      print('✅ Firestore connection successful');
      
      // Test 2: Try to write a test document
      print('\n📝 Testing Firestore write permissions...');
      final testDoc = _firestore.collection('test').doc('debug');
      await testDoc.set({
        'timestamp': FieldValue.serverTimestamp(),
        'test': 'debug_write',
      });
      print('✅ Test document write successful');
      
      // Clean up test document
      await testDoc.delete();
      print('✅ Test document cleanup successful');
      
      // Test 3: Check current user
      print('\n👤 Checking current user...');
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('✅ Current user: ${currentUser.uid} (${currentUser.email})');
        
        // Test 4: Try to write user document
        print('\n📄 Testing user document write...');
        final userModel = UserModel(
          id: currentUser.uid,
          name: 'Debug User',
          email: currentUser.email ?? 'debug@test.com',
          role: 'citizen',
        );
        
        await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .set(userModel.toMap());
        print('✅ User document write successful');
        
        // Test 5: Verify user document was created
        print('\n🔍 Verifying user document...');
        final userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
            
        if (userDoc.exists) {
          print('✅ User document exists in Firestore');
          print('📄 Document data: ${userDoc.data()}');
        } else {
          print('❌ User document NOT found in Firestore');
        }
      } else {
        print('❌ No current user found');
      }
      
    } catch (e) {
      print('❌ Debug failed: $e');
      print('📋 Error type: ${e.runtimeType}');
      
      // Check specific error types
      if (e is FirebaseException) {
        print('🔥 Firebase Error Code: ${e.code}');
        print('🔥 Firebase Error Message: ${e.message}');
      }
    }
  }

  /// Test registration flow step by step
  static Future<void> debugRegistrationFlow({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    print('🚀 Starting Registration Flow Debug...');
    
    try {
      // Step 1: Create Firebase Auth user
      print('\n🔐 Creating Firebase Auth user...');
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = result.user;
      if (user == null) {
        print('❌ Failed to create Firebase Auth user');
        return;
      }
      
      print('✅ Firebase Auth user created: ${user.uid}');
      
      // Step 2: Create user model
      print('\n📋 Creating user model...');
      final userModel = UserModel(
        id: user.uid,
        name: name,
        email: email,
        role: role,
      );
      print('✅ User model created: ${userModel.toMap()}');
      
      // Step 3: Write to Firestore with detailed logging
      print('\n💾 Writing to Firestore...');
      print('📍 Collection: users');
      print('📍 Document ID: ${user.uid}');
      print('📍 Data: ${userModel.toMap()}');
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toMap());
      
      print('✅ Firestore write completed');
      
      // Step 4: Verify the write
      print('\n🔍 Verifying Firestore write...');
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (doc.exists) {
        print('✅ Document exists in Firestore');
        print('📄 Retrieved data: ${doc.data()}');
      } else {
        print('❌ Document NOT found in Firestore after write');
      }
      
      // Step 5: List all users to see if it's there
      print('\n📋 Listing all users in Firestore...');
      final usersSnapshot = await _firestore.collection('users').get();
      print('👥 Total users in collection: ${usersSnapshot.docs.length}');
      
      for (final userDoc in usersSnapshot.docs) {
        print('👤 User: ${userDoc.id} - ${userDoc.data()}');
      }
      
    } catch (e) {
      print('❌ Registration flow failed: $e');
      print('📋 Error type: ${e.runtimeType}');
      
      if (e is FirebaseAuthException) {
        print('🔐 Auth Error Code: ${e.code}');
        print('🔐 Auth Error Message: ${e.message}');
      }
      
      if (e is FirebaseException) {
        print('🔥 Firebase Error Code: ${e.code}');
        print('🔥 Firebase Error Message: ${e.message}');
      }
    }
  }
}
