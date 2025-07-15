import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emergency.dart';
import '../providers/emergency_provider.dart';
import '../providers/auth_provider.dart';

class EmergencyStatusChanger extends ConsumerStatefulWidget {
  final Emergency emergency;
  final VoidCallback? onStatusChanged;

  const EmergencyStatusChanger({
    super.key,
    required this.emergency,
    this.onStatusChanged,
  });

  @override
  ConsumerState<EmergencyStatusChanger> createState() =>
      _EmergencyStatusChangerState();
}

class _EmergencyStatusChangerState
    extends ConsumerState<EmergencyStatusChanger> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const SizedBox.shrink();

    final userDataAsync = ref.watch(userFutureProvider(user.uid));

    return userDataAsync.when(
      data: (userData) {
        if (userData?.role != 'responder') return const SizedBox.shrink();

        return _buildStatusChanger(userData!.role);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatusChanger(String userRole) {
    final currentStatus = widget.emergency.status;

    return PopupMenuButton<String>(
      enabled: !_isLoading,
      icon:
          _isLoading
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : Icon(
                _getStatusIcon(currentStatus),
                color: _getStatusColor(currentStatus),
              ),
      tooltip: 'Change Status',
      onSelected: _changeStatus,
      itemBuilder: (context) => _buildStatusMenuItems(currentStatus, userRole),
    );
  }

  List<PopupMenuEntry<String>> _buildStatusMenuItems(
    String currentStatus,
    String userRole,
  ) {
    final List<PopupMenuEntry<String>> items = [];

    // Add current status as header
    items.add(
      PopupMenuItem<String>(
        enabled: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Status',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            Row(
              children: [
                Icon(
                  _getStatusIcon(currentStatus),
                  size: 16,
                  color: _getStatusColor(currentStatus),
                ),
                const SizedBox(width: 8),
                Text(
                  currentStatus,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(currentStatus),
                  ),
                ),
              ],
            ),
            const Divider(),
          ],
        ),
      ),
    );

    // Add available transitions based on current status and user role
    final availableStatuses = _getAvailableStatusTransitions(
      currentStatus,
      userRole,
    );

    for (final status in availableStatuses) {
      items.add(
        PopupMenuItem<String>(
          value: status,
          child: Row(
            children: [
              Icon(
                _getStatusIcon(status),
                size: 16,
                color: _getStatusColor(status),
              ),
              const SizedBox(width: 8),
              Text(status),
            ],
          ),
        ),
      );
    }

    if (availableStatuses.isEmpty) {
      items.add(
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            'No status changes available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return items;
  }

  List<String> _getAvailableStatusTransitions(
    String currentStatus,
    String userRole,
  ) {
    if (userRole != 'responder') return [];

    switch (currentStatus) {
      case 'Pending':
        return ['In Progress'];
      case 'In Progress':
        return ['Resolved'];
      case 'Resolved':
        return []; // No further transitions for responders
      default:
        return ['In Progress']; // Fallback
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.pending;
      case 'In Progress':
        return Icons.work;
      case 'Resolved':
        return Icons.check_circle;
      default:
        return Icons.help;
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

  Future<void> _changeStatus(String newStatus) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(emergencyServiceProvider)
          .updateEmergencyStatus(widget.emergency.id, newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $newStatus'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        widget.onStatusChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// Enhanced status display widget
class EmergencyStatusDisplay extends StatelessWidget {
  final String status;
  final bool showIcon;
  final double? fontSize;

  const EmergencyStatusDisplay({
    super.key,
    required this.status,
    this.showIcon = true,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(status).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _getStatusIcon(status),
              size: fontSize ?? 14,
              color: _getStatusColor(status),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            status,
            style: TextStyle(
              color: _getStatusColor(status),
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.pending;
      case 'In Progress':
        return Icons.work;
      case 'Resolved':
        return Icons.check_circle;
      default:
        return Icons.help;
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
}
