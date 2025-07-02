import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../providers/admin_provider.dart';
import '../../models/emergency.dart';

class EmergencyManagementScreen extends ConsumerStatefulWidget {
  const EmergencyManagementScreen({super.key});

  @override
  ConsumerState<EmergencyManagementScreen> createState() =>
      _EmergencyManagementScreenState();
}

class _EmergencyManagementScreenState
    extends ConsumerState<EmergencyManagementScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadEmergencies();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final emergencies = ref.watch(filteredEmergenciesProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Emergency Management',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(adminProvider.notifier).loadEmergencies(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search emergencies...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    if (value.isNotEmpty) {
                      ref.read(adminProvider.notifier).searchEmergencies(value);
                    } else {
                      ref.read(adminProvider.notifier).loadEmergencies();
                    }
                  },
                ),
                const SizedBox(height: 12),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'All', isDarkMode),
                      const SizedBox(width: 8),
                      _buildFilterChip('pending', 'Pending', isDarkMode),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'in progress',
                        'In Progress',
                        isDarkMode,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip('resolved', 'Resolved', isDarkMode),
                      const SizedBox(width: 8),
                      _buildFilterChip('medical', 'Medical', isDarkMode),
                      const SizedBox(width: 8),
                      _buildFilterChip('fire', 'Fire', isDarkMode),
                      const SizedBox(width: 8),
                      _buildFilterChip('police', 'Police', isDarkMode),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Emergency List
          Expanded(
            child:
                adminState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : adminState.error != null
                    ? _buildErrorWidget(adminState.error!)
                    : emergencies.isEmpty
                    ? _buildEmptyWidget(isDarkMode)
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: emergencies.length,
                      itemBuilder: (context, index) {
                        final emergency = emergencies[index];
                        return _buildEmergencyCard(emergency, isDarkMode);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, bool isDarkMode) {
    final isSelected = _selectedFilter == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        _applyFilter(value);
      },
      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
      selectedColor: Colors.blue.withOpacity(0.2),
      checkmarkColor: Colors.blue,
      labelStyle: GoogleFonts.poppins(
        color:
            isSelected
                ? Colors.blue
                : (isDarkMode ? Colors.white : Colors.black87),
      ),
    );
  }

  void _applyFilter(String filter) {
    switch (filter) {
      case 'pending':
        ref.read(adminProvider.notifier).loadEmergenciesByStatus('Pending');
        break;
      case 'in progress':
        ref.read(adminProvider.notifier).loadEmergenciesByStatus('In Progress');
        break;
      case 'resolved':
        ref.read(adminProvider.notifier).loadEmergenciesByStatus('Resolved');
        break;
      case 'medical':
        ref.read(adminProvider.notifier).loadEmergenciesByType('Medical');
        break;
      case 'fire':
        ref.read(adminProvider.notifier).loadEmergenciesByType('Fire');
        break;
      case 'police':
        ref.read(adminProvider.notifier).loadEmergenciesByType('Police');
        break;
      default:
        ref.read(adminProvider.notifier).loadEmergencies();
    }
  }

  Widget _buildEmergencyCard(Emergency emergency, bool isDarkMode) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getEmergencyColor(emergency.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getEmergencyIcon(emergency.type),
                    color: _getEmergencyColor(emergency.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${emergency.type} Emergency',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'ID: ${emergency.id.substring(0, 8)}...',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
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
                    color: _getStatusColor(emergency.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    emergency.status,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _getStatusColor(emergency.status),
                      fontWeight: FontWeight.w500,
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
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${emergency.latitude.toStringAsFixed(4)}, ${emergency.longitude.toStringAsFixed(4)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatTimestamp(emergency.timestamp),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEmergencyDetails(emergency),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showStatusUpdateDialog(emergency),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Update'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
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
            error,
            style: GoogleFonts.poppins(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(adminProvider.notifier).loadEmergencies(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emergency, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No emergencies found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: GoogleFonts.poppins(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _showEmergencyDetails(Emergency emergency) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Emergency Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow('Type', emergency.type),
                  _buildDetailRow('Status', emergency.status),
                  _buildDetailRow('Description', emergency.description),
                  _buildDetailRow(
                    'Location',
                    '${emergency.latitude}, ${emergency.longitude}',
                  ),
                  _buildDetailRow(
                    'Reported',
                    _formatTimestamp(emergency.timestamp),
                  ),
                  if (emergency.imageUrls.isNotEmpty)
                    _buildDetailRow(
                      'Images',
                      '${emergency.imageUrls.length} attached',
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value, style: GoogleFonts.poppins())),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog(Emergency emergency) {
    String selectedStatus = emergency.status;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Update Emergency Status'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Current Status: ${emergency.status}'),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'New Status',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            ['Pending', 'In Progress', 'Resolved']
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(adminProvider.notifier)
                            .updateEmergencyStatus(
                              emergency.id,
                              selectedStatus,
                            );
                        Navigator.pop(context);
                      },
                      child: const Text('Update'),
                    ),
                  ],
                ),
          ),
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
