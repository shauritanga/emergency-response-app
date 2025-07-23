import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../providers/admin_provider.dart';
import '../../widgets/admin/admin_app_bar.dart';
import '../../widgets/admin/stat_card.dart';
import '../../widgets/admin/quick_action_card.dart';
import '../../widgets/admin/emergency_trends_chart.dart';
import '../../widgets/admin/recent_activities_list.dart';
import 'user_management_screen.dart';
import 'emergency_management_screen.dart';
import 'system_settings_screen.dart';
import 'analytics_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadAllData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final userStats = ref.watch(userStatsProvider);
    final emergencyStats = ref.watch(emergencyStatsProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AdminAppBar(
        title: 'Admin Dashboard',
        onRefresh: () => ref.read(adminProvider.notifier).loadAllData(),
        additionalActions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SystemSettingsScreen(),
                  ),
                ),
            tooltip: 'System Settings',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Analytics'),
            Tab(text: 'Activities'),
          ],
        ),
      ),
      body:
          adminState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : adminState.error != null
              ? _buildErrorWidget(adminState.error!)
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(userStats, emergencyStats, isDarkMode),
                  _buildAnalyticsTab(isDarkMode),
                  _buildActivitiesTab(isDarkMode),
                ],
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
            'Error loading dashboard',
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
            onPressed: () => ref.read(adminProvider.notifier).loadAllData(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    Map<String, int> userStats,
    Map<String, int> emergencyStats,
    bool isDarkMode,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          _buildWelcomeSection(isDarkMode),
          const SizedBox(height: 24),

          // Quick Stats
          Text(
            'Quick Statistics',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // User Statistics
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Users',
                  value: userStats['total'].toString(),
                  icon: HugeIcons.strokeRoundedUser,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Active Responders',
                  value: userStats['responders'].toString(),
                  icon: HugeIcons.strokeRoundedShieldUser,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Emergency Statistics
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Emergencies',
                  value: emergencyStats['total'].toString(),
                  icon: HugeIcons.strokeRoundedAlert01,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Pending',
                  value: emergencyStats['pending'].toString(),
                  icon: HugeIcons.strokeRoundedClock01,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              QuickActionCard(
                title: 'Manage Users',
                subtitle: 'Add, edit, or remove users',
                icon: HugeIcons.strokeRoundedUser,
                color: Colors.blue,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserManagementScreen(),
                      ),
                    ),
              ),
              QuickActionCard(
                title: 'Manage Emergencies',
                subtitle: 'View and manage emergency reports',
                icon: HugeIcons.strokeRoundedAlert01,
                color: Colors.orange,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EmergencyManagementScreen(),
                      ),
                    ),
              ),
              QuickActionCard(
                title: 'Analytics',
                subtitle: 'View detailed analytics and reports',
                icon: HugeIcons.strokeRoundedChart,
                color: Colors.purple,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AnalyticsScreen(),
                      ),
                    ),
              ),
              QuickActionCard(
                title: 'System Settings',
                subtitle: 'Configure system parameters',
                icon: HugeIcons.strokeRoundedSettings01,
                color: Colors.grey,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SystemSettingsScreen(),
                      ),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Activity
          Text(
            'Recent Activity',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          const RecentActivitiesList(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emergency Trends',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          const EmergencyTrendsChart(),
          const SizedBox(height: 24),

          // Emergency Type Distribution
          Text(
            'Emergency Type Distribution',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          _buildEmergencyTypeDistribution(isDarkMode),
          const SizedBox(height: 24),

          // User Role Distribution
          Text(
            'User Role Distribution',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          _buildUserRoleDistribution(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildActivitiesTab(bool isDarkMode) {
    return const RecentActivitiesList();
  }

  Widget _buildWelcomeSection(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDarkMode
                  ? [Colors.blue[800]!, Colors.purple[800]!]
                  : [Colors.blue[100]!, Colors.purple[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                HugeIcons.strokeRoundedShieldUser,
                size: 32,
                color: isDarkMode ? Colors.white : Colors.blue[700],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, Admin!',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.blue[700],
                      ),
                    ),
                    Text(
                      'Manage your emergency response system',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.blue[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyTypeDistribution(bool isDarkMode) {
    final emergencyStats = ref.watch(emergencyStatsProvider);
    final total = emergencyStats['total'] ?? 0;

    if (total == 0) {
      return Center(
        child: Text(
          'No emergency data available',
          style: GoogleFonts.poppins(color: Colors.grey[600]),
        ),
      );
    }

    return Column(
      children: [
        _buildDistributionItem(
          'Medical',
          emergencyStats['medical'] ?? 0,
          total,
          Colors.red,
          HugeIcons.strokeRoundedMedicalMask,
          isDarkMode,
        ),
        const SizedBox(height: 8),
        _buildDistributionItem(
          'Fire',
          emergencyStats['fire'] ?? 0,
          total,
          Colors.orange,
          HugeIcons.strokeRoundedFire,
          isDarkMode,
        ),
        const SizedBox(height: 8),
        _buildDistributionItem(
          'Police',
          emergencyStats['police'] ?? 0,
          total,
          Colors.blue,
          HugeIcons.strokeRoundedPoliceBadge,
          isDarkMode,
        ),
      ],
    );
  }

  Widget _buildUserRoleDistribution(bool isDarkMode) {
    final userStats = ref.watch(userStatsProvider);
    final total = userStats['total'] ?? 0;

    if (total == 0) {
      return Center(
        child: Text(
          'No user data available',
          style: GoogleFonts.poppins(color: Colors.grey[600]),
        ),
      );
    }

    return Column(
      children: [
        _buildDistributionItem(
          'Citizens',
          userStats['citizens'] ?? 0,
          total,
          Colors.green,
          HugeIcons.strokeRoundedUser,
          isDarkMode,
        ),
        const SizedBox(height: 8),
        _buildDistributionItem(
          'Responders',
          userStats['responders'] ?? 0,
          total,
          Colors.blue,
          HugeIcons.strokeRoundedShieldUser,
          isDarkMode,
        ),
        const SizedBox(height: 8),
        _buildDistributionItem(
          'Admins',
          userStats['admins'] ?? 0,
          total,
          Colors.purple,
          HugeIcons.strokeRoundedSettings01,
          isDarkMode,
        ),
      ],
    );
  }

  Widget _buildDistributionItem(
    String label,
    int value,
    int total,
    Color color,
    IconData icon,
    bool isDarkMode,
  ) {
    final percentage =
        total > 0 ? (value / total * 100).toStringAsFixed(1) : '0.0';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  '$value ($percentage%)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: total > 0 ? value / total : 0,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }
}
