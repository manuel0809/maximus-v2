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
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15.0,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: onTap,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: const Color(0xFFE8B4B8),
              unselectedItemColor: Colors.white.withValues(alpha: 0.4),
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w400,
                letterSpacing: 0.4,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: Icon(
                    currentIndex == 0 ? Icons.dashboard : Icons.dashboard_outlined,
                    size: 22,
                  ),
                  activeIcon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1538).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.dashboard,
                      size: 22,
                      color: Color(0xFFE8B4B8),
                    ),
                  ),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    currentIndex == 1
                        ? Icons.event_note
                        : Icons.event_note_outlined,
                    size: 22,
                  ),
                  activeIcon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1538).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.event_note,
                      size: 22,
                      color: Color(0xFFE8B4B8),
                    ),
                  ),
                  label: 'Bookings',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    currentIndex == 2 ? Icons.person : Icons.person_outline,
                    size: 22,
                  ),
                  activeIcon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1538).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person, size: 22, color: Color(0xFFE8B4B8)),
                  ),
                  label: 'Profile',
                ),
                BottomNavigationBarItem(
                  icon: Icon(
                    currentIndex == 3
                        ? Icons.support_agent
                        : Icons.support_agent_outlined,
                    size: 22,
                  ),
                  activeIcon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B1538).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.support_agent,
                      size: 22,
                      color: Color(0xFFE8B4B8),
                    ),
                  ),
                  label: 'Support',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
