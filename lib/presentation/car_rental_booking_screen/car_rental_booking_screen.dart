import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../widgets/custom_app_bar.dart';
import './widgets/additional_services_widget.dart';
import './widgets/date_time_picker_widget.dart';
import './widgets/location_selector_widget.dart';
import './widgets/pricing_breakdown_widget.dart';
import '../../widgets/mapbox_location_picker_widget.dart';

class CarRentalBookingScreen extends StatefulWidget {
  const CarRentalBookingScreen({super.key});

  @override
  State<CarRentalBookingScreen> createState() => _CarRentalBookingScreenState();
}

class _CarRentalBookingScreenState extends State<CarRentalBookingScreen> {
  // Selected vehicle
  Map<String, dynamic>? selectedVehicle;

  // Date and time selections
  DateTime? pickupDate;
  TimeOfDay? pickupTime;
  DateTime? returnDate;
  TimeOfDay? returnTime;

  // Location selections
  String pickupLocation = '';
  String dropoffLocation = '';
  double? pickupLat;
  double? pickupLng;
  double? dropoffLat;
  double? dropoffLng;

  // Additional services
  Map<String, bool> additionalServices = {
    'gps': false,
    'childSeat': false,
    'additionalDriver': false,
    'premiumInsurance': false,
  };

  // Loading states
  bool isLoadingVehicles = false;
  bool isSubmittingBooking = false;

  // Available vehicles
  final List<Map<String, dynamic>> vehicles = [
    {
      'id': 1,
      'make': 'Mercedes-Benz',
      'model': 'Clase S',
      'year': 2024,
      'transmission': 'Automático',
      'fuelType': 'Híbrido',
      'dailyRate': 250.00,
      'available': true,
      'image': 'https://images.unsplash.com/photo-1639927659853-4c53905a22ad',
      'semanticLabel':
          'Mercedes-Benz Clase S negro estacionado frente a edificio moderno',
      'seats': 5,
      'luggage': 3,
    },
    {
      'id': 2,
      'make': 'BMW',
      'model': 'Serie 7',
      'year': 2024,
      'transmission': 'Automático',
      'fuelType': 'Gasolina',
      'dailyRate': 230.00,
      'available': true,
      'image': 'https://images.unsplash.com/photo-1713642501060-d0d29875662e',
      'semanticLabel': 'BMW Serie 7 azul oscuro en carretera al atardecer',
      'seats': 5,
      'luggage': 3,
    },
    {
      'id': 3,
      'make': 'Audi',
      'model': 'A8',
      'year': 2024,
      'transmission': 'Automático',
      'fuelType': 'Diésel',
      'dailyRate': 220.00,
      'available': true,
      'image': 'https://images.unsplash.com/photo-1623237209189-38436043387d',
      'semanticLabel':
          'Audi A8 gris plateado estacionado en zona urbana moderna',
      'seats': 5,
      'luggage': 3,
    },
    {
      'id': 4,
      'make': 'Tesla',
      'model': 'Model S',
      'year': 2024,
      'transmission': 'Automático',
      'fuelType': 'Eléctrico',
      'dailyRate': 280.00,
      'available': false,
      'image':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1b4e29ffe-1767781286635.png',
      'semanticLabel': 'Tesla Model S rojo brillante en estación de carga',
      'seats': 5,
      'luggage': 2,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Alquiler de Coches',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Vehículos Disponibles', theme),
              SizedBox(height: 2.h),
              _buildVehiclesListWidget(),
              SizedBox(height: 3.h),
              if (selectedVehicle != null) ...[
                _buildSectionHeader('Detalles de Reserva', theme),
                SizedBox(height: 2.h),
                DateTimePickerWidget(
                  pickupDate: pickupDate,
                  pickupTime: pickupTime,
                  returnDate: returnDate,
                  returnTime: returnTime,
                  onPickupDateSelected: (date) {
                    setState(() => pickupDate = date);
                  },
                  onPickupTimeSelected: (time) {
                    setState(() => pickupTime = time);
                  },
                  onReturnDateSelected: (date) {
                    setState(() => returnDate = date);
                  },
                  onReturnTimeSelected: (time) {
                    setState(() => returnTime = time);
                  },
                ),
                SizedBox(height: 2.h),
                LocationSelectorWidget(
                  pickupLocation: pickupLocation,
                  dropoffLocation: dropoffLocation,
                  onPickupLocationChanged: (location) {
                    setState(() => pickupLocation = location);
                  },
                  onDropoffLocationChanged: (location) {
                    setState(() => dropoffLocation = location);
                  },
                ),
                SizedBox(height: 2.h),

                // Interactive Map for Pickup Location
                Text(
                  'Seleccionar Ubicación de Recogida en Mapa',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 1.h),
                MapboxLocationPickerWidget(
                  initialLatitude: pickupLat,
                  initialLongitude: pickupLng,
                  defaultLatitude: 25.7617,
                  defaultLongitude: -80.1918,
                  onLocationSelected: (lat, lng, address) {
                    setState(() {
                      pickupLat = lat;
                      pickupLng = lng;
                      pickupLocation =
                          'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
                    });
                  },
                ),
                SizedBox(height: 2.h),

                // Interactive Map for Dropoff Location
                Text(
                  'Seleccionar Ubicación de Devolución en Mapa',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 1.h),
                MapboxLocationPickerWidget(
                  initialLatitude: dropoffLat,
                  initialLongitude: dropoffLng,
                  defaultLatitude: 25.7617,
                  defaultLongitude: -80.1918,
                  onLocationSelected: (lat, lng, address) {
                    setState(() {
                      dropoffLat = lat;
                      dropoffLng = lng;
                      dropoffLocation =
                          'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
                    });
                  },
                ),
                SizedBox(height: 2.h),
                AdditionalServicesWidget(
                  services: additionalServices,
                  onServiceChanged: (service, value) {
                    setState(() => additionalServices[service] = value);
                  },
                ),
                SizedBox(height: 2.h),
                PricingBreakdownWidget(
                  selectedVehicle: selectedVehicle!,
                  pickupDate: pickupDate,
                  returnDate: returnDate,
                  additionalServices: additionalServices,
                ),
                SizedBox(height: 3.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSubmitBooking() && !isSubmittingBooking
                        ? _submitBooking
                        : null,
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
                            'Confirmar Reserva',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
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

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildVehiclesListWidget() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = vehicles[index];
        return Card(
          child: ListTile(
            title: Text('${vehicle['make']} ${vehicle['model']}'),
            subtitle: Text('Daily Rate: \$${vehicle['dailyRate']}'),
            onTap: vehicle['available'] as bool
                ? () {
                    setState(() {
                      selectedVehicle = vehicle;
                    });
                  }
                : null,
          ),
        );
      },
    );
  }

  bool _canSubmitBooking() {
    return selectedVehicle != null &&
        pickupDate != null &&
        pickupTime != null &&
        returnDate != null &&
        returnTime != null &&
        pickupLocation.isNotEmpty &&
        dropoffLocation.isNotEmpty;
  }

  Future<void> _submitBooking() async {
    if (!_canSubmitBooking()) return;

    setState(() {
      isSubmittingBooking = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      isSubmittingBooking = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reserva confirmada: ${selectedVehicle!['make']} ${selectedVehicle!['model']}',
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 3),
      ),
    );

    Navigator.pop(context);
  }
}
