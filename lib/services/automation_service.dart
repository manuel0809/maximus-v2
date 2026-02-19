import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class AutomationService {
  static AutomationService? _instance;
  static AutomationService get instance => _instance ??= AutomationService._();

  AutomationService._();

  final SupabaseClient _supabase = SupabaseService.instance.client;

  /// Trigger a simulated email notification
  /// In a real production environment, this would call a Supabase Edge Function
  /// that integrates with SendGrid/Resend/Mailgun.
  Future<void> triggerNotification({
    required String type,
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      // 1. Log automation activity locally for admin review
      await _supabase.from('automation_logs').insert({
        'type': type,
        'user_id': userId,
        'payload': data,
        'status': 'sent',
        'created_at': DateTime.now().toIso8601String(),
      });

      // 2. Add to in-app notifications
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': _getNotificationTitle(type),
        'message': _getNotificationMessage(type, data),
        'type': type,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('Automation triggered: $type for user $userId');
    } catch (e) {
      debugPrint('Error triggering automation: $e');
    }
  }

  String _getNotificationTitle(String type) {
    switch (type) {
      case 'booking_confirmation': return 'Reserva Confirmada';
      case 'reminder_24h': return 'Recordatorio de Entrega';
      case 'review_request': return '¿Cómo fue tu experiencia?';
      case 'late_return_alert': return 'Alerta: Devolución Atrasada';
      case 'invoice': return 'Tu Factura está Lista';
      default: return 'Notificación de Maximus';
    }
  }

  String _getNotificationMessage(String type, Map data) {
    switch (type) {
      case 'booking_confirmation': 
        return 'Tu reserva para el ${data['vehicle_name']} ha sido confirmada.';
      case 'reminder_24h': 
        return 'Recuerda que tu renta finaliza mañana a las ${data['time']}.';
      case 'late_return_alert':
        return 'Hemos notado un retraso en la devolución. Se aplicarán cargos por hora.';
      default:
        return 'Tienes una nueva actualización en tu cuenta.';
    }
  }

  /// Automatically check for late returns and apply fines
  /// This would normally be a CRON job in Supabase, but we can trigger it 
  /// when the admin opens the dashboard for a "quick catch-up".
  Future<void> processLateReturnFines() async {
    try {
      final now = DateTime.now().toIso8601String();
      
      // Fetch rentals that are 'active' but dropoff_date is in the past
      final response = await _supabase
          .from('rentals')
          .select('id, user_id, dropoff_date, vehicles(price_per_day, brand, model)')
          .eq('status', 'active')
          .lt('dropoff_date', now);

      final overdueRentals = List<Map<String, dynamic>>.from(response);

      for (var rental in overdueRentals) {
        final dropoff = DateTime.parse(rental['dropoff_date']);
        final overdueHours = DateTime.now().difference(dropoff).inHours;
        
        if (overdueHours > 0) {
          final pricePerDay = (rental['vehicles']['price_per_day'] as num).toDouble();
          final fineAmount = (overdueHours * (pricePerDay / 10)); // 10% of daily rate per hour

          // Insert fine
          await _supabase.from('additional_charges').insert({
            'rental_id': rental['id'],
            'type': 'late_return',
            'amount': fineAmount,
            'description': 'Multa por $overdueHours horas de retraso',
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
          });

          // Notify user
          await triggerNotification(
            type: 'late_return_alert',
            userId: rental['user_id'],
            data: {'vehicle_name': '${rental['vehicles']['brand']} ${rental['vehicles']['model']}'},
          );
        }
      }
    } catch (e) {
      debugPrint('Error processing fines: $e');
    }
  }

  /// Generate a weekly summary report for the admin
  Future<void> generateWeeklyReport() async {
    try {
      final lastWeek = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
      
      // 1. Fetch rentals in last week
      final rentals = await _supabase.from('rentals').select('price_per_day').gte('created_at', lastWeek);
      final totalIncome = rentals.fold(0.0, (sum, item) => sum + (item['price_per_day'] ?? 0));

      // 2. Fetch new users in last week
      final users = await _supabase.from('profiles').select('id').gte('created_at', lastWeek);
      
      final reportData = {
        'total_income': totalIncome,
        'new_rentals': rentals.length,
        'new_users': users.length,
        'generated_at': DateTime.now().toIso8601String(),
      };

      // 3. Log report
      await _supabase.from('automation_logs').insert({
        'type': 'weekly_report',
        'user_id': _supabase.auth.currentUser?.id,
        'payload': reportData,
        'status': 'completed',
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('Weekly report generated: $reportData');
    } catch (e) {
      debugPrint('Error generating report: $e');
    }
  }
}
