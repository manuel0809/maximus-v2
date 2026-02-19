import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/premium_card.dart';

class RecentBookingCardWidget extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onRebook;

  const RecentBookingCardWidget({
    super.key,
    required this.booking,
    required this.onRebook,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canRebook = booking["canRebook"] as bool? ?? false;

    return PremiumCard(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      useGlassmorphism: true,
      opacity: 0.03,
      child: SizedBox(
        width: 75.w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  CustomImageWidget(
                    imageUrl: booking["image"] as String,
                    width: double.infinity,
                    height: 12.h,
                    fit: BoxFit.cover,
                    semanticLabel: booking["semanticLabel"] as String,
                  ),
                  Positioned(
                    top: 2.w,
                    left: 2.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (booking["serviceType"] as String).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content Section
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    booking["serviceName"] as String,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1.5.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, color: theme.colorScheme.primary, size: 12),
                              SizedBox(width: 1.5.w),
                              Text(
                                '${booking["date"]} • ${booking["time"]}',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                          SizedBox(height: 1.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                            decoration: BoxDecoration(
                              color: (booking["statusColor"] as Color).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: (booking["statusColor"] as Color).withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              booking["status"] as String,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: booking["statusColor"] as Color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (canRebook)
                        ElevatedButton(
                          onPressed: onRebook,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                            foregroundColor: theme.colorScheme.primary,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(horizontal: 3.w),
                            minimumSize: Size(0, 4.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Repetir', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
