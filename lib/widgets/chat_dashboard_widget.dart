import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../models/conversation.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../screens/chat/conversation_list_screen.dart';
import '../utils/offline_cache.dart';

/// Dashboard widget showing chat overview and quick actions
class ChatDashboardWidget extends ConsumerWidget {
  const ChatDashboardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) return const SizedBox.shrink();

    final conversationsAsync = ref.watch(userConversationsProvider(user.uid));
    final totalUnreadAsync = ref.watch(totalUnreadCountProvider(user.uid));

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildStats(conversationsAsync, totalUnreadAsync),
            const SizedBox(height: 16),
            _buildQuickActions(context, user.uid),
            const SizedBox(height: 12),
            _buildRecentActivity(conversationsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            HugeIcons.strokeRoundedMessage01,
            color: Colors.blue,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Messages',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Stay connected with emergency responders',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ConversationListScreen(),
            ),
          ),
          icon: const Icon(HugeIcons.strokeRoundedArrowRight01),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(
    AsyncValue<List<Conversation>> conversationsAsync,
    AsyncValue<int> totalUnreadAsync,
  ) {
    return conversationsAsync.when(
      data: (conversations) {
        final activeChats = conversations.where((c) => c.isActive).length;
        final emergencyChats = conversations.where((c) => c.isEmergencyRelated).length;
        
        return totalUnreadAsync.when(
          data: (unreadCount) => Row(
            children: [
              _buildStatItem(
                icon: HugeIcons.strokeRoundedMessage01,
                label: 'Active Chats',
                value: activeChats.toString(),
                color: Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildStatItem(
                icon: HugeIcons.strokeRoundedAlert02,
                label: 'Emergency',
                value: emergencyChats.toString(),
                color: Colors.red,
              ),
              const SizedBox(width: 16),
              _buildStatItem(
                icon: HugeIcons.strokeRoundedNotification01,
                label: 'Unread',
                value: unreadCount.toString(),
                color: unreadCount > 0 ? Colors.orange : Colors.green,
              ),
            ],
          ),
          loading: () => _buildStatsLoading(),
          error: (_, __) => _buildStatsError(),
        );
      },
      loading: () => _buildStatsLoading(),
      error: (_, __) => _buildStatsError(),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsLoading() {
    return Row(
      children: List.generate(3, (index) => 
        Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 2 ? 16 : 0),
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(HugeIcons.strokeRoundedAlert02, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Text(
            'Unable to load chat statistics',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildQuickActionButton(
              icon: HugeIcons.strokeRoundedAdd01,
              label: 'New Chat',
              onPressed: () => _showNewChatOptions(context),
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            _buildQuickActionButton(
              icon: HugeIcons.strokeRoundedSearch01,
              label: 'Search',
              onPressed: () => _showGlobalSearch(context, userId),
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            _buildQuickActionButton(
              icon: HugeIcons.strokeRoundedSettings01,
              label: 'Settings',
              onPressed: () => _showChatSettings(context),
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(AsyncValue<List<Conversation>> conversationsAsync) {
    return conversationsAsync.when(
      data: (conversations) {
        final recentConversations = conversations.take(3).toList();
        
        if (recentConversations.isEmpty) {
          return _buildNoActivity();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            ...recentConversations.map((conversation) => 
              _buildActivityItem(conversation),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildActivityItem(Conversation conversation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: _getConversationColor(conversation).withValues(alpha: 0.1),
            child: Icon(
              _getConversationIcon(conversation),
              color: _getConversationColor(conversation),
              size: 12,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.getDisplayTitle(''),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (conversation.lastMessage.isNotEmpty)
                  Text(
                    conversation.lastMessage,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            _formatTime(conversation.lastMessageTime),
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoActivity() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            HugeIcons.strokeRoundedMessage01,
            color: Colors.grey.shade400,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            'No recent activity',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getConversationColor(Conversation conversation) {
    switch (conversation.type) {
      case ConversationType.emergency:
        return Colors.red;
      case ConversationType.group:
        return Colors.blue;
      case ConversationType.direct:
        return Colors.green;
      case ConversationType.broadcast:
        return Colors.orange;
    }
  }

  IconData _getConversationIcon(Conversation conversation) {
    switch (conversation.type) {
      case ConversationType.emergency:
        return HugeIcons.strokeRoundedAlert02;
      case ConversationType.group:
        return HugeIcons.strokeRoundedUserGroup;
      case ConversationType.direct:
        return HugeIcons.strokeRoundedUser;
      case ConversationType.broadcast:
        return HugeIcons.strokeRoundedSpeaker;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  void _showNewChatOptions(BuildContext context) {
    // TODO: Implement new chat options
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('New chat feature coming soon!')),
    );
  }

  void _showGlobalSearch(BuildContext context, String userId) {
    // TODO: Implement global search
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Global search coming soon!')),
    );
  }

  void _showChatSettings(BuildContext context) {
    // TODO: Implement chat settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat settings coming soon!')),
    );
  }
}
