import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Simple test to check if we can write to Firestore with existing user
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
  
  runApp(const SimpleFirestoreTestApp());
}

class SimpleFirestoreTestApp extends StatelessWidget {
  const SimpleFirestoreTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Firestore Test',
      home: const SimpleFirestoreTestScreen(),
    );
  }
}

class SimpleFirestoreTestScreen extends StatefulWidget {
  const SimpleFirestoreTestScreen({super.key});

  @override
  State<SimpleFirestoreTestScreen> createState() => _SimpleFirestoreTestScreenState();
}

class _SimpleFirestoreTestScreenState extends State<SimpleFirestoreTestScreen> {
  final List<String> _logs = [];
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String()}: $message');
    });
    debugPrint(message);
  }

  Future<void> _testWithExistingUser() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    try {
      _addLog('🚀 Testing with existing Firebase Auth user...');
      
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;
      
      // Check current user
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        _addLog('❌ No user is currently signed in');
        _addLog('ℹ️ Please sign in to your app first, then run this test');
        return;
      }
      
      _addLog('✅ Current user: ${currentUser.uid}');
      _addLog('📧 User email: ${currentUser.email}');
      
      // Test Firestore write with existing user
      _addLog('📝 Testing Firestore write...');
      
      final userData = {
        'id': currentUser.uid,
        'name': 'Test User from Simple Test',
        'email': currentUser.email,
        'role': 'citizen',
        'createdAt': FieldValue.serverTimestamp(),
        'phone': null,
        'photoURL': null,
        'department': null,
        'deviceToken': null,
        'lastLocation': null,
        'notificationPreferences': null,
      };
      
      _addLog('📋 Writing data: $userData');
      
      try {
        await firestore
            .collection('users')
            .doc(currentUser.uid)
            .set(userData);
        
        _addLog('✅ Firestore write completed successfully!');
      } catch (writeError) {
        _addLog('❌ Firestore write failed: $writeError');
        if (writeError is FirebaseException) {
          _addLog('🔥 Firebase error code: ${writeError.code}');
          _addLog('🔥 Firebase error message: ${writeError.message}');
        }
        return;
      }
      
      // Verify the write
      _addLog('🔍 Verifying document exists...');
      final doc = await firestore.collection('users').doc(currentUser.uid).get();
      
      if (doc.exists) {
        _addLog('✅ SUCCESS: Document exists in Firestore!');
        _addLog('📄 Document data: ${doc.data()}');
      } else {
        _addLog('❌ Document not found after write');
      }
      
      // List all users
      _addLog('👥 Listing all users...');
      final usersSnapshot = await firestore.collection('users').get();
      _addLog('📊 Total users: ${usersSnapshot.docs.length}');
      
      for (final userDoc in usersSnapshot.docs) {
        _addLog('👤 User: ${userDoc.id}');
      }
      
      _addLog('🎉 Test completed successfully!');
      
    } catch (e) {
      _addLog('❌ Test failed: $e');
      _addLog('📋 Error type: ${e.runtimeType}');
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
        title: const Text('Simple Firestore Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'This test uses your existing signed-in user to test Firestore write permissions.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testWithExistingUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Test Firestore Write with Current User'),
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
                          color: log.contains('❌') ? Colors.red :
                                 log.contains('✅') ? Colors.green :
                                 log.contains('⚠️') ? Colors.orange :
                                 Colors.black87,
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
