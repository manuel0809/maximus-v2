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
import './widgets/promotional_banner_widget.dart';
import './widgets/recent_booking_card_widget.dart';
import './widgets/service_tile_widget.dart';
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
  bool showPromoBanner = true;
  int unreadNotificationCount = 0;

  final NotificationService _notificationService = NotificationService.instance;
  final RealtimeService _realtimeService = RealtimeService.instance;
  
  
  Map<String, dynamic>? activeRental;

  final List<Map<String, dynamic>> services = [
    {
      "id": 1,
      "titleKey": "car_rental",
      "icon": "directions_car",
      "route": "/car-rental-service-screen",
      "gradientColors": [Color(0xFFD4AF37), Color(0xFF1E1E1E)],
      "hasUpdate": false,
    },
    {
      "id": 2,
      "titleKey": "personal_transport",
      "icon": "local_taxi",
      "route": "/personal-transport-service-screen",
      "gradientColors": [Color(0xFFB5942D), Color(0xFF1A1A1A)],
      "hasUpdate": false,
    },
    {
      "id": 3,
      "titleKey": "driver_tracking",
      "icon": "my_location",
      "route": "/driver-tracking-screen",
      "gradientColors": [Color(0xFFD4AF37), Color(0xFF1E1E1E)],
      "hasUpdate": true,
    },
    {
      "id": 4,
      "titleKey": "quick_quote",
      "icon": "chat",
      "route": "/quick-quote-car-rental-screen",
      "gradientColors": [Color(0xFF2E7D32), Color(0xFF66BB6A)],
      "hasUpdate": false,
    },


    {
      "id": 8,
      "titleKey": "ratings_reviews",
      "icon": "star",
      "route": "/ratings-reviews-screen",
      "gradientColors": [Color(0xFFD4AF37), Color(0xFF1E1E1E)],
      "hasUpdate": false,
    },
    {
      "id": 9,
      "titleKey": "my_rewards",
      "icon": "workspace_premium",
      "route": "/loyalty-dashboard-screen",
      "gradientColors": [Color(0xFFD4AF37), Color(0xFFF9E79F)],
      "hasUpdate": false,
    },
  ];

  final List<Map<String, dynamic>> recentBookings = [
    {
      "serviceName": "SUV de Lujo - Miami Beach",
      "serviceType": "SUV Executive",
      "date": "18 Feb",
      "time": "20:30",
      "status": "Completado",
      "statusColor": const Color(0xFF4CAF50),
      "image": "https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?q=80&w=800",
      "semanticLabel": "SUV Executive en Miami",
      "canRebook": true,
    },
    {
      "serviceName": "Sedán Premium - Aeropuerto MIA",
      "serviceType": "Sedan Black",
      "date": "16 Feb",
      "time": "14:15",
      "status": "Completado",
      "statusColor": const Color(0xFF4CAF50),
      "image": "https://images.unsplash.com/photo-1503376780353-7e6692767b70?q=80&w=800",
      "semanticLabel": "Sedán Premium en el aeropuerto",
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

      if (mounted) {
        setState(() => activeRental = response);
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _realtimeService.getCurrentUserProfile();
      if (profile != null && mounted) {
        setState(() {
          userName = profile['full_name'] ?? 'Usuario';
        });
      }
    } catch (e) {
      // Silent fail
    }
  }

  void _subscribeToProfileUpdates() {
    _realtimeService.subscribeToProfileUpdates((updatedProfile) {
      if (mounted) {
        setState(() {
          userName = updatedProfile['full_name'] ?? 'Usuario';
        });
      }
    });
  }

  void _subscribeToTripUpdates() {
    _realtimeService.subscribeToTrips((tripData) {
      if (mounted) {
        final event = tripData['event'];
        final trip = tripData['trip'];

        // Show notification for trip status changes
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
            SnackBar(
              content: Text(message),
              backgroundColor: const Color(0xFFD4AF37),
              duration: const Duration(seconds: 3),
            ),
          );
        }

        // Refresh bookings list
        setState(() {});
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          currentLocation = "Ubicación no disponible";
          isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            currentLocation = "Permiso de ubicación denegado";
            isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          currentLocation = "Permiso de ubicación denegado";
          isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // Reverse geocode using Nominatim
      final locationName = await _reverseGeocode(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          currentLocation = locationName;
          isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          currentLocation = "Ubicación no disponible";
          isLoadingLocation = false;
        });
      }
    }
  }

  Future<String> _reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=10&addressdetails=1',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'MaximusTransportApp/1.0',
        'Accept-Language': 'es',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final city = address['city'] ?? address['town'] ?? address['village'] ?? address['municipality'] ?? '';
          final state = address['state'] ?? '';
          final country = address['country'] ?? '';

          if (city.isNotEmpty && country.isNotEmpty) {
            return '$city, $country';
          } else if (state.isNotEmpty && country.isNotEmpty) {
            return '$state, $country';
          } else if (country.isNotEmpty) {
            return country;
          }
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

  void _handleQuickRebook(Map<String, dynamic> booking) {
    // Quick rebook functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reservando nuevamente ${booking["serviceName"]}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _dismissPromoBanner() {
    setState(() => showPromoBanner = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<LocalizationService>(
      builder: (context, localization, child) {
        return Scaffold(
          body: Container(
            height: 100.h,
            width: 100.w,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: theme.colorScheme.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Luxury Header with Glassmorphism
                      _buildLuxuryHeader(theme, localization),
                      
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (activeRental != null) ...[
                              ActiveRentalCardWidget(
                                rental: activeRental!,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.activeRental,
                                  arguments: {'rental': activeRental},
                                ),
                              ),
                              SizedBox(height: 3.h),
                            ],
    
                            // Services Grid
                            _buildServicesSection(theme, localization),
                            SizedBox(height: 3.h),

                            // Recent Bookings
                            _buildRecentBookingsSection(theme, localization),
                            SizedBox(height: 3.h),

                            // Promotional Banner
                            if (showPromoBanner) ...[
                              PromotionalBannerWidget(onDismiss: _dismissPromoBanner),
                              SizedBox(height: 2.h),
                            ],
    
                            // Quick Rebook Button
                            _buildQuickRebookButton(theme, localization),
                            SizedBox(height: 2.h),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLuxuryHeader(ThemeData theme, LocalizationService localization) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localization.translate('welcome').toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
                        letterSpacing: 3.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      userName,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    // Location directly below user name
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on, color: const Color(0xFFD4AF37), size: 14),
                        SizedBox(width: 1.w),
                        isLoadingLocation
                            ? SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(const Color(0xFFD4AF37)),
                                ),
                              )
                            : Flexible(
                                child: Text(
                                  currentLocation,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildNotificationIcon(theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon(ThemeData theme) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.notificationCenter);
              _loadUnreadNotificationCount();
            },
          ),
        ),
        if (unreadNotificationCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFF8B1538),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unreadNotificationCount > 99 ? '99+' : unreadNotificationCount.toString(),
                style: const TextStyle(color: Color(0xFF0F0F0F), fontSize: 8, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationRow(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.2.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on, color: Color(0xFFD4AF37), size: 14),
          ),
          SizedBox(width: 2.w),
          isLoadingLocation
              ? SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, 
                    valueColor: AlwaysStoppedAnimation(const Color(0xFFD4AF37)),
                  ),
                )
              : Text(
                  currentLocation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, LocalizationService localization) {
    return const SizedBox.shrink(); // Replaced by _buildLuxuryHeader
  }

  Widget _buildServicesSection(
    ThemeData theme,
    LocalizationService localization,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localization.translate('services'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 3.w,
            mainAxisSpacing: 2.h,
            childAspectRatio: 1.1,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = Map<String, dynamic>.from(services[index]);
            service['title'] = localization.translate(service['titleKey']);
            return ServiceTileWidget(
              service: service,
              onTap: () =>
                  _handleServiceTap(services[index]["route"] as String),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentBookingsSection(
    ThemeData theme,
    LocalizationService localization,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              localization.translate('recent_bookings'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (recentBookings.isNotEmpty)
              TextButton(
                onPressed: () {
                  // Navigate to all bookings
                },
                child: Text(
                  localization.translate('view_all'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 1.h),
        if (recentBookings.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color:
                  theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 32,
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                SizedBox(height: 1.h),
                Text(
                  'No tienes reservas recientes',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 25.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recentBookings.length,
              separatorBuilder: (context, index) => SizedBox(width: 3.w),
              itemBuilder: (context, index) {
                return RecentBookingCardWidget(
                  booking: recentBookings[index],
                  onRebook: () => _handleQuickRebook(recentBookings[index]),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildQuickRebookButton(
    ThemeData theme,
    LocalizationService localization,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Quick rebook functionality
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(localization.translate('loading')),
                duration: Duration(seconds: 2),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: 'refresh',
                  color: Colors.white,
                  size: 24,
                ),
                SizedBox(width: 2.w),
                Text(
                  localization.translate('rebook'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
