import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';
import '../../../services/loyalty_service.dart';

class BookingDetailsWidget extends StatefulWidget {
  final String serviceType;
  final int passengerCount;
  final String specialRequirements;
  final Map<String, bool> airportServices;
  final bool isGroupBooking;
  final int groupSize;
  final bool needsReturnTrip;
  final int serviceDurationHours;
  final Function(int) onPassengerCountChanged;
  final Function(String) onSpecialRequirementsChanged;
  final Function(String, bool) onAirportServiceChanged;
  final Function(bool) onGroupBookingChanged;
  final Function(int) onGroupSizeChanged;
  final Function(int) onReturnTripChanged;
  final Function(int) onServiceDurationChanged;
  final Function(Map<String, dynamic>) onCouponApplied;

  const BookingDetailsWidget({
    super.key,
    required this.serviceType,
    required this.passengerCount,
    required this.specialRequirements,
    required this.airportServices,
    required this.isGroupBooking,
    required this.groupSize,
    required this.needsReturnTrip,
    required this.serviceDurationHours,
    required this.onPassengerCountChanged,
    required this.onSpecialRequirementsChanged,
    required this.onAirportServiceChanged,
    required this.onGroupBookingChanged,
    required this.onGroupSizeChanged,
    required this.onReturnTripChanged,
    required this.onServiceDurationChanged,
    required this.onCouponApplied,
  });

  @override
  State<BookingDetailsWidget> createState() => _BookingDetailsWidgetState();
}

class _BookingDetailsWidgetState extends State<BookingDetailsWidget> {
  final TextEditingController _couponController = TextEditingController();
  bool _isValidating = false;
  String? _couponError;
  Map<String, dynamic>? _appliedCoupon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Passenger Count
          _buildPassengerCounter(context),
          SizedBox(height: 2.h),

          // Service Duration (for BLACK POR HORA and BLACK EVENTO)
          if (widget.serviceType == 'black_por_hora' ||
              widget.serviceType == 'black_evento') ...[
            _buildDurationSelector(context),
            SizedBox(height: 2.h),
          ],

          // Airport Services (if airport service type)
          if (widget.serviceType == 'airport') ...[
            _buildAirportServices(context),
            SizedBox(height: 2.h),
          ],

          // Event Transport Options (if event service type)
          if (widget.serviceType == 'event') ...[
            _buildEventOptions(context),
            SizedBox(height: 2.h),
          ],

          // Flight Details (Conditional for Airport)
          if (widget.serviceType == 'black' || widget.serviceType == 'black_suv') ...[
             _buildFlightDetails(context),
             SizedBox(height: 2.h),
          ],

          // Special Requirements
          _buildSpecialRequirements(context),
          SizedBox(height: 3.h),

          // Coupon Code
          _buildCouponSection(context),
        ],
      ),
    );
  }

  Widget _buildFlightDetails(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalles de Vuelo (Solo si aplica)',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: 'Aerolínea',
                  hintText: 'Ej: American',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: '# de Vuelo',
                  hintText: 'Ej: AA123',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleApplyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isValidating = true;
      _couponError = null;
    });

    try {
      final coupon = await LoyaltyService.instance.validateCoupon(code, 100.0); // Mock amount for now
      if (coupon != null) {
        setState(() {
          _appliedCoupon = coupon;
          _isValidating = false;
        });
        widget.onCouponApplied(coupon);
      } else {
        setState(() {
          _couponError = 'Código inválido o expirado';
          _isValidating = false;
        });
      }
    } catch (e) {
      setState(() {
        _couponError = 'Error al validar cupón';
        _isValidating = false;
      });
    }
  }

  Widget _buildCouponSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¿Tienes un cupón de descuento?',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.5.h),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _couponController,
                decoration: InputDecoration(
                  hintText: 'Ej: MAXIMUS5',
                  errorText: _couponError,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                ),
                enabled: _appliedCoupon == null,
              ),
            ),
            SizedBox(width: 2.w),
            ElevatedButton(
              onPressed: _appliedCoupon != null || _isValidating ? null : _handleApplyCoupon,
              style: ElevatedButton.styleFrom(
                backgroundColor: _appliedCoupon != null ? Colors.green : theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isValidating 
                ? SizedBox(height: 2.h, width: 2.h, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_appliedCoupon != null ? 'Aplicado' : 'Validar'),
            ),
          ],
        ),
        if (_appliedCoupon != null)
          Padding(
            padding: EdgeInsets.only(top: 1.h),
            child: Text(
              '¡Cupón aplicado! Descuento: ${_appliedCoupon!['discount_percentage']}%',
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildPassengerCounter(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Número de Pasajeros',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            IconButton(
              onPressed: widget.passengerCount > 1
                  ? () => widget.onPassengerCountChanged(widget.passengerCount - 1)
                  : null,
              icon: CustomIconWidget(
                iconName: 'remove_circle',
                color: widget.passengerCount > 1
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                size: 32,
              ),
            ),
            Container(
              width: 15.w,
              alignment: Alignment.center,
              child: Text(
                widget.passengerCount.toString(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            IconButton(
              onPressed: widget.passengerCount < 10
                  ? () => widget.onPassengerCountChanged(widget.passengerCount + 1)
                  : null,
              icon: CustomIconWidget(
                iconName: 'add_circle',
                color: widget.passengerCount < 10
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                size: 32,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAirportServices(BuildContext context) {
    final theme = Theme.of(context);

    final services = [
      {
        'key': 'flightTracking',
        'title': 'Seguimiento de Vuelo',
        'icon': 'flight',
      },
      {
        'key': 'meetAndGreet',
        'title': 'Servicio Meet & Greet',
        'icon': 'waving_hand',
      },
      {
        'key': 'luggageAssistance',
        'title': 'Asistencia con Equipaje',
        'icon': 'luggage',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Servicios de Aeropuerto',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        ...services.map((service) {
          final key = service['key'] as String;
          final isSelected = widget.airportServices[key] ?? false;

          return Padding(
            padding: EdgeInsets.only(bottom: 1.h),
            child: GestureDetector(
              onTap: () => widget.onAirportServiceChanged(key, !isSelected),
              child: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.1,
                        )
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: service['icon'] as String,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        service['title'] as String,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) =>
                          widget.onAirportServiceChanged(key, value ?? false),
                      activeColor: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildEventOptions(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opciones de Evento',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),

        // Group Booking
        GestureDetector(
          onTap: () => widget.onGroupBookingChanged(!widget.isGroupBooking),
          child: Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: widget.isGroupBooking
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: widget.isGroupBooking
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'groups',
                  color: widget.isGroupBooking
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Reserva Grupal',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Checkbox(
                  value: widget.isGroupBooking,
                  onChanged: (value) => widget.onGroupBookingChanged(value ?? false),
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),

        if (widget.isGroupBooking) ...[
          SizedBox(height: 1.h),
          Row(
            children: [
              Text(
                'Tamaño del Grupo:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(width: 2.w),
              IconButton(
                onPressed: widget.groupSize > 1
                    ? () => widget.onGroupSizeChanged(widget.groupSize - 1)
                    : null,
                icon: CustomIconWidget(
                  iconName: 'remove_circle',
                  color: widget.groupSize > 1
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.3,
                        ),
                  size: 24,
                ),
              ),
              Text(
                widget.groupSize.toString(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              IconButton(
                onPressed: widget.groupSize < 50
                    ? () => widget.onGroupSizeChanged(widget.groupSize + 1)
                    : null,
                icon: CustomIconWidget(
                  iconName: 'add_circle',
                  color: widget.groupSize < 50
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.3,
                        ),
                  size: 24,
                ),
              ),
            ],
          ),
        ],

        SizedBox(height: 1.h),

        // Return Trip
        GestureDetector(
          onTap: () => widget.onReturnTripChanged(!widget.needsReturnTrip ? 1 : 0),
          child: Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: widget.needsReturnTrip
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: widget.needsReturnTrip
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'swap_horiz',
                  color: widget.needsReturnTrip
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Viaje de Regreso',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Checkbox(
                  value: widget.needsReturnTrip,
                  onChanged: (value) => widget.onReturnTripChanged(value ?? false ? 1 : 0),
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialRequirements(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requisitos Especiales',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        TextField(
          onChanged: widget.onSpecialRequirementsChanged,
          maxLines: 3,
          decoration: InputDecoration(
            hintText:
                'Ej: Asiento para bebé, accesibilidad para silla de ruedas...',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.all(3.w),
          ),
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildDurationSelector(BuildContext context) {
    final theme = Theme.of(context);
    final label = widget.serviceType == 'black_por_hora'
        ? 'Duración del Servicio (Horas)'
        : 'Duración del Evento (Horas)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            IconButton(
              onPressed: widget.serviceDurationHours > 1
                  ? () => widget.onServiceDurationChanged(widget.serviceDurationHours - 1)
                  : null,
              icon: CustomIconWidget(
                iconName: 'remove_circle',
                color: widget.serviceDurationHours > 1
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                size: 32,
              ),
            ),
            Container(
              width: 15.w,
              alignment: Alignment.center,
              child: Text(
                widget.serviceDurationHours.toString(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            IconButton(
              onPressed: widget.serviceDurationHours < 12
                  ? () => widget.onServiceDurationChanged(widget.serviceDurationHours + 1)
                  : null,
              icon: CustomIconWidget(
                iconName: 'add_circle',
                color: widget.serviceDurationHours < 12
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                size: 32,
              ),
            ),
            SizedBox(width: 2.w),
            Text(
              'horas',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
