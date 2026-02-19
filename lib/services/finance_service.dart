import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class FinanceService {
  static FinanceService? _instance;
  static FinanceService get instance => _instance ??= FinanceService._();

  FinanceService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  /// Fetch all expenses
  Future<List<Map<String, dynamic>>> getExpenses({String? vehicleId}) async {
    try {
      var query = _client.from('vehicle_expenses').select('''
        *,
        vehicles (brand, model)
      ''');
      
      if (vehicleId != null) {
        query = query.eq('vehicle_id', vehicleId);
      }
      
      final response = await query.order('date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener gastos: $e');
    }
  }

  /// Add a new expense
  Future<void> addExpense({
    required String vehicleId,
    required String type,
    required double amount,
    required String description,
    required DateTime date,
  }) async {
    try {
      await _client.from('vehicle_expenses').insert({
        'vehicle_id': vehicleId,
        'type': type,
        'amount': amount,
        'description': description,
        'date': date.toIso8601String().split('T')[0],
        'created_by': _client.auth.currentUser?.id,
      });
    } catch (e) {
      throw Exception('Error al registrar gasto: $e');
    }
  }

  /// Get profitability report (ROI)
  Future<List<Map<String, dynamic>>> getProfitabilityReport() async {
    try {
      final response = await _client.from('vehicle_profitability').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener reporte de rentabilidad: $e');
    }
  }

  /// Get total financial summary for a given period
  Future<Map<String, dynamic>> getFinancialSummary(String period) async {
    try {
      final now = DateTime.now();
      DateTime startDate;
      
      switch (period) {
        case 'Hoy':
           startDate = DateTime(now.year, now.month, now.day);
           break;
        case 'Esta Semana':
           startDate = now.subtract(Duration(days: now.weekday - 1));
           break;
        case 'Este Mes':
           startDate = DateTime(now.year, now.month, 1);
           break;
        case 'Este Año':
           startDate = DateTime(now.year, 1, 1);
           break;
        default:
           startDate = DateTime(now.year, now.month, 1);
      }

      // Fetch expenses in period
      final expensesResponse = await _client
          .from('vehicle_expenses')
          .select()
          .gte('date', startDate.toIso8601String().split('T')[0]);
      
      final expenses = List<Map<String, dynamic>>.from(expensesResponse);
      
      // Calculate breakdown and total
      double totalExp = 0;
      Map<String, double> breakdown = {
        'Mantenimiento': 0,
        'Gasolina': 0,
        'Seguro': 0,
        'Multas': 0,
        'Limpieza': 0,
        'Otros': 0,
      };

      for (var e in expenses) {
        final amt = (e['amount'] ?? 0).toDouble();
        totalExp += amt;
        final type = _mapTypeToLabel(e['type']);
        breakdown[type] = (breakdown[type] ?? 0) + amt;
      }

      // Fetch revenue (rentals) in period
      final revenueResponse = await _client
          .from('rentals')
          .select('total_price')
          .eq('status', 'completed')
          .gte('pickup_date', startDate.toIso8601String());
      
      double totalRev = 0;
      for (var r in revenueResponse) {
        totalRev += (r['total_price'] ?? 0).toDouble();
      }

      return {
        'total_income': totalRev,
        'total_expenses': totalExp,
        'net_profit': totalRev - totalExp,
        'expenses_breakdown': breakdown,
      };
    } catch (e) {
      return {
        'total_income': 0.0,
        'total_expenses': 0.0,
        'net_profit': 0.0,
        'expenses_breakdown': {},
      };
    }
  }

  String _mapTypeToLabel(String type) {
    switch (type) {
      case 'maintenance': return 'Mantenimiento';
      case 'fuel': return 'Gasolina';
      case 'insurance': return 'Seguro';
      case 'fine': return 'Multas';
      case 'cleaning': return 'Limpieza';
      default: return 'Otros';
    }
  }
}
