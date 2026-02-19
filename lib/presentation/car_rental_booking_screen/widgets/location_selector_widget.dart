import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class LocationSelectorWidget extends StatefulWidget {
  final String pickupLocation;
  final String dropoffLocation;
  final Function(String) onPickupLocationChanged;
  final Function(String) onDropoffLocationChanged;

  const LocationSelectorWidget({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.onPickupLocationChanged,
    required this.onDropoffLocationChanged,
  });

  @override
  State<LocationSelectorWidget> createState() => _LocationSelectorWidgetState();
}

class _LocationSelectorWidgetState extends State<LocationSelectorWidget> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  bool _isLoadingLocation = false;

  final List<String> _savedLocations = [
    'Aeropuerto Madrid-Barajas',
    'Estación de Atocha',
    'Plaza Mayor, Madrid',
    'Aeropuerto Barcelona-El Prat',
    'Oficina Central MAXIMUS',
  ];

  @override
  void initState() {
    super.initState();
    _pickupController.text = widget.pickupLocation;
    _dropoffController.text = widget.dropoffLocation;
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Pickup Location
          _buildLocationField(
            context,
            'Lugar de Recogida',
            _pickupController,
            'location_on',
            true,
          ),
          SizedBox(height: 2.h),
          // Dropoff Location
          _buildLocationField(
            context,
            'Lugar de Devolución',
            _dropoffController,
            'location_on',
            false,
          ),
          SizedBox(height: 2.h),
          // Saved Locations
          _buildSavedLocations(context),
        ],
      ),
    );
  }

  Widget _buildLocationField(
    BuildContext context,
    String label,
    TextEditingController controller,
    String icon,
    bool isPickup,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        TextField(
          controller: controller,
          onChanged: (value) {
            if (isPickup) {
              widget.onPickupLocationChanged(value);
            } else {
              widget.onDropoffLocationChanged(value);
            }
          },
          decoration: InputDecoration(
            hintText: 'Ingrese dirección',
            prefixIcon: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: icon,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            suffixIcon: IconButton(
              icon: _isLoadingLocation
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
                  : CustomIconWidget(
                      iconName: 'my_location',
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
              onPressed: _isLoadingLocation
                  ? null
                  : () => _getCurrentLocation(isPickup),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 3.w,
              vertical: 1.5.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedLocations(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ubicaciones Guardadas',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _savedLocations.map((location) {
            return GestureDetector(
              onTap: () => _selectSavedLocation(location),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: 'bookmark',
                      color: theme.colorScheme.primary,
                      size: 14,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      location,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _getCurrentLocation(bool isPickup) async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Los servicios de ubicación están deshabilitados'),
          ),
        );
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permisos de ubicación denegados')),
          );
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permisos de ubicación denegados permanentemente'),
          ),
        );
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      final locationText =
          'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';

      if (isPickup) {
        _pickupController.text = locationText;
        widget.onPickupLocationChanged(locationText);
      } else {
        _dropoffController.text = locationText;
        widget.onDropoffLocationChanged(locationText);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al obtener ubicación: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _selectSavedLocation(String location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar ubicación'),
        content: Text(
          '¿Usar "$location" como ubicación de recogida o devolución?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              _pickupController.text = location;
              widget.onPickupLocationChanged(location);
              Navigator.pop(context);
            },
            child: const Text('Recogida'),
          ),
          TextButton(
            onPressed: () {
              _dropoffController.text = location;
              widget.onDropoffLocationChanged(location);
              Navigator.pop(context);
            },
            child: const Text('Devolución'),
          ),
        ],
      ),
    );
  }
}
