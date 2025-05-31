import 'package:emergency_response_app/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userFutureProvider = FutureProvider.family<UserModel?, String>((
  ref,
  userId,
) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getUserData(userId);
});
