import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom app bar for MAXIMUS LEVEL GROUP luxury transportation app.
///
/// Provides a clean, minimal top navigation with:
/// - Centered title with Inter font
/// - Optional leading and trailing actions
/// - Transparent background with subtle elevation
/// - Platform-aware styling
///
/// This widget is parameterized and reusable across different screens.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Title text to display in the app bar
  final String title;

  /// Optional leading widget (typically back button or menu icon)
  final Widget? leading;

  /// Optional trailing actions
  final List<Widget>? actions;

  /// Whether to show back button automatically
  final bool automaticallyImplyLeading;

  /// Whether to center the title
  final bool centerTitle;

  /// Optional background color override
  final Color? backgroundColor;

  /// Optional elevation override
  final double? elevation;

  /// Optional title text style override
  final TextStyle? titleTextStyle;

  /// Optional bottom widget (e.g., TabBar)
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.centerTitle = true,
    this.backgroundColor,
    this.elevation,
    this.titleTextStyle,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      title: Text(
        title,
        style: titleTextStyle ?? theme.appBarTheme.titleTextStyle,
      ),
      leading: leading,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? colorScheme.surface,
      elevation: elevation ?? 0,
      shadowColor: isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.1),
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      iconTheme: IconThemeData(
        color: theme.appBarTheme.iconTheme?.color ?? colorScheme.onSurface,
        size: 24,
      ),
      actionsIconTheme: IconThemeData(
        color: theme.appBarTheme.iconTheme?.color ?? colorScheme.onSurface,
        size: 24,
      ),
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}

/// Variant of CustomAppBar with gradient background for premium branding moments
class CustomGradientAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  /// Title text to display in the app bar
  final String title;

  /// Optional leading widget
  final Widget? leading;

  /// Optional trailing actions
  final List<Widget>? actions;

  /// Whether to show back button automatically
  final bool automaticallyImplyLeading;

  /// Whether to center the title
  final bool centerTitle;

  /// Optional bottom widget
  final PreferredSizeWidget? bottom;

  const CustomGradientAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.centerTitle = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF8B1538), // Deep burgundy
            Color(0xFFE8B4B8), // Rose gold
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: AppBar(
        title: Text(
          title,
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            color: Colors.white,
          ),
        ),
        leading: leading,
        actions: actions,
        automaticallyImplyLeading: automaticallyImplyLeading,
        centerTitle: centerTitle,
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
        actionsIconTheme: const IconThemeData(color: Colors.white, size: 24),
        bottom: bottom,
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
