import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/feedback_utils.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _isLoading = false;
  late NotificationPreferences _preferences;

  @override
  void initState() {
    super.initState();
    _preferences = ref.read(notificationProvider).preferences;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: Text(
          'Notification Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Status Card
            _buildNotificationStatusCard(),

            const SizedBox(height: 24),

            // Emergency Alerts Section
            _buildSectionCard(
              title: 'Emergency Alerts',
              icon: HugeIcons.strokeRoundedAlert02,
              children: [
                _buildSwitchTile(
                  title: 'Emergency Notifications',
                  subtitle: 'Receive alerts for nearby emergencies',
                  value: _preferences.emergencyAlerts,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        emergencyAlerts: value,
                      );
                    });
                    _savePreferences();
                  },
                ),
                _buildSwitchTile(
                  title: 'Nearby Alerts',
                  subtitle: 'Get notified about emergencies in your area',
                  value: _preferences.nearbyAlerts,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(nearbyAlerts: value);
                    });
                    _savePreferences();
                  },
                ),
                _buildRadiusSlider(),
                _buildEmergencyTypesSelector(),
              ],
            ),

            const SizedBox(height: 16),

            // Chat Notifications Section
            _buildSectionCard(
              title: 'Chat & Messages',
              icon: HugeIcons.strokeRoundedMessage01,
              children: [
                _buildSwitchTile(
                  title: 'Chat Messages',
                  subtitle: 'Receive notifications for new messages',
                  value: _preferences.chatMessages,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(chatMessages: value);
                    });
                    _savePreferences();
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Sound & Vibration Section
            _buildSectionCard(
              title: 'Sound & Vibration',
              icon: HugeIcons.strokeRoundedVolumeHigh,
              children: [
                _buildSwitchTile(
                  title: 'Sound',
                  subtitle: 'Play notification sounds',
                  value: _preferences.soundEnabled,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(soundEnabled: value);
                    });
                    _savePreferences();
                  },
                ),
                _buildSwitchTile(
                  title: 'Vibration',
                  subtitle: 'Vibrate for notifications',
                  value: _preferences.vibrationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _preferences = _preferences.copyWith(
                        vibrationEnabled: value,
                      );
                    });
                    _savePreferences();
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Test Notification Button
            _buildTestNotificationButton(),

            const SizedBox(height: 16),

            // Reset to Defaults Button
            _buildResetButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationStatusCard() {
    return FutureBuilder<bool>(
      future: ref.read(notificationProvider.notifier).areNotificationsEnabled(),
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? false;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            isEnabled
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isEnabled
                            ? HugeIcons.strokeRoundedCheckmarkCircle02
                            : HugeIcons.strokeRoundedAlert02,
                        color: isEnabled ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEnabled
                                ? 'Notifications Enabled'
                                : 'Notifications Disabled',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            isEnabled
                                ? 'You will receive emergency and chat notifications'
                                : 'Enable notifications to receive emergency alerts',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!isEnabled) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _requestPermissions,
                      icon: const Icon(HugeIcons.strokeRoundedNotification03),
                      label: const Text('Enable Notifications'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.deepPurple),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.deepPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification Radius: ${_preferences.radius.toStringAsFixed(1)} km',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _preferences.radius,
            min: 1.0,
            max: 20.0,
            divisions: 19,
            activeColor: Colors.deepPurple,
            onChanged: (value) {
              setState(() {
                _preferences = _preferences.copyWith(radius: value);
              });
            },
            onChangeEnd: (value) {
              _savePreferences();
            },
          ),
          Text(
            'Receive alerts for emergencies within this distance',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyTypesSelector() {
    final emergencyTypes = ['Medical', 'Fire', 'Police'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emergency Types',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select which types of emergencies you want to be notified about',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children:
                emergencyTypes.map((type) {
                  final isSelected = _preferences.enabledEmergencyTypes
                      .contains(type);
                  return FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        final types = List<String>.from(
                          _preferences.enabledEmergencyTypes,
                        );
                        if (selected) {
                          types.add(type);
                        } else {
                          types.remove(type);
                        }
                        _preferences = _preferences.copyWith(
                          enabledEmergencyTypes: types,
                        );
                      });
                      _savePreferences();
                    },
                    selectedColor: Colors.deepPurple.withValues(alpha: 0.2),
                    checkmarkColor: Colors.deepPurple,
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTestNotificationButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _testNotification,
        icon: const Icon(HugeIcons.strokeRoundedNotification01),
        label: const Text('Test Notification'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _resetToDefaults,
        icon: const Icon(HugeIcons.strokeRoundedRefresh),
        label: const Text('Reset to Defaults'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey.shade700,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Future<void> _savePreferences() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        await ref
            .read(notificationProvider.notifier)
            .updateNotificationPreferences(
              user.uid,
              'citizen', // This should be dynamic based on user role
              _preferences.toMap(),
            );
      }
    } catch (e) {
      if (mounted) {
        FeedbackUtils.showError(context, 'Failed to save preferences: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final granted =
          await ref.read(notificationProvider.notifier).requestPermissions();
      if (mounted) {
        if (granted) {
          FeedbackUtils.showSuccess(
            context,
            'Notifications enabled successfully',
          );
          setState(() {}); // Refresh the status card
        } else {
          FeedbackUtils.showError(context, 'Notification permissions denied');
        }
      }
    } catch (e) {
      if (mounted) {
        FeedbackUtils.showError(context, 'Failed to request permissions: $e');
      }
    }
  }

  void _testNotification() {
    FeedbackUtils.showInfo(
      context,
      'Test notification sent! Check your notification panel.',
    );
    // In a real implementation, you would trigger a test notification here
  }

  void _resetToDefaults() {
    setState(() {
      _preferences = const NotificationPreferences();
    });
    _savePreferences();
    FeedbackUtils.showSuccess(context, 'Settings reset to defaults');
  }
}
