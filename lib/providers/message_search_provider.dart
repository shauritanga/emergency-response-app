import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

/// Provider for message search functionality
final messageSearchProvider =
    StateNotifierProvider<MessageSearchNotifier, MessageSearchState>((ref) {
      return MessageSearchNotifier();
    });

/// State for message search
class MessageSearchState {
  final String query;
  final List<ChatMessage> results;
  final bool isLoading;
  final String? error;

  MessageSearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  MessageSearchState copyWith({
    String? query,
    List<ChatMessage>? results,
    bool? isLoading,
    String? error,
  }) {
    return MessageSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Notifier for message search
class MessageSearchNotifier extends StateNotifier<MessageSearchState> {
  MessageSearchNotifier() : super(MessageSearchState());

  final ChatService _chatService = ChatService();

  /// Search messages in a conversation
  Future<void> searchMessages(String conversationId, String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(query: '', results: [], error: null);
      return;
    }

    state = state.copyWith(isLoading: true, query: query, error: null);

    try {
      // Get all messages from the conversation
      final messagesStream = _chatService.getConversationMessages(
        conversationId,
      );

      // Listen to the first emission to get current messages
      await for (final messages in messagesStream.take(1)) {
        final filteredMessages = _filterMessages(messages, query);
        state = state.copyWith(results: filteredMessages, isLoading: false);
        break;
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to search messages: ${e.toString()}',
        isLoading: false,
      );
    }
  }

  /// Filter messages based on search query
  List<ChatMessage> _filterMessages(List<ChatMessage> messages, String query) {
    final lowercaseQuery = query.toLowerCase();

    return messages.where((message) {
      // Filter out system messages
      if (message.type == MessageType.system) {
        return false;
      }

      // Search in message content
      if (message.content.toLowerCase().contains(lowercaseQuery)) {
        return true;
      }

      // Search in sender name
      if (message.senderName.toLowerCase().contains(lowercaseQuery)) {
        return true;
      }

      // Search in metadata for location messages
      if (message.metadata != null) {
        final metadataString = message.metadata.toString().toLowerCase();
        if (metadataString.contains(lowercaseQuery)) {
          return true;
        }
      }

      return false;
    }).toList();
  }

  /// Clear search results
  void clearSearch() {
    state = MessageSearchState();
  }

  /// Search messages across all conversations for a user
  Future<void> searchAllMessages(String userId, String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(query: '', results: [], error: null);
      return;
    }

    state = state.copyWith(isLoading: true, query: query, error: null);

    try {
      // This would require a more complex implementation
      // For now, we'll just clear the results and show a message
      state = state.copyWith(
        results: [],
        isLoading: false,
        error: 'Global search not yet implemented',
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to search messages: ${e.toString()}',
        isLoading: false,
      );
    }
  }
}

/// Provider for search query
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for search results filtering
final filteredSearchResultsProvider = Provider.family<
  List<ChatMessage>,
  String
>((ref, filter) {
  final searchState = ref.watch(messageSearchProvider);
  final results = searchState.results;

  if (filter.isEmpty) {
    return results;
  }

  switch (filter.toLowerCase()) {
    case 'emergency':
      return results.where((msg) => msg.type == MessageType.emergency).toList();
    case 'location':
      return results.where((msg) => msg.type == MessageType.location).toList();
    case 'status':
      return results.where((msg) => msg.type == MessageType.status).toList();
    default:
      return results;
  }
});

/// Provider for search suggestions
final searchSuggestionsProvider = Provider<List<String>>((ref) {
  return [
    'emergency',
    'location',
    'safe',
    'help',
    'status',
    'evacuation',
    'medical',
    'fire',
    'police',
    'ambulance',
  ];
});
