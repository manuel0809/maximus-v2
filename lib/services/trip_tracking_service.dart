import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/google_maps_service.dart';

/// Trip tracking service with real-time location updates and mileage verification
class TripTrackingService {
  static TripTrackingService? _instance;
  static TripTrackingService get instance => _instance ??= TripTrackingService._();

  TripTrackingService._();

  final _client = SupabaseService.instance.client;
  final _maps = GoogleMapsService.instance;

  /// Start tracking a new trip
  Future<String> startTrip({
    required String bookingId,
    required String driverId,
    required String clientId,
    required String vehicleId,
    required LatLng pickupLocation,
    required LatLng dropoffLocation,
  }) async {
    try {
      // Calculate Google Maps route (this is what we'll charge)
      final route = await _maps.calculateRoute(
        origin: pickupLocation,
        destination: dropoffLocation,
      );

      // Create active trip record
      final response = await _client.from('active_trips').insert({
        'booking_id': bookingId,
        'driver_id': driverId,
        'client_id': clientId,
        'vehicle_id': vehicleId,
        'pickup_lat': pickupLocation.latitude,
        'pickup_lng': pickupLocation.longitude,
        'dropoff_lat': dropoffLocation.latitude,
        'dropoff_lng': dropoffLocation.longitude,
        'google_maps_distance_miles': route.distanceMiles,
        'charged_distance_miles': route.distanceMiles, // ALWAYS charge Google Maps distance
        'real_gps_distance_miles': 0.0,
        'route_polyline': route.polyline,
        'status': 'en_route_to_pickup',
        'start_time': DateTime.now().toIso8601String(),
        'estimated_end_time': DateTime.now()
            .add(Duration(minutes: route.durationMinutes))
            .toIso8601String(),
        'gps_history': [],
        'current_speed_mph': 0.0,
        'deviation_percentage': 0.0,
      }).select().single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Error starting trip: $e');
    }
  }

  /// Update driver location (called every 5 seconds from driver app)
  Future<void> updateDriverLocation({
    required String tripId,
    required LatLng location,
    required double speedMph,
  }) async {
    try {
      // Get current trip data
      final trip = await _client
          .from('active_trips')
          .select()
          .eq('id', tripId)
          .single();

      // Add new GPS point to history
      final gpsHistory = List<Map<String, dynamic>>.from(trip['gps_history'] ?? []);
      gpsHistory.add({
        'lat': location.latitude,
        'lng': location.longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'speed': speedMph,
      });

      // Calculate real GPS distance from all points
      final realDistance = _calculateGPSDistance(gpsHistory);

      // Calculate deviation from Google Maps route
      final googleDistance = (trip['google_maps_distance_miles'] as num).toDouble();
      final deviation = googleDistance > 0
          ? ((realDistance - googleDistance) / googleDistance * 100).abs()
          : 0.0;

      // Update trip with new location and metrics
      await _client.from('active_trips').update({
        'current_driver_lat': location.latitude,
        'current_driver_lng': location.longitude,
        'real_gps_distance_miles': realDistance,
        'current_speed_mph': speedMph,
        'deviation_percentage': deviation,
        'gps_history': gpsHistory,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', tripId);

      // Check for alerts (fraud detection)
      await _checkForAlerts(
        tripId: tripId,
        deviation: deviation,
        speedMph: speedMph,
        gpsHistory: gpsHistory,
      );
    } catch (e) {
      throw Exception('Error updating driver location: $e');
    }
  }

  /// Update trip status
  Future<void> updateTripStatus(String tripId, String status) async {
    try {
      await _client.from('active_trips').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', tripId);
    } catch (e) {
      throw Exception('Error updating trip status: $e');
    }
  }

  /// Complete trip and return summary
  Future<TripSummary> completeTrip(String tripId) async {
    try {
      final trip = await _client
          .from('active_trips')
          .select()
          .eq('id', tripId)
          .single();

      final startTime = DateTime.parse(trip['start_time']);
      final endTime = DateTime.now();
      final durationMinutes = endTime.difference(startTime).inMinutes;

      final summary = TripSummary(
        tripId: tripId,
        googleMapsDistanceMiles: (trip['google_maps_distance_miles'] as num).toDouble(),
        realGpsDistanceMiles: (trip['real_gps_distance_miles'] as num).toDouble(),
        chargedDistanceMiles: (trip['charged_distance_miles'] as num).toDouble(),
        deviationPercentage: (trip['deviation_percentage'] as num).toDouble(),
        durationMinutes: durationMinutes,
        startTime: startTime,
        endTime: endTime,
      );

      // Mark trip as completed
      await _client.from('active_trips').update({
        'status': 'completed',
        'actual_end_time': endTime.toIso8601String(),
      }).eq('id', tripId);

      return summary;
    } catch (e) {
      throw Exception('Error completing trip: $e');
    }
  }

  /// Stream trip updates in real-time (for client/admin tracking)
  Stream<Map<String, dynamic>> streamTrip(String tripId) {
    return _client
        .from('active_trips')
        .stream(primaryKey: ['id'])
        .eq('id', tripId)
        .map((list) => list.isNotEmpty ? list.first : {});
  }

  /// Stream all active trips (for admin dashboard)
  Stream<List<Map<String, dynamic>>> streamAllActiveTrips() {
    return _client
        .from('active_trips')
        .stream(primaryKey: ['id'])
        .neq('status', 'completed');
  }

  /// Get trip by ID
  Future<Map<String, dynamic>?> getTripById(String tripId) async {
    try {
      return await _client
          .from('active_trips')
          .select()
          .eq('id', tripId)
          .maybeSingle();
    } catch (e) {
      throw Exception('Error getting trip: $e');
    }
  }

  /// Calculate total GPS distance from GPS history
  double _calculateGPSDistance(List<Map<String, dynamic>> gpsHistory) {
    if (gpsHistory.length < 2) return 0.0;

    double totalMiles = 0.0;
    for (int i = 1; i < gpsHistory.length; i++) {
      final prev = gpsHistory[i - 1];
      final curr = gpsHistory[i];

      final prevPoint = LatLng(
        (prev['lat'] as num).toDouble(),
        (prev['lng'] as num).toDouble(),
      );
      final currPoint = LatLng(
        (curr['lat'] as num).toDouble(),
        (curr['lng'] as num).toDouble(),
      );

      totalMiles += _maps.haversineDistance(prevPoint, currPoint);
    }

    return totalMiles;
  }

  /// Check for alerts and create them if necessary (anti-fraud system)
  Future<void> _checkForAlerts({
    required String tripId,
    required double deviation,
    required double speedMph,
    required List<Map<String, dynamic>> gpsHistory,
  }) async {
    // Alert 1: Route deviation > 20% (possible fraud or major detour)
    if (deviation > 20) {
      await _createAlert(
        tripId: tripId,
        type: 'route_deviation',
        severity: 'high',
        message: 'Driver deviated ${deviation.toStringAsFixed(1)}% from optimal route',
        metadata: {'deviation_percentage': deviation},
      );
    }

    // Alert 2: Excessive speed > 90 mph (safety concern)
    if (speedMph > 90) {
      await _createAlert(
        tripId: tripId,
        type: 'excessive_speed',
        severity: 'critical',
        message: 'Driver traveling at ${speedMph.toStringAsFixed(0)} mph',
        metadata: {'speed_mph': speedMph},
      );
    }

    // Alert 3: Stopped for > 15 minutes (180 GPS points at 5 sec intervals)
    if (gpsHistory.length > 180) {
      final last180 = gpsHistory.sublist(gpsHistory.length - 180);
      final firstPoint = last180.first;
      final allStopped = last180.every((point) {
        final distance = _maps.haversineDistance(
          LatLng((firstPoint['lat'] as num).toDouble(), (firstPoint['lng'] as num).toDouble()),
          LatLng((point['lat'] as num).toDouble(), (point['lng'] as num).toDouble()),
        );
        return distance < 0.01; // Less than 0.01 miles = essentially stopped
      });

      if (allStopped && speedMph < 1) {
        await _createAlert(
          tripId: tripId,
          type: 'stopped_too_long',
          severity: 'medium',
          message: 'Driver stopped for more than 15 minutes',
          metadata: {'stopped_duration_minutes': 15},
        );
      }
    }

    // Alert 4: GPS anomaly (impossible speed between points)
    if (gpsHistory.length >= 2) {
      final lastTwo = gpsHistory.sublist(gpsHistory.length - 2);
      final point1 = LatLng(
        (lastTwo[0]['lat'] as num).toDouble(),
        (lastTwo[0]['lng'] as num).toDouble(),
      );
      final point2 = LatLng(
        (lastTwo[1]['lat'] as num).toDouble(),
        (lastTwo[1]['lng'] as num).toDouble(),
      );

      final distance = _maps.haversineDistance(point1, point2);
      final timeDiff = 5.0 / 3600.0; // 5 seconds in hours
      final calculatedSpeed = distance / timeDiff;

      // If calculated speed > 200 mph, likely GPS anomaly
      if (calculatedSpeed > 200) {
        await _createAlert(
          tripId: tripId,
          type: 'gps_anomaly',
          severity: 'high',
          message: 'GPS anomaly detected: impossible speed of ${calculatedSpeed.toStringAsFixed(0)} mph',
          metadata: {'calculated_speed': calculatedSpeed},
        );
      }
    }
  }

  /// Create an alert in the database
  Future<void> _createAlert({
    required String tripId,
    required String type,
    required String severity,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _client.from('trip_alerts').insert({
        'trip_id': tripId,
        'alert_type': type,
        'severity': severity,
        'message': message,
        'metadata': metadata ?? {},
        'resolved': false,
      });
    } catch (e) {
      // Don't throw - alerts are non-critical
      debugPrint('Error creating alert: $e');
    }
  }

  /// Get unresolved alerts for a trip
  Future<List<Map<String, dynamic>>> getUnresolvedAlerts(String tripId) async {
    try {
      return await _client
          .from('trip_alerts')
          .select()
          .eq('trip_id', tripId)
          .eq('resolved', false)
          .order('created_at', ascending: false);
    } catch (e) {
      throw Exception('Error getting alerts: $e');
    }
  }

  /// Resolve an alert
  Future<void> resolveAlert(String alertId) async {
    try {
      await _client.from('trip_alerts').update({
        'resolved': true,
      }).eq('id', alertId);
    } catch (e) {
      throw Exception('Error resolving alert: $e');
    }
  }
}

/// Trip summary after completion
class TripSummary {
  final String tripId;
  final double googleMapsDistanceMiles;
  final double realGpsDistanceMiles;
  final double chargedDistanceMiles;
  final double deviationPercentage;
  final int durationMinutes;
  final DateTime startTime;
  final DateTime endTime;

  TripSummary({
    required this.tripId,
    required this.googleMapsDistanceMiles,
    required this.realGpsDistanceMiles,
    required this.chargedDistanceMiles,
    required this.deviationPercentage,
    required this.durationMinutes,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toJson() => {
        'trip_id': tripId,
        'google_maps_distance_miles': googleMapsDistanceMiles,
        'real_gps_distance_miles': realGpsDistanceMiles,
        'charged_distance_miles': chargedDistanceMiles,
        'deviation_percentage': deviationPercentage,
        'duration_minutes': durationMinutes,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
      };
}
