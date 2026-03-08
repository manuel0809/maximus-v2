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
  List<Map<String, dynamic>> frequentRoutes = [];
  List<Map<String, dynamic>> recurringClients = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final dashboardStats = await _adminService.getDashboardStats();
      final routes = await _adminService.getFrequentRoutes();
      final clients = await _adminService.getRecurringClients();
      
      if (mounted) {
        setState(() {
          stats = dashboardStats;
          frequentRoutes = routes;
          recurringClients = clients;
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

                    // Frequent Routes Section
                    if (frequentRoutes.isNotEmpty) ...[
                      _buildFrequentRoutesSection(theme),
                      SizedBox(height: 4.h),
                    ],

                    // Recurring Clients Section
                    if (recurringClients.isNotEmpty) ...[
                      _buildRecurringClientsSection(theme),
                      SizedBox(height: 4.h),
                    ],

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

  Widget _buildFrequentRoutesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rutas más Frecuentes',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 2.h),
        PremiumCard(
          borderRadius: 16,
          padding: EdgeInsets.zero,
          child: Column(
            children: frequentRoutes.map((route) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
                  child: Icon(Icons.route_outlined, color: theme.primaryColor, size: 20),
                ),
                title: Text(
                  route['route'] ?? 'Ruta desconocida',
                  style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${route['count']} reservas completadas',
                  style: TextStyle(fontSize: 9.sp, color: Colors.grey),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.grey, size: 16),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecurringClientsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Clientes VIP (Recurrentes)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        SizedBox(height: 2.h),
        SizedBox(
          height: 12.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recurringClients.length,
            itemBuilder: (context, index) {
              final client = recurringClients[index];
              final rentals = (client['rentals'] as List?)?.length ?? 0;
              
              return Container(
                width: 40.w,
                margin: EdgeInsets.only(right: 4.w),
                child: PremiumCard(
                  borderRadius: 12,
                  padding: EdgeInsets.all(2.w),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: client['avatar_url'] != null 
                            ? NetworkImage(client['avatar_url']) 
                            : null,
                        child: client['avatar_url'] == null 
                            ? Icon(Icons.person, size: 18, color: Colors.white) 
                            : null,
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client['full_name'] ?? 'Cliente',
                              style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$rentals viajes',
                              style: TextStyle(fontSize: 8.sp, color: theme.primaryColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
