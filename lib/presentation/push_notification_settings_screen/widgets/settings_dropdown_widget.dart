import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SettingsDropdownWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final dynamic value;
  final List<Map<String, dynamic>> options;
  final ValueChanged<dynamic> onChanged;

  const SettingsDropdownWidget({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
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
      trailing: DropdownButton<dynamic>(
        value: value,
        underline: const SizedBox(),
        items: options.map((option) {
          return DropdownMenuItem<dynamic>(
            value: option['value'],
            child: Text(
              option['label'],
              style: TextStyle(fontSize: 13.sp, color: colorScheme.onSurface),
            ),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
    );
  }
}
