import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../providers/auth_provider.dart';
import '../../providers/emergency_provider.dart';
import '../../widgets/chat_dashboard_widget.dart';
import '../../widgets/emergency_chat_widget.dart';
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
              // Emergency Status Card
              _buildEmergencyStatusCard(context, userEmergenciesAsync),

              // Chat Dashboard
              const ChatDashboardWidget(),

              // Active Emergency Chats
              _buildActiveEmergencyChats(context, userEmergenciesAsync),

              // Quick Actions
              _buildQuickActionsCard(context),

              // Safety Tips
              _buildSafetyTipsCard(context),

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
        backgroundColor: Colors.red,
        child: const Icon(HugeIcons.strokeRoundedAlert02, color: Colors.white),
      ),
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
                                ? Colors.red.withValues(alpha: 0.1)
                                : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        activeEmergencies.isNotEmpty
                            ? HugeIcons.strokeRoundedAlert02
                            : HugeIcons.strokeRoundedCheckmarkCircle01,
                        color:
                            activeEmergencies.isNotEmpty
                                ? Colors.red
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

  Widget _buildActiveEmergencyChats(
    BuildContext context,
    AsyncValue<List<dynamic>> emergenciesAsync,
  ) {
    return emergenciesAsync.when(
      data: (emergencies) {
        final activeEmergencies =
            emergencies.where((e) => e.status != 'Resolved').toList();

        if (activeEmergencies.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Emergency Chats',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...activeEmergencies.map(
              (emergency) => EmergencyChatWidget(
                emergencyId: emergency.id,
                showQuickActions: false,
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildQuickActionItem(
                  icon: HugeIcons.strokeRoundedAlert02,
                  label: 'Report Emergency',
                  color: Colors.red,
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmergencyReportScreen(),
                        ),
                      ),
                ),
                const SizedBox(width: 12),
                _buildQuickActionItem(
                  icon: HugeIcons.strokeRoundedLocation01,
                  label: 'Share Location',
                  color: Colors.blue,
                  onTap: () => _shareLocation(context),
                ),
                const SizedBox(width: 12),
                _buildQuickActionItem(
                  icon: HugeIcons.strokeRoundedCall,
                  label: 'Emergency Call',
                  color: Colors.green,
                  onTap: () => _makeEmergencyCall(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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

  void _shareLocation(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location sharing feature coming soon!')),
    );
  }

  void _makeEmergencyCall(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency calling feature coming soon!')),
    );
  }
}
