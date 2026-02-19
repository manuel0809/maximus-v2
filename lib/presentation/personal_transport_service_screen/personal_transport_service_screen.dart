import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import '../../services/distance_calculator_service.dart';
import '../../services/pricing_calculator_service.dart';
import './widgets/service_type_card_widget.dart';
import './widgets/route_planner_widget.dart';
import './widgets/booking_details_widget.dart';
import './widgets/transport_pricing_widget.dart';
import '../../widgets/mapbox_location_picker_widget.dart';
import '../../widgets/premium_card.dart';
import '../../services/hourly_service.dart';
import 'package:intl/intl.dart';

class PersonalTransportServiceScreen extends StatefulWidget {
  const PersonalTransportServiceScreen({super.key});

  @override
  State<PersonalTransportServiceScreen> createState() =>
      _PersonalTransportServiceScreenState();
}

class _PersonalTransportServiceScreenState
    extends State<PersonalTransportServiceScreen> {
  // Service type selection
  String? selectedServiceType;
  String selectedRegion = 'miami_broward';

  // Route details
  String pickupLocation = '';
  String dropoffLocation = '';
  DateTime? serviceDate;
  TimeOfDay? serviceTime;

  // Location coordinates
  Map<String, double>? pickupCoordinates;
  Map<String, double>? dropoffCoordinates;
  double? pickupLat;
  double? pickupLng;
  double? dropoffLat;
  double? dropoffLng;

  // Distance and pricing
  double? distanceMiles;
  int? durationMinutes;
  double? estimatedPrice;

  // Stop details
  bool hasStop = false;
  String stopLocation = '';
  Map<String, double>? stopCoordinates;
  double? stopLat;
  double? stopLng;
  
  MapSelectionMode currentSelectionMode = MapSelectionMode.pickup;

  // Booking details
  int passengerCount = 1;
  int serviceDurationHours = 2;
  String specialRequirements = '';
  String preferredLanguage = 'Español';
  bool isAirportService = false;
  int groupSize = 1;

  // Loading states
  bool isSubmittingBooking = false;
  bool isCalculatingPrice = false;

  // Coupon state
  String? appliedCouponCode;
  double discountPercentage = 0.0;
  double discountAmount = 0.0;
  bool isValidatingCoupon = false;

  String? userEmail;
  bool get isAdmin => userEmail == 'admin@maximus.com';

  final List<Map<String, dynamic>> serviceTypes = [
    {
      'id': 'black',
      'title': '🖤 BLACK',
      'description': 'Sedán de lujo o SUV premium',
      'icon': 'directions_car',
      'capacity': 'Hasta 4 Pasajeros | 3 Maletas',
      'vehicleImage': 'assets/images/Untitled-1770905042048.jpeg',
      'promoBadge': '🎁 UPGRADE GRATIS a SUV de lujo',
      'pricing': {
        'baseFare': '\$15.00',
        'perMile': '\$4.50/milla',
        'perMinute': '\$1.50/min',
        'minimumFare': '\$65.00 mínimo',
        'hourlyRate': '\$85.00/hora',
        'airportFee': '+\$15.00 aeropuerto',
        'peakSurcharge': '+20% hora pico',
      },
    },
    {
      'id': 'black_suv',
      'title': '🖤 BLACK SUV',
      'description': 'SUV de lujo garantizado (Suburban, Yukon, Escalade)',
      'icon': 'airport_shuttle',
      'capacity': 'Hasta 7 Pasajeros | 5 Maletas',
      'vehicleImage': 'assets/images/Untitled-1770905177629.jpeg',
      'pricing': {
        'baseFare': '\$20.00',
        'perMile': '\$5.50/milla',
        'perMinute': '\$1.75/min',
        'minimumFare': '\$85.00 mínimo',
        'hourlyRate': '\$110.00/hora',
        'airportFee': '+\$20.00 aeropuerto',
        'peakSurcharge': '+20% hora pico',
      },
    },
    {
      'id': 'black_hourly',
      'title': '⏰ SERVICIO POR HORA',
      'description': 'Tu vehículo y conductor por horas (mín. 4h)',
      'icon': 'schedule',
      'capacity': 'Flexibilidad total premium',
      'vehicleImage': 'assets/images/Untitled-1770905177629.jpeg',
      'pricing': {
        'hourlySuburban': '\$165.00/hora (Suburban)',
        'hourlyYukon': '\$185.00/hora (Yukon)',
        'hourlyEscalade': '\$225.00/hora (Escalade)',
        'minimumHours': '4 horas mínimo',
      },
    },
  ];

  String selectedHourlyVehicle = 'suburban';

  String? airline;
  String? flightNumber;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    setState(() {
      userEmail = 'client@maximus.com';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: CustomAppBar(title: 'Transporte Personal BLACK'),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Region Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Región de Servicio',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'miami_broward', label: Text('Miami/Broward')),
                      ButtonSegment(value: 'orlando', label: Text('Orlando')),
                    ],
                    selected: {selectedRegion},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        selectedRegion = newSelection.first;
                        _calculatePriceEstimate();
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: 3.h),
              
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
                  isAdmin: isAdmin,
                  onTap: () {
                    setState(() {
                      selectedServiceType = service['id'] as String;
                      serviceDurationHours = 4; // Reset to 4h minimum for hourly
                      estimatedPrice = null;
                      distanceMiles = null;
                      _calculatePriceEstimate();
                    });
                  },
                );
              }),
              
              if (selectedServiceType == 'black_hourly') ...[
                SizedBox(height: 3.h),
                Text(
                  'Vehículo Premium Requerido',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 1.5.h),
                _buildHourlyVehicleSelector(theme),
              ],

              /* Price Table Removed */

              if (selectedServiceType != null) ...[
                SizedBox(height: 3.h),

                // Route Planning
                Text(
                  selectedServiceType == 'black_por_hora'
                      ? 'Punto de Inicio y Duración'
                      : 'Destino de Recogida y Destino Final',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2.h),
                RoutePlannerWidget(
                  pickupLocation: pickupLocation,
                  dropoffLocation: dropoffLocation,
                  stopLocation: stopLocation,
                  hasStop: hasStop,
                  serviceDate: serviceDate,
                  serviceTime: serviceTime,
                  onPickupLocationChanged: (value, lat, lng) {
                    setState(() {
                      pickupLocation = value;
                      final isAirport = value.toLowerCase().contains('airport') || 
                                      value.toLowerCase().contains('aeropuerto') ||
                                      ['mia', 'fll', 'pbi', 'mco'].any((code) => value.toLowerCase().contains(code));
                      if (isAirport) isAirportService = true;
                      
                      if (lat != null && lng != null) {
                        pickupCoordinates = {'latitude': lat, 'longitude': lng};
                        pickupLat = lat;
                        pickupLng = lng;
                      } else {
                        pickupCoordinates = DistanceCalculatorService.getCoordinatesForLocation(value);
                        if (pickupCoordinates != null) {
                           pickupLat = pickupCoordinates!['latitude'];
                           pickupLng = pickupCoordinates!['longitude'];
                        }
                      }
                      _calculatePriceEstimate();
                    });
                  },
                  onDropoffLocationChanged: (value, lat, lng) {
                    setState(() {
                      dropoffLocation = value;
                      final isAirport = value.toLowerCase().contains('airport') || 
                                      value.toLowerCase().contains('aeropuerto') ||
                                      ['mia', 'fll', 'pbi', 'mco'].any((code) => value.toLowerCase().contains(code));
                      if (isAirport) isAirportService = true;

                      if (lat != null && lng != null) {
                        dropoffCoordinates = {'latitude': lat, 'longitude': lng};
                        dropoffLat = lat;
                        dropoffLng = lng;
                      } else {
                        dropoffCoordinates = DistanceCalculatorService.getCoordinatesForLocation(value);
                        if (dropoffCoordinates != null) {
                           dropoffLat = dropoffCoordinates!['latitude'];
                           dropoffLng = dropoffCoordinates!['longitude'];
                        }
                      }
                      _calculatePriceEstimate();
                    });
                  },
                  onStopLocationChanged: (value, lat, lng) {
                    setState(() {
                      stopLocation = value;
                      if (lat != null && lng != null) {
                        stopCoordinates = {'latitude': lat, 'longitude': lng};
                        stopLat = lat;
                        stopLng = lng;
                      } else {
                        stopCoordinates =
                            DistanceCalculatorService.getCoordinatesForLocation(
                              value,
                            );
                        if (stopCoordinates != null) {
                           stopLat = stopCoordinates!['latitude'];
                           stopLng = stopCoordinates!['longitude'];
                        }
                      }
                      _calculatePriceEstimate();
                    });
                  },
                  onToggleStop: (value) {
                    setState(() {
                      hasStop = value;
                      if (!value) {
                        stopLocation = '';
                        stopCoordinates = null;
                        stopLat = null;
                        stopLng = null;
                      } else {
                        currentSelectionMode = MapSelectionMode.stop;
                      }
                      _calculatePriceEstimate();
                    });
                  },
                  onPickupTap: () => setState(
                      () => currentSelectionMode = MapSelectionMode.pickup),
                  onDropoffTap: () => setState(
                      () => currentSelectionMode = MapSelectionMode.dropoff),
                  onStopTap: () => setState(
                      () => currentSelectionMode = MapSelectionMode.stop),
                  onDateSelected: (date) {
                    setState(() {
                      serviceDate = date;
                      _calculatePriceEstimate();
                    });
                  },
                  onTimeSelected: (time) {
                    setState(() {
                      serviceTime = time;
                      _calculatePriceEstimate();
                    });
                  },
                ),

                SizedBox(height: 3.h),

              /* Estimated Price Table Removed */
              SizedBox(height: 3.h),



                // Booking Details
                Text(
                  'Detalles de la Reserva',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2.h),
                BookingDetailsWidget(
                  serviceType: selectedServiceType!,
                  passengerCount: passengerCount,
                  specialRequirements: specialRequirements,
                  airportServices: {},
                  isGroupBooking: false,
                  groupSize: 1,
                  needsReturnTrip: false,
                  serviceDurationHours: serviceDurationHours,
                  onPassengerCountChanged: (value) {
                    setState(() {
                      passengerCount = value;
                      _calculatePriceEstimate();
                    });
                  },
                  onServiceDurationChanged: (value) {
                    setState(() {
                      serviceDurationHours = value;
                      _calculatePriceEstimate();
                    });
                  },
                  onSpecialRequirementsChanged: (value) {
                    setState(() => specialRequirements = value);
                  },
                  onAirportServiceChanged: (key, value) {},
                  onGroupBookingChanged: (value) {},
                  onGroupSizeChanged: (value) {
                    setState(() {
                      groupSize = value;
                      _calculatePriceEstimate();
                    });
                  },
                  onReturnTripChanged: (value) {},
                  onCouponApplied: (coupon) {
                    setState(() {
                      appliedCouponCode = coupon['code'];
                      discountPercentage = (coupon['discount_percentage'] ?? 0.0) / 100.0;
                      _calculatePriceEstimate();
                    });
                  },
                ),

                // Airport Service Option
                if (selectedServiceType == 'black' ||
                    selectedServiceType == 'black_suv') ...[
                  SizedBox(height: 2.h),
                  PremiumCard(
                    padding: EdgeInsets.all(4.w),
                    borderRadius: 16,
                    useGlassmorphism: true,
                    opacity: 0.03,
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.flight_takeoff,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Servicio de Aeropuerto',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(height: 0.2.h),
                              Text(
                                selectedServiceType == 'black'
                                    ? 'Cargo adicional: \$15'
                                    : 'Cargo adicional: \$20',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isAirportService,
                          onChanged: (value) {
                            setState(() {
                              isAirportService = value;
                              _calculatePriceEstimate();
                            });
                          },
                          activeThumbColor: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 3.h),

                // Interactive Map with Route
                if (selectedServiceType != null &&
                    ((pickupCoordinates != null &&
                            dropoffCoordinates != null &&
                            distanceMiles != null &&
                            durationMinutes != null &&
                            estimatedPrice != null) ||
                        (selectedServiceType == 'black_por_hora' &&
                            estimatedPrice != null) ||
                        (selectedServiceType == 'black_evento' &&
                            estimatedPrice != null))) ...[
                  Text(
                    'Resumen del Servicio',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  TransportPricingWidget(
                    distanceMiles: distanceMiles ?? 0.0,
                    durationMinutes:
                        durationMinutes ?? serviceDurationHours * 60,
                    totalPrice: estimatedPrice!,
                    discountAmount: discountAmount,
                    isAdmin: isAdmin,
                    serviceType: selectedServiceType!,
                    isAirportService: isAirportService,
                    hourlyBreakdown: _hourlyBreakdown,
                    serviceDateTime: serviceDate != null && serviceTime != null
                        ? DateTime(
                            serviceDate!.year,
                            serviceDate!.month,
                            serviceDate!.day,
                            serviceTime!.hour,
                            serviceTime!.minute,
                          )
                        : DateTime.now(),
                  ),
                  SizedBox(height: 3.h),
                ],

                SizedBox(height: 3.h),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSubmitBooking() ? _submitBooking : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: isSubmittingBooking
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
                            'Confirmar Reserva',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _calculatePriceEstimate() {
    if (selectedServiceType == null) return;

    final mockVehicle = {
      'region': selectedRegion,
      'service_rates': {
        'black': {
          'miami_broward': {'base': 12.0, 'per_mile': 4.0, 'min_tariff': 35.0},
          'orlando': {'base': 10.0, 'per_mile': 3.75, 'min_tariff': 32.0},
        },
        'black_suv_regional': {
          'miami_broward': {'base': 20.0, 'per_mile': 5.25, 'min_tariff': 48.0},
          'orlando': {'base': 18.0, 'per_mile': 5.0, 'min_tariff': 45.0},
        },
        'black_hourly': {
          'miami_broward': {
            'unit': 85, 'min_hours': 3,
            'tiers': {'4h': 320, '6h': 460, '8h': 600, '10h': 730, '12h': 850}
          },
          'orlando': {
            'unit': 78, 'min_hours': 3,
            'tiers': {'4h': 295, '6h': 425, '8h': 555, '10h': 675, '12h': 790}
          }
        },
        'black_event': {
          'miami_broward': {
            'tiers': {'4h': 380, '6h': 550, '8h': 700, '10h': 850, '12h': 990, '16h': 1250}
          },
          'orlando': {
            'tiers': {'4h': 350, '6h': 505, '8h': 650, '10h': 790, '12h': 920, '16h': 1150}
          }
        },
        'black_inter_city': {
          'Miami <-> Fort Lauderdale': 105,
          'Miami <-> Orlando': 420,
          'Miami <-> West Palm Beach': 185,
        },
        'hourly_regional': {
          'miami_broward': {
            'unit': 115, 'min_hours': 3,
            'tiers': {'4h': 440, '6h': 630, '8h': 820, '10h': 1000, '12h': 1150}
          },
          'orlando': {
            'unit': 105, 'min_hours': 3,
            'tiers': {'4h': 400, '6h': 580, '8h': 750, '10h': 920, '12h': 1060}
          }
        },
        'inter_city': {
          'Miami <-> Fort Lauderdale': 138,
          'Miami <-> Orlando': 550,
          'Miami <-> West Palm Beach': 235,
        }
      },
      'metadata': {
        'airport': 'mia',
        'destination': dropoffLocation,
        'route': '$pickupLocation <-> $dropoffLocation',
      }
    };

    String activeServiceType = selectedServiceType!;
    
    // Standardize IDs for the pricing logic
    if (selectedServiceType == 'hourly_regional') activeServiceType = 'black_hourly';
    if (selectedServiceType == 'inter_city') activeServiceType = 'black_inter_city';

    if (activeServiceType.contains('hourly')) {
      final DateTime serviceDateTime = _getServiceDateTime();
      
      final hourlyResults = HourlyService.instance.calculatePrice(
        vehicleType: selectedHourlyVehicle,
        hours: serviceDurationHours,
        zone: selectedRegion,
        bookingDateTime: serviceDateTime,
        isAirport: isAirportService,
        additionalStops: hasStop ? 1 : 0,
      );

      setState(() {
        if (hourlyResults.containsKey('error')) {
          estimatedPrice = 0;
          // You might want to show a snackbar or error text here
        } else {
          estimatedPrice = (hourlyResults['total_price'] as num).toDouble();
          // Store breakdown for display
          _hourlyBreakdown = hourlyResults;
        }
      });
      return;
    }

    if (activeServiceType == 'black' || activeServiceType == 'black_suv_regional') {
      if (pickupCoordinates != null && dropoffCoordinates != null) {
        double distance = 0.0;
        if (hasStop && stopCoordinates != null) {
           final double dist1 = DistanceCalculatorService.calculateDistance(
            pickupCoordinates!['latitude']!, pickupCoordinates!['longitude']!,
            stopCoordinates!['latitude']!, stopCoordinates!['longitude']!,
          );
          final double dist2 = DistanceCalculatorService.calculateDistance(
            stopCoordinates!['latitude']!, stopCoordinates!['longitude']!,
            dropoffCoordinates!['latitude']!, dropoffCoordinates!['longitude']!,
          );
          distance = dist1 + dist2;
        } else {
          distance = DistanceCalculatorService.calculateDistance(
            pickupCoordinates!['latitude']!, pickupCoordinates!['longitude']!,
            dropoffCoordinates!['latitude']!, dropoffCoordinates!['longitude']!,
          );
        }

        final DateTime serviceDateTime = _getServiceDateTime();
        final double price = PricingCalculatorService.calculateDynamicTransportPrice(
          vehicle: mockVehicle,
          serviceType: activeServiceType,
          distanceKm: distance, 
          serviceDateTime: serviceDateTime,
        );

        setState(() {
          distanceMiles = distance;
          durationMinutes = (distance / 30 * 60).round();
          estimatedPrice = price;
        });
      }
      return;
    }

    if (activeServiceType == 'inter_city' || activeServiceType == 'black_inter_city') {
      final double price = PricingCalculatorService.calculateDynamicTransportPrice(
        vehicle: mockVehicle,
        serviceType: activeServiceType,
      );
      if (price > 0) {
        setState(() {
          estimatedPrice = price;
          distanceMiles = 0.0;
          durationMinutes = 120;
        });
      }
      return;
    }

    if (activeServiceType == 'airport_fixed' || activeServiceType == 'black_event') {
      final double price = PricingCalculatorService.calculateDynamicTransportPrice(
        vehicle: mockVehicle,
        serviceType: activeServiceType,
        hours: serviceDurationHours,
        serviceDateTime: _getServiceDateTime(),
      );
      
      setState(() {
        estimatedPrice = price;
        distanceMiles = 0.0;
        durationMinutes = activeServiceType == 'black_event' ? serviceDurationHours * 60 : 45;
      });
      return;
    }

    // Apply Coupon Discount if exists
    if (estimatedPrice != null && discountPercentage > 0) {
      setState(() {
        discountAmount = estimatedPrice! * discountPercentage;
        estimatedPrice = estimatedPrice! - discountAmount;
      });
    } else {
      setState(() {
        discountAmount = 0.0;
      });
    }
  }


  Map<String, dynamic>? _hourlyBreakdown;

  Widget _buildHourlyVehicleSelector(ThemeData theme) {
    final hourlyRates = HourlyService.instance.getVehicleRates();
    
    return Column(
      children: hourlyRates.entries.map((entry) {
        final vehicleKey = entry.key;
        final data = entry.value;
        final isSelected = selectedHourlyVehicle == vehicleKey;
        
        return Padding(
          padding: EdgeInsets.only(bottom: 1.5.h),
          child: InkWell(
            onTap: () {
              setState(() {
                selectedHourlyVehicle = vehicleKey;
                _calculatePriceEstimate();
              });
            },
            child: Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.1) : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12.w,
                    height: 12.w,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      vehicleKey == 'escalade' ? Icons.star : Icons.directions_car,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] as String,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Tarifa base: \$${data['hourly_rate']}/hr',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: theme.colorScheme.primary),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  DateTime _getServiceDateTime() {
    final now = DateTime.now();
    final date = serviceDate ?? now;
    final time = serviceTime ?? TimeOfDay.now();
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  bool _canSubmitBooking() {
    if (selectedServiceType == null) return false;
    if (isSubmittingBooking) return false;

    if (selectedServiceType == 'black_por_hora') {
      return pickupLocation.isNotEmpty &&
          serviceDate != null &&
          serviceTime != null &&
          serviceDurationHours > 0;
    }

    return pickupLocation.isNotEmpty &&
        dropoffLocation.isNotEmpty &&
        serviceDate != null &&
        serviceTime != null;
  }

  Future<void> _submitBooking() async {
    setState(() => isSubmittingBooking = true);

    await Future.delayed(const Duration(seconds: 2));

    setState(() => isSubmittingBooking = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reserva confirmada - Total: USD \$${estimatedPrice?.toStringAsFixed(2) ?? "0.00"}',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      Navigator.pop(context);
    }
  }
}