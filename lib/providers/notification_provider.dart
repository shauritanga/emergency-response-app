import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

final notificationInitializerProvider = FutureProvider.family<void, String>((
  ref,
  userId,
) async {
  await ref.watch(notificationServiceProvider).initialize(userId: userId);
});
