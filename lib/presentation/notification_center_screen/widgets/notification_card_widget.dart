import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

class NotificationCardWidget extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onMarkAsRead;

  const NotificationCardWidget({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
    required this.onMarkAsRead,
  });

  Color _getTypeColor(String type) {
    switch (type) {
      case 'booking_status':
        return Colors.blue;
      case 'driver_assigned':
        return Colors.green;
      case 'trip_completed':
        return Colors.amber;
      case 'promotion':
        return const Color(0xFF8B1538);
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'booking_status':
        return Icons.event_note;
      case 'driver_assigned':
        return Icons.person_pin_circle;
      case 'trip_completed':
        return Icons.check_circle;
      case 'promotion':
        return Icons.local_offer;
      default:
        return Icons.notifications;
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
        return '';
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Ahora';
      } else if (difference.inMinutes < 60) {
        return 'Hace ${difference.inMinutes} min';
      } else if (difference.inHours < 24) {
        return 'Hace ${difference.inHours} h';
      } else if (difference.inDays < 7) {
        return 'Hace ${difference.inDays} días';
      } else {
        return DateFormat('dd MMM yyyy', 'es').format(dateTime);
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final type = notification['type'] ?? 'booking_status';
    final priority = notification['priority'] ?? 'medium';
    final isRead = notification['is_read'] ?? false;
    final typeColor = _getTypeColor(type);

    return Dismissible(
      key: Key(notification['id']),
      background: Container(
        margin: EdgeInsets.only(bottom: 1.5.h),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12.0),
        ),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: const Icon(Icons.check, color: Colors.white, size: 28),
      ),
      secondaryBackground: Container(
        margin: EdgeInsets.only(bottom: 1.5.h),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12.0),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onMarkAsRead();
          return false;
        } else {
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Eliminar Notificación'),
              content: const Text(
                '¿Está seguro de que desea eliminar esta notificación?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Eliminar',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete();
        }
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          margin: EdgeInsets.only(bottom: 1.5.h),
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: isRead
                ? colorScheme.surface
                : typeColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isRead
                  ? colorScheme.outline.withValues(alpha: 0.2)
                  : typeColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Icon(_getTypeIcon(type), color: typeColor, size: 24),
              ),
              SizedBox(width: 3.w),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'] ?? '',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (priority == 'urgent' || priority == 'high')
                          Container(
                            margin: EdgeInsets.only(left: 2.w),
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.3.h,
                            ),
                            decoration: BoxDecoration(
                              color: priority == 'urgent'
                                  ? Colors.red
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              _getPriorityLabel(priority),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      notification['body'] ?? '',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          _formatTimestamp(notification['created_at']),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        if (!isRead) ...[
                          SizedBox(width: 2.w),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: typeColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
