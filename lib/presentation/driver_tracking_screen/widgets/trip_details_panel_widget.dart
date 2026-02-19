import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class TripDetailsPanelWidget extends StatelessWidget {
  final String pickupLocation;
  final String dropoffLocation;
  final String estimatedFare;
  final String specialInstructions;

  const TripDetailsPanelWidget({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.estimatedFare,
    required this.specialInstructions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 1.h),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              'Detalles del Viaje',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SizedBox(height: 2.h),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.trip_origin,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recogida',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            pickupLocation,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: EdgeInsets.only(left: 20, top: 1.h, bottom: 1.h),
                  child: Container(
                    width: 2,
                    height: 30,
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),

                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Destino',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.6),
                            ),
                          ),
                          Text(
                            dropoffLocation,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 2.h),

          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),

          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tarifa Estimada',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  estimatedFare,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          if (specialInstructions.isNotEmpty) ...[
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instrucciones Especiales',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      specialInstructions,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 2.h),
        ],
      ),
    );
  }
}
