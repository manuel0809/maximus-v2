import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import './supabase_service.dart';

class GuestBookingService {
  static GuestBookingService? _instance;
  static GuestBookingService get instance =>
      _instance ??= GuestBookingService._();

  GuestBookingService._();

  static const String _guestSessionKey = 'guest_booking_session';
  static const String _guestBookingKey = 'guest_booking_data';

  // Save guest booking session
  Future<void> saveGuestSession(Map<String, dynamic> bookingData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_guestBookingKey, jsonEncode(bookingData));
    await prefs.setBool(_guestSessionKey, true);
  }

  // Get guest booking session
  Future<Map<String, dynamic>?> getGuestSession() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSession = prefs.getBool(_guestSessionKey) ?? false;

    if (!hasSession) return null;

    final bookingJson = prefs.getString(_guestBookingKey);
    if (bookingJson == null) return null;

    return jsonDecode(bookingJson) as Map<String, dynamic>;
  }

  // Clear guest session
  Future<void> clearGuestSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestBookingKey);
    await prefs.remove(_guestSessionKey);
  }

  // Check if user is in guest mode
  Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_guestSessionKey) ?? false;
  }

  // Submit guest booking to Supabase
  Future<Map<String, dynamic>> submitGuestBooking({
    required String guestName,
    required String guestEmail,
    required String guestPhone,
    required String serviceType,
    String? vehicleType,
    required String pickupLocation,
    required String dropoffLocation,
    required DateTime tripDate,
    int? durationMinutes,
    double? distanceKm,
    double? cost,
    int passengerCount = 1,
    String? specialRequirements,
  }) async {
    try {
      final supabase = SupabaseService.instance.client;

      // Generate booking reference
      final referenceResult = await supabase.rpc('generate_booking_reference');
      final bookingReference = referenceResult as String;

      // Insert guest booking
      final response = await supabase
          .from('guest_bookings')
          .insert({
            'guest_name': guestName,
            'guest_email': guestEmail,
            'guest_phone': guestPhone,
            'service_type': serviceType,
            'vehicle_type': vehicleType,
            'pickup_location': pickupLocation,
            'dropoff_location': dropoffLocation,
            'trip_date': tripDate.toIso8601String(),
            'duration_minutes': durationMinutes,
            'distance_km': distanceKm,
            'cost': cost,
            'passenger_count': passengerCount,
            'special_requirements': specialRequirements,
            'booking_reference': bookingReference,
            'status': 'pending',
          })
          .select()
          .single();

      return {
        'success': true,
        'booking': response,
        'bookingReference': bookingReference,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Convert guest booking to registered user
  Future<bool> convertGuestBookingToUser({
    required String bookingReference,
    required String userId,
  }) async {
    try {
      final supabase = SupabaseService.instance.client;

      await supabase
          .from('guest_bookings')
          .update({'converted_to_user_id': userId, 'status': 'converted'})
          .eq('booking_reference', bookingReference);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get guest booking by reference
  Future<Map<String, dynamic>?> getGuestBookingByReference(
    String reference,
  ) async {
    try {
      final supabase = SupabaseService.instance.client;

      final response = await supabase
          .from('guest_bookings')
          .select()
          .eq('booking_reference', reference)
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }
}
