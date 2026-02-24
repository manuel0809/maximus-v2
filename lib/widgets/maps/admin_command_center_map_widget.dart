import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../services/trip_tracking_service.dart';
import '../../core/constants/app_roles.dart';

/// Admin command center map showing all active trips and drivers
class AdminCommandCenterMapWidget extends StatefulWidget {
  final AppRole userRole;

  const AdminCommandCenterMapWidget({
    super.key,
    required this.userRole,
  });

  @override
  State<AdminCommandCenterMapWidget> createState() => _AdminCommandCenterMapWidgetState();
}

class _AdminCommandCenterMapWidgetState extends State<AdminCommandCenterMapWidget> {
  final _trackingService = TripTrackingService.instance;

  StreamSubscription? _tripsSubscription;
  List<Map<String, dynamic>> _activeTrips = [];

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  Map<String, dynamic>? _selectedTrip;

  @override
  void initState() {
    super.initState();
    _subscribeToActiveTrips();
  }

  @override
  void dispose() {
    _tripsSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToActiveTrips() {
    _tripsSubscription = _trackingService.streamAllActiveTrips().listen((trips) {
      setState(() {
        _activeTrips = trips;
        _updateMapElements();
      });
    });
  }

  void _updateMapElements() {
    _markers.clear();
    _polylines.clear();

    for (final trip in _activeTrips) {
      final tripId = trip['id'] as String;
      final driverLat = trip['current_driver_lat'];
      final driverLng = trip['current_driver_lng'];

      if (driverLat != null && driverLng != null) {
        final status = trip['status'] as String;
        BitmapDescriptor icon;

        switch (status) {
          case 'en_route_to_pickup':
            icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
            break;
          case 'waiting_at_pickup':
            icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
            break;
          case 'in_progress':
            icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
            break;
          default:
            icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
        }

        _markers.add(Marker(
          markerId: MarkerId('driver_$tripId'),
          position: LatLng(
            (driverLat as num).toDouble(),
            (driverLng as num).toDouble(),
          ),
          icon: icon,
          infoWindow: InfoWindow(
            title: 'Viaje #${tripId.substring(0, 8)}',
            snippet: _getStatusText(status),
          ),
          onTap: () => _onTripSelected(trip),
        ));
      }
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'en_route_to_pickup':
        return 'En camino a recoger';
      case 'waiting_at_pickup':
        return 'Esperando';
      case 'in_progress':
        return 'En viaje';
      default:
        return 'Desconocido';
    }
  }

  void _onTripSelected(Map<String, dynamic> trip) {
    setState(() => _selectedTrip = trip);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Google Map
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(25.7617, -80.1918), // Miami
            zoom: 11,
          ),
          onMapCreated: (controller) {
            if (_activeTrips.isNotEmpty) {
              _updateMapElements();
            }
          },
          markers: _markers,
          polylines: _polylines,
          zoomControlsEnabled: false,
        ),

        // Metrics dashboard
        Positioned(
          top: 16,
          left: 16,
          child: _buildMetricsDashboard(),
        ),

        // Active trips list
        Positioned(
          top: 16,
          right: 16,
          child: _buildActiveTripsList(),
        ),

        // Selected trip details
        if (_selectedTrip != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildTripDetailsCard(),
          ),
      ],
    );
  }

  Widget _buildMetricsDashboard() {
    final enRouteCount = _activeTrips.where((t) => t['status'] == 'en_route_to_pickup').length;
    final waitingCount = _activeTrips.where((t) => t['status'] == 'waiting_at_pickup').length;
    final inProgressCount = _activeTrips.where((t) => t['status'] == 'in_progress').length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '📊 AHORA MISMO',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildMetricRow('🚗 Viajes activos', _activeTrips.length.toString()),
            _buildMetricRow('🟠 En camino', enRouteCount.toString()),
            _buildMetricRow('🟡 Esperando', waitingCount.toString()),
            _buildMetricRow('🟢 En curso', inProgressCount.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTripsList() {
    return Card(
      child: Container(
        width: 300,
        constraints: const BoxConstraints(maxHeight: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Viajes Activos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _activeTrips.length,
                itemBuilder: (context, index) {
                  final trip = _activeTrips[index];
                  return ListTile(
                    leading: Icon(
                      Icons.local_taxi,
                      color: _getStatusColor(trip['status'] as String),
                    ),
                    title: Text('Viaje #${(trip['id'] as String).substring(0, 8)}'),
                    subtitle: Text(_getStatusText(trip['status'] as String)),
                    trailing: Text(
                      '${(trip['real_gps_distance_miles'] as num).toStringAsFixed(1)} mi',
                    ),
                    onTap: () => _onTripSelected(trip),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'en_route_to_pickup':
        return Colors.orange;
      case 'waiting_at_pickup':
        return Colors.amber;
      case 'in_progress':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Widget _buildTripDetailsCard() {
    final googleMiles = (_selectedTrip!['google_maps_distance_miles'] as num).toDouble();
    final realMiles = (_selectedTrip!['real_gps_distance_miles'] as num).toDouble();
    final chargedMiles = (_selectedTrip!['charged_distance_miles'] as num).toDouble();
    final deviation = (_selectedTrip!['deviation_percentage'] as num?)?.toDouble() ?? 0.0;
    final speed = (_selectedTrip!['current_speed_mph'] as num?)?.toDouble() ?? 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Viaje #${(_selectedTrip!['id'] as String).substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedTrip = null),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailColumn('Google Maps', '${googleMiles.toStringAsFixed(1)} mi'),
                _buildDetailColumn('GPS Real', '${realMiles.toStringAsFixed(1)} mi'),
                _buildDetailColumn('Cobradas', '${chargedMiles.toStringAsFixed(1)} mi'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailColumn('Desviación', '${deviation.toStringAsFixed(1)}%'),
                _buildDetailColumn('Velocidad', '${speed.toStringAsFixed(0)} mph'),
              ],
            ),
            if (deviation > 20) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '⚠️ Desviación alta de ruta',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailColumn(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
