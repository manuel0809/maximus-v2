import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TrackingMapWidget extends StatefulWidget {
  final double driverLat;
  final double driverLng;
  final double pickupLat;
  final double pickupLng;
  final String driverName;
  final String vehicleModel;
  final String vehiclePlate;

  const TrackingMapWidget({
    super.key,
    required this.driverLat,
    required this.driverLng,
    required this.pickupLat,
    required this.pickupLng,
    required this.driverName,
    required this.vehicleModel,
    required this.vehiclePlate,
  });

  @override
  State<TrackingMapWidget> createState() => _TrackingMapWidgetState();
}

class _TrackingMapWidgetState extends State<TrackingMapWidget> {
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(TrackingMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.driverLat != widget.driverLat ||
        oldWidget.driverLng != widget.driverLng) {
      // Smoothly follow the driver if needed, but for now just update state
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverPos = LatLng(widget.driverLat, widget.driverLng);
    final pickupPos = LatLng(widget.pickupLat, widget.pickupLng);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: driverPos,
        initialZoom: 14.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.maximus.transport',
        ),
        MarkerLayer(
          markers: [
            // Pickup Marker
            Marker(
              point: pickupPos,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.person_pin_circle,
                color: Colors.green,
                size: 40,
              ),
            ),
            // Driver Marker
            Marker(
              point: driverPos,
              width: 50,
              height: 50,
              child: Stack(
                alignment: Alignment.center,
                children: [
                   Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1538).withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Icon(
                    Icons.directions_car,
                    color: Color(0xFF8B1538),
                    size: 30,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

