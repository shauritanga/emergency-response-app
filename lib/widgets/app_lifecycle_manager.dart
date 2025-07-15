import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_tracking_service.dart';

class AppLifecycleManager extends StatefulWidget {
  final Widget child;

  const AppLifecycleManager({
    super.key,
    required this.child,
  });

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  final UserTrackingService _userTrackingService = UserTrackingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Start tracking if user is already signed in
    if (_auth.currentUser != null) {
      _userTrackingService.startTracking();
    }

    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        // User signed in, start tracking
        _userTrackingService.startTracking();
      } else {
        // User signed out, stop tracking
        _userTrackingService.stopTracking();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _userTrackingService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground
        _userTrackingService.onAppResumed();
        break;
      case AppLifecycleState.paused:
        // App went to background
        _userTrackingService.onAppPaused();
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        _userTrackingService.stopTracking();
        break;
      case AppLifecycleState.inactive:
        // App is inactive (e.g., during a phone call)
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
