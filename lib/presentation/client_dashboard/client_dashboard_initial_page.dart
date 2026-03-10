import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  
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

  int _selectedHours = 2;
  final double _hourlyRate = 57.96;

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadUnreadNotificationCount();
    _loadUserProfile();
    _pickupController.text = currentLocation;
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
          _pickupController.text = locationName;
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
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          // 1. Background Map
          _buildMap(),
          
          // Subtle dark overlay to map
          IgnorePointer(
            child: Container(
              color: const Color(0xFF0F0F0F).withValues(alpha: 0.1),
            ),
          ),

          // 2. Interactive Panel
          if (isDesktop)
            Positioned(
              top: MediaQuery.of(context).padding.top + 85,
              left: 40,
              bottom: 40,
              width: 440,
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
    final theme = Theme.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    final isLoggedIn = user != null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F).withValues(alpha: 0.95),
        border: const Border(
          bottom: BorderSide(color: Colors.white12, width: 0.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(isDesktop ? 40 : 20, MediaQuery.of(context).padding.top + 12, isDesktop ? 40 : 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & Tabs (Desktop)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.primary, width: 1.5),
                ),
                child: Image.asset(
                  'assets/images/maximus_official_logo.png',
                  height: isDesktop ? 34 : 28,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.star, color: theme.colorScheme.primary),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "MAXIMUS",
                    style: GoogleFonts.lexend(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: isDesktop ? 18 : 14,
                      letterSpacing: 1.5,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    "LEVEL GROUP",
                    style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                      fontSize: isDesktop ? 10 : 8,
                      letterSpacing: 2.5,
                      height: 1.0,
                    ),
                  ),
                ],
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
                         color: _isProfileMenuOpen ? theme.colorScheme.primary : const Color(0xFF1E1E1E), 
                         borderRadius: BorderRadius.circular(20),
                         border: Border.all(color: Colors.white10),
                       ),
                       child: Row(
                         children: [
                           Icon(Icons.person, color: _isProfileMenuOpen ? Colors.black : theme.colorScheme.primary, size: 18),
                           const SizedBox(width: 8),
                           Text(
                             userName.isNotEmpty ? userName : "Perfil", 
                             style: TextStyle(
                               color: _isProfileMenuOpen ? Colors.black : Colors.white, 
                               fontWeight: FontWeight.w700, 
                               fontSize: 13,
                             )
                           ),
                           const SizedBox(width: 8),
                           Icon(
                             _isProfileMenuOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, 
                             color: _isProfileMenuOpen ? Colors.black : Colors.white60, 
                             size: 18,
                           ),
                         ],
                       )
                     ),
                   ),
                 )
              ] else ...[
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.loginRegistration),
                  child: const Text("Log in", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.loginRegistration),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [theme.colorScheme.primary, Color(0xFFB5942D)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text("Sign up", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 14)),
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
    final theme = Theme.of(context);
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: isSelected ? null : Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.black : theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title, 
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white, 
                fontSize: 14, 
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopPanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 40,
            offset: const Offset(0, 15),
          )
        ]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
             Expanded(
               child: SingleChildScrollView(
                 padding: const EdgeInsets.all(32),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     _buildPanelContent(),
                     const SizedBox(height: 32),
                     const Divider(color: Colors.white10),
                     const SizedBox(height: 32),
                     _buildSuggestionsGrid(),
                   ],
                 ),
               ),
             )
          ],
        ),
      )
    );
  }

  Widget _buildMobileBottomSheet() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F0F),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          border: const Border(top: BorderSide(color: Colors.white10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
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
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
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
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildPanelContent(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
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
        ],
      ),
    );
  }

  Widget _buildActiveTabContent() {
    Widget content;
    switch (_selectedTabIndex) {
      case 0: // Viaje
        content = _buildRideContent();
        break;
      case 1: // Por Horas
        content = _buildHourlyContent();
        break;
      case 2: // Reserva
        content = _buildReserveContent();
        break;
      case 3: // Renta de Autos
        content = _buildRentalContent();
        break;
      default:
        // Other tabs might point to empty or specialized widgets in the future
        content = _buildRideContent();
    }
    return KeyedSubtree(key: ValueKey<int>(_selectedTabIndex), child: content);
  }

  Widget _buildRideContent() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Consigue un viaje",
          style: GoogleFonts.lexend(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        _buildLocationInputs(),
        const SizedBox(height: 24),
        _buildBlackButton("Buscar"),
        const SizedBox(height: 40),
        _buildRentalContent(),
      ],
    );
  }

  Widget _buildHourlyContent() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
             InkWell(
               onTap: () {
                 setState(() => _selectedTabIndex = 0);
               },
               borderRadius: BorderRadius.circular(20),
               child: Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(color: const Color(0xFF1E1E1E), shape: BoxShape.circle, border: Border.all(color: Colors.white10)),
                 child: Icon(Icons.arrow_back, size: 20, color: theme.colorScheme.primary),
               ),
             ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          "¿Cuánto tiempo necesitas?",
          style: GoogleFonts.lexend(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 40),
        
        // Hour Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
               onTap: () {
                 if (_selectedHours > 2) {
                   setState(() => _selectedHours--);
                 }
               },
               child: Container(
                 padding: const EdgeInsets.all(8), 
                 decoration: BoxDecoration(color: const Color(0xFF1E1E1E), shape: BoxShape.circle, border: Border.all(color: Colors.white10)), 
                 child: Icon(Icons.remove, size: 24, color: _selectedHours > 2 ? theme.colorScheme.primary : Colors.white24),
               ),
            ),
            const SizedBox(width: 32),
            Text(
              "$_selectedHours horas", 
              style: GoogleFonts.lexend(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(width: 32),
            InkWell(
               onTap: () {
                 if (_selectedHours < 12) {
                   setState(() => _selectedHours++);
                 }
               },
               child: Container(
                 padding: const EdgeInsets.all(8), 
                 decoration: BoxDecoration(color: const Color(0xFF1E1E1E), shape: BoxShape.circle, border: Border.all(color: Colors.white10)), 
                 child: Icon(Icons.add, size: 24, color: _selectedHours < 12 ? theme.colorScheme.primary : Colors.white24),
               ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(child: Text("Incluido: ${_selectedHours * 20} millas", style: const TextStyle(color: Colors.white60, fontSize: 14))),
        const SizedBox(height: 40),
        
        // Fake Slider (Luxury Styled)
        Row(
          children: List.generate(10, (index) {
            final isActive = index < (_selectedHours - 2) * 1; // Simplified mapping
            return Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isActive ? theme.colorScheme.primary : Colors.white12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 40),
        
        // Price Estimate
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
             const Text("Desde", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white70)),
             Column(
               crossAxisAlignment: CrossAxisAlignment.end,
               children: [
                   Text(
                     "${(_hourlyRate * _selectedHours).toStringAsFixed(2)} US\$", 
                     style: GoogleFonts.lexend(fontWeight: FontWeight.w800, fontSize: 24, color: theme.colorScheme.primary),
                   ),
                   Text(
                     "${_hourlyRate.toStringAsFixed(2)} US\$/hora", 
                     style: const TextStyle(color: Colors.white38, fontSize: 13, decoration: TextDecoration.lineThrough),
                   ),
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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Planea para más adelante",
          style: GoogleFonts.lexend(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 24),
        _buildLocationInputs(),
        const SizedBox(height: 24),
        _buildBlackButton("Programar Maximus"),
      ],
    );
  }

  Widget _buildSuggestionsGrid() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Sugerencias",
          style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildSuggestionCard("Viaje", Icons.directions_car, 0),
            _buildSuggestionCard("Reserva", Icons.calendar_today, 2),
            _buildSuggestionCard("Autos", Icons.key, 3),
            _buildSuggestionCard("Por Horas", Icons.access_time_filled, 1),
          ],
        )
      ],
    );
  }

  Widget _buildRentalContent() {
    final theme = Theme.of(context);
    final cars = [
      {'name': 'Black', 'desc': 'Viajes en vehículos de gama alta', 'passengers': 4, 'time': '11 min', 'price': '84.97 US\$', 'img': 'assets/images/Untitled-1770903998939.jpeg'},
      {'name': 'Black SUV', 'desc': 'Viajes de lujo para 6 personas con socios de la App profesionales', 'passengers': 6, 'time': '10 min', 'price': '101.98 US\$', 'img': 'assets/images/Untitled-1770905042048.jpeg'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Vehículos de Alquiler",
          style: GoogleFonts.lexend(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Selecciona el vehículo perfecto para ti.",
          style: TextStyle(fontSize: 14, color: Colors.white54),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 310,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cars.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final car = cars[index];
              return Container(
                width: 280,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: Image.asset(
                         car['img'] as String,
                         height: 140,
                         width: double.infinity,
                         fit: BoxFit.cover,
                         errorBuilder: (context, error, stackTrace) => Container(
                           height: 140,
                           color: Colors.white10,
                           child: Icon(Icons.directions_car, color: theme.colorScheme.primary, size: 48),
                         ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(car['name'] as String, style: GoogleFonts.lexend(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.white)),
                              Row(
                                children: [
                                  Icon(Icons.person, size: 14, color: theme.colorScheme.primary),
                                  const SizedBox(width: 4),
                                  Text('${car['passengers']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(car['desc'] as String, style: const TextStyle(fontSize: 12, color: Colors.white54), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(car['time'] as String, style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                                  Text(car['price'] as String, style: GoogleFonts.lexend(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white)),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, AppRoutes.carRentalService);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                child: const Text("Reservar", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              )
                            ],
                          )
                        ],
                      )
                    )
                  ],
                ),
              );
            },
          )
        )
      ],
    );
  }

  Widget _buildSuggestionCard(String title, IconData icon, int tabIndex) {
    final theme = Theme.of(context);
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
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 36, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  title, 
                  style: GoogleFonts.lexend(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildLocationInputs() {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Time Selector
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time_filled, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                const Text("Ahora", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white70),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Pickup Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E), 
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
               Icon(Icons.circle, size: 10, color: theme.colorScheme.primary),
               const SizedBox(width: 16),
               Expanded(
                 child: TextField(
                   controller: _pickupController,
                   style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                   decoration: const InputDecoration(
                     hintText: "Ubicación de recogida",
                     hintStyle: TextStyle(color: Colors.white38),
                     border: InputBorder.none,
                     isDense: true,
                   ),
                 )
               ),
            ],
          )
        ),
        const SizedBox(height: 12),
        // Destination Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E), 
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
               Icon(Icons.square, size: 10, color: theme.colorScheme.primary),
               const SizedBox(width: 16),
               Expanded(
                 child: TextField(
                   controller: _destinationController,
                   autofocus: true,
                   style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                   decoration: const InputDecoration(
                     hintText: "¿A dónde vas?",
                     hintStyle: TextStyle(color: Colors.white38),
                     border: InputBorder.none,
                     isDense: true,
                   ),
                 )
               ),
               const Icon(Icons.add, size: 20, color: Colors.white70),
            ],
          )
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E), 
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                  Icon(Icons.person, size: 14, color: theme.colorScheme.primary),
                  SizedBox(width: 8),
                  Text("Para mí", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 12)),
                  SizedBox(width: 8),
                  Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white70),
              ],
            )
          )
        )
      ],
    );
  }

  Widget _buildBlackButton(String text) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, Colors.black87],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.carRentalService);
        },
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: Colors.black, 
            fontSize: 16, 
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
