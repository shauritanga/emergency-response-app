import 'package:emergency_response_app/providers/emergency_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'emergency_detail_screen.dart';

class ResponderHistoryScreen extends ConsumerWidget {
  const ResponderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Center(child: Text('Please log in'));
    }

    final emergencyHistoryAsync = ref.watch(
      emergencyHistoryStreamProvider(user.uid),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text('Response History'),
      ),
      body: emergencyHistoryAsync.when(
        data: (data) {
          final emergencies = data;
          return emergencies.isEmpty
              ? const Center(child: Text('No response history'))
              : ListView.builder(
                itemCount: emergencies.length,
                itemBuilder: (context, index) {
                  final emergency = emergencies[index];
                  return ListTile(
                    title: Text('${emergency.type} Emergency'),
                    subtitle: Text(
                      'Status: ${emergency.status}\n${emergency.description}',
                    ),
                    trailing: Text(emergency.timestamp.toString()),
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => EmergencyDetailScreen(
                                  emergency: emergency,
                                  isResponder: true,
                                ),
                          ),
                        ),
                  );
                },
              );
        },
        error: (error, stackTrace) => Center(child: Text("Error")),
        loading: () => Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
