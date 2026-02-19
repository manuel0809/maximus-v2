import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../../services/trip_tracking_service.dart';
import '../../services/google_maps_service.dart' as gms;

/// Driver navigation map widget for turn-by-turn navigation during trips
class DriverNavigationMapWidget extends StatefulWidget {
  final String tripId;

  const DriverNavigationMapWidget({
    super.key,
    required this.tripId,
  });

  @override
  State<DriverNavigationMapWidget> createState() => _DriverNavigationMapWidgetState();
}

class _DriverNavigationMapWidgetState extends State<DriverNavigationMapWidget> {
  GoogleMapController? _mapController;
  final _trackingService = TripTrackingService.instance;

  StreamSubscription? _tripSubscription;
  StreamSubscription? _locationSubscription;
  Map<String, dynamic>? _tripData;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  Timer? _locationUpdateTimer;
  // Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _subscribeToTrip();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _tripSubscription?.cancel();
    _locationSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    super.dispose();
  }

  void _subscribeToTrip() {
    _tripSubscription = _trackingService.streamTrip(widget.tripId).listen((trip) {
      if (trip.isEmpty) return;

      setState(() {
        _tripData = trip;
        _updateMapElements();
      });
    });
  }

  void _startLocationTracking() {
    // Update location every 5 seconds
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

        // setState(() => _currentPosition = position);

        // Update trip with current location
        await _trackingService.updateDriverLocation(
          tripId: widget.tripId,
          location: gms.LatLng(position.latitude, position.longitude),
          speedMph: position.speed * 2.23694, // m/s to mph
        );

        // Update camera to follow driver
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );
      } catch (e) {
        debugPrint('Error getting location: $e');
      }
    });
  }

  void _updateMapElements() {
    if (_tripData == null) return;

    _markers.clear();
    _polylines.clear();

    final status = _tripData!['status'] as String;

    // Pickup marker
    final pickupLat = (_tripData!['pickup_lat'] as num).toDouble();
    final pickupLng = (_tripData!['pickup_lng'] as num).toDouble();
    _markers.add(Marker(
      markerId: const MarkerId('pickup'),
      position: LatLng(pickupLat, pickupLng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: 'Recogida'),
    ));

    // Dropoff marker (only show during trip)
    if (status == 'in_progress') {
      final dropoffLat = (_tripData!['dropoff_lat'] as num).toDouble();
      final dropoffLng = (_tripData!['dropoff_lng'] as num).toDouble();
      _markers.add(Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(dropoffLat, dropoffLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Destino'),
      ));
    }

    // Route polyline
    final polylineEncoded = _tripData!['route_polyline'] as String?;
    if (polylineEncoded != null && polylineEncoded.isNotEmpty) {
      final polylinePoints = PolylinePoints();
      final result = polylinePoints.decodePolyline(polylineEncoded);
      final routePoints = result
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      _polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: Colors.blue,
        width: 5,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Google Map
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(25.7617, -80.1918), // Miami
            zoom: 15,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            if (_tripData != null) {
              _updateMapElements();
            }
          },
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: true,
          mapType: MapType.normal,
        ),

        // Navigation info card
        if (_tripData != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildNavigationCard(),
          ),

        // Trip controls
        Positioned(
          top: 16,
          right: 16,
          child: _buildTripControls(),
        ),
      ],
    );
  }

  Widget _buildNavigationCard() {
    final status = _tripData!['status'] as String;
    final googleMiles = (_tripData!['google_maps_distance_miles'] as num).toDouble();
    final realMiles = (_tripData!['real_gps_distance_miles'] as num).toDouble();
    final currentSpeed = (_tripData!['current_speed_mph'] as num?)?.toDouble() ?? 0.0;

    final remainingMiles = (googleMiles - realMiles).clamp(0.0, googleMiles);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status == 'en_route_to_pickup'
                  ? 'En camino a recoger'
                  : status == 'waiting_at_pickup'
                      ? 'Esperando al cliente'
                      : 'Viaje en curso',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Millas Restantes',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '${remainingMiles.toStringAsFixed(1)} mi',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Velocidad',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '${currentSpeed.toStringAsFixed(0)} mph',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: googleMiles > 0 ? (realMiles / googleMiles).clamp(0.0, 1.0) : 0.0,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripControls() {
    final status = _tripData!['status'] as String;

    return Column(
      children: [
        if (status == 'en_route_to_pickup')
          FloatingActionButton.extended(
            onPressed: () async {
              await _trackingService.updateTripStatus(widget.tripId, 'waiting_at_pickup');
            },
            icon: const Icon(Icons.check),
            label: const Text('Llegué'),
            backgroundColor: Colors.green,
          ),
        if (status == 'waiting_at_pickup')
          FloatingActionButton.extended(
            onPressed: () async {
              await _trackingService.updateTripStatus(widget.tripId, 'in_progress');
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Iniciar Viaje'),
            backgroundColor: Colors.blue,
          ),
        if (status == 'in_progress')
          FloatingActionButton.extended(
            onPressed: () async {
              final summary = await _trackingService.completeTrip(widget.tripId);
              if (mounted) {
                // Show completion dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Viaje Completado'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Millas Google Maps: ${summary.googleMapsDistanceMiles.toStringAsFixed(1)}'),
                        Text('Millas GPS: ${summary.realGpsDistanceMiles.toStringAsFixed(1)}'),
                        Text('Millas cobradas: ${summary.chargedDistanceMiles.toStringAsFixed(1)}'),
                        Text('Duración: ${summary.durationMinutes} min'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            },
            icon: const Icon(Icons.stop),
            label: const Text('Completar'),
            backgroundColor: Colors.red,
          ),
        const SizedBox(height: 8),
        FloatingActionButton(
          onPressed: () {
            // TODO: Emergency SOS
          },
          backgroundColor: Colors.red,
          child: const Icon(Icons.warning),
        ),
      ],
    );
  }
}
