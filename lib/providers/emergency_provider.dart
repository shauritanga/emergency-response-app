import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emergency.dart';
import '../services/emergency_service.dart';

final emergencyServiceProvider = Provider<EmergencyService>(
  (ref) => EmergencyService(),
);

final emergencyProvider = FutureProvider.family<Emergency?, String>((
  ref,
  emergencyId,
) {
  return ref.watch(emergencyServiceProvider).getEmergency(emergencyId);
});

final emergenciesProvider = StreamProvider.family<List<Emergency>, String>((
  ref,
  userId,
) {
  return ref.watch(emergencyServiceProvider).getUserEmergencies(userId);
});

final responderEmergenciesProvider =
    StreamProvider.family<List<Emergency>, String>((ref, department) {
      return ref
          .watch(emergencyServiceProvider)
          .getResponderEmergencies(department);
    });

final emergencyHistoryStreamProvider =
    StreamProvider.family<List<Emergency>, String>((ref, userId) {
      try {
        return ref.watch(emergencyServiceProvider).getResponderHistory(userId);
      } catch (e) {
        // If Firestore is offline, return mock data as a stream
        return Stream.value(EmergencyService.getMockResponderHistory(userId));
      }
    });

final completedEmergenciesCountProvider = Provider.family<
  AsyncValue<int>,
  String
>((ref, userId) {
  final historyAsync = ref.watch(emergencyHistoryStreamProvider(userId));
  return historyAsync.when(
    data: (emergencies) {
      print(
        '📊 Completed emergencies provider: Found ${emergencies.length} resolved emergencies for user $userId',
      );
      return AsyncValue.data(emergencies.length);
    },
    loading: () {
      print('📊 Completed emergencies provider: Loading for user $userId');
      return const AsyncValue.loading();
    },
    error: (error, stackTrace) {
      print(
        '📊 Completed emergencies provider: Error for user $userId: $error',
      );
      return AsyncValue.error(error, stackTrace);
    },
  );
});
