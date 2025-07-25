import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../chat/conversation_list_screen.dart';

/// Citizen messages screen that displays the conversation list
class CitizenMessagesScreen extends ConsumerWidget {
  const CitizenMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Simply delegate to the conversation list screen
    return const ConversationListScreen();
  }
}
