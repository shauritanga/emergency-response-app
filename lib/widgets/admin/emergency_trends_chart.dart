import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/admin_provider.dart';

class EmergencyTrendsChart extends ConsumerWidget {
  const EmergencyTrendsChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminState = ref.watch(adminProvider);
    final trends = adminState.emergencyTrends;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (trends.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'No trend data available',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 7 Days',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildChart(trends, isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<Map<String, dynamic>> trends, bool isDarkMode) {
    if (trends.isEmpty) return const SizedBox.shrink();

    final maxValue = trends.fold<int>(0, (max, item) => 
        item['count'] > max ? item['count'] : max);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: trends.map((trend) {
        final count = trend['count'] as int;
        final date = trend['date'] as String;
        final height = maxValue > 0 ? (count / maxValue) : 0.0;

        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 20,
                height: 100 * height,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    count.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(date),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.month}/${date.day}';
    } catch (e) {
      return dateString;
    }
  }
} 