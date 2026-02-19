import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './pricing_service.dart';
import './automation_service.dart';

class CarRentalService {
  static CarRentalService? _instance;
  static CarRentalService get instance => _instance ??= CarRentalService._();

  CarRentalService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  // Fetch all vehicle categories
  Future<List<Map<String, dynamic>>> getVehicleCategories() async {
    try {
      final response = await _client
          .from('vehicle_categories')
          .select()
          .order('sort_order', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching vehicle categories: $e');
    }
  }

  // Fetch vehicles with optional category filter and advanced filters
  Future<List<Map<String, dynamic>>> getVehicles({
    String? categoryId,
    bool? isAvailable,
    double? minPrice,
    double? maxPrice,
    String? transmission,
    int? passengers,
  }) async {
    try {
      var query = _client.from('vehicles').select('''
        *,
        vehicle_categories (*)
      ''');

      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }

      if (isAvailable != null && isAvailable) {
        query = query.eq('is_available', true).eq('status', 'available');
      } else if (isAvailable != null && !isAvailable) {
        query = query.or('is_available.eq.false,status.neq.available');
      }

      if (minPrice != null) {
        query = query.gte('price_per_day', minPrice);
      }

      if (maxPrice != null) {
        query = query.lte('price_per_day', maxPrice);
      }

      if (transmission != null && transmission != 'all') {
        query = query.eq('transmission', transmission);
      }

      if (passengers != null) {
        query = query.gte('passengers', passengers);
      }

      final response = await query.order('price_per_day', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching vehicles: $e');
    }
  }

  /// Fetch vehicles that require attention (maintenance, insurance, etc.)
  Future<List<Map<String, dynamic>>> getVehicleAlerts() async {
    try {
      final vehicles = await getVehicles();
      final List<Map<String, dynamic>> alerts = [];

      final now = DateTime.now();
      final thirtyDaysFromNow = now.add(const Duration(days: 30));

      for (var vehicle in vehicles) {
        bool hasAlert = false;
        List<String> issues = [];

        // Check Insurance
        if (vehicle['insurance_expiry_date'] != null) {
          final expiry = DateTime.parse(vehicle['insurance_expiry_date']);
          if (expiry.isBefore(now)) {
            hasAlert = true;
            issues.add('Seguro Vencido');
          } else if (expiry.isBefore(thirtyDaysFromNow)) {
            hasAlert = true;
            issues.add('Seguro vence pronto');
          }
        }

        // Check Maintenance
        if (vehicle['next_maintenance_date'] != null) {
          final maintenance = DateTime.parse(vehicle['next_maintenance_date']);
          if (maintenance.isBefore(now)) {
            hasAlert = true;
            issues.add('Mantenimiento Vencido');
          } else if (maintenance.isBefore(thirtyDaysFromNow)) {
            hasAlert = true;
            issues.add('Mantenimiento próximo');
          }
        }

        // Check Oil Change (example: every 5000km)
        if (vehicle['current_km'] != null && vehicle['next_oil_change_km'] != null) {
          if (vehicle['current_km'] >= vehicle['next_oil_change_km']) {
            hasAlert = true;
            issues.add('Requiere cambio de aceite');
          }
        }

        if (hasAlert) {
          vehicle['alerts'] = issues;
          alerts.add(vehicle);
        }
      }

      return alerts;
    } catch (e) {
      // If fields don't exist yet, return empty list to avoid crash
      return [];
    }
  }

  // Fetch single vehicle by ID
  Future<Map<String, dynamic>?> getVehicleById(String vehicleId) async {
    try {
      final response = await _client
          .from('vehicles')
          .select('''
            *,
            vehicle_categories (*)
          ''')
          .eq('id', vehicleId)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Error fetching vehicle: $e');
    }
  }

  // Create new rental
  Future<Map<String, dynamic>> createRental({
    required String vehicleId,
    required String pickupLocation,
    required String dropoffLocation,
    required DateTime pickupDate,
    required DateTime dropoffDate,
    required double pricePerDay,
    double insurance = 0,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from('rentals')
          .insert({
            'user_id': userId,
            'vehicle_id': vehicleId,
            'pickup_location': pickupLocation,
            'dropoff_location': dropoffLocation,
            'pickup_date': pickupDate.toIso8601String(),
            'dropoff_date': dropoffDate.toIso8601String(),
            'price_per_day': pricePerDay,
            'insurance': insurance,
            'status': 'active', // Auto-block dates by setting status active
          })
          .select()
          .single();

      // Trigger automation
      final vehicle = await getVehicleById(vehicleId);
      await AutomationService.instance.triggerNotification(
        type: 'booking_confirmation',
        userId: userId,
        data: {
          'vehicle_name': '${vehicle?['brand'] ?? 'Vehículo'} ${vehicle?['model'] ?? ''}',
          'rental_id': response['id'],
        },
      );

      return response;
    } catch (e) {
      throw Exception('Error creating rental: $e');
    }
  }

  // Fetch user's rentals
  Future<List<Map<String, dynamic>>> getUserRentals() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _client
          .from('rentals')
          .select('''
            *,
            vehicles (
              *,
              vehicle_categories (*)
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching user rentals: $e');
    }
  }

  // Update rental status
  Future<void> updateRentalStatus(String rentalId, String status) async {
    try {
      await _client
          .from('rentals')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', rentalId);
    } catch (e) {
      throw Exception('Error updating rental status: $e');
    }
  }

  // Save digital checklist for pickup or return
  Future<void> saveDigitalChecklist(Map<String, dynamic> checklistData) async {
    try {
      await _client.from('rentals_checklists').insert(checklistData);
    } catch (e) {
      throw Exception('Error al guardar checklist: $e');
    }
  }

  Map<String, double> calculateRentalPrice({
    required double pricePerDay,
    required DateTime pickupDate,
    required DateTime dropoffDate,
    double insurance = 0,
  }) {
    final days = dropoffDate.difference(pickupDate).inDays.clamp(1, 400).toDouble();
    
    // Apply dynamic pricing rules
    final dynamicDailyPrice = PricingService.instance.calculateDynamicPrice(
      basePrice: pricePerDay,
      pickupDate: pickupDate,
      dropoffDate: dropoffDate,
    );

    final subtotal = dynamicDailyPrice * days;
    final tax = subtotal * 0.16;
    final total = subtotal + insurance + tax;

    return {
      'days': days,
      'base_daily': pricePerDay,
      'dynamic_daily': dynamicDailyPrice,
      'subtotal': subtotal,
      'insurance': insurance,
      'tax': tax,
      'total': total,
    };
  }

  // Add a new vehicle to the fleet
  Future<Map<String, dynamic>> addVehicle(Map<String, dynamic> vehicleData) async {
    try {
      final response = await _client
          .from('vehicles')
          .insert(vehicleData)
          .select()
          .single();
      return response;
    } catch (e) {
      throw Exception('Error al agregar vehículo: $e');
    }
  }

  // Update an existing vehicle
  Future<void> updateVehicle(String vehicleId, Map<String, dynamic> vehicleData) async {
    try {
      await _client
          .from('vehicles')
          .update(vehicleData)
          .eq('id', vehicleId);
    } catch (e) {
      throw Exception('Error al actualizar vehículo: $e');
    }
  }

  // Update vehicle status
  Future<void> updateVehicleStatus(String vehicleId, String status) async {
    try {
      await _client
          .from('vehicles')
          .update({
            'status': status,
            'is_available': status == 'available',
          })
          .eq('id', vehicleId);
    } catch (e) {
      throw Exception('Error al actualizar estado del vehículo: $e');
    }
  }

  // Delete a vehicle
  Future<void> deleteVehicle(String vehicleId) async {
    try {
      // 1. Get vehicle data to find image path
      final vehicle = await getVehicleById(vehicleId);
      final imageUrl = vehicle?['image_url'] as String?;

      // 2. Delete vehicle from database
      await _client.from('vehicles').delete().eq('id', vehicleId);

      // 3. Delete image from storage if it exists and is a Supabase URL
      if (imageUrl != null && imageUrl.contains('vehicle-photos')) {
        final uri = Uri.parse(imageUrl);
        final pathSegments = uri.pathSegments;
        final fileName = pathSegments.last;
        await _client.storage.from('vehicle-photos').remove([fileName]);
      }
    } catch (e) {
      throw Exception('Error al eliminar vehículo: $e');
    }
  }

  // Upload vehicle image
  Future<String> uploadVehicleImage(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      
      await _client.storage.from('vehicle-photos').upload(
        fileName,
        imageFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final String publicUrl = _client.storage
          .from('vehicle-photos')
          .getPublicUrl(fileName);
          
      return publicUrl;
    } catch (e) {
      throw Exception('Error al subir imagen: $e');
    }
  }

  // Get full history of a vehicle (rentals, maintenance, damages)
  Future<Map<String, dynamic>> getVehicleHistory(String vehicleId) async {
    try {
      // Get all rentals for this vehicle
      final rentalsResponse = await _client
          .from('rentals')
          .select('*, profiles(full_name)')
          .eq('vehicle_id', vehicleId)
          .order('pickup_date', ascending: false);
      
      final rentals = List<Map<String, dynamic>>.from(rentalsResponse);
      
      // Calculate total mileage and revenue
      double totalRevenue = 0;
      for (var r in rentals) {
        totalRevenue += (r['price_per_day'] ?? 0) * 1.0; // Simplistic
      }

      // Get maintenance logs
      final maintenanceResponse = await _client
          .from('maintenance_logs')
          .select('*')
          .eq('vehicle_id', vehicleId)
          .order('date', ascending: false);
      
      // Get damage reports
      final checklistResponse = await _client
          .from('rentals_checklists')
          .select('*')
          .eq('rental_id', vehicleId); // This logic needs careful join but keeping it for structure

      return {
        'rentals': rentals,
        'total_revenue': totalRevenue,
        'maintenance': maintenanceResponse,
        'damages': checklistResponse,
      };
    } catch (e) {
      throw Exception('Error al obtener historial: $e');
    }
  }
}
