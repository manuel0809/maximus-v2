import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class PaymentsService {
  static PaymentsService? _instance;
  static PaymentsService get instance => _instance ??= PaymentsService._();

  PaymentsService._();

  final SupabaseClient _supabase = SupabaseService.instance.client;

  // Get all payments for current user with optional filters
  Future<List<Map<String, dynamic>>> getPayments({
    String? statusFilter,
    String? serviceTypeFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      var query =
          _supabase
                  .from('payments')
                  .select('*, payment_methods(*), trips(*), rentals(*, vehicles(*)), invoices(*)')
                  .eq('user_id', userId)
              as PostgrestFilterBuilder;

      if (statusFilter != null && statusFilter != 'all') {
        query = query.eq('payment_status', statusFilter);
      }

      if (startDate != null) {
        query = query.gte('payment_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('payment_date', endDate.toIso8601String());
      }

      query =
          query.order('payment_date', ascending: false)
              as PostgrestFilterBuilder;

      final response = await query;
      var payments = List<Map<String, dynamic>>.from(response);

      // Apply service type filter if specified
      if (serviceTypeFilter != null && serviceTypeFilter != 'all') {
        payments = payments.where((payment) {
          final trip = payment['trips'] as Map<String, dynamic>?;
          return trip?['service_type'] == serviceTypeFilter;
        }).toList();
      }

      return payments;
    } catch (e) {
      throw Exception('Error loading payments: $e');
    }
  }

  // Get single payment with full details
  Future<Map<String, dynamic>> getPaymentDetails(String paymentId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('payments')
          .select('*, payment_methods(*), trips(*), invoices(*)')
          .eq('id', paymentId)
          .eq('user_id', userId)
          .single();

      return response;
    } catch (e) {
      throw Exception('Error loading payment details: $e');
    }
  }

  // Get invoice details
  Future<Map<String, dynamic>> getInvoiceDetails(String invoiceId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('invoices')
          .select('*, payments(*, payment_methods(*))')
          .eq('id', invoiceId)
          .eq('user_id', userId)
          .single();

      return response;
    } catch (e) {
      throw Exception('Error loading invoice details: $e');
    }
  }

  // Get all payment methods for current user
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('payment_methods')
          .select('*')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error loading payment methods: $e');
    }
  }

  // Add new payment method
  Future<Map<String, dynamic>> addPaymentMethod({
    required String methodType,
    String? cardLastFour,
    String? cardBrand,
    int? cardExpMonth,
    int? cardExpYear,
    String? walletProvider,
    String? bankName,
    String? accountLastFour,
    bool isDefault = false,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // If setting as default, unset other defaults first
      if (isDefault) {
        await _supabase
            .from('payment_methods')
            .update({'is_default': false})
            .eq('user_id', userId)
            .eq('is_default', true);
      }

      final response = await _supabase
          .from('payment_methods')
          .insert({
            'user_id': userId,
            'method_type': methodType,
            'card_last_four': cardLastFour,
            'card_brand': cardBrand,
            'card_exp_month': cardExpMonth,
            'card_exp_year': cardExpYear,
            'wallet_provider': walletProvider,
            'bank_name': bankName,
            'account_last_four': accountLastFour,
            'is_default': isDefault,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Error adding payment method: $e');
    }
  }

  // Update payment method
  Future<void> updatePaymentMethod(
    String methodId, {
    bool? isDefault,
    bool? isActive,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // If setting as default, unset other defaults first
      if (isDefault == true) {
        await _supabase
            .from('payment_methods')
            .update({'is_default': false})
            .eq('user_id', userId)
            .eq('is_default', true);
      }

      final updateData = <String, dynamic>{};
      if (isDefault != null) updateData['is_default'] = isDefault;
      if (isActive != null) updateData['is_active'] = isActive;

      await _supabase
          .from('payment_methods')
          .update(updateData)
          .eq('id', methodId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Error updating payment method: $e');
    }
  }

  // Delete payment method
  Future<void> deletePaymentMethod(String methodId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase
          .from('payment_methods')
          .delete()
          .eq('id', methodId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Error deleting payment method: $e');
    }
  }

  // Get payment statistics
  Future<Map<String, dynamic>> getPaymentStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      var query = _supabase
          .from('payments')
          .select('amount, payment_status, payment_date, trips(service_type)')
          .eq('user_id', userId);

      if (startDate != null) {
        query = query.gte('payment_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('payment_date', endDate.toIso8601String());
      }

      final response = await query;
      final payments = List<Map<String, dynamic>>.from(response);

      double totalSpent = 0;
      double completedTotal = 0;
      int completedCount = 0;
      int pendingCount = 0;
      Map<String, double> serviceTypeBreakdown = {};

      for (var payment in payments) {
        final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
        final status = payment['payment_status'] as String?;
        final trip = payment['trips'] as Map<String, dynamic>?;
        final serviceType = trip?['service_type'] as String? ?? 'Unknown';

        totalSpent += amount;

        if (status == 'completed') {
          completedTotal += amount;
          completedCount++;
        } else if (status == 'pending') {
          pendingCount++;
        }

        serviceTypeBreakdown[serviceType] =
            (serviceTypeBreakdown[serviceType] ?? 0) + amount;
      }

      return {
        'total_spent': totalSpent,
        'completed_total': completedTotal,
        'completed_count': completedCount,
        'pending_count': pendingCount,
        'total_transactions': payments.length,
        'service_type_breakdown': serviceTypeBreakdown,
      };
    } catch (e) {
      throw Exception('Error calculating statistics: $e');
    }
  }

  // Search payments by reference or trip details
  Future<List<Map<String, dynamic>>> searchPayments(String searchQuery) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('payments')
          .select('*, payment_methods(*), trips(*), rentals(*, vehicles(*)), invoices(*)')
          .eq('user_id', userId)
          .or(
            'transaction_reference.ilike.%$searchQuery%,trips.pickup_location.ilike.%$searchQuery%,trips.dropoff_location.ilike.%$searchQuery%',
          )
          .order('payment_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error searching payments: $e');
    }
  }

  // Subscribe to payment updates
  void subscribeToPayments(Function(Map<String, dynamic>) onPaymentUpdate) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    _supabase
        .channel('payments_channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'payments',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            onPaymentUpdate(payload.newRecord);
          },
        )
        .subscribe();
  }

  // Unsubscribe from updates
  void unsubscribe() {
    _supabase.removeAllChannels();
  }
}
