import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../models/conversation.dart';
import '../providers/auth_provider.dart';
import '../providers/emergency_provider.dart';

import '../screens/chat/chat_screen.dart';
import '../utils/emergency_chat_helper.dart';
import '../utils/feedback_utils.dart';

/// Widget for displaying emergency-specific chat features
class EmergencyChatWidget extends ConsumerWidget {
  final String emergencyId;
  final bool showQuickActions;

  const EmergencyChatWidget({
    super.key,
    required this.emergencyId,
    this.showQuickActions = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const SizedBox.shrink();

    // Get emergency details to check status
    final emergencyAsync = ref.watch(emergencyProvider(emergencyId));

    return emergencyAsync.when(
      data: (emergency) {
        // Hide chat functionality if emergency is resolved
        if (emergency?.status == 'Resolved') {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: _buildResolvedEmergencyMessage(),
          );
        }

        return FutureBuilder<Conversation?>(
          future: EmergencyChatHelper.findEmergencyConversation(emergencyId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final conversation = snapshot.data;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (conversation != null) ...[
                    _buildActionButtons(context, ref, conversation, user.uid),
                  ] else ...[
                    _buildNoConversationState(context, ref, user.uid),
                  ],
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildResolvedEmergencyMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[600], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Emergency Resolved',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'This emergency has been resolved. Chat is no longer available.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.green[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    Conversation conversation,
    String userId,
  ) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _openChat(context, conversation.id),
            icon: const Icon(HugeIcons.strokeRoundedMessage01, size: 16),
            label: Text(
              'Open Chat',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        // if (showQuickActions) ...[
        //   const SizedBox(width: 8),
        //   IconButton(
        //     onPressed:
        //         () => _showQuickActions(context, ref, conversation, userId),
        //     icon: const Icon(HugeIcons.strokeRoundedMoreVertical),
        //     style: IconButton.styleFrom(
        //       backgroundColor: Colors.grey.shade100,
        //       shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.circular(8),
        //       ),
        //     ),
        //   ),
        // ],
      ],
    );
  }

  Widget _buildNoConversationState(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                HugeIcons.strokeRoundedAlert02,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No emergency chat found. This may indicate a system issue.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _createEmergencyChat(context, ref, userId),
            icon: const Icon(HugeIcons.strokeRoundedAdd01, size: 16),
            label: Text(
              'Create Emergency Chat',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openChat(BuildContext context, String conversationId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversationId: conversationId),
      ),
    );
  }

  void _createEmergencyChat(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    try {
      FeedbackUtils.showInfo(context, 'Creating emergency chat...');

      // Get emergency details
      final emergency = await ref
          .read(emergencyServiceProvider)
          .getEmergency(emergencyId);
      if (emergency == null) {
        if (context.mounted) {
          FeedbackUtils.showError(context, 'Emergency not found');
        }
        return;
      }

      // Create emergency chat through the service
      await ref.read(emergencyServiceProvider).createEmergencyChat(emergency);

      if (context.mounted) {
        FeedbackUtils.showSuccess(
          context,
          'Emergency chat created successfully!',
        );
      }

      // Refresh the widget to show the new chat
      if (context.mounted) {
        // Trigger a rebuild by invalidating the provider
        ref.invalidate(emergencyServiceProvider);
      }
    } catch (e) {
      if (context.mounted) {
        FeedbackUtils.showError(context, 'Failed to create emergency chat: $e');
      }
    }
  }
}
