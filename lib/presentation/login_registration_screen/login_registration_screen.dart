import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/supabase_service.dart';
import '../../services/user_service.dart';
import '../../services/localization_service.dart';
import '../../core/constants/app_roles.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modern authentication screen with tabbed interface for login and registration
class LoginRegistrationScreen extends StatefulWidget {
  const LoginRegistrationScreen({super.key});

  @override
  State<LoginRegistrationScreen> createState() =>
      _LoginRegistrationScreenState();
}

class _LoginRegistrationScreenState extends State<LoginRegistrationScreen> {
  bool _isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _role = 'client';
  bool _remember = false;
  bool _loading = false;
  final _localization = LocalizationService();
  String _selectedLanguage = 'ES';
  final _storage = const FlutterSecureStorage();
  final _userService = UserService.instance;

  @override
  void initState() {
    super.initState();
    _initializeLanguage();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberMsg = prefs.getBool('remember_me') ?? false;
      
      if (rememberMsg) {
        final email = await _storage.read(key: 'user_email');
        final password = await _storage.read(key: 'user_password');
        
        if (email != null && password != null) {
          setState(() {
            _remember = true;
            _emailController.text = email;
            _passwordController.text = password;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading credentials: $e');
    }
  }

  Future<void> _initializeLanguage() async {
    await _localization.initialize();
    setState(() {
      _selectedLanguage = _localization.currentLanguage;
    });
  }

  Future<void> _changeLanguage(String language) async {
    await _localization.setLanguage(language);
    setState(() {
      _selectedLanguage = language;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_isLogin &&
        _passwordController.text != _confirmPasswordController.text) {
      _showMessage(_localization.translate('passwords_no_match'));
      return;
    }

    setState(() => _loading = true);

    try {
      if (_isLogin) {
        final response = await SupabaseService.instance.client.auth
            .signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (response.user != null && mounted) {
          final prefs = await SharedPreferences.getInstance();
          if (_remember) {
            await prefs.setBool('remember_me', true);
            await _storage.write(key: 'user_email', value: _emailController.text.trim());
            await _storage.write(key: 'user_password', value: _passwordController.text);
          } else {
            await prefs.setBool('remember_me', false);
            await _storage.delete(key: 'user_email');
            await _storage.delete(key: 'user_password');
          }
          await _routeBasedOnRole(response.user!.id);
        }
      } else {
        final response = await SupabaseService.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          data: {
            'role': _role,
            'full_name': 'New User',
          },
        );

        if (response.user != null && mounted) {
          final role = AppRole.fromString(_role);
          if (role.isStaff) {
             await _userService.updateUserProfile(
               userId: response.user!.id,
               updates: {'is_active': false}
             );
             _showApprovalPendingDialog();
             await SupabaseService.instance.client.auth.signOut();
          } else {
             _showMessage(_localization.translate('account_created'));
             await _routeBasedOnRole(response.user!.id);
          }
        }
      }
    } catch (e) {
      _showMessage(e.toString());
    } finally {
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
            child: const Text('Entendido', style: TextStyle(color: Color(0xFFE8B4B8))),
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
      body: Container(
        height: 100.h,
        width: 100.w,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative elements for background depth
            Positioned(
              top: -10.h,
              right: -10.w,
              child: Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -5.h,
              left: -5.w,
              child: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.05),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: 95.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                          blurRadius: 40,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo with subtle reflection
                          Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                                  blurRadius: 25,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20.0),
                              child: Image.asset(
                                'assets/images/Untitled-1770930294814.jpeg',
                                height: 10.h,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          SizedBox(height: 3.h),
                              
                          Text(
                            'MAXIMUS LEVEL GROUP',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFD4AF37),
                              letterSpacing: 2,
                            ),
                          ),
                              SizedBox(height: 4.h),

                      // Language Selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLanguageOption('ES', _selectedLanguage == 'ES'),
                          SizedBox(width: 2.w),
                          _buildLanguageOption('EN', _selectedLanguage == 'EN'),
                        ],
                      ),
                      SizedBox(height: 3.h),

                      // Tabs
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTab(
                                _localization.translate('login_title'),
                                _isLogin,
                                () {
                                  setState(() => _isLogin = true);
                                },
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: _buildTab(
                                _localization.translate('register_title'),
                                !_isLogin,
                                () {
                                  setState(() => _isLogin = false);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 4.h),

                      // Email Field
                      _buildTextField(
                        controller: _emailController,
                        label: _localization.translate('email_label'),
                        icon: '📧',
                        hint: _localization.translate('email_hint'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: 2.h),

                      // Password Field
                      _buildTextField(
                        controller: _passwordController,
                        label: _localization.translate('password_label'),
                        icon: '🔒',
                        hint: _localization.translate('password_hint'),
                        obscureText: true,
                      ),
                      SizedBox(height: 2.h),

                      // Confirm Password (Registration only)
                      if (!_isLogin) ...[
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: _localization.translate(
                            'confirm_password_label',
                          ),
                          icon: '🔒',
                          hint: _localization.translate('password_hint'),
                          obscureText: true,
                        ),
                        SizedBox(height: 2.h),
                      ],

                      // Remember Me / Forgot Password (Login only)
                      if (_isLogin)
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 2.w,
                          runSpacing: 1.h,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _remember,
                                    onChanged: (value) {
                                      setState(() => _remember = value!);
                                    },
                                    activeColor: const Color(0xFFD4AF37),
                                    checkColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  _localization.translate('remember_me'),
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                _localization.translate('forgot_password'),
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: const Color(0xFFD4AF37),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                      // Role Selection (Registration only)
                      if (!_isLogin) ...[
                        Text(
                          _localization.translate('select_role'),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        SizedBox(height: 1.h),
                        _buildRoleOption(
                          _localization.translate('role_client'),
                          _localization.translate('role_client_desc'),
                          'client',
                        ),
                        SizedBox(height: 1.h),
                        _buildRoleOption(
                          _localization.translate('role_admin'),
                          _localization.translate('role_admin_desc'),
                          'admin',
                        ),
                        SizedBox(height: 2.h),
                      ],

                      SizedBox(height: 3.h),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14.0),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _loading ? null : _handleAuth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.symmetric(vertical: 2.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.0),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.black,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'CONTINUAR',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      SizedBox(height: 2.h),

                      // Toggle Text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isLogin
                                ? '¿No tienes cuenta?'
                                : '¿Ya tienes cuenta?',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() => _isLogin = !_isLogin);
                            },
                            child: Text(
                              _isLogin ? 'Crear cuenta' : 'Iniciar sesión',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: const Color(0xFFD4AF37),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Guest WhatsApp Support
                      if (_isLogin) ...[
                        SizedBox(height: 2.h),
                        Divider(color: Colors.white.withValues(alpha: 0.1)),
                        SizedBox(height: 2.h),
                        Text(
                          '¿Necesitas ayuda sin registrarte?',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        SizedBox(height: 1.5.h),
                        GestureDetector(
                          onTap: () async {
                            final url = Uri.parse('https://wa.me/15619930805?text=Hola,%20necesito%20información%20sobre%20los%20servicios%20de%20Maximus%20Level%20Group');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 1.5.h, horizontal: 4.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFF25D366).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                                SizedBox(width: 2.w),
                                Text(
                                  'Soporte por WhatsApp',
                                  style: TextStyle(
                                    color: const Color(0xFF25D366),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildLanguageOption(String language, bool isSelected) {
    return GestureDetector(
      onTap: () {
        _changeLanguage(language);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37).withValues(alpha: 0.3) : Colors.transparent,
          ),
        ),
        child: Text(
          language,
          style: TextStyle(
            fontSize: 10.sp,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.black : Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFD4AF37) : Colors.transparent,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w900,
              color: isActive ? Colors.black : Colors.white.withValues(alpha: 0.5),
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String icon,
    required String hint,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 1.w, bottom: 0.8.h),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            cursorColor: const Color(0xFFE8B4B8),
            style: TextStyle(
              fontSize: 11.sp, 
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 10.sp,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Text(icon, style: TextStyle(fontSize: 14.sp)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: true,
              fillColor: Colors.transparent, // Controlled by parent Container
              contentPadding: EdgeInsets.symmetric(
                horizontal: 4.w,
                vertical: 1.8.h,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleOption(String title, String subtitle, String roleValue) {
    final isSelected = _role == roleValue;
    return GestureDetector(
      onTap: () {
        setState(() => _role = roleValue);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFD4AF37).withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withValues(alpha: 0.2),
                  width: 2,
                ),
                color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 10, color: Colors.black)
                  : null,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 9.sp, 
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
