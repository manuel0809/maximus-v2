import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

class RealtimeService {
  static RealtimeService? _instance;
  static RealtimeService get instance => _instance ??= RealtimeService._();

  RealtimeService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  // Channel subscriptions
  RealtimeChannel? _profileSubscription;
  RealtimeChannel? _tripsSubscription;
  RealtimeChannel? _adminNotificationsSubscription;

  /// Subscribe to user profile updates for current user
  void subscribeToProfileUpdates(Function(Map<String, dynamic>) onUpdate) {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return;

    _profileSubscription = _client
        .channel('profile_$currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'user_profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: currentUserId,
          ),
          callback: (payload) {
            final updatedProfile = payload.newRecord;
            onUpdate(updatedProfile);
          },
        )
        .subscribe();
  }

  /// Unsubscribe from profile updates
  void unsubscribeFromProfile() {
    _profileSubscription?.unsubscribe();
    _profileSubscription = null;
  }

  /// Subscribe to trips/bookings updates for current user
  void subscribeToTrips(Function(Map<String, dynamic>) onTripUpdate) {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return;

    _tripsSubscription = _client
        .channel('trips_$currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trips',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUserId,
          ),
          callback: (payload) {
            final tripData = {
              'event': payload.eventType.name,
              'trip': payload.newRecord,
              'oldTrip': payload.oldRecord,
            };
            onTripUpdate(tripData);
          },
        )
        .subscribe();
  }

  /// Unsubscribe from trips updates
  void unsubscribeFromTrips() {
    _tripsSubscription?.unsubscribe();
    _tripsSubscription = null;
  }

  /// Subscribe to admin notifications (broadcast channel for all admins)
  void subscribeToAdminNotifications(
    Function(Map<String, dynamic>) onAdminNotification,
  ) {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return;

    _adminNotificationsSubscription = _client
        .channel('admin_notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUserId,
          ),
          callback: (payload) {
            final notification = payload.newRecord;
            // Only process admin-relevant notifications
            if (notification['type'] == 'booking_status' ||
                notification['priority'] == 'urgent') {
              onAdminNotification(notification);
            }
          },
        )
        .subscribe();
  }

  /// Unsubscribe from admin notifications
  void unsubscribeFromAdminNotifications() {
    _adminNotificationsSubscription?.unsubscribe();
    _adminNotificationsSubscription = null;
  }

  /// Subscribe to all trips for admin dashboard (no user filter)
  void subscribeToAllTrips(Function(Map<String, dynamic>) onTripUpdate) {
    _tripsSubscription = _client
        .channel('admin_all_trips')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'trips',
          callback: (payload) {
            final tripData = {
              'event': payload.eventType.name,
              'trip': payload.newRecord,
              'oldTrip': payload.oldRecord,
            };
            onTripUpdate(tripData);
          },
        )
        .subscribe();
  }

  /// Unsubscribe from all subscriptions (cleanup)
  void unsubscribeAll() {
    unsubscribeFromProfile();
    unsubscribeFromTrips();
    unsubscribeFromAdminNotifications();
  }

  /// Get current user profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) return null;

      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', currentUserId)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  /// Get user trips/bookings
  Future<List<Map<String, dynamic>>> getUserTrips({
    String? status,
    int limit = 10,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) return [];

      var query = _client.from('trips').select().eq('user_id', currentUserId);

      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener viajes: $e');
    }
  }

  /// Get all trips for admin
  Future<List<Map<String, dynamic>>> getAllTrips({
    String? status,
    int limit = 50,
  }) async {
    try {
      var query = _client
          .from('trips')
          .select('*, user:user_id(full_name, email)');

      if (status != null && status != 'all') {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener todos los viajes: $e');
    }
  }
}
