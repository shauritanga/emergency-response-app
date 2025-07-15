import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Simple test to verify Firestore write permissions
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const FirestoreTestApp());
}

class FirestoreTestApp extends StatelessWidget {
  const FirestoreTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firestore Test',
      home: const FirestoreTestScreen(),
    );
  }
}

class FirestoreTestScreen extends StatefulWidget {
  const FirestoreTestScreen({super.key});

  @override
  State<FirestoreTestScreen> createState() => _FirestoreTestScreenState();
}

class _FirestoreTestScreenState extends State<FirestoreTestScreen> {
  final List<String> _logs = [];
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String()}: $message');
    });
    print(message);
  }

  Future<void> _testFirestoreWrite() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    try {
      _addLog('🚀 Starting Firestore write test...');
      
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;
      
      // Check if user is already signed in
      User? user = auth.currentUser;
      
      if (user == null) {
        _addLog('🔐 No user signed in, creating test user...');
        try {
          final result = await auth.createUserWithEmailAndPassword(
            email: 'test@example.com',
            password: 'password123',
          );
          user = result.user;
          _addLog('✅ Test user created: ${user?.uid}');
        } catch (e) {
          if (e.toString().contains('email-already-in-use')) {
            _addLog('ℹ️ Test user exists, signing in...');
            final result = await auth.signInWithEmailAndPassword(
              email: 'test@example.com',
              password: 'password123',
            );
            user = result.user;
            _addLog('✅ Signed in as: ${user?.uid}');
          } else {
            rethrow;
          }
        }
      } else {
        _addLog('✅ Already signed in as: ${user.uid}');
      }

      if (user == null) {
        _addLog('❌ Failed to get authenticated user');
        return;
      }

      // Test writing user document
      _addLog('📝 Writing user document to Firestore...');
      final userData = {
        'id': user.uid,
        'name': 'Test User',
        'email': user.email,
        'role': 'citizen',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await firestore
          .collection('users')
          .doc(user.uid)
          .set(userData);
      
      _addLog('✅ User document written successfully');

      // Verify the document exists
      _addLog('🔍 Verifying document exists...');
      final doc = await firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        _addLog('✅ Document verified in Firestore');
        _addLog('📄 Document data: ${doc.data()}');
      } else {
        _addLog('❌ Document not found after write');
      }

      // List all users
      _addLog('👥 Listing all users...');
      final usersSnapshot = await firestore.collection('users').get();
      _addLog('📊 Total users: ${usersSnapshot.docs.length}');
      
      for (final userDoc in usersSnapshot.docs) {
        _addLog('👤 User: ${userDoc.id} - ${userDoc.data()['name']}');
      }

      _addLog('🎉 Test completed successfully!');

    } catch (e) {
      _addLog('❌ Test failed: $e');
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
        title: const Text('Firestore Write Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testFirestoreWrite,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Test Firestore Write'),
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
