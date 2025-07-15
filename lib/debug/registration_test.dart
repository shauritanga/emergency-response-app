import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';

/// Test screen to debug registration issues
class RegistrationTestScreen extends StatefulWidget {
  const RegistrationTestScreen({super.key});

  @override
  State<RegistrationTestScreen> createState() => _RegistrationTestScreenState();
}

class _RegistrationTestScreenState extends State<RegistrationTestScreen> {
  final _emailController = TextEditingController(text: 'test@example.com');
  final _passwordController = TextEditingController(text: 'password123');
  final _nameController = TextEditingController(text: 'Test User');
  final List<String> _logs = [];
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String()}: $message');
    });
    print(message);
  }

  Future<void> _testRegistration() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    try {
      _addLog('🚀 Starting registration test...');
      
      // Test 1: Check Firestore connection
      _addLog('📡 Testing Firestore connection...');
      final firestore = FirebaseFirestore.instance;
      await firestore.enableNetwork();
      _addLog('✅ Firestore connection successful');
      
      // Test 2: Test write permissions with a simple document
      _addLog('📝 Testing Firestore write permissions...');
      try {
        await firestore.collection('test').doc('debug').set({
          'timestamp': FieldValue.serverTimestamp(),
          'test': 'debug_write',
        });
        _addLog('✅ Test document write successful');
        
        // Clean up
        await firestore.collection('test').doc('debug').delete();
        _addLog('✅ Test document cleanup successful');
      } catch (e) {
        _addLog('❌ Test document write failed: $e');
        if (e is FirebaseException) {
          _addLog('🔥 Firebase Error Code: ${e.code}');
          _addLog('🔥 Firebase Error Message: ${e.message}');
        }
      }
      
      // Test 3: Create Firebase Auth user
      _addLog('🔐 Creating Firebase Auth user...');
      final auth = FirebaseAuth.instance;
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      
      // Delete user if exists
      try {
        final existingUser = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        await existingUser.user?.delete();
        _addLog('🗑️ Deleted existing test user');
      } catch (e) {
        _addLog('ℹ️ No existing user to delete');
      }
      
      final result = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = result.user;
      if (user == null) {
        _addLog('❌ Failed to create Firebase Auth user');
        return;
      }
      
      _addLog('✅ Firebase Auth user created: ${user.uid}');
      
      // Test 4: Create and save user document
      _addLog('📄 Creating user document...');
      final userModel = UserModel(
        id: user.uid,
        name: _nameController.text.trim(),
        email: email,
        role: 'citizen',
      );
      
      _addLog('📋 User data: ${userModel.toMap()}');
      
      // Test 5: Write to Firestore
      _addLog('💾 Writing user document to Firestore...');
      try {
        await firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());
        _addLog('✅ User document write successful');
      } catch (e) {
        _addLog('❌ User document write failed: $e');
        if (e is FirebaseException) {
          _addLog('🔥 Firebase Error Code: ${e.code}');
          _addLog('🔥 Firebase Error Message: ${e.message}');
        }
        rethrow;
      }
      
      // Test 6: Verify document exists
      _addLog('🔍 Verifying user document...');
      final doc = await firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        _addLog('✅ User document verified in Firestore');
        _addLog('📄 Document data: ${doc.data()}');
      } else {
        _addLog('❌ User document NOT found in Firestore');
      }
      
      // Test 7: List all users
      _addLog('👥 Listing all users in Firestore...');
      final usersSnapshot = await firestore.collection('users').get();
      _addLog('📊 Total users in collection: ${usersSnapshot.docs.length}');
      
      for (final userDoc in usersSnapshot.docs) {
        _addLog('👤 User: ${userDoc.id}');
      }
      
      _addLog('🎉 Registration test completed successfully!');
      
    } catch (e) {
      _addLog('❌ Registration test failed: $e');
      if (e is FirebaseAuthException) {
        _addLog('🔐 Auth Error Code: ${e.code}');
        _addLog('🔐 Auth Error Message: ${e.message}');
      }
      if (e is FirebaseException) {
        _addLog('🔥 Firebase Error Code: ${e.code}');
        _addLog('🔥 Firebase Error Message: ${e.message}');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Debug'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testRegistration,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Test Registration'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        log,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: log.contains('❌') ? Colors.red :
                                 log.contains('✅') ? Colors.green :
                                 Colors.black,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
