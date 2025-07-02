import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/conversation.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/feedback_utils.dart';

class ParticipantsScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String conversationTitle;

  const ParticipantsScreen({
    super.key,
    required this.conversationId,
    required this.conversationTitle,
  });

  @override
  ConsumerState<ParticipantsScreen> createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends ConsumerState<ParticipantsScreen> {
  @override
  Widget build(BuildContext context) {
    final conversationAsync = ref.watch(
      conversationProvider(widget.conversationId),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: Text(
          'Participants',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(HugeIcons.strokeRoundedUserAdd01),
            onPressed: () => _showAddParticipantDialog(),
            tooltip: 'Add Participant',
          ),
        ],
      ),
      body: conversationAsync.when(
        data: (conversation) => _buildParticipantsList(conversation),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildParticipantsList(Conversation? conversation) {
    if (conversation == null) {
      return const Center(child: Text('Conversation not found'));
    }

    return Column(
      children: [
        // Conversation Info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.conversationTitle,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${conversation.participantIds.length} participants',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              if (conversation.isEmergencyRelated) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        HugeIcons.strokeRoundedAlert02,
                        size: 14,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Emergency Chat',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Participants List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: conversation.participantIds.length,
            itemBuilder: (context, index) {
              final participantId = conversation.participantIds[index];
              return _buildParticipantTile(participantId, conversation);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantTile(
    String participantId,
    Conversation conversation,
  ) {
    final userAsync = ref.watch(userFutureProvider(participantId));
    final currentUser = ref.watch(authStateProvider).value;
    final isCurrentUser = currentUser?.uid == participantId;

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage:
                      user.photoURL != null && user.photoURL!.isNotEmpty
                          ? CachedNetworkImageProvider(user.photoURL!)
                          : null,
                  child:
                      user.photoURL == null || user.photoURL!.isEmpty
                          ? Icon(
                            Icons.person,
                            size: 24,
                            color: Colors.grey.shade600,
                          )
                          : null,
                ),
                // Online indicator (placeholder)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    user.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
                if (isCurrentUser)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'You',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getRoleDisplayName(user.role),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: _getRoleColor(user.role),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (user.department != null)
                  Text(
                    '${user.department} Department',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
            trailing:
                !isCurrentUser
                    ? PopupMenuButton<String>(
                      onSelected:
                          (value) => _handleParticipantAction(
                            value,
                            user,
                            conversation,
                          ),
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'message',
                              child: Row(
                                children: [
                                  Icon(
                                    HugeIcons.strokeRoundedMessage01,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Send Message'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'view_profile',
                              child: Row(
                                children: [
                                  Icon(HugeIcons.strokeRoundedUser, size: 16),
                                  SizedBox(width: 8),
                                  Text('View Profile'),
                                ],
                              ),
                            ),
                            if (_canRemoveParticipant(user, conversation))
                              const PopupMenuItem(
                                value: 'remove',
                                child: Row(
                                  children: [
                                    Icon(
                                      HugeIcons.strokeRoundedUserRemove01,
                                      size: 16,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Remove',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                    )
                    : null,
          ),
        );
      },
      loading:
          () => const Card(
            child: ListTile(
              leading: CircleAvatar(child: CircularProgressIndicator()),
              title: Text('Loading...'),
            ),
          ),
      error:
          (error, _) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red.withValues(alpha: 0.1),
                child: const Icon(Icons.error, color: Colors.red),
              ),
              title: const Text('Error loading participant'),
              subtitle: Text(error.toString()),
            ),
          ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            HugeIcons.strokeRoundedAlert02,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading participants',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(HugeIcons.strokeRoundedRefresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'citizen':
        return 'Citizen';
      case 'responder':
        return 'Emergency Responder';
      case 'admin':
        return 'Administrator';
      default:
        return role.toUpperCase();
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'citizen':
        return Colors.blue;
      case 'responder':
        return Colors.deepPurple;
      case 'admin':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  bool _canRemoveParticipant(UserModel user, Conversation conversation) {
    final currentUser = ref.read(authStateProvider).value;
    if (currentUser == null) return false;

    // Only admins or conversation creators can remove participants
    // For emergency chats, only admins can remove
    if (conversation.isEmergencyRelated) {
      return currentUser.uid != user.id; // Can't remove yourself
    }

    return currentUser.uid != user.id; // Can't remove yourself
  }

  void _handleParticipantAction(
    String action,
    UserModel user,
    Conversation conversation,
  ) {
    switch (action) {
      case 'message':
        _sendDirectMessage(user);
        break;
      case 'view_profile':
        _viewProfile(user);
        break;
      case 'remove':
        _removeParticipant(user, conversation);
        break;
    }
  }

  void _sendDirectMessage(UserModel user) {
    FeedbackUtils.showInfo(context, 'Direct messaging feature coming soon!');
  }

  void _viewProfile(UserModel user) {
    FeedbackUtils.showInfo(context, 'Profile view feature coming soon!');
  }

  void _removeParticipant(UserModel user, Conversation conversation) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Participant'),
            content: Text(
              'Are you sure you want to remove ${user.name} from this conversation?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _performRemoveParticipant(user.id);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }

  void _performRemoveParticipant(String userId) {
    FeedbackUtils.showInfo(context, 'Remove participant feature coming soon!');
  }

  void _showAddParticipantDialog() {
    FeedbackUtils.showInfo(context, 'Add participant feature coming soon!');
  }
}
