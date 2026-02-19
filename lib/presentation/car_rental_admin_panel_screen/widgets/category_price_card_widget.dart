import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../../services/supabase_service.dart';

class CategoryPriceCardWidget extends StatefulWidget {
  final Map<String, dynamic> category;
  final VoidCallback onPriceUpdated;

  const CategoryPriceCardWidget({
    super.key,
    required this.category,
    required this.onPriceUpdated,
  });

  @override
  State<CategoryPriceCardWidget> createState() =>
      _CategoryPriceCardWidgetState();
}

class _CategoryPriceCardWidgetState extends State<CategoryPriceCardWidget> {
  bool isEditing = false;
  bool isSaving = false;
  late TextEditingController priceController;

  @override
  void initState() {
    super.initState();
    priceController = TextEditingController(
      text: widget.category['base_price_per_day']?.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    priceController.dispose();
    super.dispose();
  }

  String _getCategoryIcon(String? icon) {
    switch (icon) {
      case '💰':
        return '💰';
      case '🚙':
        return '🚙';
      case '✨':
        return '✨';
      default:
        return '🚗';
    }
  }

  Color _getCategoryColor(String name) {
    switch (name.toLowerCase()) {
      case 'económico':
        return const Color(0xFF2E7D32);
      case 'suv':
        return const Color(0xFF1976D2);
      case 'lujo':
        return const Color(0xFF8B1538);
      default:
        return Colors.grey;
    }
  }

  Future<void> _updatePrice() async {
    final newPrice = double.tryParse(priceController.text);
    if (newPrice == null || newPrice <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingrese un precio válido')));
      return;
    }

    setState(() => isSaving = true);

    try {
      await SupabaseService.instance.client
          .from('vehicle_categories')
          .update({'base_price_per_day': newPrice})
          .eq('id', widget.category['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Precio actualizado exitosamente')),
        );
        setState(() => isEditing = false);
        widget.onPriceUpdated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(widget.category['name'] ?? '');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isEditing ? categoryColor : Colors.grey[300]!,
          width: isEditing ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Text(
            _getCategoryIcon(widget.category['icon']),
            style: TextStyle(fontSize: 32.sp),
          ),
          SizedBox(height: 1.h),
          // Category name
          Text(
            widget.category['name'] ?? '',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: categoryColor,
            ),
          ),
          SizedBox(height: 1.h),
          // Price editor
          if (isEditing)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: Column(
                children: [
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      suffixText: '/día',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 1.h,
                      ),
                    ),
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: isSaving
                            ? null
                            : () {
                                setState(() {
                                  isEditing = false;
                                  priceController.text =
                                      widget.category['base_price_per_day']
                                          ?.toString() ??
                                      '0';
                                });
                              },
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: isSaving ? null : _updatePrice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: categoryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: isSaving
                            ? SizedBox(
                                width: 12.sp,
                                height: 12.sp,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Guardar'),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                Text(
                  '\$${widget.category['base_price_per_day']?.toStringAsFixed(2) ?? '0.00'}/día',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 1.h),
                ElevatedButton.icon(
                  onPressed: () => setState(() => isEditing = true),
                  icon: Icon(Icons.edit, size: 14.sp),
                  label: const Text('Editar Precio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: categoryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.8.h,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
