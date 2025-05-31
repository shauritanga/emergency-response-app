import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/emergency_provider.dart';
import 'emergency_detail_screen.dart';

class ResponderEmergenciesScreen extends ConsumerWidget {
  const ResponderEmergenciesScreen({super.key});

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Medical':
        return Colors.red;
      case 'Fire':
        return Colors.orange;
      case 'Police':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'In Progress':
        return Colors.blue;
      case 'Resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final userDataAsync = ref.watch(userFutureProvider(user!.uid));
    final emergenciesAsync = ref.watch(
      responderEmergenciesProvider(
        userDataAsync.asData?.value!.department ?? "Medical",
      ),
    );
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: Text(
          'Active Emergencies',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Top curved background
          Expanded(
            child: emergenciesAsync.when(
              data: (emergencies) {
                if (emergencies.isEmpty) {
                  return _buildEmptyState(context, isDarkMode);
                }
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: emergencies.length,
                    itemBuilder: (context, index) {
                      final emergency = emergencies[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _getTypeColor(
                                          emergency.type,
                                        ).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getEmergencyIcon(emergency.type),
                                        color: _getTypeColor(emergency.type),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${emergency.type} Emergency',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          emergency.status,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        emergency.status,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: _getStatusColor(
                                            emergency.status,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  emergency.description,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color:
                                        isDarkMode
                                            ? Colors.white70
                                            : Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_outlined,
                                          size: 16,
                                          color:
                                              isDarkMode
                                                  ? Colors.white60
                                                  : Colors.black54,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          emergency.description ??
                                              'Unknown location',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color:
                                                isDarkMode
                                                    ? Colors.white60
                                                    : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _formatTimestamp(emergency.timestamp),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color:
                                            isDarkMode
                                                ? Colors.white60
                                                : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading emergencies',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            style: GoogleFonts.poppins(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEmergencyIcon(String type) {
    switch (type) {
      case 'Medical':
        return Icons.medical_services_outlined;
      case 'Fire':
        return Icons.local_fire_department_outlined;
      case 'Police':
        return Icons.local_police_outlined;
      default:
        return Icons.warning_amber_outlined;
    }
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

  Widget _buildEmptyState(BuildContext context, bool isDarkMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 72,
              color: Colors.green.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'No Active Emergencies',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'There are currently no active emergencies that require your attention.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
