import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../providers/admin_provider.dart';

class RecentActivitiesList extends ConsumerWidget {
  const RecentActivitiesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);
    final emergencies = adminState.emergencies.take(10).toList();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (emergencies.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No recent activities',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Recent Activities',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: emergencies.length,
            separatorBuilder:
                (context, index) => Divider(height: 1, color: Colors.grey[300]),
            itemBuilder: (context, index) {
              final emergency = emergencies[index];
              return _buildActivityItem(emergency, isDarkMode);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(dynamic emergency, bool isDarkMode) {
    final icon = _getEmergencyIcon(emergency.type);
    final color = _getEmergencyColor(emergency.type);
    final timeAgo = _getTimeAgo(emergency.timestamp);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        '${emergency.type} Emergency',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emergency.description,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(emergency.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  emergency.status,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: _getStatusColor(emergency.status),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeAgo,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 16),
    );
  }

  IconData _getEmergencyIcon(String type) {
    switch (type.toLowerCase()) {
      case 'medical':
        return HugeIcons.strokeRoundedMedicalMask;
      case 'fire':
        return HugeIcons.strokeRoundedFire;
      case 'police':
        return HugeIcons.strokeRoundedPoliceBadge;
      default:
        return Icons.warning;
    }
  }

  Color _getEmergencyColor(String type) {
    switch (type.toLowerCase()) {
      case 'medical':
        return Colors.red;
      case 'fire':
        return Colors.orange;
      case 'police':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getTimeAgo(DateTime timestamp) {
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
