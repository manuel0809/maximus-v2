import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/loyalty_service.dart';

class CouponsAdminScreen extends StatefulWidget {
  const CouponsAdminScreen({super.key});

  @override
  State<CouponsAdminScreen> createState() => _CouponsAdminScreenState();
}

class _CouponsAdminScreenState extends State<CouponsAdminScreen> {
  final LoyaltyService _loyaltyService = LoyaltyService.instance;
  List<Map<String, dynamic>> _coupons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final coupons = await _loyaltyService.getAvailableCoupons();
      setState(() {
        _coupons = coupons;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Error al cargar cupones: $e')),
      );
    }
  }

  Future<void> _deleteCoupon(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _loyaltyService.deleteCoupon(id);
      _loadCoupons();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Cupón eliminado con éxito')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showAddCouponDialog() {
    final codeController = TextEditingController();
    final discountController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nuevo Cupón'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Código (ej: MAXIMUS10)',
                hintText: 'ESCRIBE_EL_CODIGO',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: discountController,
              decoration: const InputDecoration(
                labelText: 'Porcentaje de Descuento',
                suffixText: '%',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              final discount = double.tryParse(discountController.text) ?? 0;
              
              if (code.isNotEmpty && discount > 0) {
                Navigator.pop(context);
                try {
                  await _loyaltyService.createCoupon(
                    code: code,
                    discountPercentage: discount,
                  );
                  _loadCoupons();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Cupones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCoupons,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _coupons.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.loyalty_outlined, size: 64, color: theme.colorScheme.outline),
                      SizedBox(height: 2.h),
                      Text(
                        'No hay cupones activos',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _coupons.length,
                  itemBuilder: (context, index) {
                    final coupon = _coupons[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 2.h),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            '${coupon['discount_percentage']}%',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        title: Text(
                          coupon['code'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Activo • Descuento del ${coupon['discount_percentage']}%',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteCoupon(coupon['id'].toString()),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCouponDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Cupón'),
      ),
    );
  }
}
