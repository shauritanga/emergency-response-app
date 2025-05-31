import 'package:emergency_response_app/screens/citizen/citizen_messages_screen.dart';
import 'package:emergency_response_app/screens/citizen/citizen_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
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
    // Request location permissions
    await bg.BackgroundGeolocation.requestPermission();
    // Configure background location
    bg.BackgroundGeolocation.ready(
      bg.Config(
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
        distanceFilter: 10.0, // Update when moving 10m
        stationaryRadius: 25,
        locationUpdateInterval: 300000, // 5 minutes in milliseconds
        notificationTitle: 'Emergency Response',
        notificationText: 'Updating location for emergency notifications',
      ),
    );

    // Update location in Firestore
    bg.BackgroundGeolocation.onLocation((bg.Location location) {
      FirebaseFirestore.instance.collection('users').doc(userId).update({
        'lastLocation': {
          'latitude': location.coords.latitude,
          'longitude': location.coords.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        },
      });
    });

    // Start background location
    bg.BackgroundGeolocation.start();
  }
}
