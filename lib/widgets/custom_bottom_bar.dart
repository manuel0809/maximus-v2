import 'package:flutter/material.dart';
import 'dart:ui';

/// Custom bottom navigation bar for MAXIMUS LEVEL GROUP luxury transportation app.
///
/// Implements thumb-reachable navigation with primary service access points:
/// - Dashboard: Central service selection and booking entry
/// - Bookings: Active booking management and tracking
/// - Profile: User preferences and settings
/// - Support: Customer support and assistance
///
/// This widget is parameterized and reusable across different implementations.
class CustomBottomBar extends StatelessWidget {
  /// Current selected index
  final int currentIndex;

  /// Callback when navigation item is tapped
  final Function(int) onTap;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F).withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20.0,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: SafeArea(
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: onTap,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: primaryColor,
              unselectedItemColor: Colors.white.withValues(alpha: 0.3),
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w400,
                letterSpacing: 0.4,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.dashboard_outlined, size: 24),
                  activeIcon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.dashboard_rounded, size: 24, color: primaryColor),
                  ),
                  label: 'Inicio',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.calendar_today_outlined, size: 24),
                  activeIcon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.calendar_today_rounded, size: 24, color: primaryColor),
                  ),
                  label: 'Reservas',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_outline_rounded, size: 24),
                  activeIcon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.person_rounded, size: 24, color: primaryColor),
                  ),
                  label: 'Perfil',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.headset_mic_outlined, size: 24),
                  activeIcon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.headset_mic_rounded, size: 24, color: primaryColor),
                  ),
                  label: 'Soporte',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
