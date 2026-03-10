import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/supabase_service.dart';
import '../../services/user_service.dart';
import '../../services/notification_service.dart';
import '../../core/constants/app_roles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern authentication screen with tabbed interface for login and registration
class LoginRegistrationScreen extends StatefulWidget {
  const LoginRegistrationScreen({super.key});

  @override
  State<LoginRegistrationScreen> createState() =>
      _LoginRegistrationScreenState();
}

class _LoginRegistrationScreenState extends State<LoginRegistrationScreen> {
  final bool _isLogin = true;
  bool _isOtpSent = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  final _userService = UserService.instance;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_isOtpSent) {
      await _initiateAuth();
    } else {
      await _verifyOtp();
    }
  }

  Future<void> _initiateAuth() async {
    final contact = _emailController.text.trim().replaceAll(RegExp(r'\s+'), '').toLowerCase();
    final password = _passwordController.text;

    if (contact.isEmpty) {
      _showMessage('Por favor ingresa tu correo o número de celular');
      return;
    }
    
    setState(() => _loading = true);

    try {
      final isEmail = contact.contains('@');

      // If password provided, do direct sign in
      if (password.isNotEmpty) {
        AuthResponse response;
        if (isEmail) {
          response = await SupabaseService.instance.client.auth.signInWithPassword(
            email: contact,
            password: password,
          );
        } else {
          response = await SupabaseService.instance.client.auth.signInWithPassword(
            phone: contact,
            password: password,
          );
        }

        if (response.user != null && mounted) {
          final roleStr = response.user!.userMetadata?['role'] ?? 'client';
          final role = AppRole.fromString(roleStr);
          await _userService.updateLastLogin(response.user!.id);
          _showMessage('¡Bienvenido de nuevo!');

          if (!mounted) return;
          if (role == AppRole.admin) {
            Navigator.of(context).pushReplacementNamed('/admin-dashboard');
          } else if (role == AppRole.driver) {
            Navigator.of(context).pushReplacementNamed('/driver-dashboard');
          } else {
            Navigator.of(context).pushReplacementNamed('/client-dashboard');
          }
        }
        return; // Stop here if password login succeeds
      }

      // OTHERWISE: Fallback to OTP flow if password is empty
      if (isEmail) {
        await SupabaseService.instance.client.auth.signInWithOtp(
          email: contact,
          emailRedirectTo: 'maximus://login-callback',
        );
      } else {
        await SupabaseService.instance.client.auth.signInWithOtp(
          phone: contact,
        );
      }
      setState(() {
        _isOtpSent = true;
      });
      _showMessage('Código enviado. Revisa tu ${isEmail ? "correo" : "SMS"}.');
    } catch (e) {
      _showMessage('Error al enviar código: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final contact = _emailController.text.trim().replaceAll(RegExp(r'\s+'), '').toLowerCase();
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      _showMessage('Por favor ingresa el código');
      return;
    }

    setState(() => _loading = true);
    try {
      final isEmail = contact.contains('@');
      final response = await SupabaseService.instance.client.auth.verifyOTP(
        type: isEmail ? OtpType.magiclink : OtpType.sms,
        token: otp,
        email: isEmail ? contact : null,
        phone: !isEmail ? contact : null,
      );

      if (response.user != null && mounted) {
        if (!_isLogin) {
          // New user logic could go here if needed.
          // For now, Supabase allows setting default metadata via triggers or we just update role.
          // We default to 'client' role for OTP phone signups.
          await _userService.updateUserProfile(
            userId: response.user!.id,
            updates: {'role': 'client', 'full_name': 'New User'}
          );
          
          // Trigger welcome push notification
          await NotificationService.instance.sendWelcomeNotification('New User');
        }
        await _routeBasedOnRole(response.user!.id);
      }
    } catch (e) {
      _showMessage('Error al verificar código: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    setState(() => _loading = true);
    try {
      await SupabaseService.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: 'maximus://login-callback',
      );
    } catch (e) {
      _showMessage('Error con inicio de sesión ${provider.name}: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _routeBasedOnRole(String userId) async {
    try {
      final response = await SupabaseService.instance.client
          .from('user_profiles')
          .select('role, is_active, full_name')
          .eq('id', userId)
          .maybeSingle();

      if (response != null && mounted) {
        final navigator = Navigator.of(context);
        final isActive = response['is_active'] as bool? ?? true;
        final roleStr = response['role'] as String?;
        final role = AppRole.fromString(roleStr);

        if (!isActive) {
          if (role.isStaff) {
            _showApprovalPendingDialog();
          } else {
            _showMessage('Tu cuenta ha sido desactivada. Contacta al administrador.');
          }
          await SupabaseService.instance.client.auth.signOut();
          return;
        }

        await _userService.updateLastLogin(userId);

        if (role.isStaff) {
          navigator.pushReplacementNamed('/admin-dashboard');
        } else if (role == AppRole.driver) {
          navigator.pushReplacementNamed('/driver-dashboard-screen');
        } else if (role.isClient) {
          navigator.pushReplacementNamed('/client-dashboard');
        } else {
          _showMessage('Rol no reconocido: $roleStr. Contacta al administrador.');
          await SupabaseService.instance.client.auth.signOut();
        }
      } else if (mounted) {
        _showMessage('Perfil de usuario no encontrado. Contacta al administrador.');
        await SupabaseService.instance.client.auth.signOut();
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Error al cargar perfil: $e');
        await SupabaseService.instance.client.auth.signOut();
      }
    }
  }

  void _showApprovalPendingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Solicitud Enviada', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Tu registro como administrador está pendiente de aprobación. Se ha notificado al administrador principal para que otorgue los permisos correspondientes y clasifique tu perfil.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido', style: TextStyle(color: Color(0xFFD4AF37))),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Deep Luxury Noir
      body: Stack(
        children: [
          // Subtle elegant background elements
          Positioned(
            top: -10.h,
            right: -10.w,
            child: Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD4AF37).withValues(alpha: 0.05),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    children: [
                      SizedBox(height: 4.h),
                      // Luxury Header
                      _buildLuxuryHeader(),
                      SizedBox(height: 8.h),
                      _isOtpSent ? _buildOtpForm() : _buildEmailForm(),
                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLuxuryHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFD4AF37), width: 1),
          ),
          child: CircleAvatar(
            radius: 35,
            backgroundColor: Colors.white,
            backgroundImage: const AssetImage('assets/images/maximus_official_logo.png'),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          "MAXIMUS LEVEL GROUP",
          style: GoogleFonts.lexend(
            color: const Color(0xFFD4AF37),
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
          ),
        ),
        Container(
          width: 40,
          height: 1,
          margin: const EdgeInsets.only(top: 8),
          color: const Color(0xFFD4AF37).withValues(alpha: 0.5),
        ),
      ],
    );
  }

  Widget _buildEmailForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Inicia sesión con tu teléfono o email',
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 3.h),
        
        // Email/Phone Input Field
        _buildLuxuryTextField(
          controller: _emailController,
          hint: 'Número de teléfono o email',
          icon: Icons.person_outline,
        ),
        SizedBox(height: 2.h),

        // Password Input Field
        _buildLuxuryTextField(
          controller: _passwordController,
          hint: 'Contraseña (opcional)',
          icon: Icons.lock_outline,
          isPassword: true,
          obscure: _obscurePassword,
          onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        SizedBox(height: 2.h),

        // Submit Button
        Container(
          height: 55,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD4AF37), Color(0xFFB5942D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _loading ? null : _handleAuth,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'CONTINUAR',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: 2.0,
                    ),
                  ),
          ),
        ),

        SizedBox(height: 3.h),

        // Divider
        Row(
          children: [
            const Expanded(child: Divider(color: Colors.white24)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: const Text('o continúa con', style: TextStyle(color: Colors.white54, fontSize: 12)),
            ),
            const Expanded(child: Divider(color: Colors.white24)),
          ],
        ),

        SizedBox(height: 3.h),

        // Social Buttons Row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildRoundSocialButton(
              icon: Icons.g_mobiledata,
              onPressed: _loading ? () {} : () => _signInWithOAuth(OAuthProvider.google),
            ),
            SizedBox(width: 8.w),
            _buildRoundSocialButton(
              icon: Icons.apple,
              onPressed: _loading ? () {} : () => _signInWithOAuth(OAuthProvider.apple),
            ),
          ],
        ),
        
        SizedBox(height: 6.h),
        Text(
          'Al continuar, aceptas nuestros términos y la recepción de comunicaciones de Maximus Level Group.',
          style: TextStyle(color: Colors.white38, fontSize: 10.sp, height: 1.4),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLuxuryTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white10),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        cursorColor: const Color(0xFFD4AF37),
        style: TextStyle(fontSize: 12.sp, color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFFD4AF37).withValues(alpha: 0.6), size: 20),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white30, fontSize: 11.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.white30,
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildRoundSocialButton({required IconData icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1E1E1E),
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildOtpForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 2.h),
        Text(
          'Introduce el código de 6 dígitos enviado a ${_emailController.text}',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 2.h),
        GestureDetector(
          onTap: () {
            setState(() {
              _isOtpSent = false;
            });
          },
          child: Text(
            '¿Número incorrecto? Haz clic para volver',
            style: TextStyle(
              fontSize: 11.sp,
              color: const Color(0xFFD4AF37),
              decoration: TextDecoration.underline,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 5.h),

        // OTP Field
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: Colors.white10),
          ),
          child: TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22.sp, letterSpacing: 12.0, color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold),
            maxLength: 6,
            cursorColor: const Color(0xFFD4AF37),
            decoration: const InputDecoration(
              counterText: "",
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 24),
            ),
          ),
        ),

        SizedBox(height: 4.h),

        // Verify Button
        Container(
          height: 55,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD4AF37), Color(0xFFB5942D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _loading ? null : _handleAuth,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'VERIFICAR',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: 2.0,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButton({required IconData icon, required String text, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.black, size: 24),
      label: Text(text, style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF3F3F3), // Light grey background
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    );
  }
}
