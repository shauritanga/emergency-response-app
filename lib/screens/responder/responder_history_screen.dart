import 'package:emergency_response_app/providers/emergency_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/location_provider.dart';
import '../../utils/time_utils.dart';
import '../../models/emergency.dart';
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
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Response History'),
      ),
      body: emergencyHistoryAsync.when(
        data: (data) {
          final emergencies = data;
          return emergencies.isEmpty
              ? _buildEmptyState()
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  itemCount: emergencies.length,
                  itemBuilder: (context, index) {
                    final emergency = emergencies[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildHistoryCard(context, ref, emergency),
                    );
                  },
                ),
              );
        },
        error:
            (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading history',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'No Response History',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You haven\'t resolved any emergencies yet.\nCompleted emergencies will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    WidgetRef ref,
    Emergency emergency,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section (85% of card height)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: SizedBox(
                height: 200, // Fixed height for image section
                width: double.infinity,
                child: _buildEmergencyImage(emergency),
              ),
            ),
            // Content section (15% of card height)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildEmergencyTypeIcon(emergency.type),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getEmergencyTitle(emergency),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        TimeUtils.formatTimeSince(emergency.timestamp),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildLocationRow(ref, emergency),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyImage(Emergency emergency) {
    if (emergency.imageUrls.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: emergency.imageUrls.first,
        fit: BoxFit.cover,
        placeholder:
            (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
        errorWidget:
            (context, url, error) =>
                _buildDefaultEmergencyImage(emergency.type),
      );
    } else {
      return _buildDefaultEmergencyImage(emergency.type);
    }
  }

  Widget _buildDefaultEmergencyImage(String emergencyType) {
    Color backgroundColor;
    IconData icon;

    switch (emergencyType.toLowerCase()) {
      case 'medical':
        backgroundColor = Colors.red[100]!;
        icon = Icons.local_hospital;
        break;
      case 'fire':
        backgroundColor = Colors.orange[100]!;
        icon = Icons.local_fire_department;
        break;
      case 'police':
        backgroundColor = Colors.blue[100]!;
        icon = Icons.local_police;
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        icon = Icons.emergency;
    }

    return Container(
      color: backgroundColor,
      child: Center(
        child: Icon(
          icon,
          size: 80,
          color: backgroundColor.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildEmergencyTypeIcon(String type) {
    IconData icon;
    Color color;

    switch (type.toLowerCase()) {
      case 'medical':
        icon = Icons.local_hospital;
        color = Colors.red;
        break;
      case 'fire':
        icon = Icons.local_fire_department;
        color = Colors.orange;
        break;
      case 'police':
        icon = Icons.local_police;
        color = Colors.blue;
        break;
      default:
        icon = Icons.emergency;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 20);
  }

  String _getEmergencyTitle(Emergency emergency) {
    // Just show the simple emergency type
    switch (emergency.type.toLowerCase()) {
      case 'medical':
        return 'Medical';
      case 'fire':
        return 'Fire';
      case 'police':
        return 'Police';
      default:
        return 'Emergency';
    }
  }

  Widget _buildLocationRow(WidgetRef ref, Emergency emergency) {
    // Create a stable string key for the coordinates to prevent infinite rebuilds
    final coordinateKey = '${emergency.latitude},${emergency.longitude}';
    final locationAsync = ref.watch(locationNameProvider(coordinateKey));

    return Row(
      children: [
        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: locationAsync.when(
            data:
                (locationName) => Text(
                  locationName,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            loading:
                () => Text(
                  '${emergency.latitude.toStringAsFixed(3)}, ${emergency.longitude.toStringAsFixed(3)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
            error:
                (_, __) => Text(
                  '${emergency.latitude.toStringAsFixed(3)}, ${emergency.longitude.toStringAsFixed(3)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
          ),
        ),
      ],
    );
  }
}
