import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../widgets/custom_icon_widget.dart';

class TransportVehicleCardWidget extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final bool isSelected;
  final VoidCallback onTap;

  const TransportVehicleCardWidget({
    super.key,
    required this.vehicle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = vehicle['available'] as bool;

    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: GestureDetector(
        onTap: isAvailable ? onTap : null,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle Image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12.0),
                      topRight: Radius.circular(12.0),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: vehicle['image'] as String,
                      height: 20.h,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 20.h,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 20.h,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.directions_car,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  // Availability Badge
                  Positioned(
                    top: 2.w,
                    right: 2.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Text(
                        isAvailable ? 'Disponible' : 'No disponible',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isAvailable
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 2.w,
                      left: 2.w,
                      child: Container(
                        padding: EdgeInsets.all(1.w),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: CustomIconWidget(
                          iconName: 'check',
                          color: theme.colorScheme.onPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),

              // Vehicle Details
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle['name'] as String,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(height: 0.3.h),
                              Text(
                                vehicle['model'] as String,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${(vehicle['baseRate'] as double).toStringAsFixed(2)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Text(
                              'por servicio',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),

                    // Capacity Info
                    Row(
                      children: [
                        _buildInfoChip(
                          context,
                          'person',
                          '${vehicle['capacity']} pasajeros',
                        ),
                        SizedBox(width: 2.w),
                        _buildInfoChip(
                          context,
                          'luggage',
                          '${vehicle['luggage']} maletas',
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),

                    // Amenities
                    Text(
                      'Comodidades:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Wrap(
                      spacing: 1.w,
                      runSpacing: 0.5.h,
                      children: (vehicle['amenities'] as List<String>).map((
                        amenity,
                      ) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.3.h,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            amenity,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String icon, String text) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.8.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: icon,
            color: theme.colorScheme.primary,
            size: 16,
          ),
          SizedBox(width: 1.w),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
