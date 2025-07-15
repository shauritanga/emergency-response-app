import 'package:emergency_response_app/router/go_router_refresh_stream.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/citizen/citizen_home_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/role_loading_screen.dart';
import '../screens/responder/responder_home_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../providers/auth_provider.dart';

// Create a provider to track the current user role
final userRoleProvider = StateProvider<String?>((ref) => null);

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  // Listen to auth state changes and clear role when logged out
  ref.listen(authStateProvider, (previous, current) {
    if (current.value == null) {
      // User is logged out, clear role
      ref.read(userRoleProvider.notifier).state = null;
    }
    // Note: Role fetching is now handled by the splash screen
  });

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final currentLocation = state.matchedLocation;

      // Allow splash and onboarding screens without authentication
      if (currentLocation == '/' || currentLocation == '/onboarding') {
        return null;
      }

      final isAuthRoute =
          currentLocation == '/auth' ||
          currentLocation == '/login' ||
          currentLocation == '/register';

      // If not logged in and not on auth routes, redirect to auth
      if (!isLoggedIn && !isAuthRoute) {
        return '/auth';
      }

      // If logged in and on auth routes, redirect to role loading
      if (isLoggedIn && isAuthRoute) {
        return '/loading-role';
      }

      return null; // No redirect needed
    },
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authServiceProvider).authStateChanges,
    ),
    routes: [
      // Splash Screen
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),

      // Onboarding Screen
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth Routes
      GoRoute(path: '/auth', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Role Loading Route
      GoRoute(
        path: '/loading-role',
        builder: (context, state) => const RoleLoadingScreen(),
      ),

      // Role-specific Routes
      GoRoute(
        path: '/citizen',
        builder: (context, state) => const CitizenHomeScreen(),
      ),
      GoRoute(
        path: '/responder',
        builder: (context, state) => const ResponderHomeScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
    errorBuilder:
        (context, state) =>
            Scaffold(body: Center(child: Text('Error: ${state.error}'))),
  );
});
