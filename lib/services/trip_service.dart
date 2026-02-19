import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class TripService {
  static TripService? _instance;
  static TripService get instance => _instance ??= TripService._();

  TripService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  /// Get pending trips (for drivers to pick up)
  Future<List<Map<String, dynamic>>> getPendingTrips() async {
    try {
      final response = await _client
          .from('trips')
          .select('''
            *,
            user:user_id(full_name, email)
          ''')
          .eq('status', 'scheduled')
          .isFilter('driver_id', null)
          .order('trip_date', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Get active trip for a driver
  Future<Map<String, dynamic>?> getActiveDriverTrip() async {
    try {
      final driverId = _client.auth.currentUser?.id;
      if (driverId == null) return null;

      final response = await _client
          .from('trips')
          .select('''
            *,
            user:user_id(full_name, email)
          ''')
          .eq('driver_id', driverId)
          .or('status.eq.scheduled,status.eq.in_progress')
          .maybeSingle();
      
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Update trip status (Accept, Start, Arrive, Complete)
  Future<void> updateTripStatus({
    required String tripId,
    required String status,
    String? driverId,
  }) async {
    try {
      final updates = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (driverId != null) {
        updates['driver_id'] = driverId;
      }
      
      if (status == 'completed') {
        updates['completed_at'] = DateTime.now().toIso8601String();
      }

      await _client.from('trips').update(updates).eq('id', tripId);
    } catch (e) {
      throw Exception('Error al actualizar viaje: $e');
    }
  }

  /// Update driver location (Simulated for this phase)
  Future<void> updateDriverLocation(double lat, double lng) async {
    // In a real app, this would update a 'drivers_realtime' table or similar
    // For now, we'll use user_profiles metadata or a dedicated table if exists
  }
}
