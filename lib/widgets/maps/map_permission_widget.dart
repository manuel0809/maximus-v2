import 'package:flutter/material.dart';
import '../../core/constants/app_roles.dart';

/// Helper widget to conditionally show map features based on role permissions
class MapPermissionWidget extends StatelessWidget {
  final AppRole userRole;
  final Widget? liveMapView;
  final Widget? tripTrackingView;
  final Widget? driverNavigationView;
  final Widget? fallback;

  const MapPermissionWidget({
    super.key,
    required this.userRole,
    this.liveMapView,
    this.tripTrackingView,
    this.driverNavigationView,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    // Admin Command Center (Super Admin, Admin, Ops Manager, Dispatcher)
    if (userRole.canViewLiveMap && liveMapView != null) {
      return liveMapView!;
    }

    // Driver Navigation
    if (userRole.canUseDriverNavigation && driverNavigationView != null) {
      return driverNavigationView!;
    }

    // Trip Tracking (Clients and other staff)
    if (userRole.canTrackTrips && tripTrackingView != null) {
      return tripTrackingView!;
    }

    // Fallback
    return fallback ?? const SizedBox.shrink();
  }
}

/// Map feature access checker
class MapPermissions {
  final AppRole role;

  const MapPermissions(this.role);

  /// Check if user can access live map dashboard
  bool get canAccessLiveMap => role.canViewLiveMap;

  /// Check if user can track individual trips
  bool get canTrackTrips => role.canTrackTrips;

  /// Check if user can use driver navigation
  bool get canUseNavigation => role.canUseDriverNavigation;

  /// Check if user can view trip history
  bool get canViewHistory => role.canViewTripHistory;

  /// Check if user can view mileage reports
  bool get canViewMileageReports => role.canViewMileageReports;

  /// Check if user can resolve alerts
  bool get canResolveAlerts => role.canResolveTripAlerts;

  /// Check if user can manage geofences
  bool get canManageGeofences => role.canManageGeofences;

  /// Check if user can view driver locations
  bool get canViewDriverLocations => role.canViewDriverLocations;

  /// Get map features available to this role
  List<String> get availableFeatures {
    final features = <String>[];

    if (canAccessLiveMap) features.add('Live Map Dashboard');
    if (canTrackTrips) features.add('Trip Tracking');
    if (canUseNavigation) features.add('Driver Navigation');
    if (canViewHistory) features.add('Trip History');
    if (canViewMileageReports) features.add('Mileage Reports');
    if (canResolveAlerts) features.add('Alert Management');
    if (canManageGeofences) features.add('Geofence Management');
    if (canViewDriverLocations) features.add('Driver Locations');

    return features;
  }
}
