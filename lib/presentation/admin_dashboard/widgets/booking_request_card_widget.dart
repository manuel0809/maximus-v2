import 'package:flutter/material.dart';
import '../../../widgets/premium_card.dart';

class BookingRequestCardWidget extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onApprove;
  final VoidCallback onModify;
  final VoidCallback onReject;
  final VoidCallback? onChecklistPickup;
  final VoidCallback? onChecklistReturn;

  const BookingRequestCardWidget({
    super.key,
    required this.booking,
    required this.onApprove,
    required this.onModify,
    required this.onReject,
    this.onChecklistPickup,
    this.onChecklistReturn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = booking['status'] as String;
    final priority = booking['priority'] as String;

    return PremiumCard(
      padding: const EdgeInsets.all(16.0),
      borderRadius: 16,
      useGlassmorphism: true,
      opacity: 0.05,
      border: Border.all(
        color: _getPriorityColor(priority).withValues(alpha: 0.2),
        width: 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['id'] as String,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      booking['clientName'] as String,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildPriorityBadge(theme, priority),
                  const SizedBox(height: 8.0),
                  _buildStatusBadge(theme, status),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  theme,
                  Icons.category_outlined,
                  'Servicio',
                  booking['service'] as String,
                ),
                const SizedBox(height: 10.0),
                _buildInfoRow(
                  theme,
                  Icons.directions_car_outlined,
                  'Vehículo',
                  booking['vehicle'] as String,
                ),
                const SizedBox(height: 10.0),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        theme,
                        Icons.calendar_today_outlined,
                        'Fecha',
                        booking['date'] as String,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: _buildInfoRow(
                        theme,
                        Icons.access_time_outlined,
                        'Hora',
                        booking['time'] as String,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                _buildInfoRow(
                  theme,
                  Icons.attach_money,
                  'Monto',
                  booking['amount'] as String,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
          // Action Buttons
          if (onChecklistPickup != null || onChecklistReturn != null) ...[
            Row(
              children: [
                if (onChecklistPickup != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: _buildActionButton(
                        onPressed: onChecklistPickup!,
                        icon: Icons.qr_code_scanner,
                        label: 'Checklist Entrega',
                        color: Colors.blue,
                      ),
                    ),
                  ),
                if (onChecklistReturn != null)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: _buildActionButton(
                        onPressed: onChecklistReturn!,
                        icon: Icons.assignment_return,
                        label: 'Checklist Devolución',
                        color: Colors.purple,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12.0),
          ],
          Row(
            children: [
              Expanded(
                child: _buildOutlinedButton(
                  onPressed: onReject,
                  icon: Icons.close,
                  label: 'Rechazar',
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: _buildOutlinedButton(
                  onPressed: onModify,
                  icon: Icons.edit_outlined,
                  label: 'Modificar',
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: _buildElevatedButton(
                  onPressed: onApprove,
                  icon: Icons.check,
                  label: 'Aprobar',
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10.0,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 12.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityBadge(ThemeData theme, String priority) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: _getPriorityColor(priority).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        _getPriorityLabel(priority),
        style: theme.textTheme.bodySmall?.copyWith(
          color: _getPriorityColor(priority),
          fontWeight: FontWeight.w600,
          fontSize: 10.0,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        _getStatusLabel(status),
        style: theme.textTheme.bodySmall?.copyWith(
          color: _getStatusColor(status),
          fontWeight: FontWeight.w600,
          fontSize: 10.0,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildOutlinedButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildElevatedButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return const Color(0xFFC62828);
      case 'high':
        return const Color(0xFFEF6C00);
      case 'medium':
        return const Color(0xFF1565C0);
      case 'low':
        return Colors.blueGrey;
      default:
        return Colors.blueGrey;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'urgent':
        return 'URGENTE';
      case 'high':
        return 'ALTA';
      case 'medium':
        return 'MEDIA';
      case 'low':
        return 'BAJA';
      default:
        return priority.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF57C00);
      case 'confirmed':
        return const Color(0xFF2E7D32);
      case 'in-progress':
        return const Color(0xFF1976D2);
      case 'completed':
        return Colors.blueGrey;
      default:
        return Colors.blueGrey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'confirmed':
        return 'Confirmado';
      case 'in-progress':
        return 'En Progreso';
      case 'completed':
        return 'Completado';
      default:
        return status;
    }
  }
}
