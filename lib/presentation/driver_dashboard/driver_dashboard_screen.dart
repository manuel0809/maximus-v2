import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/user_service.dart';
import '../../services/trip_service.dart';
import '../../widgets/custom_app_bar.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final TripService _tripService = TripService.instance;
  Map<String, dynamic>? activeTrip;
  List<Map<String, dynamic>> pendingRequests = [];
  bool isLoading = true;
  bool isOnline = true;
  String driverName = 'Conductor';

  Future<void> _loadDriverData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final profile = await UserService.instance.getUserProfile(user.id);
      if (mounted && profile != null) {
        setState(() {
          driverName = profile['full_name'] ?? 'Conductor';
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDriverData();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final active = await _tripService.getActiveDriverTrip();
    List<Map<String, dynamic>> pending = [];
    if (isOnline && active == null) {
      pending = await _tripService.getPendingTrips();
    }
    
    if (mounted) {
      setState(() {
        activeTrip = active;
        pendingRequests = pending;
        isLoading = false;
      });
    }
  }

  Future<void> _handleTripAction(String tripId, String status) async {
    try {
      final driverId = Supabase.instance.client.auth.currentUser?.id;
      await _tripService.updateTripStatus(
        tripId: tripId,
        status: status,
        driverId: status == 'scheduled' ? driverId : null, // Using scheduled with driver_id as 'Accepted'
      );
      _loadTrips();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Panel del Conductor',
        actions: [
          Switch(
            value: isOnline,
            onChanged: (val) {
              setState(() => isOnline = val);
              _loadTrips();
            },
            activeThumbColor: Colors.green,
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTrips,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDriverWelcome(theme),
              SizedBox(height: 3.h),
              if (activeTrip != null) ...[
                _buildSectionTitle(theme, 'Viaje en Curso'),
                SizedBox(height: 2.h),
                _buildActiveTripCard(theme, activeTrip!),
                SizedBox(height: 4.h),
              ],
              _buildStatsRow(theme),
              SizedBox(height: 4.h),
              _buildSectionTitle(theme, 'Solicitudes Disponibles'),
              SizedBox(height: 2.h),
              _buildActiveRequestsList(theme),
              SizedBox(height: 4.h),
              _buildSectionTitle(theme, 'Mi Vehículo Asignado'),
              SizedBox(height: 2.h),
              _buildVehicleStatusCard(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTripCard(ThemeData theme, Map<String, dynamic> trip) {
    final status = trip['status'];
    final user = trip['user'];
    
    return Card(
      color: theme.primaryColor.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.primaryColor, width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(user['full_name'] ?? 'Cliente'),
              subtitle: Text(trip['service_type']),
              trailing: Text('\$${trip['cost']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const Divider(),
            _buildLocationRow(Icons.my_location, 'Recogida', trip['pickup_location']),
            SizedBox(height: 1.h),
            _buildLocationRow(Icons.location_on, 'Destino', trip['dropoff_location']),
            SizedBox(height: 3.h),
            Row(
              children: [
                if (status == 'scheduled')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleTripAction(trip['id'], 'in_progress'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      child: const Text('Comenzar Viaje'),
                    ),
                  ),
                if (status == 'in_progress')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleTripAction(trip['id'], 'completed'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: const Text('Finalizar Viaje'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String label, String address) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF8B1538)),
        SizedBox(width: 2.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(address, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveRequestsList(ThemeData theme) {
    if (!isOnline) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: const Text('Ponte en línea para ver solicitudes cercanas.'),
        ),
      );
    }

    if (pendingRequests.isEmpty) {
      return Container(
        padding: EdgeInsets.all(4.w),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
        ),
        child: Column(
          children: [
            const Icon(Icons.notifications_active_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 1.h),
            const Text('No hay solicitudes pendientes.'),
          ],
        ),
      );
    }

    return Column(
      children: pendingRequests.map((req) => Card(
        margin: EdgeInsets.only(bottom: 2.h),
        child: ListTile(
          title: Text(req['user']['full_name'] ?? 'Cliente'),
          subtitle: Text('${req['pickup_location']} -> ${req['dropoff_location']}'),
          trailing: ElevatedButton(
            onPressed: () => _handleTripAction(req['id'], 'scheduled'),
            child: const Text('Aceptar'),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildVehicleStatusCard(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Container(
              width: 15.w,
              height: 15.w,
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.directions_car, color: theme.primaryColor, size: 30),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mercedes-Benz Clase S', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Placas: ABC-1234', style: TextStyle(color: Colors.grey, fontSize: 10.sp)),
                ],
              ),
            ),
            Column(
              children: [
                const Text('Estado', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Óptimo', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverWelcome(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hola, $driverName 👋', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        Text('¿Listo para el turno de hoy?', style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18));
  }

  Widget _buildStatsRow(ThemeData theme) {
    return Row(
      children: [
        _buildStatItem('Viajes Hoy', '12', Icons.directions_car, Colors.blue),
        SizedBox(width: 4.w),
        _buildStatItem('Ganancias', '\$145.50', Icons.account_balance_wallet, Colors.green),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            SizedBox(height: 1.h),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
