import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Environment configuration loader
class EnvConfig {
  static EnvConfig? _instance;
  static EnvConfig get instance => _instance ??= EnvConfig._();

  EnvConfig._();

  late String supabaseUrl;
  late String supabaseAnonKey;
  late String googleMapsApiKey;

  /// Load environment variables from env.json
  Future<void> load() async {
    try {
      final jsonString = await rootBundle.loadString('assets/env.json');
      final Map<String, dynamic> config = json.decode(jsonString);

      supabaseUrl = config['SUPABASE_URL'] ?? '';
      supabaseAnonKey = config['SUPABASE_ANON_KEY'] ?? '';
      googleMapsApiKey = config['GOOGLE_MAPS_API_KEY'] ?? '';

      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        throw Exception('Supabase configuration is missing in env.json');
      }

      if (googleMapsApiKey.isEmpty) {
        throw Exception('Google Maps API key is missing in env.json');
      }
    } catch (e) {
      throw Exception('Failed to load environment configuration: $e');
    }
  }
}
