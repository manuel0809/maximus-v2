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
      backgroundColor: Colors.black, // Pure black background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/images/Untitled-1770930294814.jpeg',
                      height: 8.h,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // Brand Text
                  const Center(
                    child: Text(
                      'MAXIMUS',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),

                  // Language Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLanguageOption('ES', _selectedLanguage == 'ES'),
                      const SizedBox(width: 8),
                      _buildLanguageOption('EN', _selectedLanguage == 'EN'),
                    ],
                  ),
                  SizedBox(height: 4.h),

                  // Title
                  Text(
                    _isLogin
                        ? _localization.translate('login_title')
                        : _localization.translate('register_title'),
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      Text(
                        _isLogin
                            ? '¿No tienes cuenta? '
                            : '¿Ya tienes cuenta? ',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => _isLogin = !_isLogin);
                        },
                        child: Text(
                          _isLogin ? 'Crear cuenta' : 'Iniciar sesión',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: const Color(0xFFD4AF37), // Gold accent
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),

                  // Email Field
                  _buildTextField(
                    controller: _emailController,
                    hint: _localization.translate('email_hint'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 2.h),

                  // Password Field
                  _buildTextField(
                    controller: _passwordController,
                    hint: _localization.translate('password_hint'),
                    obscureText: true,
                  ),
                  SizedBox(height: 2.h),

                  // Confirm Password (Registration only)
                  if (!_isLogin) ...[
                    _buildTextField(
                      controller: _confirmPasswordController,
                      hint: _localization.translate('confirm_password_label'), 
                      obscureText: true,
                    ),
                    SizedBox(height: 2.h),
                  ],

                  // Remember Me / Forgot Password (Login only)
                  if (_isLogin)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                activeColor: Colors.white,
                                checkColor: Colors.black,
                                side: const BorderSide(color: Colors.white54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
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
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Role Selection (Registration only)
                  if (!_isLogin) ...[
                    SizedBox(height: 1.h),
                    Text(
                      _localization.translate('select_role'),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    _buildRoleOption(
                      _localization.translate('role_client'),
                      'client',
                    ),
                    SizedBox(height: 1.h),
                    _buildRoleOption(
                      _localization.translate('role_admin'),
                      'admin',
                    ),
                  ],

                  SizedBox(height: 4.h),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _loading ? null : _handleAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // Classic Uber/Maximus contrast
                      padding: EdgeInsets.symmetric(vertical: 2.h),
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.black,
                              ),
                            ),
                          )
                        : Text(
                            _isLogin ? 'Iniciar sesión' : 'Registrarse',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                  ),

                  // Guest WhatsApp Support
                  if (_isLogin) ...[
                    SizedBox(height: 4.h),
                    Divider(color: Colors.white.withValues(alpha: 0.1)),
                    SizedBox(height: 3.h),
                    Text(
                      '¿Necesitas ayuda sin registrarte?',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
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
                          color: const Color(0xFF1E1E1E), // Dark grey
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chat, color: Color(0xFFD4AF37), size: 20),
                            SizedBox(width: 2.w),
                            Text(
                              'Soporte por WhatsApp',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildLanguageOption(String language, bool isSelected) {
    return GestureDetector(
      onTap: () {
        _changeLanguage(language);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          language,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.black : Colors.white54,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark grey, minimalist
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        cursorColor: Colors.white,
        style: TextStyle(
          fontSize: 12.sp, 
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 11.sp,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        ),
      ),
    );
  }

  Widget _buildRoleOption(String title, String roleValue) {
    final isSelected = _role == roleValue;
    return GestureDetector(
      onTap: () {
        setState(() => _role = roleValue);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.black : Colors.white70,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, size: 18, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
