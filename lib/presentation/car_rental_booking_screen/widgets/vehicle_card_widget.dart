import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class VehicleCardWidget extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final bool isSelected;
  final VoidCallback onSelect;

  const VehicleCardWidget({
    super.key,
    required this.vehicle,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = vehicle['available'] as bool;

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        width: 70.w,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16.0),
                  ),
                  child: CustomImageWidget(
                    imageUrl: vehicle['image'] as String,
                    width: double.infinity,
                    height: 15.h,
                    fit: BoxFit.cover,
                    semanticLabel: vehicle['semanticLabel'] as String,
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
                          : theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      isAvailable ? 'Disponible' : 'No Disponible',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Vehicle Details
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${vehicle['make']} ${vehicle['model']}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          'Año ${vehicle['year']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        // Specifications
                        Row(
                          children: [
                            _buildSpecItem(
                              context,
                              'settings',
                              vehicle['transmission'] as String,
                            ),
                            SizedBox(width: 3.w),
                            _buildSpecItem(
                              context,
                              'local_gas_station',
                              vehicle['fuelType'] as String,
                            ),
                          ],
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          children: [
                            _buildSpecItem(
                              context,
                              'person',
                              '${vehicle['seats']} asientos',
                            ),
                            SizedBox(width: 3.w),
                            _buildSpecItem(
                              context,
                              'luggage',
                              '${vehicle['luggage']} maletas',
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Price and Select Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '\$${vehicle['dailyRate'].toStringAsFixed(2)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'por día',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (isSelected)
                          Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: CustomIconWidget(
                              iconName: 'check',
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecItem(BuildContext context, String icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CustomIconWidget(
          iconName: icon,
          color: theme.colorScheme.onSurfaceVariant,
          size: 14,
        ),
        SizedBox(width: 1.w),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
