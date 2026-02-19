enum AppRole {
  superAdmin, // Nivel 1
  admin,      // Nivel 2
  opsManager, // Nivel 3 - Gerente Operaciones
  fleetManager, // Nivel 3 - Gerente Flota
  financeManager, // Nivel 3 - Gerente Financiero
  bookingOperator, // Nivel 4 - Operador Reservas
  assistant, // Nivel 4 - Asistente
  dispatch, // Nivel 4 - Despachador
  mechanic, // Nivel 4 - Mecánico
  driver,
  client,
  clientVip,
  clientCorp;

  static AppRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'super_admin':
      case 'superadmin':
      case 'owner':
        return AppRole.superAdmin;
      case 'admin':
        return AppRole.admin;
      case 'ops_manager':
      case 'operations_manager':
      case 'gerente_operaciones':
        return AppRole.opsManager;
      case 'fleet_manager':
      case 'gerente_flota':
        return AppRole.fleetManager;
      case 'finance_manager':
      case 'gerente_financiero':
        return AppRole.financeManager;
      case 'booking_operator':
      case 'reservation_operator':
      case 'operador_reservas':
        return AppRole.bookingOperator;
      case 'assistant':
      case 'asistente':
        return AppRole.assistant;
      case 'dispatcher':
      case 'dispatch':
      case 'despachador':
        return AppRole.dispatch;
      case 'mechanic':
      case 'mecanico':
        return AppRole.mechanic;
      case 'driver':
      case 'conductor':
        return AppRole.driver;
      case 'client_vip':
        return AppRole.clientVip;
      case 'client_corp':
        return AppRole.clientCorp;
      case 'client':
      default:
        return AppRole.client;
    }
  }

  String get name => toString().split('.').last;

  /// Database value in snake_case (matches Supabase check constraints)
  String get dbValue {
    switch (this) {
      case AppRole.superAdmin: return 'super_admin';
      case AppRole.admin: return 'admin';
      case AppRole.opsManager: return 'operations_manager';
      case AppRole.fleetManager: return 'fleet_manager';
      case AppRole.financeManager: return 'finance_manager';
      case AppRole.bookingOperator: return 'reservation_operator';
      case AppRole.assistant: return 'assistant';
      case AppRole.dispatch: return 'dispatcher';
      case AppRole.mechanic: return 'mechanic';
      case AppRole.driver: return 'driver';
      case AppRole.client: return 'client';
      case AppRole.clientVip: return 'client_vip';
      case AppRole.clientCorp: return 'client_corp';
    }
  }

  int get level {
    switch (this) {
      case AppRole.superAdmin: return 1;
      case AppRole.admin: return 2;
      case AppRole.opsManager:
      case AppRole.fleetManager:
      case AppRole.financeManager: return 3;
      case AppRole.bookingOperator:
      case AppRole.assistant:
      case AppRole.dispatch:
      case AppRole.mechanic: return 4;
      default: return 5;
    }
  }

  bool get isStaff => level <= 4;
  bool get isAdminTier => level <= 2;
  bool get isManagerTier => level <= 3;
  
  // Aliases and Specific Role Checks
  bool get isSuperAdmin => this == AppRole.superAdmin;
  bool get isAdmin => isAdminTier;
  bool get isAdminOnly => this == AppRole.admin;
  bool get isAssistant => this == AppRole.assistant;
  bool get isDriver => this == AppRole.driver;
  bool get isMechanic => this == AppRole.mechanic;
  bool get isDispatcher => this == AppRole.dispatch;

  // --- SUPER ADMIN EXCLUSIVE PERMISSIONS (Nivel 1) ---
  
  bool get canManageAdmins => isSuperAdmin;
  bool get canChangeLegalInfo => isSuperAdmin;
  bool get canAccessLinkedBank => isSuperAdmin;
  bool get canDeleteCompany => isSuperAdmin;
  bool get canTransferOwnership => isSuperAdmin;
  bool get canCreateCustomRoles => isSuperAdmin;
  bool get canModifyRolePermissions => isSuperAdmin;
  bool get canAccessFullDatabase => isSuperAdmin;
  bool get canExportAllData => isSuperAdmin;
  bool get canConfigPaymentGateways => isSuperAdmin; 
  bool get canConfigurePaymentGateways => canConfigPaymentGateways; // Alias
  bool get canConfigIntegrations => isSuperAdmin;
  bool get canApproveLargePayments => isSuperAdmin;
  bool get canAuthLargeRefunds => isSuperAdmin;
  bool get canApproveRefundsLarge => isSuperAdmin; // Alias
  bool get canManageBranding => isSuperAdmin;
  bool get canAccessBackend => isSuperAdmin;

  // --- ADMINISTRATOR & ABOVE PERMISSIONS (Nivel 2) ---

  bool get canManageStaff => isAdminTier; 
  bool get canSuspendStaff => isAdminTier;
  bool get canViewStaffActivity => isAdminTier;
  bool get canManageDrivers => isAdminTier;
  bool get canVerifyDriverDocs => isAdminTier || this == AppRole.opsManager;
  bool get canAssignVehicles => isAdminTier || this == AppRole.opsManager || this == AppRole.fleetManager;
  bool get canViewDriverLocation => isAdminTier || this == AppRole.dispatch;
  bool get canManageClients => isAdminTier;
  bool get canBlockClients => isAdminTier;
  bool get canAssignVipStatus => isAdminTier;
  bool get canApproveRefundsSmall => isAdminTier;
  bool get canManageAllBookings => isAdminTier || this == AppRole.opsManager || this == AppRole.bookingOperator;
  bool get canViewAllBookings => canManageAllBookings; // Alias
  bool get canApplyDiscounts => isAdminTier || this == AppRole.opsManager;
  bool get canManageFleet => isAdminTier || this == AppRole.fleetManager;
  bool get canUpdateMaintenance => canManageFleet || this == AppRole.mechanic;
  bool get canViewFinancialDashboards => isAdminTier || this == AppRole.financeManager;
  bool get canGenerateInvoices => isAdminTier || this == AppRole.financeManager;
  bool get canExportFinancialReports => isAdminTier || this == AppRole.financeManager;
  bool get canModifyRates => isAdminTier;
  bool get canModifyGlobalPricing => isAdminTier; // Alias
  bool get canCreateCoupons => isAdminTier || this == AppRole.opsManager;
  bool get canSendMassCommunications => isAdminTier;
  bool get canSendMassNotifications => canSendMassCommunications; // Alias
  bool get canViewAdvancedAnalytics => isAdminTier;
  bool get canBlockUsersPermanently => isAdminTier;
  bool get canManageBranches => isAdminTier;

  // --- OPERATIONS MANAGER PERMISSIONS (Nivel 3) ---

  bool get canViewLiveMap => isManagerTier || this == AppRole.dispatch;
  bool get canViewAllActiveTrips => isManagerTier || this == AppRole.dispatch;
  bool get canViewDriverStatus => isManagerTier || this == AppRole.dispatch;
  bool get canViewTripAlerts => isManagerTier || this == AppRole.dispatch;
  bool get canReassignActiveTrip => this == AppRole.opsManager || isAdminTier;
  bool get canReassignDrivers => canReassignActiveTrip; // Alias
  bool get canCancelActiveTrip => this == AppRole.opsManager || isAdminTier;
  bool get canCancelActiveTrips => canCancelActiveTrip; // Alias
  bool get canContactDriverDuringTrip => isManagerTier || this == AppRole.dispatch;
  bool get canMarkTripCompleted => this == AppRole.opsManager || isAdminTier;
  bool get canReportIncidents => isStaff;
  bool get canViewDriverProfiles => isStaff;
  bool get canSendDriverMessages => isManagerTier || this == AppRole.dispatch;
  bool get canMarkDriverUnavailable => this == AppRole.opsManager || isAdminTier;
  bool get canViewDriverPerformance => isManagerTier || isAdminTier;
  bool get canViewDailyBookings => isStaff;
  bool get canAssignDriverToBooking => this == AppRole.opsManager || this == AppRole.bookingOperator || isAdminTier;
  bool get canAssignDriversToBookings => canAssignDriverToBooking; // Alias
  bool get canMarkNoShow => this == AppRole.opsManager || this == AppRole.bookingOperator || isAdminTier;
  bool get canViewDailyReports => isManagerTier || isAdminTier;
  bool get canExportOperationalReports => isManagerTier || isAdminTier;

  // --- BOOKING OPERATOR PERMISSIONS (Nivel 4) ---

  bool get canCreateBookings => this == AppRole.bookingOperator || isManagerTier || isAdminTier;
  bool get canEditBookings => this == AppRole.bookingOperator || isManagerTier || isAdminTier;
  bool get canModifyBookings => canEditBookings; // Alias
  bool get canCancelFutureBookings => this == AppRole.bookingOperator || isManagerTier || isAdminTier;
  bool get canViewFleetAvailability => this == AppRole.bookingOperator || isManagerTier || isAdminTier;
  bool get canApplyExistingCoupons => this == AppRole.bookingOperator || isManagerTier || isAdminTier;
  bool get canCalculateQuotes => this == AppRole.bookingOperator || isManagerTier || isAdminTier;
  bool get canSearchClients => this == AppRole.bookingOperator || isStaff;
  bool get canCreateClientAccounts => this == AppRole.bookingOperator || isManagerTier || isAdminTier;
  bool get canUpdateClientContact => this == AppRole.bookingOperator || isManagerTier || isAdminTier;
  bool get canViewClientPreferences => this == AppRole.bookingOperator || isStaff;
  bool get canChatWithClients => this == AppRole.bookingOperator || isStaff;
  bool get canSendBookingConfirmations => this == AppRole.bookingOperator || isManagerTier || isAdminTier;
  bool get canViewPricing => isStaff || this == AppRole.driver;

  // --- ASSISTANT PERMISSIONS (Nivel 4) ---

  bool get canHandleCustomerSupport => this == AppRole.assistant || isManagerTier || isAdminTier;
  bool get canViewConversationHistory => this == AppRole.assistant || isManagerTier || isAdminTier;
  bool get canEscalateIssues => this == AppRole.assistant || this == AppRole.bookingOperator || isManagerTier;
  bool get canCreateSupportTickets => this == AppRole.assistant || isManagerTier || isAdminTier;
  bool get canViewActiveTripDetails => this == AppRole.assistant || isManagerTier || isAdminTier;
  bool get canViewClientTripHistory => this == AppRole.assistant || this == AppRole.bookingOperator || isStaff;
  bool get canRegisterComplaints => this == AppRole.assistant || isStaff;
  bool get canRegisterLostItems => this == AppRole.assistant || isStaff;
  bool get canCreateIncidentReports => this == AppRole.assistant || isManagerTier || isAdminTier;
  bool get canAttachIncidentPhotos => this == AppRole.assistant || isManagerTier || isAdminTier;
  bool get canManageTickets => this == AppRole.assistant || isManagerTier || isAdminTier;
  bool get canRequestRefunds => this == AppRole.assistant || isManagerTier || isAdminTier;

  // --- DISPATCH PERMISSIONS (Nivel 4) ---

  bool get canManuallyAssignDrivers => this == AppRole.dispatch || isManagerTier || isAdminTier;
  bool get canReassignDriverEmergency => this == AppRole.dispatch || this == AppRole.opsManager || isAdminTier;
  bool get canCancelDriverAssignment => this == AppRole.dispatch || isManagerTier || isAdminTier;
  bool get canPrioritizeAssignments => this == AppRole.dispatch || isManagerTier || isAdminTier;
  bool get canViewRouteDetails => this == AppRole.dispatch || isManagerTier || isAdminTier;
  bool get canReportRouteDeviation => this == AppRole.dispatch || isManagerTier || isAdminTier;
  bool get canViewDispatchMetrics => this == AppRole.dispatch || isManagerTier || isAdminTier;
  bool get canReceiveDispatchAlerts => this == AppRole.dispatch || isManagerTier || isAdminTier;
  bool get canChatWithDrivers => this == AppRole.dispatch || isManagerTier || isAdminTier; // Alias/Specific

  // --- FLEET MANAGER PERMISSIONS (Nivel 3) ---

  bool get canAddVehicles => this == AppRole.fleetManager || isAdminTier;
  bool get canEditVehicleData => this == AppRole.fleetManager || isAdminTier;
  bool get canChangeVehicleStatus => this == AppRole.fleetManager || isAdminTier;
  bool get canViewVehicleGPS => this == AppRole.fleetManager || isManagerTier || isAdminTier;
  bool get canScheduleMaintenance => this == AppRole.fleetManager || isAdminTier;
  bool get canRegisterMaintenanceCosts => this == AppRole.fleetManager || isAdminTier;
  bool get canCreateInspectionChecklists => this == AppRole.fleetManager || isAdminTier;
  bool get canAssignMechanicTasks => this == AppRole.fleetManager || isAdminTier;
  bool get canManageInsurance => this == AppRole.fleetManager || isAdminTier;
  bool get canManageVehicleDocuments => this == AppRole.fleetManager || isAdminTier;
  bool get canViewFleetReports => this == AppRole.fleetManager || isAdminTier;
  bool get canViewVehicleROI => this == AppRole.fleetManager || isAdminTier;
  bool get canRegisterVehicleDamage => this == AppRole.fleetManager || this == AppRole.mechanic || isAdminTier;
  bool get canManageInsuranceClaims => this == AppRole.fleetManager || isAdminTier;

  // --- MECHANIC PERMISSIONS (Nivel 4) ---

  bool get canViewAssignedTasks => this == AppRole.mechanic;
  bool get canUpdateTaskStatus => this == AppRole.mechanic;
  bool get canUploadWorkPhotos => this == AppRole.mechanic;
  bool get canRegisterPartsUsed => this == AppRole.mechanic;
  bool get canRegisterWorkHours => this == AppRole.mechanic;
  bool get canCompleteInspectionChecklist => this == AppRole.mechanic;
  bool get canReportAdditionalIssues => this == AppRole.mechanic;
  bool get canRequestParts => this == AppRole.mechanic;
  bool get canViewVehicleMaintenanceHistory => this == AppRole.mechanic || this == AppRole.fleetManager || isAdminTier;

  // --- DRIVER PERMISSIONS ---

  bool get canManageOwnAvailability => this == AppRole.driver;
  bool get canSelectWorkZone => this == AppRole.driver;
  bool get canSelectServiceCategories => this == AppRole.driver;
  bool get canReceiveTripRequests => this == AppRole.driver;
  bool get canAcceptRejectTrips => this == AppRole.driver;
  bool get canViewTripDetails => this == AppRole.driver;
  bool get canNavigateToPickup => this == AppRole.driver;
  bool get canMarkTripMilestones => this == AppRole.driver; 
  bool get canRegisterExtraCharges => this == AppRole.driver;
  bool get canViewAssignedBookings => this == AppRole.driver;
  bool get canConfirmBooking => this == AppRole.driver;
  bool get canUseGPSNavigation => this == AppRole.driver;
  bool get canReportRouteIssues => this == AppRole.driver;
  bool get canChatWithAssignedClient => this == AppRole.driver;
  bool get canCallAssignedClient => this == AppRole.driver;
  bool get canChatWithDispatch => this == AppRole.driver;
  bool get canUseEmergencyButton => this == AppRole.driver;
  bool get canViewOwnEarnings => this == AppRole.driver;
  bool get canDownloadPaymentReceipts => this == AppRole.driver;
  bool get canUpdateOwnProfile => this == AppRole.driver || isStaff;
  bool get canUploadOwnDocuments => this == AppRole.driver;
  bool get canViewOwnRating => this == AppRole.driver;
  bool get canViewAssignedVehicle => this == AppRole.driver;
  bool get canCompletePreTripChecklist => this == AppRole.driver;
  bool get canReportVehicleIssues => this == AppRole.driver;
  bool get canRequestVehicleMaintenance => this == AppRole.driver;
  bool get canAcceptTransportRequests => this == AppRole.driver;

  // --- CLIENT PERMISSIONS ---

  bool get isClient => this == AppRole.client || this == AppRole.clientVip || this == AppRole.clientCorp;
  bool get isVipClient => this == AppRole.clientVip || this == AppRole.clientCorp;
  bool get isCorporateClient => this == AppRole.clientCorp;

  bool get canManageOwnAccount => isClient;
  bool get canAddPaymentMethods => isClient;
  bool get canUploadDriverLicense => isClient;
  bool get canBookTransportation => isClient;
  bool get canViewPriceEstimates => isClient;
  bool get canScheduleTrips => isClient;
  bool get canApplyCoupons => isClient;
  bool get canBookForOthers => isClient;
  bool get canViewAssignedDriverInfo => isClient;
  bool get canTrackDriverLocation => isClient;
  bool get canChatWithDriver => isClient;
  bool get canShareLiveTrip => isClient;
  bool get canRequestTripChanges => isClient;
  bool get canContactSupport => isClient;
  bool get canRateTrip => isClient;
  bool get canLeaveTip => isClient;
  bool get canReportTripIssues => isClient;
  bool get canRequestTripRefund => isClient;
  bool get canDownloadReceipts => isClient;
  bool get canRentVehicles => isClient;
  bool get canViewRentalCatalog => isClient;
  bool get canCompleteRentalChecklist => isClient;
  bool get canViewOwnTripHistory => isClient || this == AppRole.driver;
  bool get canRepeatPreviousBooking => isClient;
  bool get canViewPromotions => isClient;
  bool get canReferFriends => isClient;
  bool get canViewLoyaltyPoints => isClient;

  // VIP & Corporate Benefits
  bool get hasPriorityAssignment => isVipClient;
  bool get hasExtendedWaitTime => isVipClient;
  bool get hasFreeCancellation => isVipClient;
  bool get hasVipSupport => isVipClient;
  bool get hasPermanentDiscount => isVipClient;
  bool get canBookMoreSimultaneous => isVipClient;
  bool get hasMonthlyBilling => isVipClient;
  bool get hasMultiUserAccount => isCorporateClient;
  bool get canAssignCostCenters => isCorporateClient;
  bool get canSetEmployeeSpendLimits => isCorporateClient;
  bool get hasCorporateBilling => isCorporateClient;
  bool get canViewEmployeeReports => isCorporateClient;
  bool get hasVolumeDiscount => isCorporateClient;
  bool get hasAccountManager => isCorporateClient;
  bool get hasUnlimitedSimultaneous => isCorporateClient;
  bool get hasAPIAccess => isCorporateClient;

  // --- MAP & TRACKING SPECIFIC (Used by MapPermissionWidget) ---

  bool get canUseDriverNavigation => this == AppRole.driver;
  bool get canTrackTrips => isClient || isStaff;
  bool get canViewTripHistory => isClient || isStaff;
  bool get canViewMileageReports => isManagerTier || isAdminTier;
  bool get canResolveTripAlerts => isManagerTier || isAdminTier || this == AppRole.dispatch;
  bool get canManageGeofences => isAdminTier;
  bool get canViewDriverLocations => isManagerTier || isAdminTier || this == AppRole.dispatch;
}
