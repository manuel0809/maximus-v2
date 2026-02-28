import 'package:flutter/material.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/login_registration_screen/login_registration_screen.dart';
import '../presentation/client_dashboard/client_dashboard.dart';
import '../presentation/admin_dashboard/admin_dashboard.dart';
import '../presentation/car_rental_booking_screen/car_rental_booking_screen.dart';
import '../presentation/personal_transport_service_screen/personal_transport_service_screen.dart';
import '../presentation/driver_tracking_screen/driver_tracking_screen.dart';
import '../presentation/messaging_screen/messaging_screen.dart';
import '../presentation/conversations_list_screen/conversations_list_screen.dart';
import '../presentation/notification_center_screen/notification_center_screen.dart';
import '../presentation/push_notification_settings_screen/push_notification_settings_screen.dart';
import '../presentation/ratings_reviews_screen/ratings_reviews_screen.dart';
import '../presentation/guest_booking_flow_screen/guest_booking_flow_screen.dart';
import '../presentation/guest_registration_prompt_screen/guest_registration_prompt_screen.dart';
import '../presentation/payments_invoices_screen/payments_invoices_screen.dart';
import '../presentation/car_rental_service_screen/car_rental_service_screen.dart';
import '../presentation/car_rental_admin_panel_screen/car_rental_admin_panel_screen.dart';
import '../presentation/quick_quote_car_rental_screen/quick_quote_car_rental_screen.dart';
import '../presentation/identity_verification_screen/identity_verification_screen.dart';
import '../presentation/digital_checklist_screen/digital_checklist_screen.dart';
import '../presentation/active_rental_dashboard/active_rental_dashboard.dart';
import '../presentation/rental_feedback_screen/rental_feedback_screen.dart';
import '../presentation/loyalty_dashboard_screen/loyalty_dashboard_screen.dart';
import '../presentation/digital_contract_screen/digital_contract_screen.dart';
import '../presentation/my_documents_screen/my_documents_screen.dart';
import '../presentation/driver_dashboard/driver_dashboard_screen.dart';
import '../presentation/admin_dashboard/screens/admin_summary_dashboard_screen.dart';
import '../presentation/admin_dashboard/screens/fleet_management_screen.dart';
import '../presentation/admin_dashboard/screens/reservations_admin_screen.dart';
import '../presentation/admin_dashboard/screens/client_crm_screen.dart';
import '../presentation/admin_dashboard/screens/financial_reports_screen.dart';
import '../presentation/admin_dashboard/screens/branch_management_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/support_screen/support_screen.dart';
import '../presentation/settings_screen/settings_screen.dart';
import '../presentation/driver_dashboard/screens/driver_profile_screen.dart';
import '../presentation/admin_dashboard/screens/admin_user_management_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String loginRegistration = '/login-registration-screen';
  static const String clientDashboard = '/client-dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String carRentalBooking = '/car-rental-booking-screen';
  static const String personalTransportService =
      '/personal-transport-service-screen';
  static const String driverTracking = '/driver-tracking-screen';
  static const String messagingScreen = '/messaging-screen';
  static const String conversationsListScreen = '/conversations-list-screen';
  static const String notificationCenter = '/notification-center-screen';
  static const String pushNotificationSettings =
      '/push-notification-settings-screen';
  static const String ratingsReviews = '/ratings-reviews-screen';
  static const String guestBookingFlow = '/guest-booking-flow-screen';
  static const String guestRegistrationPrompt =
      '/guest-registration-prompt-screen';
  static const String paymentsInvoices = '/payments-invoices-screen';
  static const String carRentalService = '/car-rental-service-screen';
  static const String carRentalAdminPanel = '/car-rental-admin-panel-screen';
  static const String quickQuoteCarRental = '/quick-quote-car-rental-screen';
  static const String profile = '/profile-screen';
  static const String support = '/support-screen';
  static const String settings = '/settings-screen';
  static const String identityVerification = '/identity-verification-screen';
  static const String digitalChecklist = '/digital-checklist-screen';
  static const String activeRental = '/active-rental-dashboard';
  static const String rentalFeedback = '/rental-feedback-screen';
  static const String loyaltyDashboard = '/loyalty-dashboard-screen';
  static const String digitalContract = '/digital-contract-screen';
  static const String myDocuments = '/my-documents-screen';
  static const String adminSummary = '/admin-summary-screen';
  static const String fleetManagement = '/fleet-management-screen';
  static const String reservationsAdmin = '/reservations-admin-screen';
  static const String clientCRM = '/client-crm-screen';
  static const String financialReports = '/financial-reports-screen';
  static const String driverDashboard = '/driver-dashboard-screen';
  static const String branchManagement = '/branch-management-screen';
  static const String driverProfile = '/driver-profile-screen';
  static const String adminUserManagement = '/admin-user-management';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    loginRegistration: (context) => const LoginRegistrationScreen(),
    clientDashboard: (context) => ClientDashboard(),
    adminDashboard: (context) => const AdminDashboard(),
    driverDashboard: (context) => const DriverDashboardScreen(),
    branchManagement: (context) => const BranchManagementScreen(),
    carRentalBooking: (context) => const CarRentalBookingScreen(),
    personalTransportService: (context) =>
        const PersonalTransportServiceScreen(),
    driverTracking: (context) => DriverTrackingScreen(),
    messagingScreen: (context) => const MessagingScreen(),
    conversationsListScreen: (context) => const ConversationsListScreen(),
    notificationCenter: (context) => NotificationCenterScreen(),
    pushNotificationSettings: (context) =>
        const PushNotificationSettingsScreen(),
    ratingsReviews: (context) => const RatingsReviewsScreen(),
    guestBookingFlow: (context) => const GuestBookingFlowScreen(),
    guestRegistrationPrompt: (context) => const GuestRegistrationPromptScreen(),
    paymentsInvoices: (context) => const PaymentsInvoicesScreen(),
    carRentalService: (context) => const CarRentalServiceScreen(),
    carRentalAdminPanel: (context) => const CarRentalAdminPanelScreen(),
    quickQuoteCarRental: (context) => const QuickQuoteCarRentalScreen(),
    profile: (context) => const ProfileScreen(),
    support: (context) => const SupportScreen(),
    settings: (context) => const SettingsScreen(),
    identityVerification: (context) => const IdentityVerificationScreen(),
    digitalChecklist: (context) => const DigitalChecklistScreen(rentalId: 'default', isReturn: false),
    activeRental: (context) => const ActiveRentalDashboard(rental: {}),
    rentalFeedback: (context) => const RentalFeedbackScreen(vehicleName: 'Default', rentalId: 'default'),
    loyaltyDashboard: (context) => const LoyaltyDashboardScreen(),
    digitalContract: (context) => const DigitalContractScreen(rentalId: 'default'),
    myDocuments: (context) => const MyDocumentsScreen(),
    adminSummary: (context) => const AdminSummaryDashboardScreen(),
    fleetManagement: (context) => const FleetManagementScreen(),
    reservationsAdmin: (context) => const ReservationsAdminScreen(),
    clientCRM: (context) => const ClientCRMScreen(),
    financialReports: (context) => const FinancialReportsScreen(),
    driverProfile: (context) => const DriverProfileScreen(driver: {}),
    adminUserManagement: (context) => const AdminUserManagementScreen(),
  };
}
