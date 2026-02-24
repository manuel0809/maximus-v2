import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/notification_service.dart';
import '../../services/realtime_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/booking_request_card_widget.dart';
import './widgets/pricing_config_modal_widget.dart';
import './widgets/service_control_widget.dart';
import './screens/financial_reports_screen.dart';
import './screens/advanced_analytics_screen.dart';
import './screens/admin_user_management_screen.dart';

import '../../core/constants/app_roles.dart';
import '../../services/user_service.dart';
import './screens/admin_summary_dashboard_screen.dart';
import './screens/fleet_management_screen.dart';
import './screens/reservations_admin_screen.dart';
import './screens/client_crm_screen.dart';
import './screens/branch_management_screen.dart';
import './screens/coupons_admin_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String selectedSection = 'Resumen';
  String bookingFilter = 'all';
  bool showSidebar = true;
  int unreadAdminNotifications = 0;
  int pendingBookingsCount = 0;
  bool showDocumentReview = false;
  AppRole currentUserRole = AppRole.admin;

  final NotificationService _notificationService = NotificationService.instance;
  final RealtimeService _realtimeService = RealtimeService.instance;

  // Pricing configurations for BLACK services
  Map<String, Map<String, dynamic>> blackServicePricingConfigs = {
    'BLACK SUV': {
      'basePricePerMile': 2.5,
      'passengerSurcharge': 5.0,
      'basePricePerHour': 50.0,
      'eventBasePricePerMile': 3.0,
      'eventPassengerSurcharge': 8.0,
      'eventFeePerHour': 25.0,
      'hourlyPassengerSurcharge': 10.0,
      'peakMultiplier': 1.3,
      'peakHours': [
        {'startHour': 7, 'endHour': 9, 'multiplier': 1.3},
        {'startHour': 17, 'endHour': 20, 'multiplier': 1.3},
      ],
    },
    'BLACK EVENTO': {
      'basePricePerMile': 3.0,
      'passengerSurcharge': 8.0,
      'basePricePerHour': 60.0,
      'eventBasePricePerMile': 3.0,
      'eventPassengerSurcharge': 8.0,
      'eventFeePerHour': 25.0,
      'hourlyPassengerSurcharge': 12.0,
      'peakMultiplier': 1.3,
      'peakHours': [
        {'startHour': 7, 'endHour': 9, 'multiplier': 1.3},
        {'startHour': 17, 'endHour': 20, 'multiplier': 1.3},
      ],
    },
    'BLACK POR HORA': {
      'basePricePerMile': 2.0,
      'passengerSurcharge': 5.0,
      'basePricePerHour': 50.0,
      'eventBasePricePerMile': 2.5,
      'eventPassengerSurcharge': 6.0,
      'eventFeePerHour': 20.0,
      'hourlyPassengerSurcharge': 10.0,
      'peakMultiplier': 1.3,
      'peakHours': [
        {'startHour': 7, 'endHour': 9, 'multiplier': 1.3},
        {'startHour': 17, 'endHour': 20, 'multiplier': 1.3},
      ],
    },
  };

  final List<Map<String, dynamic>> kpiData = [
    {
      'title': 'Total Reservas',
      'value': '1,247',
      'change': '+12.5%',
      'isPositive': true,
      'icon': 'event_note',
      'color': const Color(0xFF8B1538),
    },
    {
      'title': 'Usuarios Activos',
      'value': '3,892',
      'change': '+8.3%',
      'isPositive': true,
      'icon': 'people',
      'color': const Color(0xFF2E7D32),
    },
    {
      'title': 'Ingresos Mensuales',
      'value': '\$284,500',
      'change': '+15.7%',
      'isPositive': true,
      'icon': 'attach_money',
      'color': const Color(0xFFD4AF37),
    },
    {
      'title': 'Tasa de Satisfacción',
      'value': '4.8/5.0',
      'change': '+0.2',
      'isPositive': true,
      'icon': 'star',
      'color': const Color(0xFFF57C00),
    },
  ];

  final List<Map<String, dynamic>> bookingRequests = [
    {
      'id': 'BK-2026-1847',
      'clientName': 'María González',
      'service': 'Alquiler de Coches',
      'vehicle': 'Mercedes-Benz Clase S',
      'date': '15/02/2026',
      'time': '10:00',
      'status': 'pending',
      'priority': 'high',
      'amount': '\$450',
    },
    {
      'id': 'BK-2026-1851',
      'clientName': 'Roberto Silva',
      'service': 'BLACK SUV',
      'vehicle': 'Cadillac Escalade',
      'date': '17/02/2026',
      'time': '11:15',
      'status': 'confirmed',
      'priority': 'medium',
      'amount': '\$120',
    },
    {
      'id': 'BK-2026-1852',
      'clientName': 'Elena Meyer',
      'service': 'BLACK POR HORA',
      'vehicle': 'Servicio de Chófer (4 hrs)',
      'date': '19/02/2026',
      'time': '16:00',
      'status': 'pending',
      'priority': 'low',
      'amount': '\$200',
    },
    {
      'id': 'BK-2026-1853',
      'clientName': 'Jorge L. Cabrera',
      'service': 'BLACK EVENTO',
      'vehicle': 'Logística VIP Bodas',
      'date': '22/02/2026',
      'time': '18:00',
      'status': 'scheduled',
      'priority': 'urgent',
      'amount': '\$850',
    },
  ];

  final List<Map<String, dynamic>> services = [
    {
      'name': 'Alquiler de Coches',
      'available': 12,
      'total': 15,
      'status': 'active',
      'revenue': '\$45,200',
    },
    {
      'name': 'Transporte Personal',
      'available': 8,
      'total': 10,
      'status': 'active',
      'revenue': '\$22,500',
    },
  ];

  final List<Map<String, dynamic>> sidebarItems = [
    {'icon': Icons.dashboard, 'label': 'Resumen', 'section': 'Resumen'},
    {
      'icon': Icons.directions_car,
      'label': 'Renta de Autos',
      'section': 'CarRental',
    },
    {
      'icon': Icons.local_taxi,
      'label': 'Transporte Personal',
      'section': 'PersonalTransport',
    },
    {'icon': Icons.people, 'label': 'Usuarios', 'section': 'Usuarios'},
    {'icon': Icons.settings, 'label': 'Configuración', 'section': 'Settings'},
    {'icon': Icons.visibility, 'label': 'Vista Previa App', 'section': 'Preview'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
    _subscribeToAdminNotifications();
    _subscribeToAllTrips();
  }

  @override
  void dispose() {
    _notificationService.unsubscribe();
    _realtimeService.unsubscribeFromAdminNotifications();
    _realtimeService.unsubscribeFromTrips();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    try {
      final roleProfile = await UserService.instance.getCurrentUser();
      if (mounted && roleProfile != null) {
        setState(() {
          currentUserRole = AppRole.fromString(roleProfile['role']);
        });
      }

      final count = await _notificationService.getUnreadCount();
      final trips = await _realtimeService.getAllTrips(status: 'scheduled');

      if (mounted) {
        setState(() {
          unreadAdminNotifications = count;
          pendingBookingsCount = trips.length;
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  void _subscribeToAdminNotifications() {
    _realtimeService.subscribeToAdminNotifications((notification) {
      if (mounted) {
        setState(() => unreadAdminNotifications++);

        // Show urgent notifications immediately
        if (notification['priority'] == 'urgent') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                notification['title'] ?? 'Nueva notificación urgente',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Ver',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.notificationCenter);
                },
              ),
            ),
          );
        }
      }
    });
  }

  void _subscribeToAllTrips() {
    _realtimeService.subscribeToAllTrips((tripData) {
      if (mounted) {
        final event = tripData['event'];
        final trip = tripData['trip'];

        // Update pending bookings count for new trips
        if (event == 'INSERT' && trip != null) {
          setState(() => pendingBookingsCount++);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Nueva reserva: ${trip['service_type'] ?? 'Servicio'}',
              ),
              backgroundColor: const Color(0xFF8B1538),
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // Update on status changes
        if (event == 'UPDATE' && trip != null) {
          final status = trip['status'];
          if (status == 'scheduled') {
            setState(() => pendingBookingsCount++);
          } else if (status == 'completed' || status == 'cancelled') {
            setState(() {
              if (pendingBookingsCount > 0) pendingBookingsCount--;
            });
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Panel de Administración',
        leading: IconButton(
          icon: Icon(showSidebar ? Icons.menu_open : Icons.menu),
          onPressed: () => setState(() => showSidebar = !showSidebar),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => _showNotifications(context),
          ),
          IconButton(
            icon: const Icon(Icons.emergency),
            onPressed: () => _showEmergencyControls(context),
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: Row(
        children: [
          if (showSidebar) _buildSidebar(theme),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildSidebar(ThemeData theme) {
    final sections = [
      {'name': 'Resumen', 'icon': 'dashboard', 'section': 'Resumen'},
      {'name': 'Mantenimiento de Flota', 'icon': 'directions_car', 'section': 'Flota'},
      {'name': 'Gestión de Reservas', 'icon': 'event_note', 'section': 'Reservas'},
      {'name': 'Gestión de Cupones', 'icon': 'confirmation_number', 'section': 'Cupones'},
      {'name': 'Clientes (CRM)', 'icon': 'people', 'section': 'Clientes'},
      if (currentUserRole.isAdmin) {'name': 'Finanzas', 'icon': 'payments', 'section': 'Finanzas'},
      if (currentUserRole.isAdmin) {'name': 'Analítica Avanzada', 'icon': 'analytics', 'section': 'Analitica'},
      if (currentUserRole.isAdmin) {'name': 'Sucursales', 'icon': 'location_city', 'section': 'Sucursales'},
      {'name': 'Transporte Personal', 'icon': 'local_taxi', 'section': 'PersonalTransport'},
      {'name': 'Configuración', 'icon': 'settings', 'section': 'Settings'},
      {'name': 'Vista Previa App', 'icon': 'visibility', 'section': 'Preview'},
    ];

    return Container(
      width: 60.w,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: 2.h),
          ...sections.map(
            (section) => _buildSidebarItem(
              section['name']!,
              section['icon']!,
              selectedSection == section['section'],
            () {
            if (section['section'] == 'Preview') {
              Navigator.pushNamed(context, '/client-dashboard');
            } else {
              setState(() => selectedSection = section['section']!);
            }
          },
            ),
          ),
          const Spacer(),
          Padding(
            padding: EdgeInsets.all(3.w),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                AppRoutes.loginRegistration,
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Salir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 5.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    String title,
    String iconName,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF8B1538), Color(0xFFE8B4B8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B1538).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: iconName,
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              size: 18,
            ),
            SizedBox(width: 4.w),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (selectedSection) {
      case 'Resumen':
        return const AdminSummaryDashboardScreen();
      case 'Flota':
        return const FleetManagementScreen();
      case 'Reservas':
        return const ReservationsAdminScreen();
      case 'Cupones':
        return const CouponsAdminScreen();
      case 'Clientes':
        return const ClientCRMScreen();
      case 'Finanzas':
        return const FinancialReportsScreen();
      case 'Analitica':
        return const AdvancedAnalyticsScreen();
      case 'Sucursales':
        return const BranchManagementScreen();
      case 'PersonalTransport':
        return _buildPersonalTransportSection();
      case 'Usuarios':
        return AdminUserManagementScreen();
      case 'Settings':
        return const Center(child: Text('Configuración del Sistema'));
      default:
        return const AdminSummaryDashboardScreen();
    }
  }



  Widget _buildPersonalTransportSection() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gestión de Transporte Personal',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          _buildBookingManagementSection(
            title: 'Reservas de Transporte',
            serviceCategory: 'PersonalTransport',
          ),
          SizedBox(height: 3.h),
          Text(
            'Configuración de Tarifas BLACK',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          _buildBlackPricingConfigList(),
          SizedBox(height: 3.h),
          Text(
            'Control de Servicios',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 2.h),
          _buildServiceControlsSection(category: 'PersonalTransport'),
        ],
      ),
    );
  }



  Widget _buildBlackPricingConfigList() {
    return Column(
      children: blackServicePricingConfigs.keys.map((serviceName) {
        return Card(
          margin: EdgeInsets.only(bottom: 1.h),
          child: ListTile(
            leading: const Icon(Icons.monetization_on, color: Color(0xFF8B1538)),
            title: Text(serviceName),
            subtitle: const Text('Configurar tarifas base y recargos'),
            trailing: const Icon(Icons.edit),
            onTap: () => _showPricingConfigModal(serviceName),
          ),
        );
      }).toList(),
    );
  }



  Widget _buildBookingManagementSection({
    String title = 'Gestión de Reservas',
    String? serviceCategory,
  }) {
    final filteredBookings = bookingRequests.where((booking) {
      // Apply status filter
      if (bookingFilter != 'all' && booking['status'] != bookingFilter) {
        return false;
      }

      // Apply category filter
      if (serviceCategory == 'CarRental') {
        return booking['service'] == 'Alquiler de Coches';
      }
      if (serviceCategory == 'PersonalTransport') {
        // Broadly match anything that isn't car rental or legacy removed services
        final personalServices = [
          'Transporte Personal',
          'BLACK',
          'BLACK SUV',
          'BLACK POR HORA',
          'BLACK EVENTO'
        ];
        return personalServices.contains(booking['service']);
      }

      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            _buildFilterChips(),
          ],
        ),
        SizedBox(height: 2.h),
        if (filteredBookings.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Text(
                'No hay reservas que coincidan con los filtros',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else
          ...filteredBookings.map(
            (booking) => Padding(
              padding: EdgeInsets.only(bottom: 1.5.h),
              child: BookingRequestCardWidget(
                booking: booking,
                onApprove: () => _handleBookingAction(booking, 'approve'),
                onModify: () => _handleBookingAction(booking, 'modify'),
                onReject: () => _handleBookingAction(booking, 'reject'),
                onChecklistPickup: booking['status'] == 'confirmed' && booking['service'] == 'Alquiler de Coches'
                    ? () => Navigator.pushNamed(
                          context,
                          '/digital-checklist-screen',
                          arguments: {'rentalId': booking['id'], 'isReturn': false},
                        )
                    : null,
                onChecklistReturn: booking['status'] == 'in-progress' && booking['service'] == 'Alquiler de Coches'
                    ? () => Navigator.pushNamed(
                          context,
                          '/digital-checklist-screen',
                          arguments: {'rentalId': booking['id'], 'isReturn': true},
                        )
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'Todos', 'value': 'all'},
      {'label': 'Pendiente', 'value': 'pending'},
      {'label': 'Confirmado', 'value': 'confirmed'},
      {'label': 'En Progreso', 'value': 'in-progress'},
      {'label': 'Completado', 'value': 'completed'},
    ];

    return Wrap(
      spacing: 2.w,
      children: filters.map((filter) {
        final isSelected = bookingFilter == filter['value'];
        return FilterChip(
          label: Text(filter['label']!),
          selected: isSelected,
          onSelected: (selected) {
            setState(() => bookingFilter = filter['value']!);
          },
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.2),
          labelStyle: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 11.sp,
          ),
        );
      }).toList(),
    );
  }



  Widget _buildServiceControlsSection({
    String? serviceNameFilter,
    String? category,
  }) {
    final filteredServices = services.where((service) {
      if (serviceNameFilter != null) {
        return service['name'] == serviceNameFilter;
      }
      if (category == 'PersonalTransport') {
        const personalServices = [
          'Transporte Personal',
          'BLACK',
          'Jetskit', // Keeping legacy in controls for now if user needs to toggle
          'Vuelos'
        ];
        return personalServices.contains(service['name']);
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...filteredServices.map(
          (service) => Padding(
            padding: EdgeInsets.only(bottom: 1.5.h),
            child: ServiceControlWidget(
              service: service,
              onToggle: () => _handleServiceToggle(service),
              onEdit: () => _handleServiceEdit(service),
            ),
          ),
        ),
      ],
    );
  }







  void _handleBookingAction(Map<String, dynamic> booking, String action) {
    String message = '';
    switch (action) {
      case 'approve':
        message = 'Reserva ${booking['id']} aprobada';
        break;
      case 'modify':
        message = 'Modificando reserva ${booking['id']}';
        break;
      case 'reject':
        message = 'Reserva ${booking['id']} rechazada';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _handleServiceToggle(Map<String, dynamic> service) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Estado de ${service['name']} actualizado'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleServiceEdit(Map<String, dynamic> service) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editando ${service['name']}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPricingConfigModal(String serviceName) {
    final currentConfig = blackServicePricingConfigs[serviceName] ?? {};

    showDialog(
      context: context,
      builder: (context) => PricingConfigModalWidget(
        serviceName: serviceName,
        currentConfig: currentConfig,
        onSave: (newConfig) {
          setState(() {
            blackServicePricingConfigs[serviceName] = newConfig;
          });
        },
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notificaciones del Sistema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: const Text('3 reservas urgentes'),
              subtitle: const Text('Requieren atención inmediata'),
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.blue),
              title: const Text('Actualización del sistema'),
              subtitle: const Text('Disponible versión 2.1.0'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyControls(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Controles de Emergencia'),
        content: const Text(
          '¿Desea activar el protocolo de emergencia? Esto notificará a todos los conductores y clientes activos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Protocolo de emergencia activado'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Activar'),
          ),
        ],
      ),
    );
  }


}
