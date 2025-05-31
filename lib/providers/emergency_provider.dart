import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emergency.dart';
import '../services/emergency_service.dart';

final emergencyServiceProvider = Provider<EmergencyService>(
  (ref) => EmergencyService(),
);

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
      return ref
          .watch(emergencyServiceProvider)
          .getResponderEmergencies(userId);
    });
