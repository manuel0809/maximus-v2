import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/app_export.dart';
import '../../services/localization_service.dart';
import '../../services/notification_service.dart';
import '../../services/realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientDashboardInitialPage extends StatefulWidget {
  const ClientDashboardInitialPage({super.key});

  @override
  State<ClientDashboardInitialPage> createState() =>
      _ClientDashboardInitialPageState();
}

class _ClientDashboardInitialPageState
    extends State<ClientDashboardInitialPage> {
  String userName = "";
  String currentLocation = "";
  bool isLoadingLocation = true;
  bool isRefreshing = false;
  int unreadNotificationCount = 0;

  final NotificationService _notificationService = NotificationService.instance;
  final RealtimeService _realtimeService = RealtimeService.instance;

  Map<String, dynamic>? activeRental;

  final List<Map<String, dynamic>> suggestions = [
    {
      "id": 1,
      "title": "Ride",
      "description": "Viaje a cualquier lugar con Maximus. Pida un viaje, súbase y relájese.",
      "imageUrl": "https://pggvfqmldoizstoxunir.supabase.co/storage/v1/object/public/vehicle-images/fleet/luxury_sedan.png", // Replaced with a generic car image URL
      "route": "/car-rental-service-screen",
    },
    {
      "id": 2,
      "title": "Reserve",
      "description": "Reserve su viaje con anticipación para que pueda relajarse ese día.",
      "imageUrl": "https://pggvfqmldoizstoxunir.supabase.co/storage/v1/object/public/vehicle-images/fleet/calendar_icon.png", 
      "route": "/car-rental-booking-screen",
    },
    {
      "id": 3,
      "title": "Rental Cars",
      "description": "Su renta de vehículos perfecta está a unos clics de distancia.",
      "imageUrl": "https://pggvfqmldoizstoxunir.supabase.co/storage/v1/object/public/vehicle-images/fleet/car_key.png",
      "route": "/car-rental-service-screen",
    },
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadUnreadNotificationCount();
    _loadUserProfile();
    _loadActiveRental();
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      setState(() => unreadNotificationCount = count);
    } catch (e) {}
  }

  Future<void> _loadActiveRental() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final response = await Supabase.instance.client
          .from('rentals')
          .select('*, vehicles(*)')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .maybeSingle();
      if (mounted) setState(() => activeRental = response);
    } catch (e) {}
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _realtimeService.getCurrentUserProfile();
      if (profile != null && mounted) {
        setState(() => userName = profile['full_name'] ?? 'Usuario');
      }
    } catch (e) {}
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() { currentLocation = "Doral, Miami"; isLoadingLocation = false; });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { currentLocation = "Miami, FL"; isLoadingLocation = false; });
          return;
        }
      }
      Position position = await Geolocator.getCurrentPosition();
      final locationName = await _reverseGeocode(position.latitude, position.longitude);
      if (mounted) setState(() { currentLocation = locationName; isLoadingLocation = false; });
    } catch (e) {
      if (mounted) setState(() { currentLocation = "Miami, FL"; isLoadingLocation = false; });
    }
  }

  Future<String> _reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=10&addressdetails=1');
      final response = await http.get(url, headers: {'User-Agent': 'MaximusTransportApp/1.0'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          return address['city'] ?? address['town'] ?? 'Miami';
        }
      }
      return 'Miami';
    } catch (e) {
      return 'Miami';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            _buildHeader(),
            
            // --- MAIN CONTENT ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.black),
                      const SizedBox(width: 4),
                      Text(
                        currentLocation.isNotEmpty ? currentLocation : "Miami, FL",
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      const Text("Cambia tu ciudad", style: TextStyle(decoration: TextDecoration.underline, fontSize: 13, color: Colors.black54)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Viaja a cualquier lugar con la app de Maximus",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // --- PICKUP/DESTINATION INPUTS ---
                  _buildRideInputs(),
                  
                  const SizedBox(height: 12),
                  _buildBlackButton("Ver tarifas sugeridas"),
                  
                  const SizedBox(height: 48),
                  
                  // --- SUGGESTIONS ---
                  const Text(
                    "Sugerencias",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  
                  ...suggestions.map((s) => _buildSuggestionCard(s)).toList(),
                  
                  const SizedBox(height: 40),
                  
                  // --- RESERVE SECTION ---
                  _buildReserveSection(),
                  
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 12, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
             children: [
               SvgPicture.asset(
                 'assets/images/img_app_logo.svg',
                 height: 28,
                 colorFilter: const ColorFilter.mode(Color(0xFFD4AF37), BlendMode.srcIn),
               ),
               const SizedBox(width: 14),
               const Text(
                 "MAXIMUS",
                 style: TextStyle(
                   color: Colors.white, 
                   fontWeight: FontWeight.w900, 
                   fontSize: 20, 
                   letterSpacing: -0.5,
                 ),
               ),
             ],
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.loginRegistration),
                child: const Text(
                  "Log in", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.loginRegistration),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Sign up", 
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRideInputs() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE), 
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                children: [
                  Icon(Icons.access_time_filled, size: 18),
                  SizedBox(width: 10),
                  Text("Reunirse ahora", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 20),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F3), 
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)),
                  Container(width: 1, height: 35, color: Colors.black),
                  Container(width: 8, height: 8, color: Colors.black),
                ],
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Punto de partida", style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w400)),
                    Divider(height: 32, thickness: 1),
                    Text("¿A dónde vas?", style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w400)),
                  ],
                ),
              ),
              const Column(
                children: [
                  Icon(Icons.near_me, size: 20, color: Colors.black),
                  SizedBox(height: 32),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBlackButton(String text) {
    return GestureDetector(
      onTap: () {
        // Navigation or main action
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black, 
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
        ),
        alignment: Alignment.center,
        child: Text(
          text, 
          style: const TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.w700, 
            fontSize: 16,
            letterSpacing: 0.2,
          )
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Text(
                  s['description'], 
                  style: TextStyle(fontSize: 14, color: Colors.black.withValues(alpha: 0.7), height: 1.4),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, s['route']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black, 
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      "Detalles", 
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              s['imageUrl'], 
              width: 90, 
              height: 90,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, size: 60, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildReserveSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Planea para más adelante", 
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
               _buildToggleButton("Maximus Reserve", true),
               const SizedBox(width: 10),
               _buildToggleButton("Maximus Rent", false),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            "Viaja con total tranquilidad", 
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.1),
          ),
          const SizedBox(height: 12),
          Text(
            "Elige la fecha y la hora para tu próximo servicio premium.", 
            style: TextStyle(fontSize: 14, color: Colors.black.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(child: _buildDateTimeInput(Icons.calendar_today, "Fecha")),
              const SizedBox(width: 16),
              Expanded(child: _buildDateTimeInput(Icons.access_time, "Hora", hasArrow: true)),
            ],
          ),
          const SizedBox(height: 24),
          _buildBlackButton("Siguiente"),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: active ? Colors.black : Colors.white, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: active ? Colors.black : Colors.black.withValues(alpha: 0.1)),
      ),
      child: Text(
        text, 
        style: TextStyle(
          color: active ? Colors.white : Colors.black, 
          fontWeight: FontWeight.w700, 
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildDateTimeInput(IconData icon, String text, {bool hasArrow = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFD4AF37)),
          const SizedBox(width: 12),
          Text(
            text, 
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
          ),
          if (hasArrow) ...[
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.black54),
          ],
        ],
      ),
    );
  }
}
