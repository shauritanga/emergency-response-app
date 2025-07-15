import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Standalone test app to debug registration issues
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with your project configuration
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyBDGtWGwL2N_QQX4g4D5sk_8bI9Jp2vJ9M',
      appId: '1:718388338279:android:743a1e052592be4417bec2',
      messagingSenderId: '718388338279',
      projectId: 'emergency-response-app-dit',
      storageBucket: 'emergency-response-app-dit.firebasestorage.app',
    ),
  );

  runApp(const RegistrationDebugApp());
}

class RegistrationDebugApp extends StatelessWidget {
  const RegistrationDebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registration Debug',
      home: const RegistrationDebugScreen(),
    );
  }
}

class RegistrationDebugScreen extends StatefulWidget {
  const RegistrationDebugScreen({super.key});

  @override
  State<RegistrationDebugScreen> createState() =>
      _RegistrationDebugScreenState();
}

class _RegistrationDebugScreenState extends State<RegistrationDebugScreen> {
  final List<String> _logs = [];
  bool _isLoading = false;
  final _emailController = TextEditingController(text: 'debug@test.com');
  final _passwordController = TextEditingController(text: 'password123');

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
      _addLog('🚀 Starting registration debug test...');

      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Clean up any existing user
      try {
        final existingUser = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        await existingUser.user?.delete();
        _addLog('🗑️ Cleaned up existing test user');
      } catch (e) {
        _addLog('ℹ️ No existing user to clean up');
      }

      // Step 1: Create Firebase Auth user
      _addLog('🔐 Creating Firebase Auth user...');

      User? user;
      try {
        final result = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = result.user;
        _addLog('✅ Auth result received');
      } catch (authError) {
        _addLog('❌ Auth creation failed: $authError');
        if (authError is FirebaseAuthException) {
          _addLog('🔐 Auth error code: ${authError.code}');
          _addLog('🔐 Auth error message: ${authError.message}');
        }
        rethrow;
      }

      if (user == null) {
        _addLog('❌ Failed to create Firebase Auth user - user is null');
        return;
      }

      _addLog('✅ Firebase Auth user created: ${user.uid}');
      _addLog('📧 User email: ${user.email}');
      _addLog('🔑 User authenticated: ${user.uid}');

      // Step 2: Test Firestore connectivity
      _addLog('📡 Testing Firestore connectivity...');
      await firestore.enableNetwork();
      _addLog('✅ Firestore network enabled');

      // Step 3: Create user document data
      final userData = {
        'id': user.uid,
        'name': 'Debug User',
        'email': user.email,
        'role': 'citizen',
        'createdAt': FieldValue.serverTimestamp(),
        'phone': null,
        'photoURL': null,
        'department': null,
        'deviceToken': null,
        'lastLocation': null,
        'notificationPreferences': null,
      };

      _addLog('📋 User data prepared: $userData');

      // Step 4: Write to Firestore
      _addLog('💾 Writing user document to Firestore...');
      _addLog('📍 Collection: users');
      _addLog('📍 Document ID: ${user.uid}');

      try {
        await firestore.collection('users').doc(user.uid).set(userData);

        _addLog('✅ Firestore write operation completed');
      } catch (writeError) {
        _addLog('❌ Firestore write failed: $writeError');
        if (writeError is FirebaseException) {
          _addLog('🔥 Firebase error code: ${writeError.code}');
          _addLog('🔥 Firebase error message: ${writeError.message}');
          _addLog('🔥 Firebase error plugin: ${writeError.plugin}');
        }
        rethrow;
      }

      // Step 5: Verify document exists
      _addLog('🔍 Verifying document creation...');
      final doc = await firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        _addLog('✅ SUCCESS: Document exists in Firestore');
        _addLog('📄 Document data: ${doc.data()}');
      } else {
        _addLog('❌ CRITICAL: Document not found after write');
      }

      // Step 6: List all users
      _addLog('👥 Listing all users in Firestore...');
      final usersSnapshot = await firestore.collection('users').get();
      _addLog('📊 Total users in collection: ${usersSnapshot.docs.length}');

      if (usersSnapshot.docs.isEmpty) {
        _addLog('⚠️ Users collection is empty');
      } else {
        for (final userDoc in usersSnapshot.docs) {
          _addLog('👤 Found user: ${userDoc.id}');
        }
      }

      // Step 7: Test reading the document
      _addLog('📖 Testing document read...');
      try {
        final readDoc = await firestore.collection('users').doc(user.uid).get();
        if (readDoc.exists) {
          _addLog('✅ Document read successful');
        } else {
          _addLog('❌ Document read failed - not found');
        }
      } catch (readError) {
        _addLog('❌ Document read error: $readError');
      }

      _addLog('🎉 Registration debug test completed!');
    } catch (e) {
      _addLog('❌ Test failed with error: $e');
      _addLog('📋 Error type: ${e.runtimeType}');

      if (e is FirebaseAuthException) {
        _addLog('🔐 Auth error code: ${e.code}');
        _addLog('🔐 Auth error message: ${e.message}');
      }

      if (e is FirebaseException) {
        _addLog('🔥 Firebase error code: ${e.code}');
        _addLog('🔥 Firebase error message: ${e.message}');
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
              decoration: const InputDecoration(
                labelText: 'Test Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Test Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Run Registration Debug Test'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        log,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color:
                              log.contains('❌')
                                  ? Colors.red
                                  : log.contains('✅')
                                  ? Colors.green
                                  : log.contains('⚠️')
                                  ? Colors.orange
                                  : Colors.black87,
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
