import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class VehicleFilterBottomSheet extends StatefulWidget {
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final String? initialTransmission;
  final int? initialPassengers;
  final Function(double?, double?, String?, int?) onApply;

  const VehicleFilterBottomSheet({
    super.key,
    this.initialMinPrice,
    this.initialMaxPrice,
    this.initialTransmission,
    this.initialPassengers,
    required this.onApply,
  });

  @override
  State<VehicleFilterBottomSheet> createState() => _VehicleFilterBottomSheetState();
}

class _VehicleFilterBottomSheetState extends State<VehicleFilterBottomSheet> {
  late RangeValues _priceRange;
  late String _transmission;
  late int _passengers;

  @override
  void initState() {
    super.initState();
    _priceRange = RangeValues(
      widget.initialMinPrice ?? 0,
      widget.initialMaxPrice ?? 1000,
    );
    _transmission = widget.initialTransmission ?? 'all';
    _passengers = widget.initialPassengers ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtros Avanzados',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          
          Text('Rango de Precio por día', style: theme.textTheme.titleMedium),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 2000,
            divisions: 20,
            activeColor: const Color(0xFF8B1538),
            labels: RangeLabels(
              '\$${_priceRange.start.round()}',
              '\$${_priceRange.end.round()}',
            ),
            onChanged: (values) => setState(() => _priceRange = values),
          ),
          
          SizedBox(height: 3.h),
          Text('Transmisión', style: theme.textTheme.titleMedium),
          SizedBox(height: 1.h),
          Row(
            children: [
              _buildChoiceChip('Cualquiera', 'all'),
              SizedBox(width: 2.w),
              _buildChoiceChip('Automático', 'automatic'),
              SizedBox(width: 2.w),
              _buildChoiceChip('Manual', 'manual'),
            ],
          ),

          SizedBox(height: 3.h),
          Text('Mínimo de Pasajeros', style: theme.textTheme.titleMedium),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [1, 2, 4, 5, 7].map((p) => ChoiceChip(
              label: Text('$p+'),
              selected: _passengers == p,
              onSelected: (selected) {
                if (selected) setState(() => _passengers = p);
              },
              selectedColor: const Color(0xFF8B1538).withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: _passengers == p ? const Color(0xFF8B1538) : null,
                fontWeight: _passengers == p ? FontWeight.bold : null,
              ),
            )).toList(),
          ),

          SizedBox(height: 4.h),
          SizedBox(
            width: double.infinity,
            height: 6.h,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(
                  _priceRange.start,
                  _priceRange.end,
                  _transmission,
                  _passengers,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B1538),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Aplicar Filtros', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, String value) {
    final isSelected = _transmission == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _transmission = value);
      },
      selectedColor: const Color(0xFF8B1538).withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF8B1538) : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }
}
