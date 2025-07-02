import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../models/conversation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/feedback_utils.dart';
import 'chat_screen.dart';

class ConversationListScreen extends ConsumerWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    final conversationsAsync = ref.watch(userConversationsProvider(user.uid));
    final totalUnreadAsync = ref.watch(totalUnreadCountProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Messages',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 8),
            totalUnreadAsync.when(
              data:
                  (count) =>
                      count > 0
                          ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              count.toString(),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                          : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(HugeIcons.strokeRoundedUserAdd01),
            onPressed: () => _showNewChatDialog(context, ref, user.uid),
            tooltip: 'New Chat',
          ),
          IconButton(
            icon: const Icon(HugeIcons.strokeRoundedSettings01),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildConversationList(context, ref, conversations, user.uid);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(context, ref, error.toString()),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "conversation_list_fab",
        onPressed: () => _showNewChatDialog(context, ref, user.uid),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(
          HugeIcons.strokeRoundedMessage01,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            HugeIcons.strokeRoundedMessage01,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with emergency responders',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showNewChatDialog(context, null, ''),
            icon: const Icon(HugeIcons.strokeRoundedUserAdd01),
            label: Text(
              'Start New Chat',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            HugeIcons.strokeRoundedAlert02,
            size: 64,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading conversations',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(userConversationsProvider);
            },
            icon: const Icon(HugeIcons.strokeRoundedRefresh),
            label: Text(
              'Retry',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(
    BuildContext context,
    WidgetRef ref,
    List<Conversation> conversations,
    String currentUserId,
  ) {
    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return _buildConversationTile(
          context,
          ref,
          conversation,
          currentUserId,
        );
      },
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    WidgetRef ref,
    Conversation conversation,
    String currentUserId,
  ) {
    final unreadCount = conversation.getUnreadCount(currentUserId);
    final hasUnread = unreadCount > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: hasUnread ? 2 : 1,
      child: ListTile(
        leading: _buildConversationAvatar(conversation),
        title: Text(
          conversation.getDisplayTitle(currentUserId),
          style: GoogleFonts.poppins(
            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conversation.lastMessage.isNotEmpty
                  ? conversation.lastMessage
                  : conversation.getDisplaySubtitle(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: hasUnread ? Colors.black87 : Colors.grey.shade600,
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(conversation.lastMessageTime),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasUnread)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
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
            if (conversation.isEmergencyRelated)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'EMERGENCY',
                  style: GoogleFonts.poppins(
                    color: Colors.red.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        onTap: () => _openConversation(context, conversation.id),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildConversationAvatar(Conversation conversation) {
    IconData icon;
    Color color;

    switch (conversation.type) {
      case ConversationType.emergency:
        icon = HugeIcons.strokeRoundedAlert02;
        color = Colors.red;
        break;
      case ConversationType.group:
        icon = HugeIcons.strokeRoundedUserGroup;
        color = Colors.blue;
        break;
      case ConversationType.direct:
        icon = HugeIcons.strokeRoundedUser;
        color = Colors.green;
        break;
      case ConversationType.broadcast:
        icon = HugeIcons.strokeRoundedSpeaker;
        color = Colors.orange;
        break;
    }

    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.1),
      child: Icon(icon, color: color, size: 20),
    );
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

  void _openConversation(BuildContext context, String conversationId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversationId: conversationId),
      ),
    );
  }

  void _showNewChatDialog(BuildContext context, WidgetRef? ref, String userId) {
    final TextEditingController recipientController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Start New Chat',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: recipientController,
                decoration: InputDecoration(
                  labelText: 'Recipient ID or Name',
                  hintText: 'Enter user ID or search name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Enter the ID of the person you want to message.',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final recipientId = recipientController.text.trim();
                if (recipientId.isNotEmpty && recipientId != userId) {
                  // Create a new conversation
                  if (ref != null) {
                    try {
                      final newConversationId = await ref.read(chatServiceProvider).createConversation(
                        type: ConversationType.direct,
                        participantIds: [userId, recipientId],
                        participantNames: {'': ''}, // Placeholder, adjust based on actual data
                        participantRoles: {'': ''}, // Placeholder, adjust based on actual data
                        createdBy: userId,
                      );
                      Navigator.of(context).pop();
                      _openConversation(context, newConversationId);
                    } catch (e) {
                      FeedbackUtils.showError(context, 'Failed to start chat: $e');
                    }
                  } else {
                    Navigator.of(context).pop();
                    FeedbackUtils.showError(context, 'Error: Unable to access chat service');
                  }
                } else {
                  FeedbackUtils.showError(context, 'Please enter a valid recipient ID');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Start Chat',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
    );
  }
}
