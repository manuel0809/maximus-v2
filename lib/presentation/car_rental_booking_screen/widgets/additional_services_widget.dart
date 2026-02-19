import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class AdditionalServicesWidget extends StatelessWidget {
  final Map<String, bool> services;
  final Function(String, bool) onServiceChanged;

  const AdditionalServicesWidget({
    super.key,
    required this.services,
    required this.onServiceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final List<Map<String, dynamic>> servicesList = [
      {
        'key': 'gps',
        'title': 'GPS Navegación',
        'description': 'Sistema de navegación GPS',
        'price': 10.00,
        'icon': 'navigation',
      },
      {
        'key': 'childSeat',
        'title': 'Asiento para Niños',
        'description': 'Asiento de seguridad infantil',
        'price': 8.00,
        'icon': 'child_care',
      },
      {
        'key': 'additionalDriver',
        'title': 'Conductor Adicional',
        'description': 'Añadir conductor extra',
        'price': 15.00,
        'icon': 'person_add',
      },
      {
        'key': 'premiumInsurance',
        'title': 'Seguro Premium',
        'description': 'Cobertura completa sin franquicia',
        'price': 25.00,
        'icon': 'verified_user',
      },
    ];

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
        children: servicesList.map((service) {
          return _buildServiceItem(
            context,
            service['key'] as String,
            service['title'] as String,
            service['description'] as String,
            service['price'] as double,
            service['icon'] as String,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildServiceItem(
    BuildContext context,
    String key,
    String title,
    String description,
    double price,
    String icon,
  ) {
    final theme = Theme.of(context);
    final isSelected = services[key] ?? false;

    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: GestureDetector(
        onTap: () => onServiceChanged(key, !isSelected),
        child: Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: CustomIconWidget(
                  iconName: icon,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 24,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 0.3.h),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'por día',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              SizedBox(width: 2.w),
              Checkbox(
                value: isSelected,
                onChanged: (value) => onServiceChanged(key, value ?? false),
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
