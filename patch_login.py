import re

with open("lib/presentation/login_registration_screen/login_registration_screen.dart", "r") as f:
    content = f.read()

# Replace variables
content = content.replace("""  bool _isLogin = true;
  bool _showEmailForm = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();""", """  bool _isLogin = true;
  bool _showEmailForm = false;
  bool _isOtpSent = false;
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();""")

# Replace dispose
content = content.replace("""  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }""", """  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }""")

# Replace _handleAuth and others
old_auth = """  Future<void> _handleAuth() async {
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

  Future<void> _signInWithOAuth(OAuthProvider provider) async {
    setState(() => _loading = true);
    try {
      await SupabaseService.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: 'maximus://login-callback', // Configured scheme for app linkage
      );
      // Note: In typical OAuth flow, Supabase handles the browser redirect and the deep link back to the app,
      // which is then caught by SupabaseFlutter to persist the session and trigger onAuthStateChange.
      // The splash screen or auth listener will then automatically route the user.
    } catch (e) {
      _showMessage('Error con inicio de sesión ${provider.name}: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithPhoneOtp() async {
    final phone = _emailController.text.trim();
    if (phone.isEmpty) {
      _showMessage('Ingresa un número de celular');
      return;
    }
    setState(() => _loading = true);
    try {
      await SupabaseService.instance.client.auth.signInWithOtp(
        phone: phone,
      );
      _showMessage('Código SMS enviado a $phone');
      // Here usually we transition UI to an OTP input screen. For now, showing message.
    } catch (e) {
      _showMessage('Error al enviar SMS: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }"""

new_auth = """  Future<void> _handleAuth() async {
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
          final role = AppRole.fromString(_role);
          if (role.isStaff) {
             await _userService.updateUserProfile(
               userId: response.user!.id,
               updates: {'is_active': false, 'role': _role, 'full_name': 'New User'}
             );
             _showApprovalPendingDialog();
             await SupabaseService.instance.client.auth.signOut();
             return;
          } else {
             await _userService.updateUserProfile(
               userId: response.user!.id,
               updates: {'role': _role, 'full_name': 'New User'}
             );
          }
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
  }"""
content = content.replace(old_auth, new_auth)

with open("lib/presentation/login_registration_screen/login_registration_screen.dart", "w") as f:
    f.write(content)

