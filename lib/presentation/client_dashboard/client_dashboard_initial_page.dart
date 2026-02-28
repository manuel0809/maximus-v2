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
  
  // Tabs: 0 -> Viaje, 1 -> Rentas Por Horas, 2 -> Más
  int _selectedTabIndex = 0;
  
  // Overlay state for dropdown menus
  OverlayEntry? _overlayEntry;
  final LayerLink _profileLink = LayerLink();
  final LayerLink _moreLink = LayerLink();
  bool _isProfileMenuOpen = false;
  bool _isMoreMenuOpen = false;

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
                CompositedTransformTarget(
                  link: _moreLink,
                  child: _buildHeaderTab("Más", Icons.more_horiz, 2, isDropdown: true),
                ),
              ]
            ],
          ),
          
          // User Actions
          Row(
            children: [
              if (isLoggedIn) ...[
                 CompositedTransformTarget(
                   link: _profileLink,
                   child: GestureDetector(
                     onTap: _toggleProfileMenu,
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                       decoration: BoxDecoration(
                         color: _isProfileMenuOpen ? const Color(0xFFE5E5E5) : const Color(0xFFF3F3F3), 
                         borderRadius: BorderRadius.circular(20),
                       ),
                       child: Row(
                         children: [
                           const Icon(Icons.person, color: Colors.black, size: 18),
                           const SizedBox(width: 8),
                           Text(userName.isNotEmpty ? userName : "Perfil", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 13)),
                           const SizedBox(width: 8),
                           Icon(_isProfileMenuOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.black, size: 18),
                         ],
                       )
                     ),
                   ),
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

  void _closeAllMenus() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    setState(() {
      _isProfileMenuOpen = false;
      _isMoreMenuOpen = false;
    });
  }

  void _toggleProfileMenu() {
    if (_isProfileMenuOpen) {
      _closeAllMenus();
    } else {
      _closeAllMenus();
      setState(() => _isProfileMenuOpen = true);
      _overlayEntry = _createProfileOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void _toggleMoreMenu() {
    if (_isMoreMenuOpen) {
      _closeAllMenus();
    } else {
      _closeAllMenus();
      setState(() => _isMoreMenuOpen = true);
      _overlayEntry = _createMoreOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  OverlayEntry _createProfileOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _closeAllMenus,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            width: 320,
            child: CompositedTransformFollower(
              link: _profileLink,
              showWhenUnlinked: false,
              offset: const Offset(-200, 50), // Adjust based on layout
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Profile
                      Row(
                        children: [
                           CircleAvatar(
                             radius: 24,
                             backgroundColor: Colors.grey[300],
                             child: const Icon(Icons.person, color: Colors.grey, size: 30),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(userName.isNotEmpty ? userName.toUpperCase() : "USUARIO", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5)),
                                 const Row(
                                   children: [
                                     Icon(Icons.star, size: 14, color: Colors.black),
                                     SizedBox(width: 4),
                                     Text("5.00", style: TextStyle(fontWeight: FontWeight.w600)),
                                   ],
                                 )
                               ],
                             )
                           )
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Top Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildProfileTopAction(Icons.help_outline, "Ayuda"),
                          _buildProfileTopAction(Icons.account_balance_wallet, "Wallet"),
                          _buildProfileTopAction(Icons.history, "Actividad"),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Uber Cash
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Maximus Cash", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            Text("0,00 US\$", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // List Tiles
                      _buildProfileListTile(Icons.person_outline, "Gestionar cuenta"),
                      _buildProfileListTile(Icons.local_offer_outlined, "Promociones"),
                      const SizedBox(height: 8),
                      // Logout
                      InkWell(
                        onTap: () async {
                          _closeAllMenus();
                          final navigator = Navigator.of(context);
                          await Supabase.instance.client.auth.signOut();
                          navigator.pushReplacementNamed(AppRoutes.loginRegistration);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F3F3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Text("Cerrar sesión", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 16)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTopAction(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 24, color: Colors.black),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }

  Widget _buildProfileListTile(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        ],
      ),
    );
  }

  OverlayEntry _createMoreOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _closeAllMenus,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            width: 200,
            child: CompositedTransformFollower(
              link: _moreLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 50),
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMoreListTile(Icons.key, "Vehículos de alquiler", 3),
                      _buildMoreListTile(Icons.local_shipping, "Entregas", 4),
                      _buildMoreListTile(Icons.restaurant, "Comer", 5),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreListTile(IconData icon, String label, int index) {
    return InkWell(
      onTap: () {
        setState(() => _selectedTabIndex = index);
        _closeAllMenus();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.black),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderTab(String title, IconData icon, int index, {bool isDropdown = false}) {
    final isSelected = _selectedTabIndex == index || (isDropdown && _isMoreMenuOpen);
    return GestureDetector(
      onTap: () {
        if (isDropdown) {
          _toggleMoreMenu();
        } else {
          setState(() {
            _selectedTabIndex = index;
            _closeAllMenus();
          });
        }
      },
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelContent(),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Padding(
            padding: const EdgeInsets.all(24),
            child: _buildSuggestionsGrid(),
          )
        ],
      )
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
              const SizedBox(height: 24),
              _buildSuggestionsGrid(),
              const SizedBox(height: 24),
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
          _buildActiveTabContent(),
          const SizedBox(height: 32),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 24),
          _buildSuggestionsGrid(),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_selectedTabIndex) {
      case 0: // Viaje
        return _buildRideContent();
      case 1: // Por Horas
        return _buildHourlyContent();
      case 2: // Reserva
        return _buildReserveContent();
      default:
        return _buildRideContent();
    }
  }

  Widget _buildRideContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Consigue un viaje",
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1, color: Colors.black),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9), // Light green tint
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.local_offer, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              const Expanded(child: Text("20% de descuento en 1 viaje de hasta...", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.green))),
              Icon(Icons.info_outline, color: Colors.green.withValues(alpha: 0.5), size: 16)
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildLocationInputs(),
        const SizedBox(height: 24),
        _buildBlackButton("Buscar"),
      ],
    );
  }

  Widget _buildHourlyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
             InkWell(
               onTap: () {},
               borderRadius: BorderRadius.circular(20),
               child: Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(color: const Color(0xFFF3F3F3), shape: BoxShape.circle),
                 child: const Icon(Icons.arrow_back, size: 20),
               ),
             ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          "¿Cuánto tiempo necesitas?",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Colors.black),
        ),
        const SizedBox(height: 40),
        
        // Hour Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
               child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFF3F3F3), shape: BoxShape.circle), child: const Icon(Icons.remove, size: 24, color: Colors.black38)),
            ),
            const SizedBox(width: 32),
            const Text("2 horas", style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800)),
            const SizedBox(width: 32),
            InkWell(
               child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFF3F3F3), shape: BoxShape.circle), child: const Icon(Icons.add, size: 24, color: Colors.black)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Center(child: Text("Incluido: 40 millas", style: TextStyle(color: Colors.black54, fontSize: 14))),
        const SizedBox(height: 40),
        
        // Fake Slider
        Row(
          children: [
            Container(width: 16, height: 16, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: Colors.grey.shade300, width: 2))),
            Expanded(child: Container(height: 2, color: Colors.black)),
            const SizedBox(width: 4),
            Expanded(child: Container(height: 2, color: Colors.black)),
            const SizedBox(width: 4),
            Expanded(child: Container(height: 2, color: Colors.black)),
            const SizedBox(width: 4),
            Expanded(child: Container(height: 2, color: Colors.black)),
            const SizedBox(width: 4),
            Expanded(child: Container(height: 2, color: Colors.black)),
          ],
        ),
        const SizedBox(height: 40),
        
        // Price Estimate
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
             const Text("Desde", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
             Column(
               crossAxisAlignment: CrossAxisAlignment.end,
               children: [
                  const Text("115,92 US\$", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                  Text("57,96 US\$/hora", style: TextStyle(color: Colors.black54, fontSize: 13, decoration: TextDecoration.lineThrough)),
               ],
             )
          ],
        ),
        const SizedBox(height: 24),
        _buildBlackButton("Elige un viaje"),
      ],
    );
  }

  Widget _buildReserveContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Planea para más adelante",
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1, color: Colors.black),
        ),
        const SizedBox(height: 24),
        _buildLocationInputs(),
        const SizedBox(height: 24),
        _buildBlackButton("Programar Maximus"),
      ],
    );
  }

  Widget _buildSuggestionsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Sugerencias",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildSuggestionCard("Ride", Icons.directions_car, 0),
            _buildSuggestionCard("Reserve", Icons.calendar_today, 2),
            _buildSuggestionCard("Rental Cars", Icons.key, 3),
            _buildSuggestionCard("Hourly", Icons.access_time_filled, 1),
            _buildSuggestionCard("Food", Icons.restaurant, 5),
            _buildSuggestionCard("Grocery", Icons.shopping_basket, 6),
          ],
        )
      ],
    );
  }

  Widget _buildSuggestionCard(String title, IconData icon, int tabIndex) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2.0;
        return GestureDetector(
          onTap: () {
             if (tabIndex <= 2) {
                setState(() => _selectedTabIndex = tabIndex);
             }
          },
          child: Container(
            width: cardWidth,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 36, color: Colors.black87),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black)),
              ],
            ),
          ),
        );
      }
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
               const Expanded(child: Text("Ubicación de recogida", style: TextStyle(color: Colors.black38, fontSize: 16, fontWeight: FontWeight.w500))),
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
               Expanded(child: Text("Ubicación de destino", style: TextStyle(color: Colors.black38, fontSize: 16, fontWeight: FontWeight.w500))),
               Icon(Icons.add, size: 20, color: Colors.black),
            ],
          )
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(color: const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(12)),
          child: const Row(
            children: [
               Icon(Icons.access_time_filled, size: 16, color: Colors.black),
               SizedBox(width: 16),
               Expanded(child: Text("Recoger ya", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600))),
               Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.black),
            ],
          )
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFF3F3F3), borderRadius: BorderRadius.circular(20)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                  Icon(Icons.person, size: 14),
                  SizedBox(width: 8),
                  Text("Para mí", style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(width: 8),
                  Icon(Icons.keyboard_arrow_down, size: 16),
              ],
            )
          )
        )
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
