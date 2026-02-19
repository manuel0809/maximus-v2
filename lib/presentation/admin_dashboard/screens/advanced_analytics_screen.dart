import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/analytics_service.dart';
import '../../../widgets/custom_app_bar.dart';

class AdvancedAnalyticsScreen extends StatefulWidget {
  const AdvancedAnalyticsScreen({super.key});

  @override
  State<AdvancedAnalyticsScreen> createState() => _AdvancedAnalyticsScreenState();
}

class _AdvancedAnalyticsScreenState extends State<AdvancedAnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService.instance;
  
  bool isLoading = true;
  Map<String, dynamic>? occupancy;
  List<Map<String, dynamic>> performance = [];
  Map<String, dynamic>? insights;
  List<double> forecast = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        _analyticsService.getOccupancyStats(),
        _analyticsService.getFleetPerformance(),
        _analyticsService.getCustomerInsights(),
        _analyticsService.getDemandForecast(),
      ]);

      setState(() {
        occupancy = results[0] as Map<String, dynamic>;
        performance = results[1] as List<Map<String, dynamic>>;
        insights = results[2] as Map<String, dynamic>;
        forecast = results[3] as List<double>;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Analíticas Avanzadas'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHighlights(theme),
            SizedBox(height: 4.h),
            _buildForecastChart(theme),
            SizedBox(height: 4.h),
            _buildROISection(theme),
            SizedBox(height: 4.h),
            _buildCustomerInsights(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlights(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildKPIBox(
            'Tasa de Ocupación',
            '${occupancy?['occupancy_rate']?.toStringAsFixed(1)}%',
            Icons.pie_chart,
            Colors.blue,
          ),
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: _buildKPIBox(
            'Tasa Cancelación',
            '${insights?['cancellation_rate']?.toStringAsFixed(1)}%',
            Icons.cancel_outlined,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildKPIBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 1.h),
          Text(value, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 9.sp, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildForecastChart(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Predicción de Demanda (Próximos 7 días) 🤖',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 2.h),
        Container(
          height: 25.h,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: forecast.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                  isCurved: true,
                  color: const Color(0xFF8B1538),
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF8B1538).withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildROISection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ROI y Rentabilidad por Unidad',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 2.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: performance.length,
          itemBuilder: (context, index) {
            final v = performance[index];
            return Card(
              margin: EdgeInsets.only(bottom: 2.h),
              child: ListTile(
                title: Text(v['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Ingreso: \$${v['income']} • Gastos: \$${v['expenses']}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${v['net'].toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                    Text('Neto', style: TextStyle(fontSize: 8.sp)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCustomerInsights(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Insights de Clientes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInsightItem('Clientes Fieles', '${insights?['loyal_count']}', Icons.star, Colors.amber),
              _buildInsightItem('Rentas/Usuario', '${insights?['avg_per_user']?.toStringAsFixed(1)}', Icons.person, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 8.sp, color: Colors.grey)),
      ],
    );
  }
}
