import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../models/conversation.dart';
import '../models/emergency.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
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

    return FutureBuilder<Conversation?>(
      future: EmergencyChatHelper.findEmergencyConversation(emergencyId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final conversation = snapshot.data;
        
        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, conversation),
                const SizedBox(height: 12),
                if (conversation != null) ...[
                  _buildConversationInfo(context, conversation, user.uid),
                  const SizedBox(height: 12),
                  _buildActionButtons(context, ref, conversation, user.uid),
                ] else ...[
                  _buildNoConversationState(context, ref, user.uid),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Conversation? conversation) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            HugeIcons.strokeRoundedMessage01,
            color: Colors.red,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Emergency Chat',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                conversation != null 
                    ? 'Active conversation'
                    : 'No active conversation',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: conversation != null ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        if (conversation != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'ACTIVE',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConversationInfo(BuildContext context, Conversation conversation, String userId) {
    final unreadCount = conversation.getUnreadCount(userId);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  conversation.getDisplayTitle(userId),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${conversation.participantCount} participants',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          if (conversation.lastMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Last: ${conversation.lastMessage}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, Conversation conversation, String userId) {
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
        if (showQuickActions) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _showQuickActions(context, ref, conversation, userId),
            icon: const Icon(HugeIcons.strokeRoundedMoreVertical),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNoConversationState(BuildContext context, WidgetRef ref, String userId) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
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

  void _showQuickActions(BuildContext context, WidgetRef ref, Conversation conversation, String userId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Emergency Chat Actions',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(HugeIcons.strokeRoundedUserGroup),
              title: const Text('View Participants'),
              onTap: () {
                Navigator.pop(context);
                FeedbackUtils.showInfo(context, 'Participants view coming soon!');
              },
            ),
            ListTile(
              leading: const Icon(HugeIcons.strokeRoundedLocation01),
              title: const Text('Share Location'),
              onTap: () {
                Navigator.pop(context);
                _shareLocation(context, ref, conversation.id);
              },
            ),
            ListTile(
              leading: const Icon(HugeIcons.strokeRoundedAlert02),
              title: const Text('Emergency Status'),
              onTap: () {
                Navigator.pop(context);
                _showEmergencyStatus(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createEmergencyChat(BuildContext context, WidgetRef ref, String userId) {
    FeedbackUtils.showInfo(context, 'Creating emergency chat...');
    // TODO: Implement emergency chat creation
  }

  void _shareLocation(BuildContext context, WidgetRef ref, String conversationId) {
    FeedbackUtils.showInfo(context, 'Location sharing coming soon!');
    // TODO: Implement location sharing
  }

  void _showEmergencyStatus(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Emergency Status',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: StreamBuilder<List<String>>(
          stream: EmergencyChatHelper.getEmergencyStatusUpdates(emergencyId),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: snapshot.data!
                    .map((status) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            status,
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ))
                    .toList(),
              );
            }
            return const CircularProgressIndicator();
          },
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
}
