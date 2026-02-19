import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

class PricingConfigModalWidget extends StatefulWidget {
  final String serviceName;
  final Map<String, dynamic> currentConfig;
  final Function(Map<String, dynamic>) onSave;

  const PricingConfigModalWidget({
    super.key,
    required this.serviceName,
    required this.currentConfig,
    required this.onSave,
  });

  @override
  State<PricingConfigModalWidget> createState() =>
      _PricingConfigModalWidgetState();
}

class _PricingConfigModalWidgetState extends State<PricingConfigModalWidget> {
  late TextEditingController _basePricePerMileController;
  late TextEditingController _passengerSurchargeController;
  late TextEditingController _basePricePerHourController;
  late TextEditingController _eventFeePerHourController;
  late TextEditingController _peakMultiplierController;

  @override
  void initState() {
    super.initState();
    _basePricePerMileController = TextEditingController(
      text: (widget.currentConfig['basePricePerMile'] ?? 2.5).toString(),
    );
    _passengerSurchargeController = TextEditingController(
      text: (widget.currentConfig['passengerSurcharge'] ?? 5.0).toString(),
    );
    _basePricePerHourController = TextEditingController(
      text: (widget.currentConfig['basePricePerHour'] ?? 50.0).toString(),
    );
    _eventFeePerHourController = TextEditingController(
      text: (widget.currentConfig['eventFeePerHour'] ?? 25.0).toString(),
    );
    _peakMultiplierController = TextEditingController(
      text: (widget.currentConfig['peakMultiplier'] ?? 1.3).toString(),
    );
  }

  @override
  void dispose() {
    _basePricePerMileController.dispose();
    _passengerSurchargeController.dispose();
    _basePricePerHourController.dispose();
    _eventFeePerHourController.dispose();
    _peakMultiplierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Container(
        constraints: BoxConstraints(maxWidth: 90.w, maxHeight: 80.h),
        padding: EdgeInsets.all(5.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CustomIconWidget(
                    iconName: 'attach_money',
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Configuración de Precios',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Text(
                widget.serviceName,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 3.h),

              // Base Price Per Mile
              _buildPriceField(
                context,
                'Costo Base por Milla',
                _basePricePerMileController,
                'Tarifa estándar por cada milla recorrida',
                '\$',
              ),
              SizedBox(height: 2.h),

              // Passenger Surcharge
              _buildPriceField(
                context,
                'Cargo por Pasajero Extra',
                _passengerSurchargeController,
                'Cargo adicional por cada pasajero extra',
                '\$',
              ),
              SizedBox(height: 2.h),

              // Base Price Per Hour (for hourly service)
              _buildPriceField(
                context,
                'Costo Base por Hora',
                _basePricePerHourController,
                'Tarifa estándar por hora de servicio',
                '\$',
              ),
              SizedBox(height: 2.h),

              // Event Fee Per Hour
              _buildPriceField(
                context,
                'Tarifa de Evento por Hora',
                _eventFeePerHourController,
                'Cargo adicional por hora para eventos',
                '\$',
              ),
              SizedBox(height: 2.h),

              // Peak Hour Multiplier
              _buildPriceField(
                context,
                'Multiplicador de Hora Pico',
                _peakMultiplierController,
                'Factor de multiplicación en horas pico (ej: 1.3 = 30% más)',
                'x',
              ),
              SizedBox(height: 2.h),

              // Peak Hours Info
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CustomIconWidget(
                          iconName: 'schedule',
                          color: theme.colorScheme.primary,
                          size: 18,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Horas Pico Configuradas',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Lunes a Viernes: 7:00-9:00 y 17:00-20:00',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 3.h),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveConfiguration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      ),
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceField(
    BuildContext context,
    String label,
    TextEditingController controller,
    String hint,
    String prefix,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          hint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 1.h),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            prefixText: prefix,
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 3.w,
              vertical: 1.5.h,
            ),
          ),
        ),
      ],
    );
  }

  void _saveConfiguration() {
    final config = {
      'basePricePerMile':
          double.tryParse(_basePricePerMileController.text) ?? 2.5,
      'passengerSurcharge':
          double.tryParse(_passengerSurchargeController.text) ?? 5.0,
      'basePricePerHour':
          double.tryParse(_basePricePerHourController.text) ?? 50.0,
      'eventBasePricePerMile':
          double.tryParse(_basePricePerMileController.text) ?? 3.0,
      'eventPassengerSurcharge':
          double.tryParse(_passengerSurchargeController.text) ?? 8.0,
      'eventFeePerHour':
          double.tryParse(_eventFeePerHourController.text) ?? 25.0,
      'hourlyPassengerSurcharge':
          double.tryParse(_passengerSurchargeController.text) ?? 10.0,
      'peakMultiplier': double.tryParse(_peakMultiplierController.text) ?? 1.3,
      'peakHours': [
        {
          'startHour': 7,
          'endHour': 9,
          'multiplier': double.tryParse(_peakMultiplierController.text) ?? 1.3,
        },
        {
          'startHour': 17,
          'endHour': 20,
          'multiplier': double.tryParse(_peakMultiplierController.text) ?? 1.3,
        },
      ],
    };

    widget.onSave(config);
    Navigator.pop(context);
  }
}
