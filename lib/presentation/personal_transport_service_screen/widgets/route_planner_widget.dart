import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

import '../../../widgets/custom_icon_widget.dart';
import '../../../services/location_search_service.dart';

class RoutePlannerWidget extends StatefulWidget {
  final String pickupLocation;
  final String dropoffLocation;
  final String stopLocation;
  final bool hasStop;
  final DateTime? serviceDate;
  final TimeOfDay? serviceTime;
  final Function(String, double?, double?) onPickupLocationChanged;
  final Function(String, double?, double?) onDropoffLocationChanged;
  final Function(String, double?, double?) onStopLocationChanged;
  final Function(bool) onToggleStop;
  final Function(DateTime) onDateSelected;
  final Function(TimeOfDay) onTimeSelected;
  final VoidCallback? onPickupTap;
  final VoidCallback? onDropoffTap;
  final VoidCallback? onStopTap;

  const RoutePlannerWidget({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.stopLocation,
    required this.hasStop,
    required this.serviceDate,
    required this.serviceTime,
    required this.onPickupLocationChanged,
    required this.onDropoffLocationChanged,
    required this.onStopLocationChanged,
    required this.onToggleStop,
    required this.onDateSelected,
    required this.onTimeSelected,
    this.onPickupTap,
    this.onDropoffTap,
    this.onStopTap,
  });

  @override
  State<RoutePlannerWidget> createState() => _RoutePlannerWidgetState();
}

class _RoutePlannerWidgetState extends State<RoutePlannerWidget> {
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  final TextEditingController _stopController = TextEditingController();
  final LocationSearchService _locationSearchService = LocationSearchService();
  bool _isLoadingLocation = false;

  // Florida locations (Miami to Orlando area)
  final List<String> _savedLocations = [
    'Miami International Airport, FL',
    'Fort Lauderdale-Hollywood International Airport, FL',
    'Orlando International Airport, FL',
    'Miami Beach, FL',
    'Downtown Miami, FL',
    'Brickell, Miami, FL',
    'Fort Lauderdale, FL',
    'West Palm Beach, FL',
    'Boca Raton, FL',
    'Delray Beach, FL',
    'Pompano Beach, FL',
    'Hollywood, FL',
    'Aventura, FL',
    'Coral Gables, FL',
    'Key Biscayne, FL',
    'South Beach, Miami, FL',
    'Port of Miami, FL',
    'Orlando Downtown, FL',
    'Disney World, Orlando, FL',
    'Universal Studios, Orlando, FL',
  ];

  @override
  void initState() {
    super.initState();
    _pickupController.text = widget.pickupLocation;
    _dropoffController.text = widget.dropoffLocation;
    _stopController.text = widget.stopLocation;
  }

  @override
  void didUpdateWidget(RoutePlannerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pickupLocation != widget.pickupLocation) {
        _pickupController.text = widget.pickupLocation;
    }
    if (oldWidget.dropoffLocation != widget.dropoffLocation) {
        _dropoffController.text = widget.dropoffLocation;
    }
    if (oldWidget.stopLocation != widget.stopLocation) {
        _stopController.text = widget.stopLocation;
    }
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _stopController.dispose();
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
            'Punto de Recogida',
            _pickupController,
            'location_on',
            true,
            false,
            widget.onPickupTap,
          ),
          SizedBox(height: 2.h),

          // Add Stop Toggle
          Row(
            children: [
              CustomIconWidget(
                iconName: 'add_location_alt',
                color: theme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                '¿Agregar parada?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              Switch(
                value: widget.hasStop,
                onChanged: widget.onToggleStop,
                activeThumbColor: theme.colorScheme.primary,
              ),
            ],
          ),
          
          if (widget.hasStop) ...[
            SizedBox(height: 1.h),
            _buildLocationField(
              context,
              'Parada Intermedia',
              _stopController,
              'pause_circle_outline',
              false,
              true,
              widget.onStopTap,
            ),
          ],
          
          SizedBox(height: 2.h),

          // Dropoff Location
          _buildLocationField(
            context,
            'Punto de Destino',
            _dropoffController,
            'place',
            false,
            false,
            widget.onDropoffTap,
          ),
          SizedBox(height: 2.h),

          // Saved Locations
          _buildSavedLocations(context),

          SizedBox(height: 2.h),
          Divider(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          SizedBox(height: 2.h),

          // Date and Time Selection
          Row(
            children: [
              Expanded(child: _buildDateSelector(context)),
              SizedBox(width: 3.w),
              Expanded(child: _buildTimeSelector(context)),
            ],
          ),
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
    bool isStop,
    VoidCallback? onTap,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CustomIconWidget(
              iconName: icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            SizedBox(width: 2.w),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            if (isPickup)
              GestureDetector(
                onTap: _getCurrentLocation,
                child: Row(
                  children: [
                    if (_isLoadingLocation)
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      )
                    else
                      CustomIconWidget(
                        iconName: 'my_location',
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                    SizedBox(width: 1.w),
                    Text(
                      'Usar ubicación actual',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        SizedBox(height: 1.h),
        Autocomplete<LocationSuggestion>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.length < 3) {
              return const Iterable<LocationSuggestion>.empty();
            }
            try {
              final results = await _locationSearchService.searchAddress(
                textEditingValue.text,
              );
              return results;
            } catch (e) {
              debugPrint('Autocomplete options error: $e');
              return const Iterable<LocationSuggestion>.empty();
            }
          },
          displayStringForOption: (LocationSuggestion option) =>
              option.displayName,
          onSelected: (LocationSuggestion selection) {
            controller.text = selection.displayName;
            if (isPickup) {
              widget.onPickupLocationChanged(
                selection.displayName,
                selection.latitude,
                selection.longitude,
              );
            } else if (isStop) {
              widget.onStopLocationChanged(
                selection.displayName,
                selection.latitude,
                selection.longitude,
              );
            } else {
              widget.onDropoffLocationChanged(
                selection.displayName,
                selection.latitude,
                selection.longitude,
              );
            }
          },
          fieldViewBuilder: (
            BuildContext context,
            TextEditingController fieldTextEditingController,
            FocusNode fieldFocusNode,
            VoidCallback onFieldSubmitted,
          ) {
            // Sync initial value only once or when external controller changes
            if (controller.text.isNotEmpty &&
                fieldTextEditingController.text != controller.text) {
              Future.microtask(() {
                if (mounted) {
                  fieldTextEditingController.text = controller.text;
                }
              });
            }

            return TextField(
              controller: fieldTextEditingController,
              focusNode: fieldFocusNode,
              onTap: onTap,
              onChanged: (value) {
                // Update parent when text changes manually (without selection)
                if (isPickup) {
                  widget.onPickupLocationChanged(value, null, null);
                } else if (isStop) {
                  widget.onStopLocationChanged(value, null, null);
                } else {
                  widget.onDropoffLocationChanged(value, null, null);
                }
              },
              decoration: InputDecoration(
                hintText: 'Ingresa la dirección',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.6,
                  ),
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
                suffixIcon: fieldTextEditingController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: theme.colorScheme.onSurfaceVariant),
                        onPressed: () {
                          fieldTextEditingController.clear();
                          controller.clear();
                          if (isPickup) {
                            widget.onPickupLocationChanged('', null, null);
                          } else if (isStop) {
                            widget.onStopLocationChanged('', null, null);
                          } else {
                            widget.onDropoffLocationChanged('', null, null);
                          }
                        },
                      )
                    : null,
              ),
              style: theme.textTheme.bodyMedium,
            );
          },
          optionsViewBuilder: (
            BuildContext context,
            AutocompleteOnSelected<LocationSuggestion> onSelected,
            Iterable<LocationSuggestion> options,
          ) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4.0,
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  width: MediaQuery.of(context).size.width - 8.w, // Match field width
                  constraints: BoxConstraints(maxHeight: 30.h),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final LocationSuggestion option = options.elementAt(index);
                      return ListTile(
                        leading: Icon(
                          Icons.location_on,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        title: Text(
                          option.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
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
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: _savedLocations.map((location) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (_pickupController.text.isEmpty) {
                    _pickupController.text = location;
                    widget.onPickupLocationChanged(location, null, null);
                  } else {
                    _dropoffController.text = location;
                    widget.onDropoffLocationChanged(location, null, null);
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  location,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    final theme = Theme.of(context);
    final dateText = widget.serviceDate != null
        ? DateFormat('dd/MM/yyyy').format(widget.serviceDate!)
        : 'Seleccionar fecha';

    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: 'calendar_today',
              color: theme.colorScheme.primary,
              size: 20,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                dateText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: widget.serviceDate != null
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(BuildContext context) {
    final theme = Theme.of(context);
    final timeText = widget.serviceTime != null
        ? widget.serviceTime!.format(context)
        : 'Seleccionar hora';

    return GestureDetector(
      onTap: () => _selectTime(context),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: 'access_time',
              color: theme.colorScheme.primary,
              size: 20,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                timeText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: widget.serviceTime != null
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      final locationText =
          'Ubicación actual (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';

      setState(() {
        _pickupController.text = locationText;
        widget.onPickupLocationChanged(locationText, position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.serviceDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      widget.onDateSelected(picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: widget.serviceTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      widget.onTimeSelected(picked);
    }
  }
}
