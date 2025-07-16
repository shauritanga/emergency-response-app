import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../common/notification_settings_screen.dart';

class ResponderNotificationsScreen extends ConsumerStatefulWidget {
  const ResponderNotificationsScreen({super.key});

  @override
  ConsumerState<ResponderNotificationsScreen> createState() =>
      _ResponderNotificationsScreenState();
}

class _ResponderNotificationsScreenState
    extends ConsumerState<ResponderNotificationsScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final notificationState = ref.watch(notificationProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view notifications')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isDarkMode ? const Color(0xFF1A237E) : Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: isDarkMode ? const Color(0xFF1A237E) : Colors.blue,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    _buildFilterChip('all', 'All', Icons.notifications),
                    const SizedBox(width: 8),
                    _buildFilterChip('emergency', 'Alerts', Icons.emergency),
                    const SizedBox(width: 8),
                    _buildFilterChip('chat', 'Messages', Icons.chat),
                  ],
                ),
              ),
            ),
          ),

          // Notifications List
          Expanded(child: _buildNotificationsList(user.uid, notificationState)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isSelected ? Colors.blue : Colors.black87,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.black87,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
      backgroundColor:
          isSelected ? Colors.white : Colors.white.withValues(alpha: 0.1),
      selectedColor: Colors.white,
      disabledColor: Colors.white.withValues(alpha: 0.1),
      side: BorderSide(
        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.5),
        width: 1,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
    );
  }

  Widget _buildNotificationsList(String userId, NotificationState state) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getNotificationsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading notifications',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final notifications = snapshot.data?.docs ?? [];
        final filteredNotifications = _filterNotifications(notifications);

        if (filteredNotifications.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredNotifications.length,
          itemBuilder: (context, index) {
            final doc = filteredNotifications[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildNotificationCard(doc.id, data);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getNotificationsStream(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots();
  }

  List<QueryDocumentSnapshot> _filterNotifications(
    List<QueryDocumentSnapshot> notifications,
  ) {
    if (_selectedFilter == 'all') return notifications;

    return notifications.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final type = data['type'] as String? ?? '';

      switch (_selectedFilter) {
        case 'emergency':
          return type == 'emergency' || type == 'emergency_update';
        case 'chat':
          return type == 'chat' || type == 'message';
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            HugeIcons.strokeRoundedNotification03,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see emergency alerts and messages here',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(String id, Map<String, dynamic> data) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final type = data['type'] as String? ?? '';
    final title = data['title'] as String? ?? 'Notification';
    final body = data['body'] as String? ?? '';
    final timestamp =
        (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final isRead = data['isRead'] as bool? ?? false;
    final emergencyId = data['emergencyId'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 1 : 3,
      color:
          isRead
              ? null
              : (isDarkMode
                  ? Colors.blue.withValues(alpha: 0.1)
                  : Colors.blue.withValues(alpha: 0.05)),
      child: InkWell(
        onTap: () => _handleNotificationTap(id, data),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getNotificationColor(type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getNotificationIcon(type),
                  color: _getNotificationColor(type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight:
                                  isRead ? FontWeight.w500 : FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _formatTimestamp(timestamp),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'emergency':
      case 'emergency_update':
        return HugeIcons.strokeRoundedAlert02;
      case 'chat':
      case 'message':
        return HugeIcons.strokeRoundedMessage01;
      case 'system':
        return HugeIcons.strokeRoundedSettings02;
      default:
        return HugeIcons.strokeRoundedNotification03;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'emergency':
      case 'emergency_update':
        return Colors.red;
      case 'chat':
      case 'message':
        return Colors.blue;
      case 'system':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _handleNotificationTap(String id, Map<String, dynamic> data) {
    // Mark as read
    _markAsRead(id);

    final type = data['type'] as String? ?? '';
    final emergencyId = data['emergencyId'] as String?;

    // Handle different notification types
    switch (type) {
      case 'emergency':
      case 'emergency_update':
        if (emergencyId != null) {
          // Navigate to emergency details
          _navigateToEmergency(emergencyId);
        }
        break;
      case 'chat':
      case 'message':
        // Navigate to messages
        Navigator.pop(context); // Go back to home
        // The home screen will handle switching to messages tab
        break;
      default:
        // Show notification details in a dialog
        _showNotificationDetails(data);
        break;
    }
  }

  void _markAsRead(String notificationId) {
    FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  void _navigateToEmergency(String emergencyId) {
    // This would navigate to emergency details
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening emergency $emergencyId'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showNotificationDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(data['title'] ?? 'Notification'),
            content: Text(data['body'] ?? 'No details available'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
