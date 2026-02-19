import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/guest_booking_service.dart';

class GuestRegistrationPromptScreen extends StatefulWidget {
  const GuestRegistrationPromptScreen({super.key});

  @override
  State<GuestRegistrationPromptScreen> createState() =>
      _GuestRegistrationPromptScreenState();
}

class _GuestRegistrationPromptScreenState
    extends State<GuestRegistrationPromptScreen> {
  bool isCreatingAccount = false;
  bool showRegistrationForm = false;

  // Registration form fields
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final bookingReference = args?['bookingReference'] as String? ?? '';
    final guestName = args?['guestName'] as String? ?? '';
    final guestEmail = args?['guestEmail'] as String? ?? '';
    final guestPhone = args?['guestPhone'] as String? ?? '';
    final estimatedPrice = args?['estimatedPrice'] as double? ?? 0.0;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 3.h),

                // Success Checkmark
                Container(
                  width: 20.w,
                  height: 20.w,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 12.w,
                  ),
                ),
                SizedBox(height: 2.h),

                // Success Message
                Text(
                  '¡Reserva Confirmada!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 1.h),

                // Booking Reference
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Referencia de Reserva',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        bookingReference,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSecondaryContainer,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 1.h),

                Text(
                  'Total: USD \$${estimatedPrice.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                SizedBox(height: 3.h),

                if (!showRegistrationForm) ...[
                  // Registration Benefits Section
                  Text(
                    '¿Quieres mejorar tu experiencia?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Crea una cuenta y obtén estos beneficios:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 3.h),

                  // Benefits Cards
                  RegistrationBenefitCardWidget(
                    icon: Icons.history,
                    title: 'Historial de Reservas',
                    description:
                        'Accede a todas tus reservas anteriores en cualquier momento',
                  ),
                  SizedBox(height: 2.h),
                  RegistrationBenefitCardWidget(
                    icon: Icons.flash_on,
                    title: 'Reservas Más Rápidas',
                    description:
                        'Información guardada para reservar en segundos',
                  ),
                  SizedBox(height: 2.h),
                  RegistrationBenefitCardWidget(
                    icon: Icons.discount,
                    title: 'Descuentos Exclusivos',
                    description:
                        'Ofertas especiales solo para miembros registrados',
                  ),
                  SizedBox(height: 2.h),
                  RegistrationBenefitCardWidget(
                    icon: Icons.support_agent,
                    title: 'Soporte Prioritario',
                    description: 'Atención al cliente preferencial 24/7',
                  ),
                  SizedBox(height: 2.h),
                  RegistrationBenefitCardWidget(
                    icon: Icons.stars,
                    title: 'Programa de Lealtad',
                    description: 'Acumula puntos y obtén viajes gratis',
                  ),
                  SizedBox(height: 3.h),

                  // Create Account Button
                  ElevatedButton(
                    onPressed: () {
                      setState(() => showRegistrationForm = true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      minimumSize: Size(double.infinity, 6.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(
                      'Crear Cuenta',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 2.h),

                  // Continue as Guest Button
                  TextButton(
                    onPressed: _continueAsGuest,
                    child: Text(
                      'Continuar como Invitado',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ] else ...[
                  // Registration Form
                  _buildRegistrationForm(
                    context,
                    guestName,
                    guestEmail,
                    guestPhone,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationForm(
    BuildContext context,
    String guestName,
    String guestEmail,
    String guestPhone,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Crear Tu Cuenta',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 2.h),

        // Pre-filled Information
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 18.sp,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 2.w),
                  Text(guestName, style: theme.textTheme.bodyMedium),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  Icon(
                    Icons.email,
                    size: 18.sp,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 2.w),
                  Text(guestEmail, style: theme.textTheme.bodyMedium),
                ],
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  Icon(
                    Icons.phone,
                    size: 18.sp,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 2.w),
                  Text(guestPhone, style: theme.textTheme.bodyMedium),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 2.h),

        // Password Field
        Text(
          'Contraseña',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        TextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          decoration: InputDecoration(
            hintText: 'Mínimo 8 caracteres',
            prefixIcon: Icon(Icons.lock, color: theme.colorScheme.primary),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                setState(() => _isPasswordVisible = !_isPasswordVisible);
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        SizedBox(height: 2.h),

        // Confirm Password Field
        Text(
          'Confirmar Contraseña',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        TextField(
          controller: _confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible,
          decoration: InputDecoration(
            hintText: 'Repite tu contraseña',
            prefixIcon: Icon(Icons.lock, color: theme.colorScheme.primary),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible
                    ? Icons.visibility
                    : Icons.visibility_off,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: () {
                setState(
                  () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
                );
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
        SizedBox(height: 2.h),

        // Terms Checkbox
        Row(
          children: [
            Checkbox(
              value: _acceptTerms,
              onChanged: (value) {
                setState(() => _acceptTerms = value ?? false);
              },
            ),
            Expanded(
              child: Text(
                'Acepto los términos y condiciones',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),

        // Create Account Button
        ElevatedButton(
          onPressed: isCreatingAccount ? null : _handleCreateAccount,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            minimumSize: Size(double.infinity, 6.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          child: isCreatingAccount
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.onPrimary,
                    ),
                  ),
                )
              : Text(
                  'Crear Cuenta y Vincular Reserva',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        SizedBox(height: 2.h),

        // Back Button
        TextButton(
          onPressed: () {
            setState(() => showRegistrationForm = false);
          },
          child: Text(
            'Volver',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleCreateAccount() async {
    // Validate password
    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('La contraseña debe tener al menos 8 caracteres'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Las contraseñas no coinciden'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debes aceptar los términos y condiciones'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => isCreatingAccount = true);

    // Mock account creation - in production, use real Supabase auth
    await Future.delayed(const Duration(seconds: 2));

    // Clear guest session
    await GuestBookingService.instance.clearGuestSession();

    setState(() => isCreatingAccount = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '¡Cuenta creada exitosamente! Tu reserva ha sido vinculada.',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      // Navigate to client dashboard
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushReplacementNamed('/client-dashboard');
    }
  }

  void _continueAsGuest() async {
    // Clear guest session
    await GuestBookingService.instance.clearGuestSession();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reserva guardada. Recibirás un correo con los detalles.',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      // Navigate to login screen
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushReplacementNamed('/login-registration-screen');
    }
  }
}

// Add this widget class
class RegistrationBenefitCardWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const RegistrationBenefitCardWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 24),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
