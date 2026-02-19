import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Role selection widget for choosing between client and administrator
class RoleSelectionWidget extends StatelessWidget {
  final String selectedRole;
  final Function(String) onRoleChanged;

  const RoleSelectionWidget({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seleccione su rol',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.0),
        Row(
          children: [
            Expanded(
              child: _buildRoleOption(
                context: context,
                theme: theme,
                role: 'client',
                label: 'Cliente',
                icon: 'person',
                description: 'Reservar servicios',
              ),
            ),
            SizedBox(width: 8.0),
            Expanded(
              child: _buildRoleOption(
                context: context,
                theme: theme,
                role: 'admin',
                label: 'Administrador',
                icon: 'admin_panel_settings',
                description: 'Gestionar servicios',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleOption({
    required BuildContext context,
    required ThemeData theme,
    required String role,
    required String label,
    required String icon,
    required String description,
  }) {
    final isSelected = selectedRole == role;

    return InkWell(
      onTap: () => onRoleChanged(role),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 32,
            ),
            SizedBox(height: 8.0),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            SizedBox(height: 4.0),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
