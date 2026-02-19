import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ServiceControlWidget extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const ServiceControlWidget({
    super.key,
    required this.service,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = service['status'] as String;
    final isActive = status == 'active';

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service['name'] as String,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isActive ? Icons.check_circle : Icons.warning,
                                size: 14,
                                color: isActive ? Colors.green : Colors.orange,
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                isActive ? 'Activo' : 'Mantenimiento',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isActive
                                      ? Colors.green
                                      : Colors.orange,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Switch(
                value: isActive,
                onChanged: (value) => onToggle(),
                activeThumbColor: theme.colorScheme.primary,
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn(
                  theme,
                  'Disponibles',
                  '${service['available']}/${service['total']}',
                ),
                Container(
                  width: 1,
                  height: 4.h,
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
                _buildInfoColumn(
                  theme,
                  'Ingresos',
                  service['revenue'] as String,
                ),
                Container(
                  width: 1,
                  height: 4.h,
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
                _buildInfoColumn(
                  theme,
                  'Utilización',
                  '${((service['available'] as int) / (service['total'] as int) * 100).toStringAsFixed(0)}%',
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: Icon(Icons.edit_outlined, size: 18),
                  label: Text('Editar Servicio'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.attach_money, size: 18),
                  label: Text('Ajustar Precio'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(ThemeData theme, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10.sp,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }
}
