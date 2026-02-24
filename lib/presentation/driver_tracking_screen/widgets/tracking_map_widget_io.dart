// The errors indicate that this is a platform-specific file (_io.dart) that is missing the imports
// All the undefined classes and methods are from Flutter/Dart packages that need to be imported
// This file appears to be incorrectly structured - these imports should exist at the top

// The primary issue is that the imports at lines 1-3 are flagged as non-existent
// This typically happens when analyzing a platform-specific file in the wrong context
// However, since we need to fix the errors as presented, the file structure suggests
// this is meant to be a stub or conditional import file

// Since all errors stem from missing imports that should exist, and this appears to be
// a platform-specific implementation file that's being analyzed in wrong context,
// the file needs a conditional compilation guard or proper import structure

// For a _io.dart file that should only compile on native platforms:
// Add conditional check capability

// Keep existing imports but wrapped
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

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

class _TrackingMapWidgetState extends State<TrackingMapWidget>
    with SingleTickerProviderStateMixin {
  MapboxMap? _mapboxMap;
  late AnimationController _pulseController;
  PointAnnotationManager? _pointAnnotationManager;
  PolylineAnnotationManager? _polylineAnnotationManager;
  PointAnnotation? _driverAnnotation;
  PolylineAnnotation? _routePolyline;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void didUpdateWidget(TrackingMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.driverLat != widget.driverLat ||
        oldWidget.driverLng != widget.driverLng) {
      _updateDriverPosition();
      _updateCameraBounds();
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
    _updateCameraBounds();
  }

  Future<void> _setupAnnotations() async {
    if (_mapboxMap == null) return;

    _pointAnnotationManager = await _mapboxMap!.annotations
        .createPointAnnotationManager();
    _polylineAnnotationManager = await _mapboxMap!.annotations
        .createPolylineAnnotationManager();

    await _createDriverMarker();
    await _createPickupMarker();
    await _createRoutePolyline();
  }

  Future<void> _createDriverMarker() async {
    if (_pointAnnotationManager == null) return;

    final driverIcon = await _createDriverIconBitmap();

    _driverAnnotation = await _pointAnnotationManager!.create(
      PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(widget.driverLng, widget.driverLat),
        ),
        image: driverIcon,
        iconSize: 1.5,
      ),
    );
  }

  Future<void> _createPickupMarker() async {
    if (_pointAnnotationManager == null) return;

    final pickupIcon = await _createPickupIconBitmap();

    await _pointAnnotationManager!.create(
      PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(widget.pickupLng, widget.pickupLat),
        ),
        image: pickupIcon,
        iconSize: 1.2,
      ),
    );
  }

  Future<void> _createRoutePolyline() async {
    if (_polylineAnnotationManager == null) return;

    _routePolyline = await _polylineAnnotationManager!.create(
      PolylineAnnotationOptions(
        geometry: LineString(
          coordinates: [
            Position(widget.driverLng, widget.driverLat),
            Position(widget.pickupLng, widget.pickupLat),
          ],
        ),
        lineColor: 0xFF8B1538,
        lineWidth: 4.0,
      ),
    );
  }

  Future<Uint8List> _createDriverIconBitmap() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final size = Size(width: 80, height: 80);

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

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2 + 2),
      25,
      shadowPaint,
    );

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 25, borderPaint);

    final fillPaint = Paint()
      ..color = const Color(0xFF8B1538)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 25, fillPaint);

    final iconPainter = TextPainter(
      text: const TextSpan(
        text: '\\u{1F697}',
        style: TextStyle(fontSize: 28, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        (size.width - iconPainter.width) / 2,
        (size.height - iconPainter.height) / 2,
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

  Future<Uint8List> _createPickupIconBitmap() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final size = Size(width: 50, height: 50);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2 + 2),
      25,
      shadowPaint,
    );

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 25, borderPaint);

    final fillPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 25, fillPaint);

    final iconPainter = TextPainter(
      text: const TextSpan(
        text: '\\u{1F464}',
        style: TextStyle(fontSize: 28, color: Colors.white),
      ),
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        (size.width - iconPainter.width) / 2,
        (size.height - iconPainter.height) / 2,
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

  Future<void> _updateDriverPosition() async {
    if (_driverAnnotation == null || _pointAnnotationManager == null) return;

    await _pointAnnotationManager!.delete(_driverAnnotation!);
    await _createDriverMarker();

    if (_routePolyline != null && _polylineAnnotationManager != null) {
      await _polylineAnnotationManager!.delete(_routePolyline!);
      await _createRoutePolyline();
    }
  }

  void _updateCameraBounds() async {
    if (_mapboxMap == null || !mounted) return;

    await _mapboxMap!.setCamera(
      CameraOptions(
        center: Point(
          coordinates: Position(
            (widget.driverLng + widget.pickupLng) / 2,
            (widget.driverLat + widget.pickupLat) / 2,
          ),
        ),
        padding: MbxEdgeInsets(top: 100, left: 100, bottom: 100, right: 100),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const String accessToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');

    if (accessToken.isEmpty) {
      return const Center(
        child: Text(
          'Error: MAPBOX_ACCESS_TOKEN no configurado',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return MapWidget(
      key: ValueKey('map_${widget.driverLat}_${widget.driverLng}'),
      cameraOptions: CameraOptions(
        center: Point(
          coordinates: Position(widget.driverLng, widget.driverLat),
        ),
        zoom: 13.0,
      ),
      styleUri: MapboxStyles.MAPBOX_STREETS,
      textureView: true,
      onMapCreated: _onMapCreated,
    );
  }
}
