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
                  
                  const SizedBox(height: 12),
                  const Text("Inicia sesión para ver tu actividad reciente", style: TextStyle(decoration: TextDecoration.underline, fontSize: 14)),
                  
                  const SizedBox(height: 48),
                  
                  // --- SUGGESTIONS ---
                  const Text(
                    "Sugerencias",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  
                  ...suggestions.map((s) => _buildSuggestionCard(s)).toList(),
                  
                  const SizedBox(height: 40),
                  
                  // --- LOGIN CTA SECTION ---
                  _buildLoginSection(),
                  
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
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
             children: [
               SvgPicture.asset(
                 'assets/images/img_app_logo.svg',
                 height: 24,
                 colorFilter: const ColorFilter.mode(Color(0xFFD4AF37), BlendMode.srcIn),
               ),
               const SizedBox(width: 12),
               const Text(
                 "MAXIMUS",
                 style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5),
               ),
               const SizedBox(width: 20),
               const Text("Viaje", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)),
             ],
          ),
          Row(
            children: [
              const Text("Inicia sesión", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37), 
                  borderRadius: BorderRadius.circular(20)
                ),
                child: const Text("Regístrate", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.menu, color: Colors.white),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(20)),
              child: const Row(
                children: [
                  Icon(Icons.access_time_filled, size: 16),
                  SizedBox(width: 8),
                  Text("Pedir ahora", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Icon(Icons.keyboard_arrow_down, size: 18),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(color: const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(s['description'], style: const TextStyle(fontSize: 13, color: Colors.black87)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37), 
                    borderRadius: BorderRadius.circular(20)
                  ),
                  child: const Text("Detalles", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Image.network(s['imageUrl'], width: 80, errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, size: 60)),
        ],
      ),
    );
  }

  Widget _buildLoginSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Inicia sesión para ver los detalles de tu cuenta", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        const Text("Consulta viajes anteriores, sugerencias personalizadas, recursos de ventaja y más.", style: TextStyle(fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 24),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
              child: const Text("Inicia sesión en tu cuenta", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            const Text("Crear una cuenta", style: TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 24),
        Image.network(
          "https://pggvfqmldoizstoxunir.supabase.co/storage/v1/object/public/vehicle-images/fleet/rider_driver_illus.png",
          errorBuilder: (_, __, ___) => Container(height: 150, color: Colors.grey[200]),
        ),
      ],
    );
  }

  Widget _buildReserveSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5F7FF),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Planea para más adelante", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          Row(
            children: [
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
                 child: const Text("Maximus Reserve", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
               ),
               const SizedBox(width: 8),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                 child: const Text("Maximus Rent", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
               ),
            ],
          ),
          const SizedBox(height: 32),
          const Text("Viaja bien con Maximus Reserve", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          const Text("Elige la fecha y la hora", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16),
                      SizedBox(width: 12),
                      Text("Fecha", style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Icon(Icons.access_time, size: 16),
                      SizedBox(width: 12),
                      Text("Tiempo", style: TextStyle(fontSize: 14)),
                      Spacer(),
                      Icon(Icons.keyboard_arrow_down, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBlackButton("Siguiente"),
        ],
      ),
    );
  }
}
