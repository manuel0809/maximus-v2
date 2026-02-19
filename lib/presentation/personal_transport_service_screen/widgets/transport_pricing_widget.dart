import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';
import '../../../services/pricing_calculator_service.dart';

class TransportPricingWidget extends StatelessWidget {
  final double distanceMiles;
  final int durationMinutes;
  final double totalPrice;
  final double discountAmount;
  final bool isAdmin;
  final String serviceType;
  final bool isAirportService;
  final DateTime serviceDateTime;
  final Map<String, dynamic>? hourlyBreakdown;

  const TransportPricingWidget({
    super.key,
    required this.distanceMiles,
    required this.durationMinutes,
    required this.totalPrice,
    this.discountAmount = 0.0,
    required this.isAdmin,
    required this.serviceType,
    required this.isAirportService,
    required this.serviceDateTime,
    this.hourlyBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Map<String, dynamic>? adminBreakdown;
    if (isAdmin && !serviceType.contains('hourly')) {
      adminBreakdown = PricingCalculatorService.getPricingBreakdown(
        serviceType: serviceType.contains('suv') ? 'black_suv' : 'black',
        distanceMiles: distanceMiles,
        durationMinutes: durationMinutes,
        serviceDateTime: serviceDateTime,
        isAirport: isAirportService,
      );
    }

    // Determine if this is a distance-based service
    final bool isDistanceBased =
        serviceType == 'black' || serviceType == 'black_suv';
    final bool showDistanceInfo = isDistanceBased && distanceMiles > 0;

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
          if (showDistanceInfo) ...[
            _buildSummaryRow(
              context,
              'Distancia',
              '${distanceMiles.toStringAsFixed(1)} millas',
              Icons.straighten,
            ),
            SizedBox(height: 1.5.h),
          ],
          _buildSummaryRow(
            context,
            'Tiempo Estimado',
            durationMinutes >= 60
                ? '${(durationMinutes / 60).toStringAsFixed(1)} horas'
                : '$durationMinutes minutos',
            Icons.access_time,
          ),
          SizedBox(height: 1.5.h),

          if (hourlyBreakdown != null) ...[
            _buildSummaryRow(
              context,
              'Millas Incluidas',
              '${hourlyBreakdown!['miles_included']} millas',
              Icons.speed,
            ),
            SizedBox(height: 1.5.h),
            if (hourlyBreakdown!['surcharge_percent'] > 0) ...[
              _buildSummaryRow(
                context,
                'Recargos Aplicados',
                '+${(hourlyBreakdown!['surcharge_percent'] * 100).toInt()}%',
                Icons.trending_up,
                color: Colors.orange,
              ),
              SizedBox(height: 1.h),
              Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: Column(
                  children: (hourlyBreakdown!['surcharge_reasons'] as List<dynamic>).map((reason) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 0.5.h),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 14, color: Colors.orange.shade700),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              reason.toString(),
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange.shade900),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 1.5.h),
            ],
          ],

          if (discountAmount > 0) ...[
            _buildSummaryRow(
              context,
              'Descuento Aplicado',
              '-\$${discountAmount.toStringAsFixed(2)} USD',
              Icons.loyalty,
              color: Colors.green,
            ),
            SizedBox(height: 1.5.h),
          ],
          Divider(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          SizedBox(height: 1.5.h),
          _buildSummaryRow(
            context,
            'Precio Total',
            '\$${totalPrice.toStringAsFixed(2)} USD',
            Icons.payments,
            isTotal: true,
          ),

          if (isAdmin && adminBreakdown != null) ...[
            SizedBox(height: 2.h),
            Divider(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: theme.colorScheme.error,
                        size: 18,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'DESGLOSE ADMINISTRATIVO',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.5.h),
                  _buildAdminRow(
                    context,
                    'Tarifa Base',
                    adminBreakdown['baseFare'] as double,
                  ),
                  _buildAdminRow(
                    context,
                    'Costo por Distancia',
                    adminBreakdown['distanceCost'] as double,
                  ),
                  _buildAdminRow(
                    context,
                    'Costo por Tiempo',
                    adminBreakdown['timeCost'] as double,
                  ),
                  _buildAdminRow(
                    context,
                    'Subtotal',
                    adminBreakdown['subtotal'] as double,
                  ),
                  _buildAdminRow(
                    context,
                    'Ajuste Automático (${serviceType == "black_suv" ? "0.85" : "0.80"})',
                    adminBreakdown['adjustedTotal'] as double,
                  ),
                  if (adminBreakdown['minimumFareApplied'] as bool)
                    _buildAdminRow(
                      context,
                      'Tarifa Mínima Aplicada',
                      adminBreakdown['adjustedTotal'] as double,
                      isHighlight: true,
                    ),
                  if (adminBreakdown['peakHourAdjustment'] as double > 0)
                    _buildAdminRow(
                      context,
                      'Ajuste Hora Pico (+20%)',
                      adminBreakdown['peakHourAdjustment'] as double,
                    ),
                  if (adminBreakdown['airportFee'] as double > 0)
                    _buildAdminRow(
                      context,
                      'Tarifa Aeropuerto',
                      adminBreakdown['airportFee'] as double,
                    ),
                ],
              ),
            ),
          ],

          if (isAdmin && hourlyBreakdown != null) ...[
            SizedBox(height: 2.h),
            Divider(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: theme.colorScheme.error,
                        size: 18,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'DESGLOSE (POR HORA)',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.5.h),
                  _buildAdminRow(
                    context,
                    'Precio Base (Paquete)',
                    hourlyBreakdown!['base_price'] as double,
                  ),
                  _buildAdminRow(
                    context,
                    'Monto Recargos (%)',
                    hourlyBreakdown!['surcharge_amount'] as double,
                  ),
                  if (hourlyBreakdown!['fixed_surcharges'] > 0)
                    _buildAdminRow(
                      context,
                      'Cargos Fijos (Aero/Paradas)',
                      hourlyBreakdown!['fixed_surcharges'] as double,
                    ),
                ],
              ),
            ),
          ],

          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'info',
                  color: theme.colorScheme.primary,
                  size: 16,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    isAdmin
                        ? 'Los clientes solo ven el resumen final sin el desglose administrativo detallado'
                        : 'Precio calculado según duración, vehículo seleccionado y condiciones premium',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isTotal = false,
    Color? color,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          color: color ?? (isTotal
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant),
          size: isTotal ? 24 : 20,
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Text(
            label,
            style: isTotal
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  )
                : theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
        Text(
          value,
          style: isTotal
              ? theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                )
              : theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color ?? theme.colorScheme.onSurface,
                ),
        ),
      ],
    );
  }

  Widget _buildAdminRow(
    BuildContext context,
    String label,
    double amount, {
    bool isHighlight = false,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isHighlight
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
