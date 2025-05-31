import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../services/message_service.dart';

final messageServiceProvider = Provider<MessageService>((ref) {
  return MessageService();
});

final userMessagesProvider = StreamProvider.family<List<Message>, String>((ref, userId) {
  return ref.watch(messageServiceProvider).getUserMessages(userId);
});