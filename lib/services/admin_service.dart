import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class AdminService {
  static AdminService? _instance;
  static AdminService get instance => _instance ??= AdminService._();

  AdminService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  /// Get all drivers
  Future<List<Map<String, dynamic>>> getDrivers() async {
    try {
      final response = await _client
          .from('user_profiles')
          .select('id, full_name, email, phone, avatar_url, is_active')
          .eq('role', 'driver')
          .order('full_name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener conductores: $e');
    }
  }

  /// Get all driver contacts
  Future<List<Map<String, dynamic>>> getDriverContacts() async {
    try {
      final response = await _client
          .from('driver_contacts')
          .select('*, driver:driver_id(full_name, email)')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener contactos de conductores: $e');
    }
  }

  /// Add or update driver contact
  Future<void> saveDriverContact({
    required String driverId,
    required String phoneNumber,
    bool isActive = true,
    String? notes,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('Usuario no autenticado');

      // Check if contact exists
      final existing = await _client
          .from('driver_contacts')
          .select('id')
          .eq('driver_id', driverId)
          .maybeSingle();

      if (existing != null) {
        // Update existing
        await _client
            .from('driver_contacts')
            .update({
              'phone_number': phoneNumber,
              'is_active': isActive,
              'notes': notes,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id']);
      } else {
        // Insert new
        await _client.from('driver_contacts').insert({
          'driver_id': driverId,
          'phone_number': phoneNumber,
          'is_active': isActive,
          'notes': notes,
          'created_by': currentUserId,
        });
      }
    } catch (e) {
      throw Exception('Error al guardar contacto: $e');
    }
  }

  /// Delete driver contact
  Future<void> deleteDriverContact(String contactId) async {
    try {
      await _client.from('driver_contacts').delete().eq('id', contactId);
    } catch (e) {
      throw Exception('Error al eliminar contacto: $e');
    }
  }

  /// Toggle driver contact active status
  Future<void> toggleDriverContactStatus(
    String contactId,
    bool isActive,
  ) async {
    try {
      await _client
          .from('driver_contacts')
          .update({'is_active': isActive})
          .eq('id', contactId);
    } catch (e) {
      throw Exception('Error al actualizar estado: $e');
    }
  }

  /// Get dashboard statistics (income, occupancy, active counts)
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final now = DateTime.now();
      
      // Get all payments for totals
      final paymentsResponse = await _client.from('payments').select('amount, payment_date').eq('payment_status', 'completed');
      final payments = List<Map<String, dynamic>>.from(paymentsResponse);

      double dailyIncome = 0;
      double monthlyIncome = 0;
      for (var p in payments) {
        final pDate = DateTime.parse(p['payment_date']);
        if (pDate.year == now.year && pDate.month == now.month && pDate.day == now.day) dailyIncome += p['amount'];
        if (pDate.year == now.year && pDate.month == now.month) monthlyIncome += p['amount'];
      }

      // Get fleet status
      final vehiclesResponse = await _client.from('vehicles').select('status');
      final vehicles = List<Map<String, dynamic>>.from(vehiclesResponse);
      int totalVehicles = vehicles.length;
      int available = vehicles.where((v) => v['status'] == 'available').length;
      int rented = vehicles.where((v) => v['status'] == 'rented').length;
      int maintenance = vehicles.where((v) => v['status'] == 'maintenance').length;

      // Get active/pending reservations
      final rentalsResponse = await _client.from('rentals').select('status');
      final rentals = List<Map<String, dynamic>>.from(rentalsResponse);
      int activeRentals = rentals.where((r) => r['status'] == 'active').length;
      int pendingRentals = rentals.where((r) => r['status'] == 'pending').length;

      return {
        'income': {
          'daily': dailyIncome,
          'monthly': monthlyIncome,
        },
        'fleet': {
          'total': totalVehicles,
          'available': available,
          'rented': rented,
          'maintenance': maintenance,
          'occupancy_rate': totalVehicles > 0 ? (rented / totalVehicles) * 100 : 0,
        },
        'rentals': {
          'active': activeRentals,
          'pending': pendingRentals,
        }
      };
    } catch (e) {
      throw Exception('Error al calcular estadísticas: $e');
    }
  }

  /// Get monthly revenue data for charts
  Future<List<Map<String, dynamic>>> getRevenueChartData() async {
    try {
      final response = await _client.rpc('get_monthly_revenue');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Get top 5 most rented vehicles
  Future<List<Map<String, dynamic>>> getTopVehicles() async {
    try {
      final response = await _client
          .from('vehicles')
          .select('brand, model, plate, rentals(count)')
          .order('rentals(count)', ascending: false)
          .limit(5);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}
