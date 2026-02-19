import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class GuestInfoFormWidget extends StatelessWidget {
  final String guestName;
  final String guestEmail;
  final String guestPhone;
  final Function(String) onNameChanged;
  final Function(String) onEmailChanged;
  final Function(String) onPhoneChanged;

  const GuestInfoFormWidget({
    super.key,
    required this.guestName,
    required this.guestEmail,
    required this.guestPhone,
    required this.onNameChanged,
    required this.onEmailChanged,
    required this.onPhoneChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: theme.colorScheme.primary,
                size: 24.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'Información del Invitado',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Privacy Notice
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 18.sp,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'Tus datos solo se usarán para esta reserva y se almacenarán temporalmente.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),

          // Name Field
          Text(
            'Nombre Completo *',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          TextField(
            onChanged: onNameChanged,
            decoration: InputDecoration(
              hintText: 'Ej: Juan Pérez',
              prefixIcon: Icon(Icons.person, color: theme.colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // Email Field
          Text(
            'Correo Electrónico *',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          TextField(
            onChanged: onEmailChanged,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Ej: juan@ejemplo.com',
              prefixIcon: Icon(Icons.email, color: theme.colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // Phone Field
          Text(
            'Teléfono *',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          TextField(
            onChanged: onPhoneChanged,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Ej: +1 234 567 8900',
              prefixIcon: Icon(Icons.phone, color: theme.colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
