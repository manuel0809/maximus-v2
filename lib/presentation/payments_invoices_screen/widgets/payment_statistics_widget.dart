import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class PaymentStatisticsWidget extends StatelessWidget {
  final Map<String, dynamic> statistics;

  const PaymentStatisticsWidget({super.key, required this.statistics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    final totalSpent = (statistics['total_spent'] as num?)?.toDouble() ?? 0;
    final completedTotal =
        (statistics['completed_total'] as num?)?.toDouble() ?? 0;
    final pendingCount = statistics['pending_count'] as int? ?? 0;
    final totalTransactions = statistics['total_transactions'] as int? ?? 0;
    final serviceTypeBreakdown =
        statistics['service_type_breakdown'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Spent',
                currencyFormat.format(totalSpent),
                Icons.payments,
                theme.colorScheme.primary,
                theme,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildStatCard(
                'Completed',
                currencyFormat.format(completedTotal),
                Icons.check_circle,
                Colors.green,
                theme,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Transactions',
                totalTransactions.toString(),
                Icons.receipt_long,
                Colors.blue,
                theme,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildStatCard(
                'Pending',
                pendingCount.toString(),
                Icons.pending,
                Colors.orange,
                theme,
              ),
            ),
          ],
        ),
        SizedBox(height: 3.h),

        // Service type breakdown
        if (serviceTypeBreakdown.isNotEmpty) ...[
          Text(
            'Spending by Service Type',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Container(
            height: 30.h,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: PieChart(
              PieChartData(
                sections: _buildPieChartSections(serviceTypeBreakdown, theme),
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // Legend
          Wrap(
            spacing: 3.w,
            runSpacing: 1.h,
            children: serviceTypeBreakdown.entries.map((entry) {
              final color = _getServiceTypeColor(entry.key);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    '${entry.key}: ${currencyFormat.format((entry.value as num).toDouble())}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 1.h),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    Map<String, dynamic> breakdown,
    ThemeData theme,
  ) {
    final total = breakdown.values.fold<double>(
      0,
      (sum, value) => sum + (value as num).toDouble(),
    );

    return breakdown.entries.map((entry) {
      final value = (entry.value as num).toDouble();
      final percentage = (value / total * 100).toStringAsFixed(1);
      final color = _getServiceTypeColor(entry.key);

      return PieChartSectionData(
        value: value,
        title: '$percentage%',
        color: color,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getServiceTypeColor(String serviceType) {
    switch (serviceType) {
      case 'BLACK':
        return const Color(0xFF8B1538);
      case 'BLACK SUV':
        return const Color(0xFF6B0F2A);
      case 'Car Rental':
        return const Color(0xFFE8B4B8);
      default:
        return Colors.grey;
    }
  }
}
