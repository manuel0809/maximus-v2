import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
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
      final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
      final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
      
      // Get daily income
      final dailyResponse = await _client
          .from('payments')
          .select('amount')
          .eq('payment_status', 'completed')
          .gte('payment_date', startOfDay);
      
      double dailyIncome = dailyResponse.fold(0.0, (sum, item) => sum + (item['amount'] ?? 0));

      // Get monthly income
      final monthlyResponse = await _client
          .from('payments')
          .select('amount')
          .eq('payment_status', 'completed')
          .gte('payment_date', startOfMonth);
      
      double monthlyIncome = monthlyResponse.fold(0.0, (sum, item) => sum + (item['amount'] ?? 0));

      // Get fleet status
      final vehiclesResponse = await _client.from('vehicles').select('status');
      final vehicles = List<Map<String, dynamic>>.from(vehiclesResponse);
      int totalVehicles = vehicles.length;
      int available = vehicles.where((v) => v['status'] == 'available').length;
      int rented = vehicles.where((v) => v['status'] == 'rented').length;
      int maintenance = vehicles.where((v) => v['status'] == 'maintenance').length;

      // Get active/pending reservations
      final rentalsResponse = await _client
          .from('rentals')
          .select('status')
          .inFilter('status', ['active', 'pending']);
      
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

  /// Get most frequent routes based on completed rentals
  Future<List<Map<String, dynamic>>> getFrequentRoutes() async {
    try {
      final response = await _client
          .from('rentals')
          .select('pickup_location, destination_location')
          .eq('status', 'completed');
      
      final rentals = List<Map<String, dynamic>>.from(response);
      final routeCounts = <String, int>{};
      final routeDetails = <String, Map<String, String>>{};

      for (var rental in rentals) {
        final pickup = rental['pickup_location']?.toString() ?? 'N/A';
        final dest = rental['destination_location']?.toString() ?? 'N/A';
        final routeKey = '$pickup -> $dest';
        
        routeCounts[routeKey] = (routeCounts[routeKey] ?? 0) + 1;
        routeDetails[routeKey] = {
          'pickup': pickup,
          'destination': dest,
        };
      }

      final sortedRoutes = routeCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedRoutes.take(5).map((e) => {
        'route': e.key,
        'count': e.value,
        'pickup': routeDetails[e.key]?['pickup'],
        'destination': routeDetails[e.key]?['destination'],
      }).toList();
    } catch (e) {
      debugPrint('AdminService: Error fetching frequent routes: $e');
      return [];
    }
  }

  /// Get recurring clients (more than 2 completed rentals)
  Future<List<Map<String, dynamic>>> getRecurringClients() async {
    try {
      // Logic: Get users who have > 1 completed rentals
      final response = await _client
          .from('user_profiles')
          .select('id, full_name, email, avatar_url, rentals(id)')
          .eq('rentals.status', 'completed');
      
      final profiles = List<Map<String, dynamic>>.from(response);
      final recurring = profiles.where((p) {
        final rentals = p['rentals'] as List?;
        return rentals != null && rentals.length > 2;
      }).toList();

      // Sort by rental count
      recurring.sort((a, b) {
        final countA = (a['rentals'] as List).length;
        final countB = (b['rentals'] as List).length;
        return countB.compareTo(countA);
      });

      return recurring;
    } catch (e) {
      debugPrint('AdminService: Error fetching recurring clients: $e');
      return [];
    }
  }
}
