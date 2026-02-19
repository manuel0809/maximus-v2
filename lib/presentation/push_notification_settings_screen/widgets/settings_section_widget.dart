import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SettingsSectionWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const SettingsSectionWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 24),
                SizedBox(width: 2.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
          ...children,
        ],
      ),
    );
  }
}
