import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../widgets/premium_card.dart';

class PromotionalBannerWidget extends StatelessWidget {
  final VoidCallback onDismiss;

  const PromotionalBannerWidget({super.key, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: const Key('promo_banner'),
      direction: DismissDirection.horizontal,
      onDismissed: (direction) => onDismiss(),
      child: PremiumCard(
        borderRadius: 16,
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        gradient: const LinearGradient(
          colors: [Color(0xFF6B0F2A), Color(0xFF8B1538)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: CustomIconWidget(
                iconName: 'local_offer',
                color: Colors.white,
                size: 22,
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    'Oferta Exclusiva'.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    '20% de descuento en tu próxima reserva',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.6), size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
