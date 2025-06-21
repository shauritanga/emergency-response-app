import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

/// Provider for ChatService instance
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

/// Provider for user's conversations stream
final userConversationsProvider =
    StreamProvider.family<List<Conversation>, String>((ref, userId) {
      return ref.watch(chatServiceProvider).getUserConversations(userId);
    });

/// Provider for conversation messages stream
final conversationMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, conversationId) {
      return ref
          .watch(chatServiceProvider)
          .getConversationMessages(conversationId);
    });

/// Provider for a specific conversation
final conversationProvider = FutureProvider.family<Conversation?, String>((
  ref,
  conversationId,
) {
  return ref.watch(chatServiceProvider).getConversation(conversationId);
});

/// Provider for total unread count
final totalUnreadCountProvider = FutureProvider.family<int, String>((
  ref,
  userId,
) {
  return ref.watch(chatServiceProvider).getTotalUnreadCount(userId);
});

/// Provider for managing current conversation state
final currentConversationProvider = StateProvider<String?>((ref) => null);

/// Provider for managing typing indicators
final typingIndicatorProvider = StateProvider.family<Set<String>, String>(
  (ref, conversationId) => {},
);

/// Provider for managing message composition state
final messageCompositionProvider = StateProvider.family<String, String>(
  (ref, conversationId) => '',
);

/// Provider for managing chat UI state
final chatUIStateProvider =
    StateNotifierProvider<ChatUIStateNotifier, ChatUIState>((ref) {
      return ChatUIStateNotifier();
    });

/// Chat UI state management
class ChatUIState {
  final bool isLoading;
  final String? error;
  final bool isComposing;
  final Map<String, bool> conversationStates;

  ChatUIState({
    this.isLoading = false,
    this.error,
    this.isComposing = false,
    this.conversationStates = const {},
  });

  ChatUIState copyWith({
    bool? isLoading,
    String? error,
    bool? isComposing,
    Map<String, bool>? conversationStates,
  }) {
    return ChatUIState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isComposing: isComposing ?? this.isComposing,
      conversationStates: conversationStates ?? this.conversationStates,
    );
  }
}

/// State notifier for chat UI
class ChatUIStateNotifier extends StateNotifier<ChatUIState> {
  ChatUIStateNotifier() : super(ChatUIState());

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void setComposing(bool composing) {
    state = state.copyWith(isComposing: composing);
  }

  void setConversationState(String conversationId, bool isActive) {
    final updatedStates = Map<String, bool>.from(state.conversationStates);
    updatedStates[conversationId] = isActive;
    state = state.copyWith(conversationStates: updatedStates);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for emergency-specific conversations for a user
final emergencyConversationsForUserProvider = Provider.family<
  AsyncValue<List<Conversation>>,
  ({String userId, String emergencyId})
>((ref, params) {
  final conversationsAsync = ref.watch(
    userConversationsProvider(params.userId),
  );

  return conversationsAsync.when(
    data: (conversations) {
      final emergencyConversations =
          conversations
              .where((conv) => conv.emergencyId == params.emergencyId)
              .toList();
      return AsyncValue.data(emergencyConversations);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Provider for conversation participants
final conversationParticipantsProvider =
    FutureProvider.family<List<String>, String>((ref, conversationId) async {
      final conversation = await ref.watch(
        conversationProvider(conversationId).future,
      );
      return conversation?.participantIds ?? [];
    });

/// Provider for checking if user can send messages in conversation
final canSendMessageProvider =
    FutureProvider.family<bool, ({String conversationId, String userId})>((
      ref,
      params,
    ) async {
      final conversation = await ref.watch(
        conversationProvider(params.conversationId).future,
      );
      if (conversation == null) return false;

      // Check if user is participant
      if (!conversation.hasParticipant(params.userId)) return false;

      // Check if conversation is active
      if (!conversation.isActive) return false;

      // Additional role-based checks can be added here
      return true;
    });

/// Provider for conversation display info
final conversationDisplayInfoProvider = FutureProvider.family<
  ConversationDisplayInfo?,
  ({String conversationId, String currentUserId})
>((ref, params) async {
  final conversation = await ref.watch(
    conversationProvider(params.conversationId).future,
  );
  if (conversation == null) return null;

  return ConversationDisplayInfo(
    title: conversation.getDisplayTitle(params.currentUserId),
    subtitle: conversation.getDisplaySubtitle(),
    participantCount: conversation.participantCount,
    isEmergencyRelated: conversation.isEmergencyRelated,
    unreadCount: conversation.getUnreadCount(params.currentUserId),
  );
});

/// Display information for a conversation
class ConversationDisplayInfo {
  final String title;
  final String subtitle;
  final int participantCount;
  final bool isEmergencyRelated;
  final int unreadCount;

  ConversationDisplayInfo({
    required this.title,
    required this.subtitle,
    required this.participantCount,
    required this.isEmergencyRelated,
    required this.unreadCount,
  });
}

/// Provider for filtering conversations by type
final conversationsByTypeProvider = Provider.family<
  AsyncValue<List<Conversation>>,
  ({String userId, ConversationType? type})
>((ref, params) {
  final conversationsAsync = ref.watch(
    userConversationsProvider(params.userId),
  );

  return conversationsAsync.when(
    data: (conversations) {
      if (params.type == null) {
        return AsyncValue.data(conversations);
      }
      final filtered =
          conversations.where((conv) => conv.type == params.type).toList();
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Provider for recent conversations (last 24 hours)
final recentConversationsProvider =
    Provider.family<AsyncValue<List<Conversation>>, String>((ref, userId) {
      final conversationsAsync = ref.watch(userConversationsProvider(userId));

      return conversationsAsync.when(
        data: (conversations) {
          final now = DateTime.now();
          final yesterday = now.subtract(const Duration(hours: 24));

          final recent =
              conversations
                  .where((conv) => conv.lastMessageTime.isAfter(yesterday))
                  .toList();

          return AsyncValue.data(recent);
        },
        loading: () => const AsyncValue.loading(),
        error: (error, stack) => AsyncValue.error(error, stack),
      );
    });

/// Provider for emergency conversations only
final emergencyOnlyConversationsProvider =
    Provider.family<AsyncValue<List<Conversation>>, String>((ref, userId) {
      return ref.watch(
        conversationsByTypeProvider((
          userId: userId,
          type: ConversationType.emergency,
        )),
      );
    });

/// Provider for all emergency-related conversations (including those with emergencyId)
final allEmergencyConversationsProvider =
    Provider.family<AsyncValue<List<Conversation>>, String>((ref, userId) {
      final conversationsAsync = ref.watch(userConversationsProvider(userId));

      return conversationsAsync.when(
        data: (conversations) {
          final emergencyConversations =
              conversations.where((conv) => conv.isEmergencyRelated).toList();
          return AsyncValue.data(emergencyConversations);
        },
        loading: () => const AsyncValue.loading(),
        error: (error, stack) => AsyncValue.error(error, stack),
      );
    });

/// Provider for direct conversations only
final directConversationsProvider =
    Provider.family<AsyncValue<List<Conversation>>, String>((ref, userId) {
      return ref.watch(
        conversationsByTypeProvider((
          userId: userId,
          type: ConversationType.direct,
        )),
      );
    });

/// Provider for group conversations only
final groupConversationsProvider =
    Provider.family<AsyncValue<List<Conversation>>, String>((ref, userId) {
      return ref.watch(
        conversationsByTypeProvider((
          userId: userId,
          type: ConversationType.group,
        )),
      );
    });

/// Provider for conversations with unread messages
final unreadConversationsProvider =
    Provider.family<AsyncValue<List<Conversation>>, String>((ref, userId) {
      final conversationsAsync = ref.watch(userConversationsProvider(userId));

      return conversationsAsync.when(
        data: (conversations) {
          final unreadConversations =
              conversations
                  .where((conv) => conv.hasUnreadMessages(userId))
                  .toList();
          return AsyncValue.data(unreadConversations);
        },
        loading: () => const AsyncValue.loading(),
        error: (error, stack) => AsyncValue.error(error, stack),
      );
    });

/// Provider for checking if a conversation exists between two users
final conversationExistsProvider =
    FutureProvider.family<String?, ({String user1Id, String user2Id})>((
      ref,
      params,
    ) async {
      final conversationsAsync = await ref.watch(
        userConversationsProvider(params.user1Id).future,
      );

      for (final conversation in conversationsAsync) {
        if (conversation.type == ConversationType.direct &&
            conversation.participantIds.contains(params.user2Id) &&
            conversation.participantIds.length == 2) {
          return conversation.id;
        }
      }
      return null;
    });
