import 'package:emergency_response_app/screens/citizen/setting_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../models/message.dart';
import '../../providers/message_provider.dart';

class CitizenMessagesScreen extends ConsumerWidget {
  const CitizenMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    final messagesAsync = ref.watch(userMessagesProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
          ),
        ],
      ),
      body: messagesAsync.when(
        data: (messages) {
          if (messages.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.message, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No messages',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.notifications, color: Colors.blue),
                ),
                title: Text(message.title),
                subtitle: Text(message.body),
                trailing: Text(
                  _formatTimestamp(message.timestamp),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
