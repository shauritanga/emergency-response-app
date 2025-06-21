import 'package:emergency_response_app/screens/citizen/citizen_messages_screen.dart';
import 'package:emergency_response_app/screens/citizen/citizen_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import 'citizen_dashboard_screen.dart';
import 'emergency_report_screen.dart';
import 'emergency_status_screen.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;

// Provider to track the current tab index
final citizenTabIndexProvider = StateProvider<int>((ref) => 0);

class CitizenHomeScreen extends ConsumerStatefulWidget {
  const CitizenHomeScreen({super.key});

  @override
  ConsumerState<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends ConsumerState<CitizenHomeScreen> {
  // List of screens to display in the IndexedStack
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const CitizenDashboardScreen(),
      const EmergencyReportScreen(isEmbedded: true),
      const EmergencyStatusScreen(isEmbedded: true),
      const CitizenMessagesScreen(),
      const CitizenProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    // Initialize notifications and background location
    ref
        .watch(notificationServiceProvider)
        .initialize(userId: user.uid, role: 'citizen');
    _initBackgroundLocation(ref, user.uid);

    // Get the current tab index
    final currentIndex = ref.watch(citizenTabIndexProvider);

    return Scaffold(
      // No AppBar here - each tab will provide its own
      body: IndexedStack(index: currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(HugeIcons.strokeRoundedDashboardSquare01),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(HugeIcons.strokeRoundedSiriNew),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(HugeIcons.strokeRoundedClipboard),
            label: 'Emergencies',
          ),
          BottomNavigationBarItem(
            icon: Icon(HugeIcons.strokeRoundedMessage01),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(HugeIcons.strokeRoundedUserAccount),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          ref.read(citizenTabIndexProvider.notifier).state = index;
        },
      ),
    );
  }

  Future<void> _initBackgroundLocation(WidgetRef ref, String userId) async {
    try {
      // Request location permissions
      await bg.BackgroundGeolocation.requestPermission();

      // Configure background location with new Notification class
      await bg.BackgroundGeolocation.ready(
        bg.Config(
          desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
          distanceFilter: 10.0, // Update when moving 10m
          stationaryRadius: 25,
          locationUpdateInterval: 300000, // 5 minutes in milliseconds
          // Use new Notification class instead of deprecated notification* fields
          notification: bg.Notification(
            title: 'Emergency Response',
            text: 'Location tracking active for emergency services',
            color: '#FF0000', // Red color for emergency app
            channelName: 'Emergency Location Service',
            smallIcon: 'drawable/ic_notification',
            largeIcon: 'drawable/ic_launcher',
            priority: bg.Config.NOTIFICATION_PRIORITY_HIGH,
            sticky: true, // Keep notification persistent
          ),
          // Emergency response optimizations
          enableHeadless: true, // Continue when app is closed
          preventSuspend: true, // Prevent suspension on iOS
          heartbeatInterval: 60, // Check every minute when stationary
          stopOnTerminate: false, // Continue after app termination
          startOnBoot: true, // Start on device boot
        ),
      );

      debugPrint('Background location configured successfully');
    } catch (e) {
      debugPrint('Failed to configure background location: $e');
    }

    // Set up location update handler
    bg.BackgroundGeolocation.onLocation((bg.Location location) async {
      try {
        final locationData = {
          'latitude': location.coords.latitude,
          'longitude': location.coords.longitude,
          'accuracy': location.coords.accuracy,
          'timestamp': DateTime.now().toIso8601String(),
          'isMoving': location.isMoving,
        };

        // Add optional fields if available
        if (location.coords.altitude != -1) {
          locationData['altitude'] = location.coords.altitude;
        }
        if (location.coords.speed != -1) {
          locationData['speed'] = location.coords.speed;
        }
        if (location.coords.heading != -1) {
          locationData['heading'] = location.coords.heading;
        }
        if (location.battery.level != -1) {
          locationData['batteryLevel'] = location.battery.level;
        }
        locationData['isCharging'] = location.battery.isCharging;

        await FirebaseFirestore.instance.collection('users').doc(userId).update(
          {'lastLocation': locationData},
        );

        debugPrint(
          'Location updated: ${location.coords.latitude}, ${location.coords.longitude} '
          '(accuracy: ${location.coords.accuracy}m)',
        );
      } catch (e) {
        debugPrint('Failed to update location in Firestore: $e');
      }
    });

    // Handle provider changes (GPS on/off, etc.)
    bg.BackgroundGeolocation.onProviderChange((bg.ProviderChangeEvent event) {
      debugPrint(
        'Location provider change: Status=${event.status}, GPS=${event.gps}, Network=${event.network}',
      );
    });

    // Handle motion changes (moving/stationary)
    bg.BackgroundGeolocation.onMotionChange((bg.Location location) {
      debugPrint(
        'Motion change: ${location.isMoving ? "MOVING" : "STATIONARY"} '
        'at ${location.coords.latitude}, ${location.coords.longitude}',
      );
    });

    // Start background location tracking
    try {
      bg.State state = await bg.BackgroundGeolocation.start();
      debugPrint('Background location tracking started: ${state.enabled}');

      if (!state.enabled) {
        debugPrint('Warning: Background location tracking failed to start');
      }
    } catch (e) {
      debugPrint('Error starting background location: $e');
    }
  }
}
