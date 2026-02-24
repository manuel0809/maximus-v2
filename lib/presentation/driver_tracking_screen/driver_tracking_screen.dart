import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/messaging_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/driver_info_card_widget.dart';
import './widgets/tracking_map_widget_io.dart';
import './widgets/trip_details_panel_widget.dart';

class DriverTrackingScreen extends StatefulWidget {
  const DriverTrackingScreen({super.key});

  @override
  State<DriverTrackingScreen> createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends State<DriverTrackingScreen> {
  double driverLat = 25.7617;
  double driverLng = -80.1918;

  final double pickupLat = 25.7907;
  final double pickupLng = -80.1300;

  int etaMinutes = 8;
  double distanceMiles = 3.2;
  String driverStatus = 'En camino';

  Timer? _locationUpdateTimer;
  bool _showTripDetails = false;

  final Map<String, dynamic> driverInfo = {
    'name': 'Carlos Rodríguez',
    'photo':
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
    'rating': 4.9,
    'totalTrips': 1247,
    'yearsOfService': 5,
    'vehicle': {
      'make': 'Mercedes-Benz',
      'model': 'S-Class',
      'color': 'Negro',
      'plate': 'ABC-1234',
      'year': 2023,
    },
    'phone': '+1 (305) 555-0123',
  };

  final MessagingService _messagingService = MessagingService.instance;
  String? _driverPhoneNumber;
  String? _driverId;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
    _loadDriverPhoneNumber();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && etaMinutes > 0) {
        setState(() {
          driverLat += (pickupLat - driverLat) * 0.1;
          driverLng += (pickupLng - driverLng) * 0.1;

          distanceMiles = distanceMiles * 0.9;
          if (distanceMiles < 0.1) {
            etaMinutes = 0;
            driverStatus = 'Llegó';
            timer.cancel();
            _showArrivalNotification();
          } else {
            etaMinutes = (distanceMiles * 3).round();
          }
        });
      }
    });
  }

  void _showArrivalNotification() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¡Tu conductor ha llegado!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            SizedBox(height: 2.h),
            Text(
              '${driverInfo['name']} está esperando',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Vehículo: ${driverInfo['vehicle']['color']} ${driverInfo['vehicle']['make']} ${driverInfo['vehicle']['model']}',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            Text(
              'Placa: ${driverInfo['vehicle']['plate']}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }



  Future<void> _handleCallDriver() async {
    if (_driverPhoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Número de teléfono no disponible'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final uri = Uri.parse('tel:$_driverPhoneNumber');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se puede realizar la llamada'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al llamar: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleMessageDriver() {
    if (_driverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Información del conductor no disponible'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/messaging-screen',
      arguments: {
        'userId': _driverId,
        'user': {'full_name': driverInfo['name'], 'role': 'driver'},
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: CustomAppBar(title: 'Seguimiento del Conductor'),
      body: Container(
        width: 100.w,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            TrackingMapWidget(
              driverLat: driverLat,
              driverLng: driverLng,
              pickupLat: pickupLat,
              pickupLng: pickupLng,
              driverName: driverInfo['name'] as String,
              vehicleModel: '${driverInfo['vehicle']['make']} ${driverInfo['vehicle']['model']}',
              vehiclePlate: driverInfo['vehicle']['plate'] as String,
            ),
    
            Positioned(
              left: 4.w,
              right: 4.w,
              bottom: 4.h,
              child: DriverInfoCardWidget(
                driverInfo: driverInfo,
                etaMinutes: etaMinutes,
                distanceMiles: distanceMiles,
                driverStatus: driverStatus,
                onCallPressed: _handleCallDriver,
                onMessagePressed: _handleMessageDriver,
              ),
            ),

          if (_showTripDetails)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity! > 0) {
                    setState(() {
                      _showTripDetails = false;
                    });
                  }
                },
                child: TripDetailsPanelWidget(
                  pickupLocation: 'Miami Beach, FL',
                  dropoffLocation: 'Miami International Airport',
                  estimatedFare: '\$45.00',
                  specialInstructions: 'Vuelo a las 3:00 PM - Terminal Norte',
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Future<void> _loadDriverPhoneNumber() async {
    const mockDriverId = 'driver@maximus.com';
    try {
      final phone = await _messagingService.getDriverPhoneNumber(mockDriverId);
      setState(() {
        _driverPhoneNumber = phone;
        _driverId = mockDriverId;
      });
    } catch (e) {
      // Silent fail
    }
  }
}
