import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../chat/conversation_list_screen.dart';

/// Responder messages screen that displays the conversation list
class ResponderMessagesScreen extends ConsumerWidget {
  const ResponderMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Simply delegate to the conversation list screen
    return const ConversationListScreen();
  }
}
