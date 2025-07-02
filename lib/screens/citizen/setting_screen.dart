import 'package:emergency_response_app/providers/notification_provider.dart';
import 'package:emergency_response_app/screens/common/notification_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _notifyProximity;
  bool? _notifyEmergencies;
  String? _role;
  String? _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (userDoc.exists) {
        final preferences = userDoc.data()?['notificationPreferences'] ?? {};
        setState(() {
          _userId = user.uid;
          _role = userDoc.data()?['role'] ?? 'citizen';
          _notifyProximity =
              _role == 'citizen'
                  ? (preferences['notifyProximity'] ?? true)
                  : null;
          _notifyEmergencies =
              _role == 'responder'
                  ? (preferences['notifyEmergencies'] ?? true)
                  : null;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _savePreferences() async {
    if (_userId == null || _role == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final preferences = {
        'notifyProximity': _notifyProximity,
        'notifyEmergencies': _notifyEmergencies,
      };
      await ref
          .read(notificationServiceProvider)
          .updateNotificationPreferences(_userId!, _role!, preferences);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Preferences saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notification Preferences',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_role == 'citizen')
                      SwitchListTile(
                        title: const Text(
                          'Receive nearby emergency notifications',
                        ),
                        subtitle: const Text(
                          'Get notified about emergencies within 5km',
                        ),
                        value: _notifyProximity ?? false,
                        onChanged: (value) {
                          setState(() {
                            _notifyProximity = value;
                          });
                        },
                      ),
                    if (_role == 'responder')
                      SwitchListTile(
                        title: const Text('Receive emergency notifications'),
                        subtitle: const Text(
                          'Get notified about emergencies in your department',
                        ),
                        value: _notifyEmergencies ?? false,
                        onChanged: (value) {
                          setState(() {
                            _notifyEmergencies = value;
                          });
                        },
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _savePreferences,
                      child: const Text('Save Preferences'),
                    ),

                    const SizedBox(height: 24),

                    // Advanced Notification Settings Button
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.settings_outlined),
                        title: const Text('Advanced Notification Settings'),
                        subtitle: const Text(
                          'Configure detailed notification preferences',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => const NotificationSettingsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
