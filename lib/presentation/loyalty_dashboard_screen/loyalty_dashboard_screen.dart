import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/loyalty_service.dart';
import '../../widgets/custom_app_bar.dart';

class LoyaltyDashboardScreen extends StatefulWidget {
  const LoyaltyDashboardScreen({super.key});

  @override
  State<LoyaltyDashboardScreen> createState() => _LoyaltyDashboardScreenState();
}

class _LoyaltyDashboardScreenState extends State<LoyaltyDashboardScreen> {
  final LoyaltyService _loyaltyService = LoyaltyService.instance;
  Map<String, dynamic>? loyaltyData;
  List<Map<String, dynamic>> coupons = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLoyaltyData();
  }

  Future<void> _loadLoyaltyData() async {
    try {
      final data = await _loyaltyService.getLoyaltyData();
      final availableCoupons = await _loyaltyService.getAvailableCoupons();
      if (mounted) {
        setState(() {
          loyaltyData = data;
          coupons = availableCoupons;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = loyaltyData?['points'] as int? ?? 0;
    final level = loyaltyData?['membership_level'] as String? ?? 'Bronce';

    return Scaffold(
      appBar: CustomAppBar(title: 'Programa de Fidelidad'),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadLoyaltyData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Level Card
                    _buildLevelCard(theme, points, level),
                    SizedBox(height: 4.h),

                    // Offers Header
                    Text(
                      'Mis Cupones y Ofertas',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2.h),

                    // Coupon List
                    if (coupons.isEmpty)
                      _buildEmptyCoupons(theme)
                    else
                      ...coupons.map((coupon) => _buildCouponCard(theme, coupon)),

                    SizedBox(height: 4.h),
                    
                    // Refer a Friend Card
                    _buildReferralCard(theme),
                    SizedBox(height: 4.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLevelCard(ThemeData theme, int points, String level) {
    Color levelColor = const Color(0xFF8B1538);
    IconData levelIcon = Icons.shield_outlined;
    
    if (level == 'Plata') levelColor = Colors.grey;
    if (level == 'Oro') levelColor = Colors.amber;
    if (level == 'Platino') levelColor = const Color(0xFFE5E4E2);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [levelColor, levelColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: levelColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Nivel $level',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 10.sp),
                  ),
                  Text(
                    '$points Puntos',
                    style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Icon(levelIcon, color: Colors.white, size: 40),
            ],
          ),
          SizedBox(height: 3.h),
          LinearProgressIndicator(
            value: (points % 1000) / 1000,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 1.h),
          Text(
            '${1000 - (points % 1000)} puntos para el siguiente nivel',
            style: TextStyle(color: Colors.white, fontSize: 8.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCard(ThemeData theme, Map<String, dynamic> coupon) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: const Color(0xFF8B1538).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.confirmation_number_outlined, color: Color(0xFF8B1538)),
        ),
        title: Text(coupon['title'] ?? 'Descuento Especial', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(coupon['description'] ?? 'Canjea este código en tu próxima renta'),
        trailing: Text(
          '${coupon['discount']}% OFF',
          style: const TextStyle(color: Color(0xFF8B1538), fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyCoupons(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(Icons.redeem_outlined, size: 40, color: Colors.grey[400]),
          SizedBox(height: 1.h),
          const Text('No hay cupones activos en este momento', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildReferralCard(ThemeData theme) {
    final referralCode = loyaltyData?['referral_code'] ?? 'MAXIMUS123';
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: const Color(0xFFE8B4B8).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B1538).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.people_outline, color: Color(0xFF8B1538)),
              SizedBox(width: 3.w),
              Text('Refiere y Gana', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp)),
            ],
          ),
          SizedBox(height: 1.h),
          const Text('Comparte tu código y ambos recibirán \$10 de crédito al completar su primera renta.'),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(referralCode, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp, letterSpacing: 2)),
                const Icon(Icons.copy, size: 18, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
