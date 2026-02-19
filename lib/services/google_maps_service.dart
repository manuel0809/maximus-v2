import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/config/env_config.dart';

/// Google Maps service for route calculation, geocoding, and distance matrix
class GoogleMapsService {
  static GoogleMapsService? _instance;
  static GoogleMapsService get instance => _instance ??= GoogleMapsService._();

  GoogleMapsService._();

  String get _apiKey => EnvConfig.instance.googleMapsApiKey;

  /// Calculate route between two points using Directions API
  Future<RouteInfo> calculateRoute({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
  }) async {
    try {
      final originStr = '${origin.latitude},${origin.longitude}';
      final destStr = '${destination.latitude},${destination.longitude}';
      
      String url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=$originStr'
          '&destination=$destStr'
          '&key=$_apiKey';

      if (waypoints != null && waypoints.isNotEmpty) {
        final waypointsStr = waypoints
            .map((w) => '${w.latitude},${w.longitude}')
            .join('|');
        url += '&waypoints=$waypointsStr';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          return RouteInfo(
            distanceMiles: _metersToMiles(leg['distance']['value']),
            durationMinutes: (leg['duration']['value'] / 60).round(),
            polyline: route['overview_polyline']['points'],
            steps: (leg['steps'] as List)
                .map((s) => s['html_instructions'] as String)
                .toList(),
            distanceText: leg['distance']['text'],
            durationText: leg['duration']['text'],
          );
        }
      }

      throw Exception('Failed to calculate route: ${response.body}');
    } catch (e) {
      throw Exception('Error calculating route: $e');
    }
  }

  /// Calculate distance between two points using Distance Matrix API
  Future<double> calculateDistanceMiles({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final originStr = '${origin.latitude},${origin.longitude}';
      final destStr = '${destination.latitude},${destination.longitude}';

      final url = 'https://maps.googleapis.com/maps/api/distancematrix/json'
          '?origins=$originStr'
          '&destinations=$destStr'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['rows'].isNotEmpty) {
          final element = data['rows'][0]['elements'][0];
          if (element['status'] == 'OK') {
            return _metersToMiles(element['distance']['value']);
          }
        }
      }

      throw Exception('Failed to calculate distance: ${response.body}');
    } catch (e) {
      throw Exception('Error calculating distance: $e');
    }
  }

  /// Search places with autocomplete using Places API
  Future<List<PlacePrediction>> searchPlaces(String query) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(query)}'
          '&components=country:us'
          '&types=address'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          return (data['predictions'] as List)
              .map((p) => PlacePrediction(
                    placeId: p['place_id'],
                    description: p['description'],
                    mainText: p['structured_formatting']['main_text'],
                    secondaryText: p['structured_formatting']['secondary_text'],
                  ))
              .toList();
        }
      }

      return [];
    } catch (e) {
      throw Exception('Error searching places: $e');
    }
  }

  /// Get coordinates from place ID
  Future<LatLng> getPlaceCoordinates(String placeId) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId'
          '&fields=geometry'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          return LatLng(
            location['lat'].toDouble(),
            location['lng'].toDouble(),
          );
        }
      }

      throw Exception('Failed to get place coordinates: ${response.body}');
    } catch (e) {
      throw Exception('Error getting place coordinates: $e');
    }
  }

  /// Convert address to coordinates (Geocoding)
  Future<LatLng> geocodeAddress(String address) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json'
          '?address=${Uri.encodeComponent(address)}'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          return LatLng(
            location['lat'].toDouble(),
            location['lng'].toDouble(),
          );
        }
      }

      throw Exception('Failed to geocode address: ${response.body}');
    } catch (e) {
      throw Exception('Error geocoding address: $e');
    }
  }

  /// Convert coordinates to address (Reverse Geocoding)
  Future<String> reverseGeocode(LatLng coordinates) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=${coordinates.latitude},${coordinates.longitude}'
          '&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }

      throw Exception('Failed to reverse geocode: ${response.body}');
    } catch (e) {
      throw Exception('Error reverse geocoding: $e');
    }
  }

  /// Calculate Haversine distance between two coordinates (in miles)
  double haversineDistance(LatLng point1, LatLng point2) {
    const R = 3958.8; // Earth radius in miles

    final lat1 = _toRadians(point1.latitude);
    final lat2 = _toRadians(point2.latitude);
    final dLat = _toRadians(point2.latitude - point1.latitude);
    final dLon = _toRadians(point2.longitude - point1.longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  double _metersToMiles(int meters) => meters * 0.000621371;
  double _toRadians(double degrees) => degrees * pi / 180;
}

/// Latitude/Longitude coordinate
class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  Map<String, dynamic> toJson() => {
        'lat': latitude,
        'lng': longitude,
      };

  factory LatLng.fromJson(Map<String, dynamic> json) => LatLng(
        json['lat'].toDouble(),
        json['lng'].toDouble(),
      );

  @override
  String toString() => 'LatLng($latitude, $longitude)';
}

/// Route information from Directions API
class RouteInfo {
  final double distanceMiles;
  final int durationMinutes;
  final String polyline;
  final List<String> steps;
  final String distanceText;
  final String durationText;

  RouteInfo({
    required this.distanceMiles,
    required this.durationMinutes,
    required this.polyline,
    required this.steps,
    required this.distanceText,
    required this.durationText,
  });

  Map<String, dynamic> toJson() => {
        'distance_miles': distanceMiles,
        'duration_minutes': durationMinutes,
        'polyline': polyline,
        'steps': steps,
        'distance_text': distanceText,
        'duration_text': durationText,
      };
}

/// Place prediction from Places API
class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });
}
