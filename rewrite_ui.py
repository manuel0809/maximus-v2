import sys

file_path = "lib/presentation/login_registration_screen/login_registration_screen.dart"

with open(file_path, "r") as f:
    content = f.read()

# We need to replace everything from `  @override\n  Widget build(BuildContext context) {` to the end of the file.
build_start = content.find("  @override\n  Widget build(BuildContext context) {")

if build_start == -1:
    print("Could not find build method")
    sys.exit(1)

new_ui = """  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'MAXIMUS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
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
        
        SizedBox(height: 1.5.h),
        
        // QR Button (Placeholder)
        _buildSocialButton(
          icon: Icons.qr_code_scanner,
          text: 'Inicia sesión con el código QR',
          onPressed: () {
            _showMessage('Próximamente');
          },
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
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            onPressed: () {
              setState(() {
                _isOtpSent = false;
              });
            },
          ),
        ),
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

        // OTP Field (Simple text field for now, styled like Uber)
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
"""

content = content[:build_start] + new_ui

with open(file_path, "w") as f:
    f.write(content)
