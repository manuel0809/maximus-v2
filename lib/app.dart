import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import './routes/app_routes.dart';
import './services/localization_service.dart';
import './services/notification_service.dart';
import './services/realtime_service.dart';
import './core/app_config.dart';

class MaximusApp extends StatelessWidget {
  const MaximusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LocalizationService()),
            Provider(create: (_) => NotificationService.instance),
            Provider(create: (_) => RealtimeService.instance),
          ],
          child: MaterialApp(
            title: AppConfig.appTitle,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.dark,
              primaryColor: const Color(0xFFD4AF37),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFD4AF37),
                brightness: Brightness.dark,
                primary: const Color(0xFFD4AF37),
                onPrimary: Colors.black,
              ),
            ),
            initialRoute: AppRoutes.initial,
            routes: AppRoutes.routes,
          ),
        );
      },
    );
  }
}
