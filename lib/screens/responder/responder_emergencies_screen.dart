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
        return Colors.deepPurple;
      case 'Fire':
        return Colors.purple;
      case 'Police':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.deepPurple;
      case 'In Progress':
        return Colors.purple;
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
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: emergenciesAsync.when(
          data:
              (emergencies) => Text(
                'Active Emergencies (${emergencies.length})',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
          loading:
              () => Text(
                'Active Emergencies',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
          error:
              (_, __) => Text(
                'Active Emergencies',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh the emergencies list
              ref.invalidate(responderEmergenciesProvider);
            },
            tooltip: 'Refresh emergencies',
          ),
        ],
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
                      final isNew = _isNewEmergency(emergency.timestamp);
                      final isUrgent = _isUrgentEmergency(emergency.timestamp);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: isUrgent ? 6 : (isNew ? 4 : 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side:
                              isUrgent
                                  ? BorderSide(
                                    color: Colors.red.shade300,
                                    width: 2,
                                  )
                                  : isNew
                                  ? BorderSide(
                                    color: Colors.orange.shade300,
                                    width: 1,
                                  )
                                  : BorderSide.none,
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
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient:
                                  isUrgent
                                      ? LinearGradient(
                                        colors: [
                                          Colors.red.shade50,
                                          Colors.white,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                      : isNew
                                      ? LinearGradient(
                                        colors: [
                                          Colors.orange.shade50,
                                          Colors.white,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                      : null,
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
                                          ).withValues(alpha: 0.1),
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
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    '${emergency.type} Emergency',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (isUrgent) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'URGENT',
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                                  ),
                                                ] else if (isNew) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'NEW',
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
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
                                          ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                      Expanded(
                                        child: Row(
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
                                            Expanded(
                                              child: Text(
                                                '${emergency.latitude.toStringAsFixed(4)}, ${emergency.longitude.toStringAsFixed(4)}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color:
                                                      isDarkMode
                                                          ? Colors.white60
                                                          : Colors.black54,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              isUrgent
                                                  ? Colors.red.withValues(
                                                    alpha: 0.1,
                                                  )
                                                  : isNew
                                                  ? Colors.orange.withValues(
                                                    alpha: 0.1,
                                                  )
                                                  : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border:
                                              isUrgent || isNew
                                                  ? Border.all(
                                                    color:
                                                        isUrgent
                                                            ? Colors.red
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                )
                                                            : Colors.orange
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                ),
                                                    width: 1,
                                                  )
                                                  : null,
                                        ),
                                        child: Text(
                                          _formatTimestamp(emergency.timestamp),
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight:
                                                isUrgent || isNew
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                            color:
                                                isUrgent
                                                    ? Colors.red.shade700
                                                    : isNew
                                                    ? Colors.orange.shade700
                                                    : (isDarkMode
                                                        ? Colors.white60
                                                        : Colors.black54),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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

  bool _isNewEmergency(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inMinutes <=
        30; // Consider emergency "new" if within 30 minutes
  }

  bool _isUrgentEmergency(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inMinutes <=
        5; // Consider emergency "urgent" if within 5 minutes
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
