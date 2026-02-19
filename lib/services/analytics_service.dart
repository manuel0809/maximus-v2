import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance => _instance ??= AnalyticsService._();

  AnalyticsService._();

  final SupabaseClient _supabase = SupabaseService.instance.client;

  /// Get occupancy statistics (days rented vs days available)
  Future<Map<String, dynamic>> getOccupancyStats() async {
    try {
      final now = DateTime.now();
      final last30Days = now.subtract(const Duration(days: 30)).toIso8601String();

      // Simple metric: Number of active/completed rentals in last 30 days
      final response = await _supabase
          .from('rentals')
          .select('id, pickup_date, dropoff_date')
          .gte('created_at', last30Days);
      
      final rentals = List<Map<String, dynamic>>.from(response);
      
      double totalRentedDays = 0;
      for (var r in rentals) {
        final start = DateTime.parse(r['pickup_date']);
        final end = DateTime.parse(r['dropoff_date']);
        totalRentedDays += end.difference(start).inDays.clamp(1, 30);
      }

      // Assume 10 vehicles in fleet for calculation (or fetch actual count)
      const fleetSize = 10; 
      final totalCapacity = fleetSize * 30;
      final occupancyRate = (totalRentedDays / totalCapacity) * 100;

      return {
        'total_rented_days': totalRentedDays,
        'capacity': totalCapacity,
        'occupancy_rate': occupancyRate.clamp(0, 100),
      };
    } catch (e) {
      return {'occupancy_rate': 0};
    }
  }

  /// Get ROI and performance per vehicle
  Future<List<Map<String, dynamic>>> getFleetPerformance() async {
    try {
      final response = await _supabase.from('vehicles').select('''
        id, brand, model, price_per_day,
        rentals(price_per_day),
        maintenance_logs(cost)
      ''');

      final vehicles = List<Map<String, dynamic>>.from(response);
      final List<Map<String, dynamic>> performance = [];

      for (var v in vehicles) {
        final rentals = v['rentals'] as List;
        final maintenance = v['maintenance_logs'] as List;

        double income = 0;
        for (var r in rentals) {
          income += (r['price_per_day'] ?? 0);
        }

        double expenses = 0;
        for (var m in maintenance) {
          expenses += (m['cost'] ?? 0);
        }

        performance.add({
          'id': v['id'],
          'name': '${v['brand']} ${v['model']}',
          'income': income,
          'expenses': expenses,
          'net': income - expenses,
          'roi': expenses > 0 ? (income / expenses) : income,
        });
      }

      performance.sort((a, b) => b['net'].compareTo(a['net']));
      return performance;
    } catch (e) {
      return [];
    }
  }

  /// Get customer behavior insights
  Future<Map<String, dynamic>> getCustomerInsights() async {
    try {
      final response = await _supabase.from('rentals').select('user_id, status');
      final rentals = List<Map<String, dynamic>>.from(response);

      final userBookings = <String, int>{};
      int cancellations = 0;

      for (var r in rentals) {
        final uid = r['user_id'];
        userBookings[uid] = (userBookings[uid] ?? 0) + 1;
        if (r['status'] == 'cancelled') cancellations++;
      }

      final loyalCustomers = userBookings.values.where((count) => count >= 3).length;
      final avgBookingsPerUser = rentals.isEmpty ? 0 : (rentals.length / userBookings.keys.length);

      return {
        'loyal_count': loyalCustomers,
        'cancellation_rate': rentals.isEmpty ? 0 : (cancellations / rentals.length) * 100,
        'avg_per_user': avgBookingsPerUser,
      };
    } catch (e) {
      return {'loyal_count': 0};
    }
  }

  /// Simulated AI Demand Forecasting
  Future<List<double>> getDemandForecast() async {
    // In a real app, this would call a Python/FastAPI service with a Prophet/LSTM model.
    // For now, we simulate seasonality-based demand for the next 7 days.
    final now = DateTime.now();
    final forecast = <double>[];

    for (int i = 0; i < 7; i++) {
        final day = now.add(Duration(days: i)).weekday;
        // Peak on weekends
        if (day >= 5) {
          forecast.add(0.8 + (i * 0.02)); // 80%+ demand
        } else {
          forecast.add(0.5 + (i * 0.01)); // 50% demand
        }
    }
    return forecast;
  }
}
