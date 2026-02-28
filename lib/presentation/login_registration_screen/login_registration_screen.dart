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
  final _otpController = TextEditingController();
  bool _loading = false;
  final _userService = UserService.instance;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_isOtpSent) {
      await _sendOtp();
    } else {
      await _verifyOtp();
    }
  }

  Future<void> _sendOtp() async {
    final contact = _emailController.text.trim();
    if (contact.isEmpty) {
      _showMessage('Por favor ingresa tu correo o número de celular');
      return;
    }
    setState(() => _loading = true);
    try {
      final isEmail = contact.contains('@');
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
    final contact = _emailController.text.trim();
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "MAXIMUS LEVEL GROUP",
              style: GoogleFonts.lexend(
                color: Colors.black,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            Image.asset(
              'assets/images/maximus_official_logo.png',
              height: 40,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _isOtpSent ? _buildOtpForm() : _buildEmailForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '¿Cuál es tu número de teléfono o email?',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
            height: 1.2,
          ),
        ),
        SizedBox(height: 3.h),
        
        // Input Field
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F3), // Light grey
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.transparent),
          ),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            cursorColor: Colors.black,
            style: TextStyle(
              fontSize: 12.sp, 
              color: Colors.black,
            ),
            decoration: InputDecoration(
              hintText: 'Introducir número de teléfono o email',
              hintStyle: TextStyle(
                color: Colors.black54,
                fontSize: 11.sp,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            ),
          ),
        ),
        SizedBox(height: 2.h),

        // Submit Button
        ElevatedButton(
          onPressed: _loading ? null : _handleAuth,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            padding: EdgeInsets.symmetric(vertical: 2.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
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
                  'Continuar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),

        SizedBox(height: 3.h),

        // Divider
        Row(
          children: [
            const Expanded(child: Divider(color: Colors.black26)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: const Text('o', style: TextStyle(color: Colors.black54)),
            ),
            const Expanded(child: Divider(color: Colors.black26)),
          ],
        ),

        SizedBox(height: 3.h),

        // Google Button
        _buildSocialButton(
          icon: Icons.g_mobiledata, // Fallback for G logo
          text: 'Continuar con Google',
          onPressed: _loading ? () {} : () => _signInWithOAuth(OAuthProvider.google),
        ),
        SizedBox(height: 1.5.h),
        
        // Apple Button
        _buildSocialButton(
          icon: Icons.apple,
          text: 'Continuar con Apple',
          onPressed: _loading ? () {} : () => _signInWithOAuth(OAuthProvider.apple),
        ),
        
        SizedBox(height: 4.h),
        Text(
          'Al continuar, aceptas recibir llamadas, incluidas las realizadas con marcadores automáticos, mensajes de WhatsApp o SMS de Maximus y sus afiliados.',
          style: TextStyle(color: Colors.black54, fontSize: 9.sp, height: 1.4),
          textAlign: TextAlign.left,
        ),
      ],
    );
  }

  Widget _buildOtpForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 2.h),
        Text(
          'Introduce el código de 6 dígitos que te hemos enviado a ${_emailController.text}',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
            height: 1.2,
          ),
        ),
        SizedBox(height: 1.h),
        GestureDetector(
          onTap: () {
            setState(() {
              _isOtpSent = false;
            });
          },
          child: Text(
            '¿Has cambiado tu número / correo?',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.black,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        SizedBox(height: 4.h),

        // OTP Field
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18.sp, letterSpacing: 8.0),
            maxLength: 6,
            decoration: const InputDecoration(
              counterText: "",
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),

        SizedBox(height: 3.h),

        ElevatedButton(
          onPressed: _loading ? null : _handleAuth,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEEEEEE),
            foregroundColor: Colors.black,
            elevation: 0,
            padding: EdgeInsets.symmetric(vertical: 2.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.0),
            ),
          ),
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                )
              : const Text(
                  'Siguiente',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
