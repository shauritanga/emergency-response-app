import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import '../../providers/auth_provider.dart';
import '../../providers/emergency_provider.dart';
import '../../services/location_service.dart';
import 'emergency_report_screen.dart';

class CitizenDashboardScreen extends ConsumerWidget {
  const CitizenDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    final userEmergenciesAsync = ref.watch(emergenciesProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            Text(
              'Welcome back, ${user.displayName ?? 'Citizen'}',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showQuickActions(context),
            icon: const Icon(HugeIcons.strokeRoundedAdd01),
            tooltip: 'Quick Actions',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh data
          ref.invalidate(emergenciesProvider(user.uid));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Status Card
              _buildLocationStatusCard(context),

              // Emergency Status Card
              _buildEmergencyStatusCard(context, userEmergenciesAsync),

              // Emergency Contacts Card
              _buildEmergencyContactsCard(context),

              // Safety Tips
              _buildSafetyTipsCard(context),

              // Recent Activity Card
              _buildRecentActivityCard(context),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "citizen_dashboard_fab",
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EmergencyReportScreen(),
              ),
            ),
        backgroundColor: Colors.deepPurple,
        child: const Icon(HugeIcons.strokeRoundedAlert02, color: Colors.white),
      ),
    );
  }

  Widget _buildLocationStatusCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    HugeIcons.strokeRoundedLocation01,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Location Status',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Active',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Background tracking enabled',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your location is being shared with emergency services',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _testLocation(context),
                        icon: const Icon(Icons.gps_fixed, color: Colors.white),
                        tooltip: 'Test GPS',
                      ),
                      IconButton(
                        onPressed: () => _shareLocation(context),
                        icon: const Icon(
                          HugeIcons.strokeRoundedShare08,
                          color: Colors.white,
                        ),
                        tooltip: 'Share Current Location',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyContactsCard(BuildContext context) {
    final emergencyContacts = [
      {
        'name': 'Police',
        'number': '911',
        'icon': Icons.local_police,
        'color': Colors.blue,
      },
      {
        'name': 'Fire Dept',
        'number': '911',
        'icon': Icons.local_fire_department,
        'color': Colors.orange,
      },
      {
        'name': 'Medical',
        'number': '911',
        'icon': Icons.medical_services,
        'color': Colors.red,
      },
      {
        'name': 'Tanesco',
        'number': '1234567890',
        'icon': Icons.warning,
        'color': Colors.purple,
      },
    ];

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  HugeIcons.strokeRoundedCall,
                  color: Colors.deepPurple,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Emergency Contacts',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: emergencyContacts.length,
              itemBuilder: (context, index) {
                final contact = emergencyContacts[index];
                return InkWell(
                  onTap:
                      () => _callEmergencyNumber(
                        context,
                        contact['number'] as String,
                        contact['name'] as String,
                      ),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: (contact['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (contact['color'] as Color).withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Icon(
                            contact['icon'] as IconData,
                            color: contact['color'] as Color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  contact['name'] as String,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: contact['color'] as Color,
                                  ),
                                ),
                                Text(
                                  contact['number'] as String,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: Colors.deepPurple, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildActivityItem(
              icon: HugeIcons.strokeRoundedLocation01,
              title: 'Location Updated',
              subtitle: 'Background location tracking active',
              time: 'Just now',
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildActivityItem(
              icon: HugeIcons.strokeRoundedShield01,
              title: 'Safety Check',
              subtitle: 'All emergency services available',
              time: '5 min ago',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildActivityItem(
              icon: HugeIcons.strokeRoundedNotification03,
              title: 'System Update',
              subtitle: 'Emergency response system updated',
              time: '1 hour ago',
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildEmergencyStatusCard(
    BuildContext context,
    AsyncValue<List<dynamic>> emergenciesAsync,
  ) {
    return emergenciesAsync.when(
      data: (emergencies) {
        final activeEmergencies =
            emergencies.where((e) => e.status != 'Resolved').toList();

        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            activeEmergencies.isNotEmpty
                                ? Colors.deepPurple.withValues(alpha: 0.1)
                                : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        activeEmergencies.isNotEmpty
                            ? HugeIcons.strokeRoundedAlert02
                            : HugeIcons.strokeRoundedCheckmarkCircle01,
                        color:
                            activeEmergencies.isNotEmpty
                                ? Colors.deepPurple
                                : Colors.green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeEmergencies.isNotEmpty
                                ? 'Active Emergency'
                                : 'All Clear',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            activeEmergencies.isNotEmpty
                                ? '${activeEmergencies.length} active emergency${activeEmergencies.length > 1 ? 'ies' : ''}'
                                : 'No active emergencies',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (activeEmergencies.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'You have active emergency reports. Stay safe and follow instructions from emergency responders.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => _buildLoadingCard(),
      error: (_, __) => _buildErrorCard('Unable to load emergency status'),
    );
  }

  Widget _buildSafetyTipsCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  HugeIcons.strokeRoundedShield01,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Safety Tips',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSafetyTip('Keep your emergency contacts updated'),
            _buildSafetyTip('Ensure location services are enabled'),
            _buildSafetyTip('Stay informed about local emergency procedures'),
            _buildSafetyTip('Keep your phone charged during emergencies'),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: SizedBox(
        height: 100,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(HugeIcons.strokeRoundedAlert02, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Quick Actions',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(
                    HugeIcons.strokeRoundedAlert02,
                    color: Colors.red,
                  ),
                  title: const Text('Report Emergency'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmergencyReportScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    HugeIcons.strokeRoundedLocation01,
                    color: Colors.blue,
                  ),
                  title: const Text('Share Location'),
                  onTap: () {
                    Navigator.pop(context);
                    _shareLocation(context);
                  },
                ),
                ListTile(
                  leading: Icon(
                    HugeIcons.strokeRoundedCall,
                    color: Colors.green,
                  ),
                  title: const Text('Emergency Call'),
                  onTap: () {
                    Navigator.pop(context);
                    _makeEmergencyCall(context);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _shareLocation(BuildContext context) async {
    try {
      debugPrint('🔍 ShareLocation: Starting location sharing process');

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Getting your location...'),
                ],
              ),
            ),
      );

      debugPrint('🔍 ShareLocation: Loading dialog shown, getting location...');

      // Get current location
      final locationService = LocationService();
      final locationData = await locationService.getCurrentLocation();

      debugPrint(
        '🔍 ShareLocation: Location data received: ${locationData != null ? "Success" : "Failed"}',
      );

      if (locationData != null) {
        debugPrint(
          '🔍 ShareLocation: Lat=${locationData.latitude}, Lng=${locationData.longitude}, Accuracy=${locationData.accuracy}',
        );
      }

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (locationData != null && context.mounted) {
        final latitude = locationData.latitude!;
        final longitude = locationData.longitude!;
        final accuracy = locationData.accuracy!.toInt();

        // Create location message
        final locationMessage =
            '''
📍 My Current Location

🌍 Coordinates: $latitude, $longitude
📏 Accuracy: ${accuracy}m
🕐 Time: ${DateTime.now().toString().split('.')[0]}

🗺️ View on Google Maps:
https://maps.google.com/?q=$latitude,$longitude

🧭 View on Apple Maps:
https://maps.apple.com/?q=$latitude,$longitude

📱 Shared via Emergency Response App
        '''.trim();

        debugPrint('🔍 ShareLocation: Attempting to share location message');
        debugPrint(
          '🔍 ShareLocation: Message length: ${locationMessage.length} characters',
        );

        // Try to share location with fallback options
        await _shareLocationWithFallback(context, locationMessage);

        debugPrint('🔍 ShareLocation: Share completed successfully');

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Location shared successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else if (context.mounted) {
        debugPrint(
          '🔍 ShareLocation: Location data is null - GPS may be disabled or permission denied',
        );
        _showLocationError(
          context,
          'Unable to get your current location. Please:\n\n• Enable GPS/Location Services\n• Grant location permission to this app\n• Ensure you\'re not in airplane mode',
        );
      }
    } catch (e) {
      debugPrint('🔍 ShareLocation: Error occurred: ${e.toString()}');
      debugPrint('🔍 ShareLocation: Error type: ${e.runtimeType}');

      // Close loading dialog if still open
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        _showLocationError(
          context,
          'Failed to share location: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _shareLocationWithFallback(
    BuildContext context,
    String locationMessage,
  ) async {
    try {
      // Try share_plus first
      debugPrint('🔍 ShareLocationFallback: Attempting share_plus');
      await share_plus.Share.share(
        locationMessage,
        subject: 'My Current Location',
      );
      debugPrint('🔍 ShareLocationFallback: share_plus successful');
    } catch (e) {
      debugPrint(
        '🔍 ShareLocationFallback: share_plus failed: ${e.toString()}',
      );

      if (e.toString().contains('MissingPluginException') ||
          e.toString().contains('No implementation found')) {
        debugPrint('🔍 ShareLocationFallback: Using fallback sharing methods');
        if (context.mounted) {
          await _showAlternativeShareOptions(context, locationMessage);
        }
      } else {
        // Re-throw other exceptions
        rethrow;
      }
    }
  }

  Future<void> _showAlternativeShareOptions(
    BuildContext context,
    String locationMessage,
  ) async {
    // Extract coordinates from the message for map links
    final lines = locationMessage.split('\n');
    String? coordinatesLine;
    for (final line in lines) {
      if (line.contains('Coordinates:')) {
        coordinatesLine = line;
        break;
      }
    }

    String? latitude, longitude;
    if (coordinatesLine != null) {
      final coords = coordinatesLine.split('Coordinates:')[1].trim().split(',');
      if (coords.length == 2) {
        latitude = coords[0].trim();
        longitude = coords[1].trim();
      }
    }

    if (!context.mounted) return;

    // Show alternative sharing options
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.share, color: Colors.blue),
                SizedBox(width: 8),
                Text('Share Location'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Choose how to share your location:'),
                const SizedBox(height: 16),

                // Copy to clipboard option
                ListTile(
                  leading: const Icon(Icons.copy, color: Colors.green),
                  title: const Text('Copy to Clipboard'),
                  subtitle: const Text('Copy location details to clipboard'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _copyToClipboard(context, locationMessage);
                  },
                ),

                // Open in Google Maps
                if (latitude != null && longitude != null)
                  ListTile(
                    leading: const Icon(Icons.map, color: Colors.red),
                    title: const Text('Open in Google Maps'),
                    subtitle: const Text('View location in Google Maps'),
                    onTap: () {
                      Navigator.of(context).pop();
                      _openInGoogleMaps(context, latitude!, longitude!);
                    },
                  ),

                // SMS option (if available)
                ListTile(
                  leading: const Icon(Icons.sms, color: Colors.blue),
                  title: const Text('Send via SMS'),
                  subtitle: const Text('Open SMS app with location'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _sendViaSMS(context, locationMessage);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) async {
    try {
      // Use Flutter's built-in clipboard
      await Clipboard.setData(ClipboardData(text: text));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Location copied to clipboard!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('🔍 CopyToClipboard: Error - ${e.toString()}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openInGoogleMaps(
    BuildContext context,
    String latitude,
    String longitude,
  ) async {
    try {
      final Uri googleMapsUri = Uri.parse(
        'https://maps.google.com/?q=$latitude,$longitude',
      );

      if (await canLaunchUrl(googleMapsUri)) {
        await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.map, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Opening location in Google Maps...'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Could not launch Google Maps');
      }
    } catch (e) {
      debugPrint('🔍 OpenInGoogleMaps: Error - ${e.toString()}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open Google Maps: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sendViaSMS(BuildContext context, String message) async {
    try {
      final Uri smsUri = Uri(scheme: 'sms', queryParameters: {'body': message});

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.sms, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Opening SMS app...'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Could not launch SMS app');
      }
    } catch (e) {
      debugPrint('🔍 SendViaSMS: Error - ${e.toString()}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open SMS app: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _testLocation(BuildContext context) async {
    try {
      debugPrint('🔍 TestLocation: Starting GPS test');

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Testing GPS...'),
                ],
              ),
            ),
      );

      // Get current location
      final locationService = LocationService();
      final locationData = await locationService.getCurrentLocation();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      if (locationData != null && context.mounted) {
        final latitude = locationData.latitude!;
        final longitude = locationData.longitude!;
        final accuracy = locationData.accuracy!.toInt();

        debugPrint(
          '🔍 TestLocation: Success - Lat=$latitude, Lng=$longitude, Accuracy=${accuracy}m',
        );

        // Show success dialog with location details
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('GPS Test Successful'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📍 Latitude: $latitude'),
                    Text('📍 Longitude: $longitude'),
                    Text('📏 Accuracy: ${accuracy}m'),
                    Text('🕐 Time: ${DateTime.now().toString().split('.')[0]}'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      } else if (context.mounted) {
        debugPrint('🔍 TestLocation: Failed - Location data is null');

        // Show error dialog
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: 8),
                    Text('GPS Test Failed'),
                  ],
                ),
                content: const Text(
                  'Unable to get your location. Please:\n\n'
                  '• Enable GPS/Location Services\n'
                  '• Grant location permission to this app\n'
                  '• Ensure you\'re not in airplane mode\n'
                  '• Try moving to an area with better GPS signal',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      debugPrint('🔍 TestLocation: Error - ${e.toString()}');

      // Close loading dialog if still open
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: 8),
                    Text('GPS Test Error'),
                  ],
                ),
                content: Text('Error testing GPS: ${e.toString()}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    }
  }

  void _makeEmergencyCall(BuildContext context) async {
    // Show emergency call options dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.emergency, color: Colors.red),
                SizedBox(width: 8),
                Text('Emergency Call'),
              ],
            ),
            content: const Text(
              'Choose an emergency service to call:',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              // Police
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _callEmergencyNumber(context, '911', 'Police');
                },
                icon: const Icon(Icons.local_police, color: Colors.blue),
                label: const Text('Police (911)'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),

              // Fire Department
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _callEmergencyNumber(context, '911', 'Fire Department');
                },
                icon: const Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                ),
                label: const Text('Fire (911)'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),

              // Medical Emergency
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _callEmergencyNumber(context, '911', 'Medical Emergency');
                },
                icon: const Icon(Icons.medical_services, color: Colors.red),
                label: const Text('Medical (911)'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),

              // Cancel
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }

  void _callEmergencyNumber(
    BuildContext context,
    String number,
    String service,
  ) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: number);

      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);

        // Show confirmation message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.phone, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Calling $service ($number)...'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else if (context.mounted) {
        _showCallError(context, 'Unable to make phone calls on this device.');
      }
    } catch (e) {
      if (context.mounted) {
        _showCallError(
          context,
          'Failed to make emergency call: ${e.toString()}',
        );
      }
    }
  }

  void _showLocationError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Location Error'),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showCallError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Call Error'),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
