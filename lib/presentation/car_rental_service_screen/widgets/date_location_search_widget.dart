import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/mapbox_location_picker_widget.dart'
    if (dart.library.io) '../../../widgets/mapbox_location_picker_widget_io.dart'
    if (dart.library.html) '../../../widgets/mapbox_location_picker_widget_web.dart';

class DateLocationSearchWidget extends StatefulWidget {
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final DateTime? pickupDate;
  final DateTime? dropoffDate;
  final Function(double, double) onPickupLocationChanged;
  final Function(double, double) onDropoffLocationChanged;
  final Function(DateTime) onPickupDateChanged;
  final Function(DateTime) onDropoffDateChanged;
  final VoidCallback onSearchPressed;

  const DateLocationSearchWidget({
    super.key,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    required this.pickupDate,
    required this.dropoffDate,
    required this.onPickupLocationChanged,
    required this.onDropoffLocationChanged,
    required this.onPickupDateChanged,
    required this.onDropoffDateChanged,
    required this.onSearchPressed,
  });

  @override
  State<DateLocationSearchWidget> createState() =>
      _DateLocationSearchWidgetState();
}

class _DateLocationSearchWidgetState extends State<DateLocationSearchWidget> {
  bool showPickupMap = false;
  bool showDropoffMap = false;

  Future<void> _selectDate(BuildContext context, bool isPickup) async {
    final DateTime initialDate = isPickup
        ? (widget.pickupDate ?? DateTime.now())
        : (widget.dropoffDate ?? widget.pickupDate ?? DateTime.now());

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8B1538),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (isPickup) {
        widget.onPickupDateChanged(picked);
      } else {
        widget.onDropoffDateChanged(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10.0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildLocationSelector(
            label: '📍 Lugar de recogida',
            lat: widget.pickupLat,
            lng: widget.pickupLng,
            showMap: showPickupMap,
            onToggleMap: () {
              setState(() {
                showPickupMap = !showPickupMap;
                if (showPickupMap) showDropoffMap = false;
              });
            },
            onLocationSelected: (lat, lng, address) {
              widget.onPickupLocationChanged(lat, lng);
              setState(() => showPickupMap = false);
            },
          ),
          SizedBox(height: 2.h),
          _buildLocationSelector(
            label: '🏁 Lugar de devolución',
            lat: widget.dropoffLat,
            lng: widget.dropoffLng,
            showMap: showDropoffMap,
            onToggleMap: () {
              setState(() {
                showDropoffMap = !showDropoffMap;
                if (showDropoffMap) showPickupMap = false;
              });
            },
            onLocationSelected: (lat, lng, address) {
              widget.onDropoffLocationChanged(lat, lng);
              setState(() => showDropoffMap = false);
            },
            placeholder: widget.pickupLat != null && widget.pickupLng != null
                ? 'Mismo lugar de recogida'
                : 'Seleccionar en el mapa',
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  context: context,
                  label: '📅 Recogida',
                  date: widget.pickupDate,
                  onTap: () => _selectDate(context, true),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildDatePicker(
                  context: context,
                  label: '📅 Devolución',
                  date: widget.dropoffDate,
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onSearchPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B1538),
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search, color: Colors.white),
                  SizedBox(width: 2.w),
                  Text(
                    'Buscar autos disponibles',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelector({
    required String label,
    required double? lat,
    required double? lng,
    required bool showMap,
    required VoidCallback onToggleMap,
    required Function(double, double, String) onLocationSelected,
    String? placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 1.h),
        InkWell(
          onTap: onToggleMap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              border: Border.all(
                color: showMap ? const Color(0xFF8B1538) : Colors.grey.shade300,
                width: showMap ? 2.0 : 1.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: lat != null && lng != null
                      ? const Color(0xFF8B1538)
                      : Colors.grey.shade600,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    lat != null && lng != null
                        ? '📌 Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}'
                        : placeholder ?? 'Seleccionar en el mapa',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: lat != null && lng != null
                          ? Colors.black
                          : Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  showMap ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
        if (showMap) ...[
          SizedBox(height: 1.h),
          Container(
            height: 35.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: const Color(0xFF8B1538), width: 2.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: MapboxLocationPickerWidget(
                initialLatitude: lat,
                initialLongitude: lng,
                onLocationSelected: onLocationSelected,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDatePicker({
    required BuildContext context,
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 1.h),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF8B1538),
                  size: 18,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    date != null
                        ? DateFormat('dd/MM/yyyy').format(date)
                        : 'Seleccionar',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: date != null ? Colors.black : Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}