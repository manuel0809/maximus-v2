import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/distance_calculator_service.dart';
import '../../services/guest_booking_service.dart';
import '../../services/pricing_calculator_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../personal_transport_service_screen/widgets/service_type_card_widget.dart';
import '../personal_transport_service_screen/widgets/route_planner_widget.dart';
import '../personal_transport_service_screen/widgets/transport_pricing_widget.dart';

class GuestBookingFlowScreen extends StatefulWidget {
  const GuestBookingFlowScreen({super.key});

  @override
  State<GuestBookingFlowScreen> createState() => _GuestBookingFlowScreenState();
}

class _GuestBookingFlowScreenState extends State<GuestBookingFlowScreen> {
  // Service type selection
  String? selectedServiceType;

  // Route details
  String pickupLocation = '';
  String dropoffLocation = '';
  DateTime? serviceDate;
  TimeOfDay? serviceTime;

  // Location coordinates
  Map<String, double>? pickupCoordinates;
  Map<String, double>? dropoffCoordinates;

  // Distance and pricing
  double? distanceMiles;
  int? durationMinutes;
  double? estimatedPrice;

  // Booking details
  int passengerCount = 1;
  int serviceDurationHours = 2;
  String specialRequirements = '';

  // Guest information
  String guestName = '';
  String guestEmail = '';
  String guestPhone = '';

  // Loading states
  bool isSubmittingBooking = false;
  bool isCalculatingPrice = false;
  bool showGuestForm = false;

  final List<Map<String, dynamic>> serviceTypes = [
    {
      'id': 'black',
      'title': 'BLACK',
      'description': 'Servicio premium para hasta 4 personas',
      'icon': 'directions_car',
      'capacity': 'Máximo 4 personas',
      'baseInfo': 'Tarifa base \$15.00 + \$4.50/milla + \$1.50/min',
      'maxPersons': 4,
      'vehicleImage': 'assets/images/Untitled-1770905042048.jpeg',
      'rates': {
        'baseFare': '\$15.00',
        'perMile': '\$4.50',
        'perMinute': '\$1.50',
        'minimum': '\$65.00',
        'airport': '+\$15',
      },
    },
    {
      'id': 'black_suv',
      'title': 'BLACK SUV',
      'description': 'Servicio premium SUV para hasta 6 personas',
      'icon': 'airport_shuttle',
      'capacity': 'Máximo 6 personas',
      'baseInfo': 'Tarifa base \$20.00 + \$5.50/milla + \$1.75/min',
      'maxPersons': 6,
      'vehicleImage': 'assets/images/Untitled-1770905177629.jpeg',
      'rates': {
        'baseFare': '\$20.00',
        'perMile': '\$5.50',
        'perMinute': '\$1.75',
        'minimum': '\$85.00',
        'airport': '+\$20',
      },
    },
    {
      'id': 'black_evento',
      'title': 'BLACK EVENTO',
      'description': 'Servicio premium para eventos especiales',
      'icon': 'event',
      'capacity': 'Servicio personalizado',
      'baseInfo': 'Tarifa personalizada según evento',
      'maxPersons': 6,
      'vehicleImage': 'assets/images/Untitled-1770905177629.jpeg',
    },
    {
      'id': 'black_por_hora',
      'title': 'BLACK POR HORAS',
      'description': 'Servicio premium por horas con conductor',
      'icon': 'schedule',
      'capacity': 'Servicio por tiempo',
      'baseInfo': '\$85/hora (mín. 2h) - BLACK | \$110/hora (mín. 2h) - SUV',
      'maxPersons': 6,
      'vehicleImage': 'assets/images/Untitled-1770905177629.jpeg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Reserva como Invitado',
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(
                context,
                '/login-registration-screen',
              );
            },
            child: Text(
              'Iniciar Sesión',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Guest Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 18.sp,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Modo Invitado',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),

              // Service Type Selection
              Text(
                'Selecciona el Servicio BLACK',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 2.h),
              ...serviceTypes.map((service) {
                return ServiceTypeCardWidget(
                  service: service,
                  isSelected: selectedServiceType == service['id'],
                  isAdmin: false,
                  onTap: () {
                    setState(() {
                      selectedServiceType = service['id'] as String?;
                      showGuestForm = false;
                    });
                  },
                );
              }),

              if (selectedServiceType != null) ...[
                SizedBox(height: 3.h),

                // Route Planner
                RoutePlannerWidget(
                  pickupLocation: pickupLocation,
                  dropoffLocation: dropoffLocation,
                  stopLocation: '',
                  hasStop: false,
                  serviceDate: serviceDate,
                  serviceTime: serviceTime,
                  onPickupLocationChanged: (loc, lat, lng) {
                    setState(() {
                      pickupLocation = loc;
                      if (lat != null && lng != null) {
                        pickupCoordinates = {'lat': lat, 'lng': lng};
                      }
                    });
                  },
                  onDropoffLocationChanged: (loc, lat, lng) {
                    setState(() {
                      dropoffLocation = loc;
                      if (lat != null && lng != null) {
                        dropoffCoordinates = {'lat': lat, 'lng': lng};
                      }
                    });
                  },
                  onStopLocationChanged: (_, __, ___) {},
                  onToggleStop: (_) {},
                  onDateSelected: (date) => setState(() => serviceDate = date),
                  onTimeSelected: (time) => setState(() => serviceTime = time),
                ),
                SizedBox(height: 2.h),

                // Calculate Price Button
                if (pickupLocation.isNotEmpty &&
                    dropoffLocation.isNotEmpty &&
                    serviceDate != null &&
                    serviceTime != null)
                  ElevatedButton(
                    onPressed: isCalculatingPrice ? null : _calculatePrice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      minimumSize: Size(double.infinity, 6.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: isCalculatingPrice
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Text(
                            'Calcular Precio',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),

                // Pricing Display
                if (estimatedPrice != null) ...[
                  SizedBox(height: 3.h),
                  TransportPricingWidget(
                    distanceMiles: distanceMiles ?? 0.0,
                    durationMinutes: durationMinutes ?? 0,
                    totalPrice: estimatedPrice ?? 0.0,
                    isAdmin: false,
                    serviceType: selectedServiceType ?? 'black',
                    isAirportService: false,
                    serviceDateTime: serviceDate != null 
                        ? DateTime(serviceDate!.year, serviceDate!.month, serviceDate!.day, serviceTime?.hour ?? 0, serviceTime?.minute ?? 0)
                        : DateTime.now(),
                  ),
                  SizedBox(height: 2.h),

                  // Show Guest Form Button
                  if (!showGuestForm)
                    ElevatedButton(
                      onPressed: () {
                        setState(() => showGuestForm = true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        minimumSize: Size(double.infinity, 6.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: Text(
                        'Continuar con la Reserva',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],

                // Guest Information Form
                if (showGuestForm) ...[
                  SizedBox(height: 3.h),
                  _buildGuestInfoForm(theme),
                  SizedBox(height: 2.h),

                  // Submit Guest Booking Button
                  ElevatedButton(
                    onPressed: isSubmittingBooking ? null : _submitGuestBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B1538),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 1.8.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: isSubmittingBooking
                        ? SizedBox(
                            height: 2.h,
                            width: 2.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Confirmar Reserva como Invitado',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _calculatePrice() async {
    if (pickupCoordinates == null || dropoffCoordinates == null || selectedServiceType == null) return;

    setState(() => isCalculatingPrice = true);

    final distanceResult = DistanceCalculatorService.calculateDistance(
      pickupCoordinates!['lat']!,
      pickupCoordinates!['lng']!,
      dropoffCoordinates!['lat']!,
      dropoffCoordinates!['lng']!,
    );

    setState(() {
      distanceMiles = distanceResult;
      durationMinutes = (distanceResult * 2).toInt(); // Estimate
    });

    final price = PricingCalculatorService.calculateBlackPrice(
      distanceMiles: distanceResult,
      durationMinutes: durationMinutes!,
      isPeakHour: PricingCalculatorService.isPeakHour(serviceDate ?? DateTime.now()),
      isAirport: false,
    );

    setState(() {
      estimatedPrice = price;
      isCalculatingPrice = false;
    });
  }

  Widget _buildGuestInfoForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información de Contacto',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Nombre Completo',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => guestName = value),
        ),
        SizedBox(height: 2.h),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Correo Electrónico',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) => setState(() => guestEmail = value),
        ),
        SizedBox(height: 2.h),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Teléfono',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          onChanged: (value) => setState(() => guestPhone = value),
        ),
      ],
    );
  }

  Future<void> _submitGuestBooking() async {
    // Validate guest information
    if (guestName.trim().isEmpty ||
        guestEmail.trim().isEmpty ||
        guestPhone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor complete todos los campos'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => isSubmittingBooking = true);

    // Save guest session
    await GuestBookingService.instance.saveGuestSession({
      'guestName': guestName,
      'guestEmail': guestEmail,
      'guestPhone': guestPhone,
      'serviceType': selectedServiceType,
      'pickupLocation': pickupLocation,
      'dropoffLocation': dropoffLocation,
      'tripDate': serviceDate!.toIso8601String(),
      'estimatedPrice': estimatedPrice,
    });

    // Submit guest booking
    final result = await GuestBookingService.instance.submitGuestBooking(
      guestName: guestName.trim(),
      guestEmail: guestEmail.trim(),
      guestPhone: guestPhone.trim(),
      serviceType: selectedServiceType!,
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      tripDate: DateTime(
        serviceDate!.year,
        serviceDate!.month,
        serviceDate!.day,
        serviceTime!.hour,
        serviceTime!.minute,
      ),
      durationMinutes: durationMinutes,
      distanceKm: distanceMiles != null ? distanceMiles! * 1.60934 : null,
      cost: estimatedPrice,
      passengerCount: passengerCount,
      specialRequirements: specialRequirements.isNotEmpty
          ? specialRequirements
          : null,
    );

    setState(() => isSubmittingBooking = false);

    if (mounted) {
      if (result['success'] == true) {
        // Navigate to registration prompt screen
        Navigator.pushReplacementNamed(
          context,
          '/guest-registration-prompt-screen',
          arguments: {
            'bookingReference': result['bookingReference'],
            'guestName': guestName,
            'guestEmail': guestEmail,
            'guestPhone': guestPhone,
            'estimatedPrice': estimatedPrice,
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear la reserva: ${result['error']}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
