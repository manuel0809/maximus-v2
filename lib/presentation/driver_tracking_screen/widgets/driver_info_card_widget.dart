import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';

class DriverInfoCardWidget extends StatelessWidget {
  final Map<String, dynamic> driverInfo;
  final int etaMinutes;
  final double distanceMiles;
  final String driverStatus;
  final VoidCallback onCallPressed;
  final VoidCallback onMessagePressed;

  const DriverInfoCardWidget({
    super.key,
    required this.driverInfo,
    required this.etaMinutes,
    required this.distanceMiles,
    required this.driverStatus,
    required this.onCallPressed,
    required this.onMessagePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicle = driverInfo['vehicle'] as Map<String, dynamic>;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: CachedNetworkImage(
                    imageUrl: driverInfo['photo'] as String,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 60,
                      height: 60,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.person, size: 32),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 60,
                      height: 60,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.person, size: 32),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverInfo['name'] as String,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber[400]),
                          SizedBox(width: 1.w),
                          Text(
                            '${driverInfo['rating']} • ${driverInfo['totalTrips']} viajes',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        '${driverInfo['yearsOfService']} años de servicio',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFE8B4B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                Column(
                  children: [
                    IconButton(
                      onPressed: onCallPressed,
                      icon: const Icon(Icons.phone),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF8B1538).withValues(
                          alpha: 0.2,
                        ),
                        foregroundColor: const Color(0xFFE8B4B8),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    IconButton(
                      onPressed: onMessagePressed,
                      icon: const Icon(Icons.message),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF8B1538).withValues(
                          alpha: 0.2,
                        ),
                        foregroundColor: const Color(0xFFE8B4B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),

          Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                const Icon(
                  Icons.directions_car,
                  size: 24,
                  color: Color(0xFFE8B4B8),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicle['color']} ${vehicle['make']} ${vehicle['model']}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Placa: ${vehicle['plate']} • ${vehicle['year']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),

          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: const Color(0xFF8B1538).withValues(alpha: 0.1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '$etaMinutes min',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: const Color(0xFFE8B4B8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ETA',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                Column(
                  children: [
                    Text(
                      '${distanceMiles.toStringAsFixed(1)} mi',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: const Color(0xFFE8B4B8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Distancia',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                Column(
                  children: [
                    Text(
                      driverStatus,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: driverStatus == 'Llegó'
                            ? const Color(0xFF25D366)
                            : const Color(0xFFE8B4B8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Estado',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
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
}
