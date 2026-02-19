import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:async';
import '../../services/trip_tracking_service.dart';

/// Client tracking map widget for viewing trip progress in real-time
class ClientTrackingMapWidget extends StatefulWidget {
  final String tripId;

  const ClientTrackingMapWidget({
    super.key,
    required this.tripId,
  });

  @override
  State<ClientTrackingMapWidget> createState() => _ClientTrackingMapWidgetState();
}

class _ClientTrackingMapWidgetState extends State<ClientTrackingMapWidget> {
  GoogleMapController? _mapController;
  final _trackingService = TripTrackingService.instance;

  StreamSubscription? _tripSubscription;
  Map<String, dynamic>? _tripData;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _subscribeToTrip();
  }

  @override
  void dispose() {
    _tripSubscription?.cancel();
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

  void _updateMapElements() {
    if (_tripData == null) return;

    _markers.clear();
    _polylines.clear();

    // Pickup marker
    final pickupLat = (_tripData!['pickup_lat'] as num).toDouble();
    final pickupLng = (_tripData!['pickup_lng'] as num).toDouble();
    _markers.add(Marker(
      markerId: const MarkerId('pickup'),
      position: LatLng(pickupLat, pickupLng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(title: 'Recogida'),
    ));

    // Dropoff marker
    final dropoffLat = (_tripData!['dropoff_lat'] as num).toDouble();
    final dropoffLng = (_tripData!['dropoff_lng'] as num).toDouble();
    _markers.add(Marker(
      markerId: const MarkerId('dropoff'),
      position: LatLng(dropoffLat, dropoffLng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: 'Destino'),
    ));

    // Driver marker (current location)
    final driverLat = _tripData!['current_driver_lat'];
    final driverLng = _tripData!['current_driver_lng'];
    if (driverLat != null && driverLng != null) {
      _markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(
          (driverLat as num).toDouble(),
          (driverLng as num).toDouble(),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Tu Conductor'),
        rotation: 0, // TODO: Calculate bearing from GPS history
      ));

      // Animate camera to driver location
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(
            (driverLat).toDouble(),
            (driverLng).toDouble(),
          ),
        ),
      );
    }

    // Route polyline
    final polylineEncoded = _tripData!['route_polyline'] as String?;
    if (polylineEncoded != null && polylineEncoded.isNotEmpty) {
      final polylinePoints = PolylinePoints();
      final result = polylinePoints.decodePolyline(polylineEncoded);
      _routePoints = result
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      _polylines.add(Polyline(
        polylineId: const PolylineId('route'),
        points: _routePoints,
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
            zoom: 13,
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
          zoomControlsEnabled: false,
        ),

        // Trip info card
        if (_tripData != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildTripInfoCard(),
          ),
      ],
    );
  }

  Widget _buildTripInfoCard() {
    final status = _tripData!['status'] as String;
    final googleMiles = (_tripData!['google_maps_distance_miles'] as num).toDouble();
    final realMiles = (_tripData!['real_gps_distance_miles'] as num).toDouble();
    final currentSpeed = (_tripData!['current_speed_mph'] as num?)?.toDouble() ?? 0.0;

    String statusText;
    Color statusColor;
    switch (status) {
      case 'en_route_to_pickup':
        statusText = 'Conductor en camino';
        statusColor = Colors.orange;
        break;
      case 'waiting_at_pickup':
        statusText = 'Conductor esperando';
        statusColor = Colors.amber;
        break;
      case 'in_progress':
        statusText = 'Viaje en curso';
        statusColor = Colors.green;
        break;
      default:
        statusText = 'Completado';
        statusColor = Colors.blue;
    }

    final progress = googleMiles > 0 ? (realMiles / googleMiles).clamp(0.0, 1.0) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Progress bar
            if (status == 'in_progress') ...[
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toStringAsFixed(0)}% completado',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Millas Recorridas',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '${realMiles.toStringAsFixed(1)} / ${googleMiles.toStringAsFixed(1)} mi',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (status == 'in_progress')
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Open chat
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Chat'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Make call
                  },
                  icon: const Icon(Icons.phone),
                  label: const Text('Llamar'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Share trip
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Compartir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
