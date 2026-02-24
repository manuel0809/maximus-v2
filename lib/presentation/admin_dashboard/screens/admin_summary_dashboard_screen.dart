import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/admin_service.dart';
import '../widgets/kpi_card_widget.dart';
import '../widgets/analytics_chart_widget.dart';
import '../../../services/automation_service.dart';
import '../../../widgets/premium_card.dart';

class AdminSummaryDashboardScreen extends StatefulWidget {
  const AdminSummaryDashboardScreen({super.key});

  @override
  State<AdminSummaryDashboardScreen> createState() => _AdminSummaryDashboardScreenState();
}

class _AdminSummaryDashboardScreenState extends State<AdminSummaryDashboardScreen> {
  final AdminService _adminService = AdminService.instance;
  Map<String, dynamic>? stats;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final dashboardStats = await _adminService.getDashboardStats();
      if (mounted) {
        setState(() {
          stats = dashboardStats;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen General',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 3.h),
                    
                    // KPI Row 1: Income
                    Row(
                      children: [
                        Expanded(
                          child: KPICardWidget(
                            title: 'Ingresos Hoy',
                            value: '\$${stats?['income']?['daily']?.toStringAsFixed(2) ?? '0.00'}',
                            icon: Icons.monetization_on_outlined,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: KPICardWidget(
                            title: 'Ingresos Mes',
                            value: '\$${stats?['income']?['monthly']?.toStringAsFixed(2) ?? '0.00'}',
                            icon: Icons.account_balance_wallet_outlined,
                            color: const Color(0xFF8B1538),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),

                    // KPI Row 2: Rentals
                    Row(
                      children: [
                        Expanded(
                          child: KPICardWidget(
                            title: 'Rentas Activas',
                            value: '${stats?['rentals']?['active'] ?? 0}',
                            icon: Icons.directions_car_outlined,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: KPICardWidget(
                            title: 'Ocupación',
                            value: '${stats?['fleet']?['occupancy_rate']?.toStringAsFixed(1) ?? '0'}%',
                            icon: Icons.pie_chart_outline,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),

                    // Analytics Chart
                    const Text(
                      'Desempeño de Ingresos',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 2.h),
                    SizedBox(height: 30.h, child: const AnalyticsChartWidget()),
                    SizedBox(height: 4.h),

                    // Automation Toolbar
                    _buildAutomationToolbar(theme),
                    SizedBox(height: 4.h),

                    // Fleet Summary
                    _buildFleetSummarySection(theme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAutomationToolbar(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Centro de Automatización',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildAutomationButton(
                'Detectar Retrasos',
                Icons.history_toggle_off,
                Colors.orange,
                () async {
                   final messenger = ScaffoldMessenger.of(context);
                   await AutomationService.instance.processLateReturnFines();
                   messenger.showSnackBar(
                     const SnackBar(content: Text('Proceso de multas completado')),
                   );
                }
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: _buildAutomationButton(
                'Reporte Semanal',
                Icons.summarize_outlined,
                Colors.blue,
                () async {
                   final messenger = ScaffoldMessenger.of(context);
                   await AutomationService.instance.generateWeeklyReport();
                   messenger.showSnackBar(
                     const SnackBar(content: Text('Reporte semanal generado y guardado')),
                   );
                }
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAutomationButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return PremiumCard(
      onTap: onTap,
      borderRadius: 12,
      padding: EdgeInsets.all(3.w),
      color: color.withValues(alpha: 0.05),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 1.5.h),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFleetSummarySection(ThemeData theme) {
    final fleet = stats?['fleet'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estado de la Flota',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 2.h),
        PremiumCard(
          borderRadius: 16,
          useGlassmorphism: true,
          opacity: 0.03,
          padding: EdgeInsets.all(4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusItem('Disponibles', fleet?['available'] ?? 0, Colors.green),
              _buildStatusItem('Rentados', fleet?['rented'] ?? 0, Colors.blue),
              _buildStatusItem('Taller', fleet?['maintenance'] ?? 0, Colors.orange),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
      ],
    );
  }
}
