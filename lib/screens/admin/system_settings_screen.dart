import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/admin_provider.dart';

class SystemSettingsScreen extends ConsumerStatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  ConsumerState<SystemSettingsScreen> createState() =>
      _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends ConsumerState<SystemSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _notificationRadiusController;
  late TextEditingController _maxRespondersController;
  late TextEditingController _emergencyTimeoutController;
  bool _autoAssignResponders = true;
  bool _enableNotifications = true;
  bool _enableLocationTracking = true;

  @override
  void initState() {
    super.initState();
    _notificationRadiusController = TextEditingController(text: '5.0');
    _maxRespondersController = TextEditingController(text: '5');
    _emergencyTimeoutController = TextEditingController(text: '30');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadSystemSettings();
    });
  }

  @override
  void dispose() {
    _notificationRadiusController.dispose();
    _maxRespondersController.dispose();
    _emergencyTimeoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'System Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveSettings),
        ],
      ),
      body:
          adminState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : adminState.error != null
              ? _buildErrorWidget(adminState.error!)
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Notification Settings', isDarkMode),
                      _buildNotificationSettings(isDarkMode),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        'Emergency Response Settings',
                        isDarkMode,
                      ),
                      _buildEmergencySettings(isDarkMode),
                      const SizedBox(height: 24),
                      _buildSectionHeader('System Configuration', isDarkMode),
                      _buildSystemConfiguration(isDarkMode),
                      const SizedBox(height: 32),
                      _buildSaveButton(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildNotificationSettings(bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: Text(
                'Enable Push Notifications',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Send notifications to users about emergencies',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              value: _enableNotifications,
              onChanged: (value) {
                setState(() {
                  _enableNotifications = value;
                });
              },
            ),
            const Divider(),
            TextFormField(
              controller: _notificationRadiusController,
              decoration: InputDecoration(
                labelText: 'Notification Radius (km)',
                hintText: '5.0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixText: 'km',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a radius';
                }
                final radius = double.tryParse(value);
                if (radius == null || radius <= 0) {
                  return 'Please enter a valid radius';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencySettings(bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: Text(
                'Auto-assign Responders',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Automatically assign responders to emergencies',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              value: _autoAssignResponders,
              onChanged: (value) {
                setState(() {
                  _autoAssignResponders = value;
                });
              },
            ),
            const Divider(),
            TextFormField(
              controller: _maxRespondersController,
              decoration: InputDecoration(
                labelText: 'Max Responders per Emergency',
                hintText: '5',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a number';
                }
                final number = int.tryParse(value);
                if (number == null || number <= 0) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emergencyTimeoutController,
              decoration: InputDecoration(
                labelText: 'Emergency Timeout (minutes)',
                hintText: '30',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixText: 'min',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a timeout';
                }
                final timeout = int.tryParse(value);
                if (timeout == null || timeout <= 0) {
                  return 'Please enter a valid timeout';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemConfiguration(bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: Text(
                'Enable Location Tracking',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Track user locations for proximity-based notifications',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              value: _enableLocationTracking,
              onChanged: (value) {
                setState(() {
                  _enableLocationTracking = value;
                });
              },
            ),
            const Divider(),
            ListTile(
              title: Text(
                'System Version',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                '1.0.0',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              trailing: const Icon(Icons.info_outline),
            ),
            ListTile(
              title: Text(
                'Database Status',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Connected',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.green),
              ),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          'Save Settings',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error loading settings',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: GoogleFonts.poppins(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed:
                () => ref.read(adminProvider.notifier).loadSystemSettings(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      final settings = {
        'notificationRadius': double.parse(_notificationRadiusController.text),
        'maxResponders': int.parse(_maxRespondersController.text),
        'emergencyTimeout': int.parse(_emergencyTimeoutController.text),
        'autoAssignResponders': _autoAssignResponders,
        'enableNotifications': _enableNotifications,
        'enableLocationTracking': _enableLocationTracking,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      ref.read(adminProvider.notifier).updateSystemSettings(settings);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
