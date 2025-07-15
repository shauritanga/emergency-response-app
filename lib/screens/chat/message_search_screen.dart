import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../models/message.dart';
import '../../providers/message_search_provider.dart';

class MessageSearchScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String conversationTitle;

  const MessageSearchScreen({
    super.key,
    required this.conversationId,
    required this.conversationTitle,
  });

  @override
  ConsumerState<MessageSearchScreen> createState() =>
      _MessageSearchScreenState();
}

class _MessageSearchScreenState extends ConsumerState<MessageSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(messageSearchProvider);
    final suggestions = ref.watch(searchSuggestionsProvider);
    final filteredResults = ref.watch(
      filteredSearchResultsProvider(_selectedFilter),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search Messages',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Text(
              widget.conversationTitle,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                  color: Colors.black.withValues(alpha: 0.1),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search messages...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                    prefixIcon: const Icon(HugeIcons.strokeRoundedSearch01),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                ref
                                    .read(messageSearchProvider.notifier)
                                    .clearSearch();
                              },
                              icon: const Icon(HugeIcons.strokeRoundedCancel01),
                            )
                            : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onChanged: (query) {
                    setState(() {});
                    if (query.isNotEmpty) {
                      ref
                          .read(messageSearchProvider.notifier)
                          .searchMessages(widget.conversationId, query);
                    } else {
                      ref.read(messageSearchProvider.notifier).clearSearch();
                    }
                  },
                ),

                // Filter chips
                if (searchState.results.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', ''),
                        _buildFilterChip('Emergency', 'emergency'),
                        _buildFilterChip('Location', 'location'),
                        _buildFilterChip('Status', 'status'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Search results
          Expanded(
            child: _buildSearchContent(
              searchState,
              filteredResults,
              suggestions,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchContent(
    MessageSearchState searchState,
    List<ChatMessage> filteredResults,
    List<String> suggestions,
  ) {
    if (searchState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchState.error != null) {
      return _buildErrorState(searchState.error!);
    }

    if (searchState.query.isEmpty) {
      return _buildSuggestionsState(suggestions);
    }

    if (filteredResults.isEmpty) {
      return _buildNoResultsState(searchState.query);
    }

    return _buildResultsList(filteredResults, searchState.query);
  }

  Widget _buildSuggestionsState(List<String> suggestions) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Suggestions',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                suggestions.map((suggestion) {
                  return InkWell(
                    onTap: () {
                      _searchController.text = suggestion;
                      ref
                          .read(messageSearchProvider.notifier)
                          .searchMessages(widget.conversationId, suggestion);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        suggestion,
                        style: GoogleFonts.poppins(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            HugeIcons.strokeRoundedSearch01,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No messages match "$query"',
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
            'Search Error',
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

  Widget _buildResultsList(List<ChatMessage> results, String query) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${results.length} result${results.length == 1 ? '' : 's'} for "$query"',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final message = results[index];
              return _buildMessageTile(message, query);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMessageTile(ChatMessage message, String query) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getMessageTypeColor(
            message.type,
          ).withValues(alpha: 0.1),
          child: Icon(
            _getMessageTypeIcon(message.type),
            color: _getMessageTypeColor(message.type),
            size: 20,
          ),
        ),
        title: Text(
          message.senderName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _highlightSearchTerm(message.content, query),
              style: GoogleFonts.poppins(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(message.timestamp),
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        onTap: () {
          // Navigate back to chat and scroll to message
          Navigator.pop(context, message.id);
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String filter) {
    final isSelected = _selectedFilter == filter;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.blue,
            fontWeight: FontWeight.w500,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? filter : '';
          });
        },
        selectedColor: Colors.blue,
        backgroundColor: Colors.blue.withValues(alpha: 0.1),
        side: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
      ),
    );
  }

  Color _getMessageTypeColor(MessageType type) {
    switch (type) {
      case MessageType.emergency:
        return Colors.red;
      case MessageType.location:
        return Colors.green;
      case MessageType.status:
        return Colors.blue;
      case MessageType.text:
      default:
        return Colors.grey;
    }
  }

  IconData _getMessageTypeIcon(MessageType type) {
    switch (type) {
      case MessageType.emergency:
        return HugeIcons.strokeRoundedAlert02;
      case MessageType.location:
        return HugeIcons.strokeRoundedLocation01;
      case MessageType.status:
        return HugeIcons.strokeRoundedCheckmarkCircle01;
      case MessageType.text:
      default:
        return HugeIcons.strokeRoundedMessage01;
    }
  }

  String _highlightSearchTerm(String text, String query) {
    // Simple highlighting - in a real app you might want to use RichText
    return text;
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
}
