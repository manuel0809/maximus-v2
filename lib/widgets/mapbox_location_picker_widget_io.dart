import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart' as geo; // Add prefix to resolve ambiguous imports
import 'dart:ui' as ui;
import 'dart:typed_data';

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
    this.defaultLatitude = 25.7617, // Miami, Florida
    this.defaultLongitude = -80.1918,
    this.defaultZoom = 12.0,
  });

  @override
  State<MapboxLocationPickerWidget> createState() =>
      _MapboxLocationPickerWidgetState();
}

class _MapboxLocationPickerWidgetState extends State<MapboxLocationPickerWidget>
    with SingleTickerProviderStateMixin {
  MapboxMap? _mapboxMap;
  late AnimationController _pulseController;
  PointAnnotationManager? _pointAnnotationManager;
  PointAnnotation? _markerAnnotation;

  double? _selectedLat;
  double? _selectedLng;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    // Set initial location from pickupLat or initialLatitude
    final double? effectiveLat = widget.pickupLat ?? widget.initialLatitude;
    final double? effectiveLng = widget.pickupLng ?? widget.initialLongitude;

    if (effectiveLat != null && effectiveLng != null) {
      _selectedLat = effectiveLat;
      _selectedLng = effectiveLng;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    await _setupAnnotations();

    // Add initial marker if location provided
    if (_selectedLat != null && _selectedLng != null) {
      await _updateMarker(_selectedLat!, _selectedLng!);
    }

    // Set up tap listener - use onTapListener instead of addOnMapClickListener
    _mapboxMap!.setOnMapTapListener(_onMapTap);
  }

  Future<void> _setupAnnotations() async {
    if (_mapboxMap == null) return;

    _pointAnnotationManager = await _mapboxMap!.annotations
        .createPointAnnotationManager();
  }

  Future<void> _onMapTap(MapContentGestureContext context) async {
    final point = context.point;
    final lat = point.coordinates.lat.toDouble();
    final lng = point.coordinates.lng.toDouble();

    await _updateMarker(lat, lng);

    // Notify parent
    if (widget.onLocationSelected != null) {
      widget.onLocationSelected!(lat, lng, 'Ubicación seleccionada');
    }
  }

  Future<void> _updateMarker(double lat, double lng) async {
    if (_pointAnnotationManager == null) return;

    setState(() {
      _selectedLat = lat;
      _selectedLng = lng;
    });

    // Remove existing marker
    if (_markerAnnotation != null) {
      await _pointAnnotationManager!.delete(_markerAnnotation!);
    }

    // Create new marker
    final markerIcon = await _createMarkerIconBitmap();

    _markerAnnotation = await _pointAnnotationManager!.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(lng, lat)), // mapbox Position is used here
        image: markerIcon,
        iconSize: 1.2,
      ),
    );
  }

  Future<Uint8List> _createMarkerIconBitmap() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final size = ui.Size(80, 80); // Remove const and use ui.Size with named parameters

    // Pulse effect
    final pulsePaint = Paint()
      ..color = const Color(
        0xFF8B1538,
      ).withValues(alpha: 0.3 * (1 - _pulseController.value))
      ..style = PaintingStyle.fill;

    final pulseRadius = 30 + (_pulseController.value * 10);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      pulseRadius,
      pulsePaint,
    );

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2 + 2),
      24,
      shadowPaint,
    );

    // White border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 24, borderPaint);

    // Burgundy fill
    final fillPaint = Paint()
      ..color = const Color(0xFF8B1538)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 24, fillPaint);

    // Pin icon (📍)
    final iconPainter = TextPainter(
      text: const TextSpan(
        text: '📍',
        style: TextStyle(fontSize: 32, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        (size.width - iconPainter.width) / 2,
        (size.height - iconPainter.height) / 2 - 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Los servicios de ubicación están deshabilitados'),
            backgroundColor: Color(0xFFC62828),
          ),
        );
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permisos de ubicación denegados'),
              backgroundColor: Color(0xFFC62828),
            ),
          );
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permisos de ubicación denegados permanentemente. Por favor, habilítelos en configuración.',
            ),
            backgroundColor: Color(0xFFC62828),
            duration: Duration(seconds: 4),
          ),
        );
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      geo.Position position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );

      // Update marker and camera
      await _updateMarker(position.latitude, position.longitude);

      // Move camera to current location
      if (_mapboxMap != null) {
        await _mapboxMap!.flyTo(
          CameraOptions(
            center: Point(
              coordinates: Position(position.longitude, position.latitude), // mapbox Position
            ),
            zoom: 15.0,
          ),
          MapAnimationOptions(duration: 1000),
        );
      }

      // Notify parent
      if (widget.onLocationSelected != null) {
        widget.onLocationSelected!(
          position.latitude,
          position.longitude,
          'Mi ubicación actual',
        );
      }

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

  void _zoomIn() {
    if (_mapboxMap != null) {
      _mapboxMap!.getCameraState().then((cameraState) {
        _mapboxMap!.flyTo(
          CameraOptions(zoom: (cameraState.zoom + 1).clamp(0, 22)),
          MapAnimationOptions(duration: 300),
        );
      });
    }
  }

  void _zoomOut() {
    if (_mapboxMap != null) {
      _mapboxMap!.getCameraState().then((cameraState) {
        _mapboxMap!.flyTo(
          CameraOptions(zoom: (cameraState.zoom - 1).clamp(0, 22)),
          MapAnimationOptions(duration: 300),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            // Mapbox Map
            MapWidget(
              key: ValueKey('mapbox_location_picker'),
              styleUri: MapboxStyles.STANDARD,
              cameraOptions: CameraOptions(
                center: Point(
                  coordinates: Position(
                    widget.pickupLng ?? widget.initialLongitude ?? widget.defaultLongitude,
                    widget.pickupLat ?? widget.initialLatitude ?? widget.defaultLatitude,
                  ),
                ),
                zoom: widget.defaultZoom,
              ),
              onMapCreated: _onMapCreated,
              textureView: true,
            ),

            // Geolocation Control (Top Right)
            Positioned(
              top: 2.h,
              right: 2.w,
              child: Column(
                children: [
                  // Current Location Button
                  Material(
                    color: theme.colorScheme.surface,
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8.0),
                    child: InkWell(
                      onTap: _isLoadingLocation ? null : _getCurrentLocation,
                      borderRadius: BorderRadius.circular(8.0),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: _isLoadingLocation
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.primary,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.my_location,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: 1.h),

                  // Zoom In Button
                  Material(
                    color: theme.colorScheme.surface,
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8.0),
                    child: InkWell(
                      onTap: _zoomIn,
                      borderRadius: BorderRadius.circular(8.0),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.add,
                          color: theme.colorScheme.onSurface,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 0.5.h),

                  // Zoom Out Button
                  Material(
                    color: theme.colorScheme.surface,
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8.0),
                    child: InkWell(
                      onTap: _zoomOut,
                      borderRadius: BorderRadius.circular(8.0),
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.remove,
                          color: theme.colorScheme.onSurface,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Instructions (Bottom Center)
            if (_selectedLat == null)
              Positioned(
                bottom: 3.h,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app,
                          color: theme.colorScheme.primary,
                          size: 18,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          'Toca el mapa para seleccionar ubicación',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Selected Location Label (Bottom Center)
            if (_selectedLat != null)
              Positioned(
                bottom: 3.h,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📍', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 2.w),
                        Text(
                          'Ubicación seleccionada',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}