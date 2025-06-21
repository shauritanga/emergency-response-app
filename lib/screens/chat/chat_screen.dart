import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/location_provider.dart';
import '../../services/chat_service.dart';
import '../../utils/feedback_utils.dart';
import '../../utils/message_templates.dart';
import '../../widgets/message_templates_widget.dart';
import 'message_search_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsRead();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markAsRead() async {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      try {
        await ref
            .read(chatServiceProvider)
            .markAsRead(
              conversationId: widget.conversationId,
              userId: user.uid,
            );
      } catch (e) {
        // Silently handle error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    final conversationAsync = ref.watch(
      conversationProvider(widget.conversationId),
    );
    final messagesAsync = ref.watch(
      conversationMessagesProvider(widget.conversationId),
    );

    return Scaffold(
      appBar: AppBar(
        title: conversationAsync.when(
          data:
              (conversation) =>
                  conversation != null
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conversation.getDisplayTitle(user.uid),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${conversation.participantCount} participants',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      )
                      : Text(
                        'Chat',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
          loading:
              () => Text(
                'Loading...',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
          error:
              (_, __) => Text(
                'Error',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(HugeIcons.strokeRoundedMoreVertical),
            onPressed: () => _showChatOptions(context),
          ),
        ],
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) => _buildMessageList(messages, user.uid),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildErrorState(error.toString()),
            ),
          ),
          _buildMessageInput(user.uid),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages, String currentUserId) {
    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isCurrentUser = message.senderId == currentUserId;
        final showSenderInfo = _shouldShowSenderInfo(
          messages,
          index,
          currentUserId,
        );

        return _buildMessageBubble(message, isCurrentUser, showSenderInfo);
      },
    );
  }

  Widget _buildEmptyState() {
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
            'No messages yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation by sending a message',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading messages',
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
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    bool isCurrentUser,
    bool showSenderInfo,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser && showSenderInfo) _buildAvatar(message),
          if (!isCurrentUser && !showSenderInfo) const SizedBox(width: 40),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color:
                    isCurrentUser
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: Radius.circular(
                    !isCurrentUser && showSenderInfo ? 4 : 18,
                  ),
                  bottomRight: Radius.circular(
                    isCurrentUser && showSenderInfo ? 4 : 18,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser && showSenderInfo)
                    Text(
                      message.senderName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getRoleColor(message.senderRole),
                      ),
                    ),
                  _buildMessageContent(message, isCurrentUser),
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(message.timestamp),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color:
                          isCurrentUser ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser && showSenderInfo) _buildAvatar(message),
          if (isCurrentUser && !showSenderInfo) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildAvatar(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: _getRoleColor(
          message.senderRole,
        ).withValues(alpha: 0.1),
        child: Text(
          message.senderName.isNotEmpty
              ? message.senderName[0].toUpperCase()
              : '?',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _getRoleColor(message.senderRole),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(String currentUserId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Quick action buttons
          Row(
            children: [
              _buildQuickActionButton(
                icon: HugeIcons.strokeRoundedLocation01,
                label: 'Location',
                onPressed: () => _shareLocation(currentUserId),
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              _buildQuickActionButton(
                icon: HugeIcons.strokeRoundedAlert02,
                label: 'Status',
                onPressed: () => _sendStatusUpdate(currentUserId),
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              _buildQuickActionButton(
                icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                label: 'Safe',
                onPressed:
                    () => _sendQuickMessage(currentUserId, '✅ I am safe'),
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildQuickActionButton(
                icon: HugeIcons.strokeRoundedMessage01,
                label: 'Templates',
                onPressed: () => _showMessageTemplates(currentUserId),
                color: Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Message input row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed:
                      _isLoading ? null : () => _sendMessage(currentUserId),
                  icon:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Icon(
                            HugeIcons.strokeRoundedSent,
                            color: Colors.white,
                          ),
                ),
              ),
            ],
          ),
        ],
      ),
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
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message, bool isCurrentUser) {
    switch (message.type) {
      case MessageType.location:
        return _buildLocationMessage(message, isCurrentUser);
      case MessageType.system:
        return _buildSystemMessage(message);
      case MessageType.emergency:
        return _buildEmergencyMessage(message);
      case MessageType.status:
        return _buildStatusMessage(message, isCurrentUser);
      case MessageType.text:
      default:
        return Text(
          message.content,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isCurrentUser ? Colors.white : Colors.black87,
          ),
        );
    }
  }

  Widget _buildLocationMessage(ChatMessage message, bool isCurrentUser) {
    final metadata = message.metadata;
    final latitude = metadata?['latitude'] as double?;
    final longitude = metadata?['longitude'] as double?;
    final accuracy = metadata?['accuracy'] as double?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              HugeIcons.strokeRoundedLocation01,
              color: isCurrentUser ? Colors.white : Colors.green,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              message.content,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isCurrentUser ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (latitude != null && longitude != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isCurrentUser ? Colors.white : Colors.grey.shade100)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lat: ${latitude.toStringAsFixed(6)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color:
                        isCurrentUser ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
                Text(
                  'Lng: ${longitude.toStringAsFixed(6)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color:
                        isCurrentUser ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
                if (accuracy != null)
                  Text(
                    'Accuracy: ${accuracy.toStringAsFixed(1)}m',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color:
                          isCurrentUser ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSystemMessage(ChatMessage message) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            HugeIcons.strokeRoundedAlert02,
            color: Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.content,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyMessage(ChatMessage message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                HugeIcons.strokeRoundedAlert02,
                color: Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'EMERGENCY ALERT',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.red.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMessage(ChatMessage message, bool isCurrentUser) {
    Color statusColor = Colors.blue;
    IconData statusIcon = HugeIcons.strokeRoundedCheckmarkCircle01;

    if (message.content.contains('🚨') ||
        message.content.toLowerCase().contains('emergency')) {
      statusColor = Colors.red;
      statusIcon = HugeIcons.strokeRoundedAlert02;
    } else if (message.content.contains('⚠️') ||
        message.content.toLowerCase().contains('assistance')) {
      statusColor = Colors.orange;
      statusIcon = HugeIcons.strokeRoundedAlert01;
    } else if (message.content.contains('✅') ||
        message.content.toLowerCase().contains('safe')) {
      statusColor = Colors.green;
      statusIcon = HugeIcons.strokeRoundedCheckmarkCircle01;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.content,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowSenderInfo(
    List<ChatMessage> messages,
    int index,
    String currentUserId,
  ) {
    if (index == messages.length - 1) return true;

    final currentMessage = messages[index];
    final nextMessage = messages[index + 1];

    return currentMessage.senderId != nextMessage.senderId ||
        currentMessage.timestamp.difference(nextMessage.timestamp).inMinutes >
            5;
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'responder':
        return Colors.blue;
      case 'admin':
        return Colors.purple;
      case 'citizen':
        return Colors.green;
      case 'system':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatMessageTime(DateTime timestamp) {
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

  Future<void> _sendMessage(String currentUserId) async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userDataAsync = await ref.read(
        userFutureProvider(currentUserId).future,
      );
      if (userDataAsync == null) {
        throw Exception('User data not found');
      }

      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: widget.conversationId,
        senderId: currentUserId,
        senderName: userDataAsync.name,
        senderRole: userDataAsync.role,
        content: content,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );

      await ref.read(chatServiceProvider).sendMessage(message);

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        FeedbackUtils.showError(
          context,
          'Failed to send message: ${e.toString()}',
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(HugeIcons.strokeRoundedUserGroup),
                  title: const Text('View Participants'),
                  onTap: () {
                    Navigator.pop(context);
                    FeedbackUtils.showInfo(
                      context,
                      'Participants view coming soon!',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(HugeIcons.strokeRoundedSearch01),
                  title: const Text('Search Messages'),
                  onTap: () {
                    Navigator.pop(context);
                    _openMessageSearch();
                  },
                ),
                ListTile(
                  leading: const Icon(HugeIcons.strokeRoundedArchive),
                  title: const Text('Archive Chat'),
                  onTap: () {
                    Navigator.pop(context);
                    _archiveConversation();
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _archiveConversation() async {
    try {
      await ref
          .read(chatServiceProvider)
          .archiveConversation(widget.conversationId);
      if (mounted) {
        FeedbackUtils.showSuccess(context, 'Conversation archived');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        FeedbackUtils.showError(context, 'Failed to archive conversation');
      }
    }
  }

  /// Share current location in the chat
  Future<void> _shareLocation(String currentUserId) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final location =
          await ref.read(locationServiceProvider).getCurrentLocation();
      if (location == null) {
        throw Exception('Unable to get current location');
      }

      final userDataAsync = await ref.read(
        userFutureProvider(currentUserId).future,
      );
      if (userDataAsync == null) {
        throw Exception('User data not found');
      }

      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: widget.conversationId,
        senderId: currentUserId,
        senderName: userDataAsync.name,
        senderRole: userDataAsync.role,
        content: '📍 Location shared',
        type: MessageType.location,
        timestamp: DateTime.now(),
        metadata: {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'accuracy': location.accuracy,
        },
      );

      await ref.read(chatServiceProvider).sendMessage(message);
      _scrollToBottom();

      if (mounted) {
        FeedbackUtils.showSuccess(context, 'Location shared successfully');
      }
    } catch (e) {
      if (mounted) {
        FeedbackUtils.showError(
          context,
          'Failed to share location: ${e.toString()}',
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

  /// Send a status update message
  Future<void> _sendStatusUpdate(String currentUserId) async {
    final status = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Send Status Update',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: const Text('All Clear'),
                  onTap:
                      () => Navigator.pop(
                        context,
                        '✅ All clear - situation under control',
                      ),
                ),
                ListTile(
                  leading: const Icon(Icons.warning, color: Colors.orange),
                  title: const Text('Need Assistance'),
                  onTap:
                      () => Navigator.pop(
                        context,
                        '⚠️ Need assistance - please respond',
                      ),
                ),
                ListTile(
                  leading: const Icon(Icons.emergency, color: Colors.red),
                  title: const Text('Emergency'),
                  onTap:
                      () => Navigator.pop(
                        context,
                        '🚨 EMERGENCY - immediate help needed',
                      ),
                ),
              ],
            ),
          ),
    );

    if (status != null) {
      await _sendQuickMessage(currentUserId, status);
    }
  }

  /// Send a quick predefined message
  Future<void> _sendQuickMessage(String currentUserId, String content) async {
    try {
      final userDataAsync = await ref.read(
        userFutureProvider(currentUserId).future,
      );
      if (userDataAsync == null) {
        throw Exception('User data not found');
      }

      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: widget.conversationId,
        senderId: currentUserId,
        senderName: userDataAsync.name,
        senderRole: userDataAsync.role,
        content: content,
        type: MessageType.status,
        timestamp: DateTime.now(),
      );

      await ref.read(chatServiceProvider).sendMessage(message);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        FeedbackUtils.showError(
          context,
          'Failed to send message: ${e.toString()}',
        );
      }
    }
  }

  /// Show message templates bottom sheet
  void _showMessageTemplates(String currentUserId) async {
    final userDataAsync = await ref.read(
      userFutureProvider(currentUserId).future,
    );
    if (userDataAsync == null) return;

    if (mounted) {
      showMessageTemplates(
        context: context,
        userRole: userDataAsync.role,
        onTemplateSelected: (template) {
          _sendTemplateMessage(currentUserId, template);
        },
      );
    }
  }

  /// Send a message from a template
  Future<void> _sendTemplateMessage(
    String currentUserId,
    MessageTemplate template,
  ) async {
    try {
      final userDataAsync = await ref.read(
        userFutureProvider(currentUserId).future,
      );
      if (userDataAsync == null) {
        throw Exception('User data not found');
      }

      // Process template variables if needed
      String content = template.content;

      // You can add variable processing here
      // For example: content = MessageTemplates.processTemplate(content, variables);

      final messageType = _getMessageTypeFromTemplate(template);

      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: widget.conversationId,
        senderId: currentUserId,
        senderName: userDataAsync.name,
        senderRole: userDataAsync.role,
        content: content,
        type: messageType,
        timestamp: DateTime.now(),
      );

      await ref.read(chatServiceProvider).sendMessage(message);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        FeedbackUtils.showError(
          context,
          'Failed to send template message: ${e.toString()}',
        );
      }
    }
  }

  /// Get message type based on template priority and category
  MessageType _getMessageTypeFromTemplate(MessageTemplate template) {
    if (template.priority == MessagePriority.urgent) {
      return MessageType.emergency;
    } else if (template.category == 'Status') {
      return MessageType.status;
    } else {
      return MessageType.text;
    }
  }

  /// Open message search screen
  void _openMessageSearch() async {
    final conversationAsync = await ref.read(
      conversationProvider(widget.conversationId).future,
    );
    final conversation = conversationAsync;

    if (conversation != null && mounted) {
      final user = ref.read(authStateProvider).value;
      final conversationTitle =
          user != null ? conversation.getDisplayTitle(user.uid) : 'Chat';

      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder:
              (context) => MessageSearchScreen(
                conversationId: widget.conversationId,
                conversationTitle: conversationTitle,
              ),
        ),
      );

      // If a message ID was returned, scroll to that message
      if (result != null && mounted) {
        // TODO: Implement scroll to specific message
        FeedbackUtils.showInfo(context, 'Found message: $result');
      }
    }
  }
}
