import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/localization_service.dart';
import '../../services/notification_service.dart';
import '../../services/realtime_service.dart';
import './widgets/active_rental_card_widget.dart';
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

  final List<Map<String, dynamic>> services = [
    {
      "id": 1,
      "titleKey": "car_rental",
      "subtitleKey": "Alquila tu vehículo ideal",
      "icon": Icons.directions_car_outlined,
      "route": "/car-rental-service-screen",
      "imageUrl": "https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?q=80&w=400",
    },
    {
      "id": 2,
      "titleKey": "personal_transport",
      "subtitleKey": "Transporte privado a tu puerta",
      "icon": Icons.local_taxi_outlined,
      "route": "/personal-transport-service-screen",
      "imageUrl": "https://images.unsplash.com/photo-1629485474020-d282d2b7b4c4?q=80&w=400",
    },
    {
      "id": 3,
      "titleKey": "driver_tracking",
      "subtitleKey": "Sigue tu viaje en tiempo real",
      "icon": Icons.my_location_outlined,
      "route": "/driver-tracking-screen",
      "imageUrl": "https://images.unsplash.com/photo-1527482797697-8795b05a13fe?q=80&w=400",
    },
    {
      "id": 4,
      "titleKey": "quick_quote",
      "subtitleKey": "Obtén una cotización rápida",
      "icon": Icons.chat_bubble_outline,
      "route": "/quick-quote-car-rental-screen",
      "imageUrl": "https://images.unsplash.com/photo-1618844970163-a0798e3d0779?q=80&w=400",
    },
    {
      "id": 8,
      "titleKey": "ratings_reviews",
      "subtitleKey": "Tu experiencia importa",
      "icon": Icons.star_outline,
      "route": "/ratings-reviews-screen",
      "imageUrl": "https://images.unsplash.com/photo-1560472355-536de3962603?q=80&w=400",
    },
    {
      "id": 9,
      "titleKey": "my_rewards",
      "subtitleKey": "Puntos y beneficios exclusivos",
      "icon": Icons.workspace_premium_outlined,
      "route": "/loyalty-dashboard-screen",
      "imageUrl": "https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?q=80&w=400",
    },
  ];

  final List<Map<String, dynamic>> recentBookings = [
    {
      "serviceName": "SUV de Lujo",
      "serviceType": "SUV Executive",
      "destination": "Miami Beach",
      "date": "18 Feb",
      "time": "20:30",
      "status": "Completado",
      "statusColor": const Color(0xFF22C55E),
      "image": "https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?q=80&w=400",
      "canRebook": true,
    },
    {
      "serviceName": "Sedán Premium",
      "serviceType": "Sedan Black",
      "destination": "Aeropuerto MIA",
      "date": "16 Feb",
      "time": "14:15",
      "status": "Completado",
      "statusColor": const Color(0xFF22C55E),
      "image": "https://images.unsplash.com/photo-1503376780353-7e6692767b70?q=80&w=400",
      "canRebook": true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadUnreadNotificationCount();
    _subscribeToNotifications();
    _loadUserProfile();
    _subscribeToProfileUpdates();
    _subscribeToTripUpdates();
    _loadActiveRental();
  }

  @override
  void dispose() {
    _notificationService.unsubscribe();
    _realtimeService.unsubscribeFromProfile();
    _realtimeService.unsubscribeFromTrips();
    super.dispose();
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      setState(() => unreadNotificationCount = count);
    } catch (e) {
      // Silent fail
    }
  }

  void _subscribeToNotifications() {
    _notificationService.subscribeToNotifications((notification) {
      setState(() => unreadNotificationCount++);
    });
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
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _realtimeService.getCurrentUserProfile();
      if (profile != null && mounted) {
        setState(() => userName = profile['full_name'] ?? 'Usuario');
      }
    } catch (e) {
      // Silent fail
    }
  }

  void _subscribeToProfileUpdates() {
    _realtimeService.subscribeToProfileUpdates((updatedProfile) {
      if (mounted) setState(() => userName = updatedProfile['full_name'] ?? 'Usuario');
    });
  }

  void _subscribeToTripUpdates() {
    _realtimeService.subscribeToTrips((tripData) {
      if (mounted) {
        final event = tripData['event'];
        final trip = tripData['trip'];
        if (event == 'UPDATE' && trip != null) {
          final status = trip['status'];
          String message = '';
          switch (status) {
            case 'in_progress':
              message = 'Su viaje ha comenzado';
              break;
            case 'completed':
              message = 'Su viaje ha sido completado';
              break;
            case 'cancelled':
              message = 'Su viaje ha sido cancelado';
              break;
            default:
              message = 'Estado del viaje actualizado';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.black87, duration: const Duration(seconds: 3)),
          );
        }
        setState(() {});
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() { currentLocation = "Ubicación no disponible"; isLoadingLocation = false; });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { currentLocation = "Permiso denegado"; isLoadingLocation = false; });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() { currentLocation = "Permiso denegado"; isLoadingLocation = false; });
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final locationName = await _reverseGeocode(position.latitude, position.longitude);
      if (mounted) setState(() { currentLocation = locationName; isLoadingLocation = false; });
    } catch (e) {
      if (mounted) setState(() { currentLocation = "Ubicación no disponible"; isLoadingLocation = false; });
    }
  }

  Future<String> _reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=10&addressdetails=1');
      final response = await http.get(url, headers: {'User-Agent': 'MaximusTransportApp/1.0', 'Accept-Language': 'es'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final city = address['city'] ?? address['town'] ?? address['village'] ?? address['municipality'] ?? '';
          final country = address['country'] ?? '';
          if (city.isNotEmpty && country.isNotEmpty) return '$city, $country';
          if (country.isNotEmpty) return country;
        }
      }
      return 'Lat: ${lat.toStringAsFixed(2)}, Lon: ${lon.toStringAsFixed(2)}';
    } catch (e) {
      return 'Ubicación no disponible';
    }
  }

  Future<void> _handleRefresh() async {
    setState(() => isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1));
    await _getCurrentLocation();
    setState(() => isRefreshing = false);
  }

  void _handleServiceTap(String route) {
    if (AppRoutes.routes.containsKey(route)) {
      Navigator.of(context, rootNavigator: true).pushNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F7F7),
          body: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: Colors.black,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ─── Sticky App Bar ───
                SliverAppBar(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  pinned: true,
                  expandedHeight: 0,
                  leading: Padding(
                    padding: const EdgeInsets.all(10),
                    child: CircleAvatar(
                      backgroundColor: Colors.black,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'M',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                  title: GestureDetector(
                    onTap: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: Colors.black, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: isLoadingLocation
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : Text(
                                  currentLocation.isEmpty ? 'Mi ubicación' : currentLocation,
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 18),
                      ],
                    ),
                  ),
                  centerTitle: false,
                  actions: [
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none_outlined, color: Colors.black, size: 26),
                          onPressed: () async {
                            await Navigator.pushNamed(context, AppRoutes.notificationCenter);
                            _loadUnreadNotificationCount();
                          },
                        ),
                        if (unreadNotificationCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(height: 1, color: const Color(0xFFE5E5E5)),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── Hero Search Section ───
                      _buildHeroSearchSection(localization),

                      // ─── Active Rental ───
                      if (activeRental != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ActiveRentalCardWidget(
                            rental: activeRental!,
                            onTap: () => Navigator.pushNamed(context, AppRoutes.activeRental, arguments: {'rental': activeRental}),
                          ),
                        ),

                      // ─── Services (Sugerencias estilo Uber) ───
                      _buildServicesSection(localization),

                      // ─── Recent Bookings ───
                      _buildRecentBookingsSection(localization),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  HERO — Search Bar (estilo Uber)
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeroSearchSection(LocalizationService localization) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¿A dónde vas,',
            style: TextStyle(fontSize: 28.sp > 32 ? 32 : 28, fontWeight: FontWeight.w900, color: Colors.black, height: 1.15),
          ),
          Text(
            userName.isNotEmpty ? '$userName?' : '¿a dónde?',
            style: TextStyle(fontSize: 28.sp > 32 ? 32 : 28, fontWeight: FontWeight.w900, color: Colors.black, height: 1.15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),

          // ── Input de destino estilo Uber ──
          GestureDetector(
            onTap: () => _handleServiceTap('/car-rental-service-screen'),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Icono de búsqueda circular negro
                  Container(
                    margin: const EdgeInsets.all(12),
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                    child: const Icon(Icons.search, color: Colors.white, size: 20),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('¿A dónde quieres ir?', style: TextStyle(color: Colors.black.withValues(alpha: 0.4), fontSize: 15, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  // Botón de programar
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.black),
                        const SizedBox(width: 4),
                        const Text('Ahora', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black)),
                        const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.black),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  SERVICES — "Sugerencias" estilo Uber (grid 2 columnas + card horizontal)
  // ─────────────────────────────────────────────────────────────
  Widget _buildServicesSection(LocalizationService localization) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const Text('Servicios', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black)),
        ),
        const SizedBox(height: 12),

        // Grid 2 columns (primer fila de los 2 primeros servicios grande)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: _buildBigServiceCard(services[0], localization)),
              const SizedBox(width: 10),
              Expanded(child: _buildBigServiceCard(services[1], localization)),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Lista restante de servicios en cards horizontales
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: services.skip(2).map((service) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildHorizontalServiceCard(service, localization),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBigServiceCard(Map<String, dynamic> service, LocalizationService localization) {
    return GestureDetector(
      onTap: () => _handleServiceTap(service['route'] as String),
      child: Container(
        height: 16.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Imagen de fondo
            Positioned(
              right: -10,
              bottom: -10,
              child: SizedBox(
                width: 110,
                height: 110,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomImageWidget(
                    imageUrl: service['imageUrl'] as String,
                    fit: BoxFit.cover,
                    semanticLabel: localization.translate(service['titleKey'] as String),
                  ),
                ),
              ),
            ),
            // Overlay gradiente
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.white, Colors.white.withValues(alpha: 0.6), Colors.transparent],
                  ),
                ),
              ),
            ),
            // Texto
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(service['icon'] as IconData, size: 20, color: Colors.black),
                  const SizedBox(height: 6),
                  Text(
                    localization.translate(service['titleKey'] as String),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.black),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalServiceCard(Map<String, dynamic> service, LocalizationService localization) {
    return GestureDetector(
      onTap: () => _handleServiceTap(service['route'] as String),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Icono
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(12)),
              child: Icon(service['icon'] as IconData, size: 26, color: Colors.black),
            ),
            const SizedBox(width: 14),
            // Texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(localization.translate(service['titleKey'] as String),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black)),
                  const SizedBox(height: 2),
                  Text(service['subtitleKey'] as String,
                      style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.45), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black45),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  RECENT BOOKINGS
  // ─────────────────────────────────────────────────────────────
  Widget _buildRecentBookingsSection(LocalizationService localization) {
    if (recentBookings.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Viajes recientes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black)),
              TextButton(
                onPressed: () {},
                child: const Text('Ver todos', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 13, decoration: TextDecoration.underline)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: recentBookings.map((booking) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildRecentBookingRow(booking),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentBookingRow(Map<String, dynamic> booking) {
    final statusColor = booking['statusColor'] as Color;
    final canRebook = booking['canRebook'] as bool? ?? false;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Thumbnail vehículo
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 60,
              height: 60,
              child: CustomImageWidget(imageUrl: booking['image'] as String, fit: BoxFit.cover, semanticLabel: booking['serviceName'] as String),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking['serviceName'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.black)),
                const SizedBox(height: 2),
                Text('${booking['destination']}  •  ${booking['date']} ${booking['time']}',
                    style: TextStyle(fontSize: 12, color: Colors.black.withValues(alpha: 0.45))),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(booking['status'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
                ),
              ],
            ),
          ),
          // Botón repetir
          if (canRebook)
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Repetir', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}
