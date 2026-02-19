import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../widgets/premium_card.dart';

class KPICardWidget extends StatelessWidget {
  final String title;
  final String value;
  final dynamic icon; // Can be IconData or String (for CustomIconWidget)
  final Color color;
  final String? change;
  final bool isPositive;

  const KPICardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.change,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PremiumCard(
      padding: EdgeInsets.all(4.w),
      borderRadius: 16,
      useGlassmorphism: true,
      opacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: icon is IconData
                    ? Icon(icon as IconData, color: color, size: 22)
                    : CustomIconWidget(
                        iconName: icon as String,
                        color: color,
                        size: 22,
                      ),
              ),
              if (change != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 10,
                        color: isPositive ? Colors.green : Colors.orange,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        change!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isPositive ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 0.5.h),
              Text(
                title.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
