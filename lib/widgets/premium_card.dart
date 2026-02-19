import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? color;
  final Gradient? gradient;
  final bool useGlassmorphism;
  final double blur;
  final double opacity;
  final Border? border;
  final VoidCallback? onTap;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.color,
    this.gradient,
    this.useGlassmorphism = false,
    this.blur = 10.0,
    this.opacity = 0.1,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget content = Container(
      padding: padding ?? EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: useGlassmorphism 
            ? Colors.white.withValues(alpha: opacity)
            : color ?? theme.cardColor,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius ?? 16.0),
        border: border ?? (useGlassmorphism 
            ? Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5)
            : Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.1))),
        boxShadow: gradient != null || useGlassmorphism
            ? [
                BoxShadow(
                  color: (gradient?.colors.first ?? theme.shadowColor).withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: child,
    );

    if (useGlassmorphism) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius ?? 16.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? 16.0),
          child: content,
        ),
      );
    }

    return content;
  }
}
