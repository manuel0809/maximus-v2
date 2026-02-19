import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import '../core/constants/app_roles.dart';

class UserService {
  static UserService? _instance;
  static UserService get instance => _instance ??= UserService._();

  UserService._();

  final SupabaseClient _client = SupabaseService.instance.client;

  /// Get all users with optional filtering
  Future<List<Map<String, dynamic>>> getUsers({
    String? query,
    String? roleFilter,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var request = _client.from('user_profiles').select();

      if (query != null && query.isNotEmpty) {
        request = request.or(
          'full_name.ilike.%$query%,email.ilike.%$query%',
        );
      }

      if (roleFilter != null && roleFilter != 'all') {
        request = request.eq('role', roleFilter);
      }

      final response = await request
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  /// Get specific user profile by ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      throw Exception('Error al obtener perfil de usuario: $e');
    }
  }

  /// Alias for getUserById used in DriverDashboard
  Future<Map<String, dynamic>?> getUserProfile(String userId) => getUserById(userId);

  /// Update user active status (suspend/activate)
  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      await _client
          .from('user_profiles')
          .update({'is_active': isActive})
          .eq('id', userId);
    } catch (e) {
      throw Exception('Error al actualizar estado de usuario: $e');
    }
  }

  /// Get current authenticated user's profile
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      return await getUserById(user.id);
    } catch (e) {
      throw Exception('Error al obtener usuario actual: $e');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  /// Update user profile details
  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _client.from('user_profiles').update(updates).eq('id', userId);
    } catch (e) {
      throw Exception('Error al actualizar perfil: $e');
    }
  }

  /// Update user verification status with optional reason
  Future<void> updateVerificationStatus({
    required String userId,
    required String status,
    String? reason,
  }) async {
    try {
      await _client.from('user_profiles').update({
        'verification_status': status,
        'verification_rejection_reason': reason,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Error al actualizar verificación: $e');
    }
  }

  /// Update user verification document URLs
  Future<void> updateVerificationDocuments({
    required String userId,
    required String licenseUrl,
    required String selfieUrl,
  }) async {
    try {
      await _client.from('user_profiles').update({
        'driver_license_url': licenseUrl,
        'selfie_url': selfieUrl,
        'verification_status': 'pending',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Error al actualizar documentos: $e');
    }
  }

  /// Lock or unlock a user with internal notes
  Future<void> toggleUserLock(String userId, bool isLocked, String? notes) async {
    try {
      await _client.from('user_profiles').update({
        'is_active': !isLocked,
        'internal_notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Error al bloquear usuario: $e');
    }
  }

  /// Calculate internal customer rating based on rental history
  Future<double> getCustomerInternalRating(String userId) async {
    try {
      // Logic: Average rating given by admin + points for completed rentals - points for delays
      final rentals = await _client.from('rentals').select('status').eq('user_id', userId);
      final list = List<Map<String, dynamic>>.from(rentals);
      
      if (list.isEmpty) return 5.0; // Standard for new clients

      int completed = list.where((r) => r['status'] == 'completed').length;
      int cancelled = list.where((r) => r['status'] == 'cancelled').length;
      
      double score = 5.0 + (completed * 0.1) - (cancelled * 0.5);
      return score.clamp(1.0, 10.0);
    } catch (e) {
      return 5.0;
    }
  }

  /// Update user role (Admin only)
  Future<void> updateUserRole(String userId, AppRole role) async {
    try {
      await _client.from('user_profiles').update({
        'role': role.dbValue,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Error al actualizar rol de usuario: $e');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Error al enviar correo de recuperación: $e');
    }
  }

  /// Create a new user profile manually (Admin only)
  /// Note: This only creates the profile entry. Auth must be handled separately or via invitation.
  Future<void> createUser({
    required String email,
    required String fullName,
    String? phone,
    required AppRole role,
  }) async {
    try {
      await _client.from('user_profiles').insert({
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'role': role.dbValue,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Error al crear usuario manualmente: $e');
    }
  }

  // =====================================================
  // ROLE HIERARCHY SYSTEM METHODS
  // =====================================================

  /// Valid roles in the system
  static const List<String> validRoles = [
    'super_admin',
    'admin',
    'operations_manager',
    'reservation_operator',
    'assistant',
    'dispatcher',
    'fleet_manager',
    'mechanic',
    'finance_manager',
    'driver',
    'client',
    'client_vip',
    'client_corp',
  ];

  /// Create a new user with specified role and authentication
  Future<Map<String, dynamic>> createUserWithRole({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phoneNumber,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Validate role
      if (!validRoles.contains(role)) {
        throw Exception('Invalid role: $role. Must be one of: ${validRoles.join(", ")}');
      }

      // Create user in Auth
      final authResponse = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create user in authentication system');
      }

      // Create profile in user_profiles
      await _client.from('user_profiles').insert({
        'id': authResponse.user!.id,
        'email': email,
        'full_name': fullName,
        'role': role,
        'phone_number': phoneNumber,
        'is_active': true,
        'metadata': metadata ?? {},
        'created_at': DateTime.now().toIso8601String(),
      });

      return {
        'user_id': authResponse.user!.id,
        'email': email,
        'role': role,
        'full_name': fullName,
      };
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  /// Get role permissions for a specific role
  Future<Map<String, bool>> getRolePermissions(String role) async {
    final appRole = AppRole.fromString(role);

    return {
      // Super Admin Permissions
      'canManageBranding': appRole.canManageBranding,
      'canChangeLegalInfo': appRole.canChangeLegalInfo,
      'canManageAdmins': appRole.canManageAdmins,
      'canDeleteCompany': appRole.canDeleteCompany,
      'canTransferOwnership': appRole.canTransferOwnership,
      'canConfigurePaymentGateways': appRole.canConfigurePaymentGateways,
      'canAccessBackend': appRole.canAccessBackend,
      
      // Admin Tier Permissions
      'canManageStaff': appRole.canManageStaff,
      'canManageDrivers': appRole.canManageDrivers,
      'canManageClients': appRole.canManageClients,
      'canManageFleet': appRole.canManageFleet,
      'canModifyGlobalPricing': appRole.canModifyGlobalPricing,
      'canCreateCoupons': appRole.canCreateCoupons,
      'canSendMassNotifications': appRole.canSendMassNotifications,
      
      // Financial Permissions
      'canViewFinancialDashboards': appRole.canViewFinancialDashboards,
      'canApproveRefundsSmall': appRole.canApproveRefundsSmall,
      'canApproveRefundsLarge': appRole.canApproveRefundsLarge,
      'canExportFinancialReports': appRole.canExportFinancialReports,
      
      // Operations Permissions
      'canViewLiveMap': appRole.canViewLiveMap,
      'canReassignDrivers': appRole.canReassignDrivers,
      'canCancelActiveTrips': appRole.canCancelActiveTrips,
      'canViewAllBookings': appRole.canViewAllBookings,
      
      // Booking Permissions
      'canCreateBookings': appRole.canCreateBookings,
      'canModifyBookings': appRole.canModifyBookings,
      'canAssignDriversToBookings': appRole.canAssignDriversToBookings,
      'canApplyExistingCoupons': appRole.canApplyExistingCoupons,
      
      // Communication Permissions
      'canChatWithClients': appRole.canChatWithClients,
      'canChatWithDrivers': appRole.canChatWithDrivers,
      'canEscalateIssues': appRole.canEscalateIssues,
      
      // Fleet Management Permissions
      'canAddVehicles': appRole.canAddVehicles,
      'canEditVehicleData': appRole.canEditVehicleData,
      'canScheduleMaintenance': appRole.canScheduleMaintenance,
      'canManageInsurance': appRole.canManageInsurance,
      
      // Driver Permissions
      'canAcceptTransportRequests': appRole.canAcceptTransportRequests,
      'canViewOwnEarnings': appRole.canViewOwnEarnings,
      'canUpdateOwnProfile': appRole.canUpdateOwnProfile,
      
      // Client Permissions
      'canBookTransportation': appRole.canBookTransportation,
      'canRentVehicles': appRole.canRentVehicles,
      'canRateTrip': appRole.canRateTrip,
      'canRequestTripRefund': appRole.canRequestTripRefund,
      
      // VIP Client Benefits
      'hasPriorityAssignment': appRole.hasPriorityAssignment,
      'hasFreeCancellation': appRole.hasFreeCancellation,
      'hasPermanentDiscount': appRole.hasPermanentDiscount,
      
      // Corporate Client Benefits
      'hasMultiUserAccount': appRole.hasMultiUserAccount,
      'canAssignCostCenters': appRole.canAssignCostCenters,
      'hasAPIAccess': appRole.hasAPIAccess,
    };
  }

  /// Get current user's role
  Future<AppRole?> getCurrentUserRole() async {
    try {
      final user = await getCurrentUser();
      if (user == null) return null;
      
      final roleStr = user['role'] as String?;
      return AppRole.fromString(roleStr);
    } catch (e) {
      throw Exception('Error getting current user role: $e');
    }
  }

  /// Check if current user has a specific permission
  Future<bool> hasPermission(String permissionName) async {
    try {
      final role = await getCurrentUserRole();
      if (role == null) return false;
      
      final permissions = await getRolePermissions(role.name);
      return permissions[permissionName] ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Update user's last login timestamp
  Future<void> updateLastLogin(String userId) async {
    try {
      await _client.from('user_profiles').update({
        'last_login_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      // Silently fail - not critical
    }
  }

  /// Get users by role
  Future<List<Map<String, dynamic>>> getUsersByRole(String role) async {
    try {
      if (!validRoles.contains(role)) {
        throw Exception('Invalid role: $role');
      }

      final response = await _client
          .from('user_profiles')
          .select()
          .eq('role', role)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error getting users by role: $e');
    }
  }

  /// Update user role by string value (admin only)
  Future<void> updateUserRoleByString(String userId, String newRole) async {
    try {
      if (!validRoles.contains(newRole)) {
        throw Exception('Invalid role: $newRole');
      }

      await _client.from('user_profiles').update({
        'role': newRole,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw Exception('Error updating user role: $e');
    }
  }
}

