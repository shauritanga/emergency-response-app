import 'package:emergency_response_app/screens/responder/emergency_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/emergency_provider.dart';

class EmergencyStatusScreen extends ConsumerWidget {
  final bool isEmbedded;

  const EmergencyStatusScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    final emergenciesAsync = ref.watch(emergenciesProvider(user.uid));

    return isEmbedded
        ? Scaffold(
          appBar: AppBar(
            title: const Text('Emergency Status'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.refresh(emergenciesProvider(user.uid));
                },
              ),
            ],
          ),
          body: _buildContent(context, emergenciesAsync),
        )
        : Scaffold(
          appBar: AppBar(title: const Text('Emergency Status')),
          body: _buildContent(context, emergenciesAsync),
        );
  }

  Widget _buildContent(BuildContext context, AsyncValue emergenciesAsync) {
    return emergenciesAsync.when(
      data: (emergencies) {
        if (emergencies.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No emergencies reported',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: emergencies.length,
          itemBuilder: (context, index) {
            final emergency = emergencies[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: _getEmergencyIcon(emergency.type),
                title: Text('${emergency.type} Emergency'),
                subtitle: Text(
                  'Status: ${emergency.status}\n${emergency.description}',
                ),
                trailing: _getStatusIndicator(emergency.status),
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => EmergencyDetailScreen(
                              emergency: emergency,
                              isResponder: false,
                            ),
                      ),
                    ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }

  Widget _getEmergencyIcon(String type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'Medical':
        iconData = Icons.local_hospital;
        iconColor = Colors.red;
        break;
      case 'Fire':
        iconData = Icons.fire_extinguisher;
        iconColor = Colors.orange;
        break;
      case 'Police':
        iconData = Icons.local_police;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.warning;
        iconColor = Colors.amber;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.2),
      child: Icon(iconData, color: iconColor),
    );
  }

  Widget _getStatusIndicator(String status) {
    Color color;
    String label;

    switch (status) {
      case 'Pending':
        color = Colors.orange;
        label = 'Pending';
        break;
      case 'In Progress':
        color = Colors.blue;
        label = 'In Progress';
        break;
      case 'Resolved':
        color = Colors.green;
        label = 'Resolved';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
