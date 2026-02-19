import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SettingsToggleWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsToggleWidget({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12.sp,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            )
          : null,
      value: value,
      onChanged: onChanged,
      activeThumbColor: colorScheme.primary,
      contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
    );
  }
}
