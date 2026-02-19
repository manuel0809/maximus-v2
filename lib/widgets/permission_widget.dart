import 'package:flutter/material.dart';
import '../core/constants/app_roles.dart';

/// A widget that conditionally displays its child based on user permissions
/// 
/// Example usage:
/// ```dart
/// PermissionWidget(
///   userRole: currentUserRole,
///   permissionCheck: (role) => role.canManageFleet,
///   child: FleetManagementButton(),
///   fallback: Text('No tienes permiso'),
/// )
/// ```
class PermissionWidget extends StatelessWidget {
  final AppRole userRole;
  final bool Function(AppRole) permissionCheck;
  final Widget child;
  final Widget? fallback;

  const PermissionWidget({
    super.key,
    required this.userRole,
    required this.permissionCheck,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (permissionCheck(userRole)) {
      return child;
    }
    return fallback ?? const SizedBox.shrink();
  }
}

/// A widget that shows different content based on multiple permission levels
/// 
/// Example usage:
/// ```dart
/// MultiPermissionWidget(
///   userRole: currentUserRole,
///   permissions: {
///     (role) => role.isSuperAdmin: SuperAdminControls(),
///     (role) => role.isAdminTier: AdminControls(),
///     (role) => role.isStaff: StaffControls(),
///   },
///   fallback: Text('Sin acceso'),
/// )
/// ```
class MultiPermissionWidget extends StatelessWidget {
  final AppRole userRole;
  final Map<bool Function(AppRole), Widget> permissions;
  final Widget? fallback;

  const MultiPermissionWidget({
    super.key,
    required this.userRole,
    required this.permissions,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    for (final entry in permissions.entries) {
      if (entry.key(userRole)) {
        return entry.value;
      }
    }
    return fallback ?? const SizedBox.shrink();
  }
}

/// A builder widget that provides the current user's role to its builder function
/// 
/// Example usage:
/// ```dart
/// RoleBuilder(
///   builder: (context, role) {
///     if (role == null) return LoadingWidget();
///     
///     return Column(
///       children: [
///         if (role.canManageUsers) UserManagementSection(),
///         if (role.canViewFinancials) FinancialSection(),
///       ],
///     );
///   },
/// )
/// ```
class RoleBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, AppRole? role) builder;
  final Future<AppRole?> Function()? roleProvider;

  const RoleBuilder({
    super.key,
    required this.builder,
    this.roleProvider,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppRole?>(
      future: roleProvider?.call(),
      builder: (context, snapshot) {
        return builder(context, snapshot.data);
      },
    );
  }
}

/// Extension methods for easier permission checking in UI
extension PermissionChecks on AppRole {
  /// Check if this role has any of the given permissions
  bool hasAnyPermission(List<bool Function(AppRole)> checks) {
    return checks.any((check) => check(this));
  }

  /// Check if this role has all of the given permissions
  bool hasAllPermissions(List<bool Function(AppRole)> checks) {
    return checks.every((check) => check(this));
  }
}
