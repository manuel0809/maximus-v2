import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

enum MapSelectionMode { pickup, dropoff, stop }

class MapboxLocationPickerWidget extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final List<Map<String, double>> stops;
  final MapSelectionMode selectionMode;
  final Function(double lat, double lng, String address)? onLocationSelected;
  final double defaultLatitude;
  final double defaultLongitude;
  final double defaultZoom;

  const MapboxLocationPickerWidget({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.stops = const [],
    this.selectionMode = MapSelectionMode.pickup,
    this.onLocationSelected,
    this.defaultLatitude = 25.7617,
    this.defaultLongitude = -80.1918,
    this.defaultZoom = 12.0,
  });

  @override
  State<MapboxLocationPickerWidget> createState() =>
      _MapboxLocationPickerWidgetState();
}

class _MapboxLocationPickerWidgetState
    extends State<MapboxLocationPickerWidget> {
  final MapController _mapController = MapController();
  bool _isLoadingLocation = false;

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _updateLocation(
          position.latitude, position.longitude, 'Mi ubicación actual');

      _mapController.move(
        LatLng(position.latitude, position.longitude),
        15.0,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ubicación actual obtenida'),
          backgroundColor: Color(0xFF2E7D32),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener ubicación: $e'),
          backgroundColor: const Color(0xFFC62828),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _updateLocation(double lat, double lng, String address) {
    if (widget.onLocationSelected != null) {
      widget.onLocationSelected!(lat, lng, address);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine initial center
    LatLng initialCenter;
    final double? effectivePickupLat = widget.pickupLat ?? widget.initialLatitude;
    final double? effectivePickupLng = widget.pickupLng ?? widget.initialLongitude;

    if (effectivePickupLat != null && effectivePickupLng != null) {
      initialCenter = LatLng(effectivePickupLat, effectivePickupLng);
    } else {
      initialCenter = LatLng(widget.defaultLatitude, widget.defaultLongitude);
    }

    final markers = <Marker>[];

    // Pickup Marker
    if (effectivePickupLat != null && effectivePickupLng != null) {
      markers.add(
        Marker(
          point: LatLng(effectivePickupLat, effectivePickupLng),
          width: 40,
          height: 40,
          alignment: Alignment.topCenter,
          child: const Icon(
            Icons.location_on,
            color: Color(0xFF2E7D32), // Green for pickup
            size: 40,
          ),
        ),
      );
    }

    // Stop Markers
    for (var i = 0; i < widget.stops.length; i++) {
        final stop = widget.stops[i];
        if (stop['latitude'] != null && stop['longitude'] != null) {
            markers.add(
                Marker(
                    point: LatLng(stop['latitude']!, stop['longitude']!),
                    width: 35,
                    height: 35,
                    alignment: Alignment.topCenter,
                    child: const Icon(
                        Icons.location_on,
                        color: Colors.orange, // Orange for stops
                        size: 35,
                    ),
                ),
            );
        }
    }

    // Dropoff Marker
    if (widget.dropoffLat != null && widget.dropoffLng != null) {
      markers.add(
        Marker(
          point: LatLng(widget.dropoffLat!, widget.dropoffLng!),
          width: 40,
          height: 40,
          alignment: Alignment.topCenter,
          child: const Icon(
            Icons.location_on,
            color: Color(0xFF8B1538), // Red Color for dropoff
            size: 40,
          ),
        ),
      );
    }

    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: widget.defaultZoom,
                onTap: (tapPosition, point) {
                  _updateLocation(point.latitude, point.longitude,
                      'Ubicación seleccionada');
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.maximus.transport',
                ),
                if (markers.isNotEmpty) MarkerLayer(markers: markers),
              ],
            ),

            // Mode Indicator
            Positioned(
              top: 2.h,
              left: 2.w,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: Text(
                  widget.selectionMode == MapSelectionMode.pickup
                      ? 'Seleccionando: Recogida'
                      : widget.selectionMode == MapSelectionMode.dropoff
                          ? 'Seleccionando: Destino'
                          : 'Seleccionando: Parada',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.selectionMode == MapSelectionMode.pickup
                        ? Colors.green
                        : widget.selectionMode == MapSelectionMode.dropoff
                            ? const Color(0xFF8B1538)
                            : Colors.orange,
                  ),
                ),
              ),
            ),

            // Current Location Button
            Positioned(
              top: 2.h,
              right: 2.w,
              child: FloatingActionButton.small(
                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                backgroundColor: theme.colorScheme.surface,
                child: _isLoadingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.my_location, color: theme.colorScheme.primary),
              ),
            ),

            // Zoom Controls
            Positioned(
              bottom: 10.h,
              right: 2.w,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'zoomIn',
                    onPressed: () {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom + 1,
                      );
                    },
                    backgroundColor: theme.colorScheme.surface,
                    child: const Icon(Icons.add),
                  ),
                  SizedBox(height: 1.h),
                  FloatingActionButton.small(
                    heroTag: 'zoomOut',
                    onPressed: () {
                      _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom - 1,
                      );
                    },
                    backgroundColor: theme.colorScheme.surface,
                    child: const Icon(Icons.remove),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}