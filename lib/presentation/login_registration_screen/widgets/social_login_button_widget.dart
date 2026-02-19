import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Social login button widget for third-party authentication
class SocialLoginButtonWidget extends StatelessWidget {
  final String provider;
  final String iconName;
  final VoidCallback onPressed;

  const SocialLoginButtonWidget({
    super.key,
    required this.provider,
    required this.iconName,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 20.w,
        height: 6.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: CustomIconWidget(
            iconName: iconName,
            color: theme.colorScheme.onSurface,
            size: 24,
          ),
        ),
      ),
    );
  }
}
