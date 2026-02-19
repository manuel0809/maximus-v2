import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

class CompletedTripCardWidget extends StatelessWidget {
  final Map<String, dynamic> trip;
  final bool hasReview;
  final VoidCallback onTap;

  const CompletedTripCardWidget({
    super.key,
    required this.trip,
    required this.hasReview,
    required this.onTap,
  });

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy, HH:mm', 'es').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with service type and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip['service_type'] ?? 'Servicio',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            trip['vehicle_type'] ?? 'Vehículo',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: hasReview
                            ? Colors.green.withValues(alpha: 0.1)
                            : theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasReview ? Icons.check_circle : Icons.rate_review,
                            size: 16,
                            color: hasReview
                                ? Colors.green
                                : theme.colorScheme.primary,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            hasReview ? 'Reseñado' : 'Pendiente',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: hasReview
                                  ? Colors.green
                                  : theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 2.h),

                // Route information
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        trip['pickup_location'] ?? 'Origen',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Icon(
                      Icons.flag,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        trip['dropoff_location'] ?? 'Destino',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 1.5.h),

                // Trip details
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      _formatDate(trip['completed_at'] ?? trip['trip_date']),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    if (trip['duration_minutes'] != null) ...[
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '${trip['duration_minutes']} min',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    SizedBox(width: 4.w),
                    if (trip['cost'] != null) ...[
                      Icon(
                        Icons.attach_money,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '${trip['cost']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),

                if (!hasReview) ...[
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      SizedBox(width: 1.w),
                      Text(
                        'Toca para calificar este viaje',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
