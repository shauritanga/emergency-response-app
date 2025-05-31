import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  Future<void> _updateUserRole(String userId, String newRole) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'role': newRole,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final users = snapshot.data!.docs;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              final userId = user['id'];
              final currentRole = user['role'] ?? 'citizen';
              return ListTile(
                title: Text(user['name']),
                subtitle: Text('Email: ${user['email']}\nRole: $currentRole'),
                trailing: DropdownButton<String>(
                  value: currentRole,
                  items:
                      ['citizen', 'responder', 'admin'].map((role) {
                        return DropdownMenuItem(value: role, child: Text(role));
                      }).toList(),
                  onChanged: (newRole) {
                    if (newRole != null && newRole != currentRole) {
                      _updateUserRole(userId, newRole);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
