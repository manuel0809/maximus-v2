import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import './routes/app_routes.dart';
import './services/localization_service.dart';
import './services/notification_service.dart';
import './services/realtime_service.dart';

void main() {
  runApp(const MaximusApp());
}

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
            title: 'Maximus level group',
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
            routes: {
              ...AppRoutes.routes,
              '/login-premium': (context) => const LoginPremiumScreen(),
            },
            // Temporarily use LoginPremiumScreen as initial if needed, 
            // but SplashScreen usually handles this.
            home: const LoginPremiumScreen(),
          ),
        );
      },
    );
  }
}

class LoginPremiumScreen extends StatelessWidget {
  const LoginPremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. FONDO: Imagen de Suburban en Miami de Noche
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?q=80&w=2000'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Premium Gradient Overlay for visual depth and text legibility
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(red: 0, green: 0, blue: 0, alpha: 0.2),
                  Colors.black.withValues(red: 0, green: 0, blue: 0, alpha: 0.6),
                  Colors.black,
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // 3. CONTENIDO
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  
                  // NOMBRE DE LA COMPAÑÍA EN 3D (Efecto Gold & Shadows)
                  Text(
                    "MAXIMUS\nLEVEL GROUP",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cinzel( // Fuente muy elegante/exclusiva
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      color: const Color(0xFFD4AF37), // Color Oro
                      shadows: [
                        const Shadow(offset: Offset(3, 3), blurRadius: 8, color: Colors.black),
                        const Shadow(offset: Offset(-1, -1), blurRadius: 2, color: Colors.white24),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // SLOGAN EN BLANCO (Más pequeño y limpio)
                  Text(
                    "Premium Ride Experience",
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.5,
                    ),
                  ),

                  const Spacer(),

                  // BOTÓN DE LOGIN PRINCIPAL
                  _buildMainButton(context, "Login", Colors.white, Colors.black, () {
                    Navigator.pushNamed(context, AppRoutes.clientDashboard);
                  }),
                  
                  const SizedBox(height: 15),

                  // BOTÓN APPLE
                  _buildSocialButton(context, "Continue with Apple", Icons.apple, Colors.white, () {
                    Navigator.pushNamed(context, AppRoutes.clientDashboard);
                  }),
                  
                  const SizedBox(height: 12),

                  // BOTÓN GOOGLE
                  _buildSocialButton(context, "Continue with Google", Icons.g_mobiledata, Colors.white, () {
                    Navigator.pushNamed(context, AppRoutes.clientDashboard);
                  }),

                  const SizedBox(height: 15),

                  const SizedBox(height: 30),

                  // TEXTO FINAL
                  Text(
                    "or create an account manually",
                    style: GoogleFonts.lexend(color: Colors.white54, fontSize: 14),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGETS AUXILIARES PARA LOS BOTONES
  Widget _buildMainButton(BuildContext context, String text, Color bg, Color txt, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: Colors.black.withValues(red: 0, green: 0, blue: 0, alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Center(
            child: Text(text, style: GoogleFonts.lexend(color: txt, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(BuildContext context, String text, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: double.infinity,
          height: 55,
            decoration: BoxDecoration(
            color: Colors.white.withValues(red: 1, green: 1, blue: 1, alpha: 0.1), // Estilo Glassmorphism
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 10),
              Text(text, style: GoogleFonts.lexend(color: color, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

// Backwards-compatible alias for tests that expect `MyApp`.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaximusApp();
  }
}
