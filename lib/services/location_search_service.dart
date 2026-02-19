import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LocationSuggestion {
  final String displayName;
  final double latitude;
  final double longitude;

  LocationSuggestion({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    return LocationSuggestion(
      displayName: json['display_name'] ?? '',
      latitude: double.parse(json['lat']),
      longitude: double.parse(json['lon']),
    );
  }
}

class LocationSearchService {
  final Dio _dio = Dio();
  
  // Nominatim OpenStreetMap Search API
  // Usage Policy: https://operations.osmfoundation.org/policies/nominatim/
  // - Maximum of 1 request per second
  // - Provide a valid User-Agent
  final String _baseUrl = 'https://nominatim.openstreetmap.org/search';

  Future<List<LocationSuggestion>> searchAddress(String query) async {
    if (query.length < 3) return [];

    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': 1,
          'limit': 10, // Increased limit
          // Removed countrycodes to allow broader search
        },
        options: Options(
          headers: {
            'User-Agent': 'MaximusTransportApp/1.0',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .where((json) => json['lat'] != null && json['lon'] != null)
            .map((json) => LocationSuggestion.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint('Error searching address: $e');
    }

    return [];
  }
}
