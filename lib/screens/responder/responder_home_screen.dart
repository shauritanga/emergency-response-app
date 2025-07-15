import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'responder_dashboard_screen.dart';
import 'responder_emergencies_screen.dart';
import 'responder_history_screen.dart';
import 'responder_profile_screen.dart';
import 'responder_messages_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/emergency_provider.dart';

class ResponderHomeScreen extends ConsumerStatefulWidget {
  const ResponderHomeScreen({super.key});

  @override
  ConsumerState<ResponderHomeScreen> createState() =>
      _ResponderHomeScreenState();
}

class _ResponderHomeScreenState extends ConsumerState<ResponderHomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }
    final userDataAsync = ref.watch(userFutureProvider(user.uid));

    final emergenciesAsync = ref.watch(
      responderEmergenciesProvider(
        userDataAsync.asData?.value!.department ?? "Medical",
      ),
    );

    final List<Widget> screens = [
      const ResponderDashboardScreen(),
      const ResponderEmergenciesScreen(),
      const ResponderMessagesScreen(),
      const ResponderHistoryScreen(),
      const ResponderProfileScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        showUnselectedLabels: true,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(HugeIcons.strokeRoundedDashboardSquare01),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible:
                  emergenciesAsync.asData?.value.isNotEmpty ?? false,
              label: Text(
                emergenciesAsync.asData?.value.length.toString() ?? '0',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              child: const Icon(HugeIcons.strokeRoundedWorkoutRun),
            ),
            label: 'Emergencies',
          ),
          const BottomNavigationBarItem(
            icon: Icon(HugeIcons.strokeRoundedMessage01),
            label: 'Messages',
          ),
          const BottomNavigationBarItem(
            icon: Icon(HugeIcons.strokeRoundedWorkHistory),
            label: 'History',
          ),
          const BottomNavigationBarItem(
            icon: Icon(HugeIcons.strokeRoundedUserAccount),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}
