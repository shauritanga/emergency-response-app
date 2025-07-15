import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../router/app_router.dart';

class RoleLoadingScreen extends ConsumerStatefulWidget {
  const RoleLoadingScreen({super.key});

  @override
  ConsumerState<RoleLoadingScreen> createState() => _RoleLoadingScreenState();
}

class _RoleLoadingScreenState extends ConsumerState<RoleLoadingScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserRole();
    });
  }

  Future<void> _loadUserRole() async {
    if (_hasNavigated) return;

    final authState = ref.read(authStateProvider);
    final user = authState.value;

    if (user == null) {
      // User is not authenticated, go to auth
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        context.go('/auth');
      }
      return;
    }

    // Try to fetch user role with retry logic
    String? userRole = await _fetchUserRoleWithRetry(user.uid);

    if (!mounted || _hasNavigated) return;

    if (userRole != null) {
      // Set the role in the provider
      ref.read(userRoleProvider.notifier).state = userRole;

      // Navigate to appropriate screen based on role
      _hasNavigated = true;
      switch (userRole) {
        case 'citizen':
          context.go('/citizen');
          break;
        case 'responder':
          context.go('/responder');
          break;
        case 'admin':
          context.go('/admin');
          break;
        default:
          context.go('/citizen'); // Default fallback
      }
    } else {
      // If we can't determine the role, go to auth to re-authenticate
      _hasNavigated = true;
      context.go('/auth');
    }
  }

  Future<String?> _fetchUserRoleWithRetry(String userId, {int maxRetries = 3}) async {
    int attempts = 0;

    while (attempts < maxRetries && !_hasNavigated) {
      try {
        final userData = await ref.read(authServiceProvider).getUserData(userId);
        if (userData != null) {
          return userData.role;
        }

        // If userData is null, wait before retrying (Firestore propagation delay)
        if (attempts < maxRetries - 1 && !_hasNavigated) {
          await Future.delayed(
            Duration(milliseconds: 500 * (attempts + 1)),
          ); // Exponential backoff
        }
      } catch (e) {
        debugPrint('Error fetching user role (attempt ${attempts + 1}): $e');
        if (attempts < maxRetries - 1 && !_hasNavigated) {
          await Future.delayed(
            Duration(milliseconds: 500 * (attempts + 1)),
          ); // Exponential backoff
        }
      }

      attempts++;
    }

    // If all retries failed, log the issue
    debugPrint(
      'Failed to fetch user role after $maxRetries attempts for user: $userId',
    );
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.shade600,
              Colors.red.shade800,
              Colors.red.shade900,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 24),
              Text(
                'Loading your profile...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
