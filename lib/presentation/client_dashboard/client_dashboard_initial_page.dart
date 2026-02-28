import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/notification_service.dart';
import '../../services/realtime_service.dart';

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
  LatLng? _currentLatLng;
  int unreadNotificationCount = 0;
  GoogleMapController? _mapController;
  
  // Tabs: 0 -> Viaje, 1 -> Rentas Por Horas, 2 -> Reserve
  int _selectedTabIndex = 0;

  final NotificationService _notificationService = NotificationService.instance;
  final RealtimeService _realtimeService = RealtimeService.instance;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadUnreadNotificationCount();
    _loadUserProfile();
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) setState(() => unreadNotificationCount = count);
    } catch (e) {
      debugPrint("Error loading notifications: $e");
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _realtimeService.getCurrentUserProfile();
      if (profile != null && mounted) {
        setState(() => userName = profile['full_name'] ?? 'Usuario');
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() { currentLocation = "Doral, Miami"; isLoadingLocation = false; });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() { currentLocation = "Doral, Miami"; isLoadingLocation = false; });
          return;
        }
      }
      Position position = await Geolocator.getCurrentPosition();
      final locationName = await _reverseGeocode(position.latitude, position.longitude);
      
      if (mounted) {
        setState(() { 
          currentLocation = locationName; 
          isLoadingLocation = false; 
          _currentLatLng = LatLng(position.latitude, position.longitude);
        });
        
        if (_mapController != null && _currentLatLng != null) {
          _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_currentLatLng!, 14));
        }
      }
    } catch (e) {
      if (mounted) setState(() { currentLocation = "Doral, Miami"; isLoadingLocation = false; });
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
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background Map
          _buildMap(),

          // 2. Interactive Panel
          if (isDesktop)
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              left: 40,
              bottom: 40,
              width: 420,
              child: _buildDesktopPanel(),
            )
          else
            _buildMobileBottomSheet(),

          // 3. Header Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeader(isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _currentLatLng ?? const LatLng(25.8088, -80.3228), // Doral, Miami default
        zoom: 12,
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapType: MapType.normal,
      onMapCreated: (controller) {
        _mapController = controller;
        if (_currentLatLng != null) {
          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentLatLng!, 14));
        }
      },
    );
  }

  Widget _buildHeader(bool isDesktop) {
    final user = Supabase.instance.client.auth.currentUser;
    final isLoggedIn = user != null;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(isDesktop ? 40 : 20, MediaQuery.of(context).padding.top + 16, isDesktop ? 40 : 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & Tabs (Desktop)
          Row(
            children: [
              const Text(
                "MAXIMUS",
                style: TextStyle(
                  color: Colors.black, 
                  fontWeight: FontWeight.w900, 
                  fontSize: 24, 
                  letterSpacing: -1.0,
                ),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 40),
                _buildHeaderTab("Viaje", Icons.directions_car, 0),
                const SizedBox(width: 8),
                _buildHeaderTab("Por Horas", Icons.access_time_filled, 1),
                const SizedBox(width: 8),
                _buildHeaderTab("Reserva", Icons.calendar_today, 2),
              ]
            ],
          ),
          
          // User Actions
          Row(
            children: [
              if (isLoggedIn) ...[
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   decoration: BoxDecoration(color: const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(20)),
                   child: Row(
                     children: [
                       const Icon(Icons.person, color: Colors.black, size: 18),
                       const SizedBox(width: 8),
                       Text(userName.isNotEmpty ? userName : "Perfil", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 13)),
                       const SizedBox(width: 8),
                       const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 18),
                     ],
                   )
                 )
              ] else ...[
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.loginRegistration),
                  child: const Text("Log in", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 14)),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.loginRegistration),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(24)),
                    child: const Text("Sign up", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTab(String title, IconData icon, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF3F3F3) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.black),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ]
      ),
      child: _buildPanelContent(),
    );
  }

  Widget _buildMobileBottomSheet() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ]
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildHeaderTab("Viaje", Icons.directions_car, 0),
                    const SizedBox(width: 8),
                    _buildHeaderTab("Por Horas", Icons.access_time_filled, 1),
                    const SizedBox(width: 8),
                    _buildHeaderTab("Reserva", Icons.calendar_today, 2),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildPanelContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanelContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _selectedTabIndex == 0 ? "Solicita un viaje" : _selectedTabIndex == 1 ? "Por hora" : "Planea para más adelante",
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1, color: Colors.black),
          ),
          const SizedBox(height: 24),
          _buildLocationInputs(),
          const SizedBox(height: 24),
          _buildBlackButton(_selectedTabIndex == 2 ? "Programar Maximus" : "Ver tarifas sugeridas"),
        ],
      ),
    );
  }

  Widget _buildLocationInputs() {
    return Column(
      children: [
        // Time Selector
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time_filled, size: 16, color: Colors.black),
                SizedBox(width: 8),
                Text("Pedir para llevar ahora", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 13)),
                SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Inputs
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(color: const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
               const Icon(Icons.circle, size: 10, color: Colors.black),
               const SizedBox(width: 16),
               const Expanded(child: Text("Ingresa una ubicación", style: TextStyle(color: Colors.black38, fontSize: 16, fontWeight: FontWeight.w500))),
               const Icon(Icons.near_me, size: 20, color: Colors.black),
            ],
          )
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(color: const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(12)),
          child: const Row(
            children: [
               Icon(Icons.square, size: 10, color: Colors.black),
               SizedBox(width: 16),
               Expanded(child: Text("Ingresa un destino", style: TextStyle(color: Colors.black38, fontSize: 16, fontWeight: FontWeight.w500))),
            ],
          )
        ),
      ],
    );
  }

  Widget _buildBlackButton(String text) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: () {
          // Actions
        },
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
