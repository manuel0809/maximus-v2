import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../widgets/premium_card.dart';

class ServiceTypeCardWidget extends StatelessWidget {
  final Map<String, dynamic> service;
  final bool isSelected;
  final bool isAdmin;
  final VoidCallback onTap;

  const ServiceTypeCardWidget({
    super.key,
    required this.service,
    required this.isSelected,
    required this.isAdmin,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: PremiumCard(
        onTap: onTap,
        borderRadius: 16,
        padding: EdgeInsets.all(4.w),
        useGlassmorphism: !isSelected,
        opacity: isSelected ? 1.0 : 0.03,
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFF8B1538), Color(0xFF6B0F2A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: Border.all(
          color: isSelected
              ? const Color(0xFFE8B4B8).withValues(alpha: 0.5)
              : theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Vehicle Image
                if (service['vehicleImage'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: CustomImageWidget(
                      imageUrl: service['vehicleImage'] as String,
                      height: 80,
                      width: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: CustomIconWidget(
                      iconName: service['icon'] as String,
                      color: isSelected ? Colors.white : theme.colorScheme.primary,
                      size: 32,
                    ),
                  ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service['title'] as String,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        service['description'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.8)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (service['promoBadge'] != null) ...[
              SizedBox(height: 1.5.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFFFD700).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.white.withValues(alpha: 0.4) : const Color(0xFFFFD700).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.stars,
                      size: 14,
                      color: isSelected ? Colors.white : const Color(0xFFB8860B),
                    ),
                    SizedBox(width: 1.5.w),
                    Text(
                      (service['promoBadge'] as String).toUpperCase(),
                      style: TextStyle(
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.white : const Color(0xFFB8860B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 2.h),
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 14,
                  color: isSelected ? Colors.white70 : theme.colorScheme.primary,
                ),
                SizedBox(width: 1.5.w),
                Text(
                  service['capacity'] as String,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isSelected ? Colors.white.withValues(alpha: 0.7) : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            // Pricing breakdown section
            if (service['pricing'] != null) ...[
              SizedBox(height: 1.5.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFD4AF37).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : const Color(0xFFD4AF37).withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 13,
                          color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFFD4AF37),
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          'TARIFAS',
                          style: TextStyle(
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFFD4AF37),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Wrap(
                      spacing: 2.w,
                      runSpacing: 0.5.h,
                      children: (service['pricing'] as Map<String, dynamic>).entries.map((entry) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.1)
                                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            entry.value.toString(),
                            style: TextStyle(
                              fontSize: 7.5.sp,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
            if (isAdmin && service['baseInfo'] != null) ...[
              SizedBox(height: 1.h),
              Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 14,
                    color: isSelected ? Colors.white70 : theme.colorScheme.primary,
                  ),
                  SizedBox(width: 1.5.w),
                  Expanded(
                    child: Text(
                      service['baseInfo'] as String,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected ? Colors.white : theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
