import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/user_service.dart';
import '../../core/constants/app_roles.dart';
import '../../core/app_config.dart';
import '../../routes/app_routes.dart';

/// Splash Screen for MAXIMUS LEVEL GROUP luxury transportation platform
///
/// Provides branded app launch experience while initializing core services
/// and determining user navigation path. Displays full-screen with system
/// status bar matching burgundy brand color, centered animated logo with
/// signature gradient background, and minimal loading indicator.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isInitializing = true;
  String _initializationStatus = 'Inicializando servicios...';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  /// Setup elegant scale and fade animations for logo
  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  /// Initialize core services and determine navigation path
  Future<void> _initializeApp() async {
    try {
      // Simulate checking authentication status
      await Future.delayed(const Duration(milliseconds: 800));
      debugPrint('SplashScreen: Verifying authentication...');
      setState(() {
        _initializationStatus = 'Verificando autenticación...';
      });

      // Simulate loading user preferences
      await Future.delayed(const Duration(milliseconds: 600));
      debugPrint('SplashScreen: Loading preferences...');
      setState(() {
        _initializationStatus = 'Cargando preferencias...';
      });

      // Simulate fetching service availability
      await Future.delayed(const Duration(milliseconds: 700));
      setState(() {
        _initializationStatus = 'Preparando servicios...';
      });

      // Simulate preparing cached booking information
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _initializationStatus = 'Finalizando...';
        _isInitializing = false;
      });

      // Wait for animation to complete
      await Future.delayed(const Duration(milliseconds: 400));

      // Navigation logic
      if (mounted) {
        final user = Supabase.instance.client.auth.currentUser;
        debugPrint('SplashScreen: Auth check - User ID: ${user?.id}');
        
        // --- CLIENT LANDING PAGE LOGIC ---
        if (user == null) {
          if (AppConfig.isClient) {
            debugPrint('SplashScreen: Unauthorized client. Navigating to Landing/Dashboard');
            Navigator.of(context, rootNavigator: true)
                .pushReplacementNamed(AppRoutes.clientDashboard);
            return;
          }
          debugPrint('SplashScreen: Navigating to Login');
          Navigator.of(context, rootNavigator: true)
              .pushReplacementNamed(AppRoutes.loginRegistration);
          return;
        }
        // ---------------------------------

        debugPrint('SplashScreen: Fetching profile for ${user.id}');
        final profile = await UserService.instance.getUserById(user.id);
          debugPrint('SplashScreen: Profile fetch result: ${profile != null ? "Success" : "Empty"}');
          if (!mounted) return;
          
          final roleStr = profile?['role'] as String?;
          final role = AppRole.fromString(roleStr);
          debugPrint('SplashScreen: Determined role: ${role.dbValue}');

          // --- FLAVOR SECURITY LOGIC ---
          final bool isStaffBuild = AppConfig.isStaff;
          final bool userIsStaff = role.isAdmin || role.isAssistant || role.isDriver;

          if (isStaffBuild && !userIsStaff) {
            // Un cliente intentando entrar al sitio de Staff
            _showAccessDenied('Este sitio es exclusivo para personal. Por favor, usa la web de clientes.');
            return;
          }

          if (!isStaffBuild && userIsStaff) {
            // Staff entrando al sitio de clientes (opcionalmente permitido, pero mejor separar)
            debugPrint('SplashScreen: Staff user on Client site. Proceeding as client UI.');
          }
          // ------------------------------

          if (role.isAdmin || role.isAssistant) {
            debugPrint('SplashScreen: Navigating to Admin Dashboard');
            Navigator.of(context, rootNavigator: true)
                .pushReplacementNamed(AppRoutes.adminDashboard);
          } else if (role.isDriver) {
            debugPrint('SplashScreen: Navigating to Driver Dashboard');
            Navigator.of(context, rootNavigator: true)
                .pushReplacementNamed(AppRoutes.driverDashboard);
          } else {
            debugPrint('SplashScreen: Navigating to Client Dashboard');
            Navigator.of(context, rootNavigator: true)
                .pushReplacementNamed(AppRoutes.clientDashboard);
          }
        }
      }
    } catch (e) {
      debugPrint('SplashScreen: ERROR during initialization: $e');
      setState(() {
        _initializationStatus = 'Error de conexión. Reintentando...';
      });
      await Future.delayed(const Duration(seconds: 2));
      _initializeApp(); // Retry initialization
    }
  }

  void _showAccessDenied(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Acceso Restringido', style: TextStyle(color: Color(0xFFD4AF37))),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              // Redirect to client site or just logout
              Supabase.instance.client.auth.signOut();
              Navigator.of(context).pushReplacementNamed(AppRoutes.loginRegistration);
            },
            child: const Text('Cerrar Sesión', style: TextStyle(color: Color(0xFFD4AF37))),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F0F0F), // Near black
              Color(0xFF1A1A1A), // Noir
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              height: 100.h,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Spacer to push content to center
                  const Spacer(flex: 2),

                  // Animated Logo Section
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: _buildLogoSection(),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 6.h),

                  // Loading Indicator
                  if (_isInitializing) _buildLoadingIndicator(theme),

                  // Initialization Status Text
                  if (_isInitializing) ...[
                    SizedBox(height: 2.h),
                    Text(
                      _initializationStatus,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.sp,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  // Spacer to balance layout
                  const Spacer(flex: 3),

                  // Brand Tagline
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: Text(
                      'Transporte de Lujo Premium',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 10.sp,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build logo section with company branding
  Widget _buildLogoSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo Container with MAXIMUS LEVEL GROUP logo
        Container(
          width: 35.w,
          height: 35.w,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/Untitled-1770930294814.jpeg',
              fit: BoxFit.contain,
              semanticLabel:
                  'MAXIMUS LEVEL GROUP logo with stylized M in burgundy and rose gold',
            ),
          ),
        ),
      ],
    );
  }

  /// Build platform-native loading indicator
  Widget _buildLoadingIndicator(ThemeData theme) {
    return SizedBox(
      width: 8.w,
      height: 8.w,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}
