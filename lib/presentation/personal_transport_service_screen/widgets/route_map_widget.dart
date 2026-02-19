import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sizer/sizer.dart';

class RouteMapWidget extends StatefulWidget {
  final Map<String, double> pickupCoordinates;
  final Map<String, double> dropoffCoordinates;
  final String pickupLocation;
  final String dropoffLocation;

  const RouteMapWidget({
    super.key,
    required this.pickupCoordinates,
    required this.dropoffCoordinates,
    required this.pickupLocation,
    required this.dropoffLocation,
  });

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> {
  MapController? _mapController;
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeMapData();
  }

  @override
  void didUpdateWidget(RouteMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pickupCoordinates != widget.pickupCoordinates ||
        oldWidget.dropoffCoordinates != widget.dropoffCoordinates) {
      _initializeMapData();
    }
  }

  void _initializeMapData() {
    final pickupLat = widget.pickupCoordinates['latitude']!;
    final pickupLng = widget.pickupCoordinates['longitude']!;
    final dropoffLat = widget.dropoffCoordinates['latitude']!;
    final dropoffLng = widget.dropoffCoordinates['longitude']!;

    _markers = [
      Marker(
        width: 40.0,
        height: 40.0,
        point: LatLng(pickupLat, pickupLng),
        child: const Icon(Icons.location_on, color: Colors.green, size: 40),
      ),
      Marker(
        width: 40.0,
        height: 40.0,
        point: LatLng(dropoffLat, dropoffLng),
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      ),
    ];

    _polylines = [
      Polyline(
        points: [LatLng(pickupLat, pickupLng), LatLng(dropoffLat, dropoffLng)],
        color: const Color(0xFF2196F3),
        strokeWidth: 4.0,
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _mapController != null) {
        _updateCameraBounds(pickupLat, pickupLng, dropoffLat, dropoffLng);
      }
    });

    setState(() {});
  }

  void _updateCameraBounds(
    double pickupLat,
    double pickupLng,
    double dropoffLat,
    double dropoffLng,
  ) {
    final bounds = LatLngBounds(
      LatLng(
        pickupLat < dropoffLat ? pickupLat : dropoffLat,
        pickupLng < dropoffLng ? pickupLng : dropoffLng,
      ),
      LatLng(
        pickupLat > dropoffLat ? pickupLat : dropoffLat,
        pickupLng > dropoffLng ? pickupLng : dropoffLng,
      ),
    );

    _mapController?.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pickupLat = widget.pickupCoordinates['latitude']!;
    final pickupLng = widget.pickupCoordinates['longitude']!;

    return Container(
      height: 35.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(pickupLat, pickupLng),
            initialZoom: 12.0,
            minZoom: 5.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.maximus.transport',
            ),
            PolylineLayer(polylines: _polylines),
            MarkerLayer(markers: _markers),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
