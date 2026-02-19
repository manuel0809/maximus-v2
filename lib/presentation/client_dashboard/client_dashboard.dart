import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_bottom_bar.dart';
import './client_dashboard_initial_page.dart';

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  ClientDashboardState createState() => ClientDashboardState();
}

class ClientDashboardState extends State<ClientDashboard> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  int currentIndex = 0;

  // ALL CustomBottomBar routes in EXACT order matching CustomBottomBar items
  // Dashboard, Bookings, Profile, Support
  final List<String> routes = [
    '/client-dashboard',
    '/payments-invoices-screen',
    '/profile-screen',
    '/support-screen',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        key: navigatorKey,
        initialRoute: '/client-dashboard',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/client-dashboard' || '/':
              return MaterialPageRoute(
                builder: (context) => const ClientDashboardInitialPage(),
                settings: settings,
              );
            default:
              // Check AppRoutes.routes for all other routes
              if (AppRoutes.routes.containsKey(settings.name)) {
                return MaterialPageRoute(
                  builder: AppRoutes.routes[settings.name]!,
                  settings: settings,
                );
              }
              return null;
          }
        },
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: currentIndex,
        onTap: (index) {
          // For the routes that are not in the AppRoutes.routes, do not navigate to them.
          if (!AppRoutes.routes.containsKey(routes[index])) {
            return;
          }
          if (currentIndex != index) {
            setState(() => currentIndex = index);
            navigatorKey.currentState?.pushReplacementNamed(routes[index]);
          }
        },
      ),
    );
  }
}
