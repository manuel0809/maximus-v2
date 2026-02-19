import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PricingBreakdownWidget extends StatelessWidget {
  final Map<String, dynamic>? selectedVehicle;
  final DateTime? pickupDate;
  final DateTime? returnDate;
  final Map<String, bool> additionalServices;

  const PricingBreakdownWidget({
    super.key,
    required this.selectedVehicle,
    required this.pickupDate,
    required this.returnDate,
    required this.additionalServices,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (selectedVehicle == null || pickupDate == null || returnDate == null) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Center(
          child: Text(
            'Seleccione un vehículo y fechas para ver el precio',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final int days = returnDate!.difference(pickupDate!).inDays + 1;
    final double dailyRate = selectedVehicle!['dailyRate'] as double;
    final double baseRate = dailyRate * days;
    final double taxRate = 0.21;
    final double taxes = baseRate * taxRate;
    final double insurance = 15.00 * days;
    final double additionalServicesCost = _calculateAdditionalServices(days);
    final double total = baseRate + taxes + insurance + additionalServicesCost;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          _buildPriceRow(
            context,
            'Tarifa base',
            '\$${dailyRate.toStringAsFixed(2)} × $days días',
            baseRate,
            false,
          ),
          SizedBox(height: 1.h),
          _buildPriceRow(context, 'Impuestos (IVA 21%)', '', taxes, false),
          SizedBox(height: 1.h),
          _buildPriceRow(
            context,
            'Seguro básico',
            '\$15.00 × $days días',
            insurance,
            false,
          ),
          if (additionalServicesCost > 0) ...[
            SizedBox(height: 1.h),
            _buildPriceRow(
              context,
              'Servicios adicionales',
              '',
              additionalServicesCost,
              false,
            ),
          ],
          SizedBox(height: 1.h),
          Divider(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
          SizedBox(height: 1.h),
          _buildPriceRow(context, 'Total', '', total, true),
        ],
      ),
    );
  }

  dynamic _buildPriceRow(
    dynamic context,
    String label,
    String subtitle,
    double amount,
    bool isTotal,
  ) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: isTotal
                    ? theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      )
                    : theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
              ),
              if (subtitle.isNotEmpty) ...[
                SizedBox(height: 0.3.h),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: isTotal
              ? theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                )
              : theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
        ),
      ],
    );
  }

  double _calculateAdditionalServices(int days) {
    double total = 0.0;

    if (additionalServices['gps'] == true) {
      total += 10.00 * days;
    }
    if (additionalServices['childSeat'] == true) {
      total += 8.00 * days;
    }
    if (additionalServices['additionalDriver'] == true) {
      total += 15.00 * days;
    }
    if (additionalServices['premiumInsurance'] == true) {
      total += 25.00 * days;
    }

    return total;
  }
}
