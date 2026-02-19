import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/loyalty_service.dart';
import '../../../widgets/custom_app_bar.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final LoyaltyService _loyaltyService = LoyaltyService.instance;
  Map<String, dynamic>? profile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLoyaltyData();
  }

  Future<void> _loadLoyaltyData() async {
    final data = await _loyaltyService.getLoyaltyProfile();
    if (mounted) {
      setState(() {
        profile = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tier = profile?['tier'] ?? 'bronze';
    final benefits = _loyaltyService.getTierBenefits(tier);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Mis Recompensas'),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(5.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTrophyCard(theme, tier, benefits),
                  SizedBox(height: 4.h),
                  const Text('Puntos Acumulados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 1.h),
                  _buildPointsSection(theme),
                  SizedBox(height: 4.h),
                  const Text('Mis Beneficios VIP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 2.h),
                  _buildBenefitsList(theme, tier),
                ],
              ),
            ),
    );
  }

  Widget _buildTrophyCard(ThemeData theme, String tier, Map<String, dynamic> benefits) {
    Color tierColor;
    IconData tierIcon;
    
    switch (tier) {
      case 'platinum':
        tierColor = Colors.blueGrey[900]!;
        tierIcon = Icons.diamond;
        break;
      case 'gold':
        tierColor = const Color(0xFFD4AF37);
        tierIcon = Icons.workspace_premium;
        break;
      case 'silver':
        tierColor = Colors.grey;
        tierIcon = Icons.military_tech;
        break;
      default:
        tierColor = const Color(0xFFCD7F32);
        tierIcon = Icons.star_border;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tierColor, tierColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: tierColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(tierIcon, size: 60, color: Colors.white),
          SizedBox(height: 2.h),
          Text(
            benefits['label'].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          SizedBox(height: 1.h),
          Text(
            benefits['description'],
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Row(
          children: [
            const Icon(Icons.monetization_on, color: Colors.amber, size: 40),
            SizedBox(width: 4.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile?['points'] ?? 0}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                Text('Puntos Maximus', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              child: const Text('Cómo canjear'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsList(ThemeData theme, String currentTier) {
    final tiers = ['bronze', 'silver', 'gold', 'platinum'];
    return Column(
      children: tiers.map((t) {
        final b = _loyaltyService.getTierBenefits(t);
        final isCurrent = currentTier == t;
        return Card(
          elevation: isCurrent ? 4 : 1,
          margin: EdgeInsets.only(bottom: 2.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isCurrent ? const BorderSide(color: Color(0xFF8B1538), width: 2) : BorderSide.none,
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCurrent ? const Color(0xFF8B1538) : Colors.grey[200],
              child: Text('${(b['discount'] * 100).toInt()}%', style: TextStyle(color: isCurrent ? Colors.white : Colors.black)),
            ),
            title: Text(b['label'], style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
            subtitle: Text(b['description']),
            trailing: isCurrent ? const Icon(Icons.check_circle, color: Colors.green) : null,
          ),
        );
      }).toList(),
    );
  }
}
