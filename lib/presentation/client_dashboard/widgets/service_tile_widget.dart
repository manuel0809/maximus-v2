import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:ui';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../widgets/premium_card.dart';

class ServiceTileWidget extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onTap;

  const ServiceTileWidget({
    super.key,
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUpdate = service["hasUpdate"] as bool? ?? false;

    return PremiumCard(
      onTap: onTap,
      borderRadius: 24,
      padding: EdgeInsets.zero,
      useGlassmorphism: true,
      blur: 20,
      opacity: 0.05,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
            width: 0.8,
          ),
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.05),
              Colors.transparent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: EdgeInsets.all(5.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CustomIconWidget(
                      iconName: service["icon"] as String,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    service["title"] as String,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      fontSize: 10.sp,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Notification Badge
            if (hasUpdate)
              Positioned(
                top: 3.w,
                right: 3.w,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37), // Gold for premium alerts
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
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
}
