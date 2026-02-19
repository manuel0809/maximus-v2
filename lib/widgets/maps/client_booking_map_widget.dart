import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../services/google_maps_service.dart' as gms;

/// Client booking map widget for selecting pickup/dropoff and viewing route
class ClientBookingMapWidget extends StatefulWidget {
  final Function(gms.LatLng pickup, gms.LatLng dropoff, double miles, int minutes)? onRouteCalculated;

  const ClientBookingMapWidget({
    super.key,
    this.onRouteCalculated,
  });

  @override
  State<ClientBookingMapWidget> createState() => _ClientBookingMapWidgetState();
}

class _ClientBookingMapWidgetState extends State<ClientBookingMapWidget> {
  GoogleMapController? _mapController;
  final _mapsService = gms.GoogleMapsService.instance;

  gms.LatLng? _pickupLocation;
  gms.LatLng? _dropoffLocation;
  gms.RouteInfo? _routeInfo;
  List<LatLng> _polylineCoordinates = [];

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  bool _isCalculatingRoute = false;

  List<gms.PlacePrediction> _searchResults = [];

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
          onMapCreated: (controller) => _mapController = controller,
          markers: _markers,
          polylines: _polylines,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          onTap: _onMapTapped,
        ),

        // Search bar
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: _buildSearchBar(),
        ),

        // Route info card
        if (_routeInfo != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildRouteInfoCard(),
          ),

        // Loading indicator
        if (_isCalculatingRoute)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Card(
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: 'Buscar dirección...',
              prefixIcon: Icon(Icons.search),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            onChanged: _onSearchChanged,
          ),
          if (_searchResults.isNotEmpty)
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final prediction = _searchResults[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(prediction.mainText),
                    subtitle: Text(prediction.secondaryText),
                    onTap: () => _onPlaceSelected(prediction),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRouteInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Información de Ruta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.straighten, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_routeInfo!.distanceMiles.toStringAsFixed(1)} millas',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_routeInfo!.durationMinutes} minutos',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                if (_pickupLocation != null && _dropoffLocation != null) {
                  widget.onRouteCalculated?.call(
                    _pickupLocation!,
                    _dropoffLocation!,
                    _routeInfo!.distanceMiles,
                    _routeInfo!.durationMinutes,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Continuar con Reserva'),
            ),
          ],
        ),
      ),
    );
  }

  void _onMapTapped(LatLng position) {
    final location = gms.LatLng(position.latitude, position.longitude);

    if (_pickupLocation == null) {
      setState(() {
        _pickupLocation = location;
        _updateMarkers();
      });
    } else if (_dropoffLocation == null) {
      setState(() {
        _dropoffLocation = location;
        _updateMarkers();
      });
      _calculateRoute();
    } else {
      // Reset and start over
      setState(() {
        _pickupLocation = location;
        _dropoffLocation = null;
        _routeInfo = null;
        _polylineCoordinates.clear();
        _polylines.clear();
        _updateMarkers();
      });
    }
  }

  void _updateMarkers() {
    _markers.clear();

    if (_pickupLocation != null) {
      _markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(_pickupLocation!.latitude, _pickupLocation!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'Punto de Recogida'),
      ));
    }

    if (_dropoffLocation != null) {
      _markers.add(Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(_dropoffLocation!.latitude, _dropoffLocation!.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Destino'),
      ));
    }
  }

  Future<void> _calculateRoute() async {
    if (_pickupLocation == null || _dropoffLocation == null) return;

    setState(() => _isCalculatingRoute = true);

    try {
      final route = await _mapsService.calculateRoute(
        origin: _pickupLocation!,
        destination: _dropoffLocation!,
      );

      // Decode polyline
      final polylinePoints = PolylinePoints();
      final result = polylinePoints.decodePolyline(route.polyline);

      setState(() {
        _routeInfo = route;
        _polylineCoordinates = result
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();

        _polylines.clear();
        _polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          points: _polylineCoordinates,
          color: Colors.blue,
          width: 5,
        ));
      });

      // Adjust camera to show entire route
      if (_mapController != null && _polylineCoordinates.isNotEmpty) {
        final bounds = _calculateBounds(_polylineCoordinates);
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error calculando ruta: $e')),
        );
      }
    } finally {
      setState(() => _isCalculatingRoute = false);
    }
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() {
        // _searchQuery = '';
        _searchResults.clear();
      });
      return;
    }

    // setState(() => _searchQuery = query);

    try {
      final results = await _mapsService.searchPlaces(query);
      setState(() => _searchResults = results);
    } catch (e) {
      debugPrint('Error searching places: $e');
    }
  }

  Future<void> _onPlaceSelected(gms.PlacePrediction prediction) async {
    try {
      final location = await _mapsService.getPlaceCoordinates(prediction.placeId);

      setState(() {
        _searchResults.clear();
        // _searchQuery = '';
      });

      if (_pickupLocation == null) {
        setState(() {
          _pickupLocation = location;
          _updateMarkers();
        });
      } else if (_dropoffLocation == null) {
        setState(() {
          _dropoffLocation = location;
          _updateMarkers();
        });
        _calculateRoute();
      }

      // Move camera to selected location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(location.latitude, location.longitude),
          14,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error seleccionando lugar: $e')),
        );
      }
    }
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    double south = points.first.latitude;
    double north = points.first.latitude;
    double west = points.first.longitude;
    double east = points.first.longitude;

    for (final point in points) {
      if (point.latitude < south) south = point.latitude;
      if (point.latitude > north) north = point.latitude;
      if (point.longitude < west) west = point.longitude;
      if (point.longitude > east) east = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }
}
