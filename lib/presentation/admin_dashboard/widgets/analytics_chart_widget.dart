import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:sizer/sizer.dart';
import '../../../widgets/premium_card.dart';

class AnalyticsChartWidget extends StatelessWidget {
  const AnalyticsChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PremiumCard(
      padding: EdgeInsets.all(4.w),
      borderRadius: 16,
      useGlassmorphism: true,
      opacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tendencia de Reservas',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  _buildLegendItem(theme, 'Reservas', Color(0xFF8B1538)),
                  SizedBox(width: 3.w),
                  _buildLegendItem(theme, 'Ingresos', Color(0xFF2E7D32)),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 30.h,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const months = [
                          'Ene',
                          'Feb',
                          'Mar',
                          'Abr',
                          'May',
                          'Jun',
                        ];
                        if (value.toInt() >= 0 &&
                            value.toInt() < months.length) {
                          return Padding(
                            padding: EdgeInsets.only(top: 1.h),
                            child: Text(
                              months[value.toInt()],
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10.sp,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10.sp,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    left: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                minX: 0,
                maxX: 5,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 45),
                      FlSpot(1, 52),
                      FlSpot(2, 48),
                      FlSpot(3, 65),
                      FlSpot(4, 72),
                      FlSpot(5, 85),
                    ],
                    isCurved: true,
                    color: const Color(0xFF8B1538),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF8B1538).withValues(alpha: 0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 30),
                      FlSpot(1, 38),
                      FlSpot(2, 42),
                      FlSpot(3, 55),
                      FlSpot(4, 68),
                      FlSpot(5, 78),
                    ],
                    isCurved: true,
                    color: const Color(0xFF2E7D32),
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toInt()}',
                          TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11.sp,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(ThemeData theme, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 1.w),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.sp),
        ),
      ],
    );
  }
}
