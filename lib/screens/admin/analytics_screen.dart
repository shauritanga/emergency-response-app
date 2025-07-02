import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../providers/admin_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadDashboardStats();
      ref.read(adminProvider.notifier).loadEmergencyTrends();
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
      appBar: AppBar(
        title: Text(
          'Analytics & Reports',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(adminProvider.notifier).loadDashboardStats();
              ref.read(adminProvider.notifier).loadEmergencyTrends();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Users'),
            Tab(text: 'Emergencies'),
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
                  _buildUsersTab(userStats, isDarkMode),
                  _buildEmergenciesTab(emergencyStats, isDarkMode),
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
          _buildOverviewCard(userStats, emergencyStats, isDarkMode),
          const SizedBox(height: 24),
          _buildPerformanceMetrics(isDarkMode),
          const SizedBox(height: 24),
          _buildResponseTimeAnalysis(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
    Map<String, int> userStats,
    Map<String, int> emergencyStats,
    bool isDarkMode,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                isDarkMode
                    ? [Colors.blue[800]!, Colors.purple[800]!]
                    : [Colors.blue[50]!, Colors.purple[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Overview',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.blue[700],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewStat(
                    'Total Users',
                    userStats['total'].toString(),
                    HugeIcons.strokeRoundedUser,
                    Colors.blue,
                    isDarkMode,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildOverviewStat(
                    'Total Emergencies',
                    emergencyStats['total'].toString(),
                    HugeIcons.strokeRoundedAlert01,
                    Colors.orange,
                    isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewStat(
                    'Active Responders',
                    userStats['responders'].toString(),
                    HugeIcons.strokeRoundedShieldUser,
                    Colors.green,
                    isDarkMode,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildOverviewStat(
                    'Pending Emergencies',
                    emergencyStats['pending'].toString(),
                    HugeIcons.strokeRoundedClock01,
                    Colors.red,
                    isDarkMode,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewStat(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Average Response Time',
              '2.5 minutes',
              Colors.green,
            ),
            _buildMetricRow('Emergency Resolution Rate', '85%', Colors.blue),
            _buildMetricRow('User Satisfaction', '4.2/5', Colors.orange),
            _buildMetricRow('System Uptime', '99.9%', Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseTimeAnalysis(bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Response Time Analysis',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildResponseTimeBar('Medical', 2.1, Colors.red),
            _buildResponseTimeBar('Fire', 3.2, Colors.orange),
            _buildResponseTimeBar('Police', 2.8, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseTimeBar(String type, double minutes, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                type,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                '${minutes.toStringAsFixed(1)} min',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: minutes / 5.0, // Normalize to 5 minutes max
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab(Map<String, int> userStats, bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserDistributionCard(userStats, isDarkMode),
          const SizedBox(height: 24),
          _buildUserActivityCard(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildUserDistributionCard(
    Map<String, int> userStats,
    bool isDarkMode,
  ) {
    final total = userStats['total'] ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Distribution',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildUserDistributionItem(
              'Citizens',
              userStats['citizens'] ?? 0,
              total,
              Colors.green,
            ),
            _buildUserDistributionItem(
              'Responders',
              userStats['responders'] ?? 0,
              total,
              Colors.blue,
            ),
            _buildUserDistributionItem(
              'Admins',
              userStats['admins'] ?? 0,
              total,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDistributionItem(
    String label,
    int count,
    int total,
    Color color,
  ) {
    final percentage =
        total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '$count ($percentage%)',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserActivityCard(bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Activity',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildActivityMetric('Active Users Today', '156'),
            _buildActivityMetric('New Registrations', '12'),
            _buildActivityMetric('Users Online', '89'),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityMetric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergenciesTab(
    Map<String, int> emergencyStats,
    bool isDarkMode,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEmergencyStatusCard(emergencyStats, isDarkMode),
          const SizedBox(height: 24),
          _buildEmergencyTypeCard(emergencyStats, isDarkMode),
        ],
      ),
    );
  }

  Widget _buildEmergencyStatusCard(
    Map<String, int> emergencyStats,
    bool isDarkMode,
  ) {
    final total = emergencyStats['total'] ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency Status',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusItem(
              'Pending',
              emergencyStats['pending'] ?? 0,
              total,
              Colors.orange,
            ),
            _buildStatusItem(
              'In Progress',
              emergencyStats['inProgress'] ?? 0,
              total,
              Colors.blue,
            ),
            _buildStatusItem(
              'Resolved',
              emergencyStats['resolved'] ?? 0,
              total,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String status, int count, int total, Color color) {
    final percentage =
        total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '$count ($percentage%)',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyTypeCard(
    Map<String, int> emergencyStats,
    bool isDarkMode,
  ) {
    final total = emergencyStats['total'] ?? 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emergency Types',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildTypeItem(
              'Medical',
              emergencyStats['medical'] ?? 0,
              total,
              Colors.red,
            ),
            _buildTypeItem(
              'Fire',
              emergencyStats['fire'] ?? 0,
              total,
              Colors.orange,
            ),
            _buildTypeItem(
              'Police',
              emergencyStats['police'] ?? 0,
              total,
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeItem(String type, int count, int total, Color color) {
    final percentage =
        total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              type,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '$count ($percentage%)',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
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
            'Error loading analytics',
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
            onPressed: () {
              ref.read(adminProvider.notifier).loadDashboardStats();
              ref.read(adminProvider.notifier).loadEmergencyTrends();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
