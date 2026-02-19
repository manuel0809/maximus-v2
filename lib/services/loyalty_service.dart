import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class LoyaltyService {
  static LoyaltyService? _instance;
  static LoyaltyService get instance => _instance ??= LoyaltyService._();

  LoyaltyService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  /// Get complete loyalty data for the frontend
  Future<Map<String, dynamic>?> getLoyaltyData() async {
    final profile = await getLoyaltyProfile();
    if (profile == null) return {'points': 0, 'membership_level': 'Bronce', 'referral_code': 'MAXIMUS123'};
    
    return {
      'points': profile['points'],
      'membership_level': _mapTierToLabel(profile['tier']),
      'referral_code': 'MAXIMUS${profile['user_id'].toString().substring(0, 4).toUpperCase()}',
      'total_spent': profile['total_spent'],
    };
  }

  String _mapTierToLabel(String tier) {
    switch (tier.toLowerCase()) {
      case 'platinum': return 'Platino';
      case 'gold': return 'Oro';
      case 'silver': return 'Plata';
      default: return 'Bronce';
    }
  }

  /// Get active coupons
  Future<List<Map<String, dynamic>>> getAvailableCoupons() async {
    try {
      final response = await _client
          .from('coupons')
          .select()
          .eq('is_active', true)
          .or('expiry_date.is.null,expiry_date.gte.${DateTime.now().toIso8601String().split('T')[0]}');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Original getLoyaltyProfile
  Future<Map<String, dynamic>?> getLoyaltyProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('loyalty_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      return response;
    } catch (e) {
      return null;
    }
  }

  /// Add points and spend to user profile after a completed trip/rental
  Future<void> awardPoints({required double amountSpent}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      // 1 point per $10 spent
      final int pointsToAward = (amountSpent / 10).floor();

      // Check if profile exists
      final profile = await getLoyaltyProfile();
      
      if (profile == null) {
        await _client.from('loyalty_profiles').insert({
          'user_id': userId,
          'points': pointsToAward,
          'total_spent': amountSpent,
        });
      } else {
        await _client.from('loyalty_profiles').update({
          'points': (profile['points'] as int) + pointsToAward,
          'total_spent': (profile['total_spent'] as num).toDouble() + amountSpent,
          'last_updated': DateTime.now().toIso8601String(),
        }).eq('user_id', userId);
      }
    } catch (e) {
      // Handle error
    }
  }

  /// Validate and apply a coupon
  Future<Map<String, dynamic>?> validateCoupon(String code, double purchaseAmount) async {
    try {
      final response = await _client
          .from('coupons')
          .select()
          .eq('code', code.toUpperCase())
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;

      // Check expiry
      if (response['expiry_date'] != null) {
        final expiry = DateTime.parse(response['expiry_date']);
        if (expiry.isBefore(DateTime.now())) return null;
      }

      // Check min purchase
      if (purchaseAmount < (response['min_purchase_amount'] ?? 0)) return null;

      // Check usage limit
      if (response['usage_limit'] != null && response['usage_count'] >= response['usage_limit']) {
        return null;
      }

      return response;
    } catch (e) {
      return null;
    }
  }
  
  /// Get membership tier benefits
  Map<String, dynamic> getTierBenefits(String tier) {
    switch (tier.toLowerCase()) {
      case 'platinum':
        return {
          'discount': 0.15,
          'label': 'Platinum VIP',
          'description': '15% de descuento fijo, prioridad en reservas y champagne de bienvenida.',
        };
      case 'gold':
        return {
          'discount': 0.10,
          'label': 'Gold Member',
          'description': '10% de descuento fijo y prioridad en reservas.',
        };
      case 'silver':
        return {
          'discount': 0.05,
          'label': 'Silver Member',
          'description': '5% de descuento fijo.',
        };
      default:
        return {
          'discount': 0.0,
          'label': 'Bronze Member',
          'description': 'Sigue sumando puntos para subir de nivel.',
        };
    }
  }

  /// Create a new coupon
  Future<void> createCoupon({
    required String code,
    required double discountPercentage,
    DateTime? expiryDate,
    double? minPurchase,
    int? usageLimit,
  }) async {
    try {
      await _client.from('coupons').insert({
        'code': code.toUpperCase(),
        'discount_percentage': discountPercentage,
        'expiry_date': expiryDate?.toIso8601String(),
        'min_purchase_amount': minPurchase,
        'usage_limit': usageLimit,
        'is_active': true,
      });
    } catch (e) {
      throw Exception('Error al crear cupón: $e');
    }
  }

  /// Delete a coupon
  Future<void> deleteCoupon(String couponId) async {
    try {
      await _client.from('coupons').delete().eq('id', couponId);
    } catch (e) {
      throw Exception('Error al eliminar cupón: $e');
    }
  }
}
