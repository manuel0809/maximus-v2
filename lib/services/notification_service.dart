import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_service_stub.dart'
    if (dart.library.io) 'notification_service_io.dart'
    if (dart.library.html) 'notification_service_web.dart';
import './supabase_service.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance =>
      _instance ??= NotificationService._();

  NotificationService._();

  final SupabaseClient _client = SupabaseService.instance.client;
  RealtimeChannel? _notificationSubscription;
  final NotificationPlatform _platform = NotificationPlatform();

  /// Initialize notification service
  Future<void> initialize() async {
    await _platform.initialize();
  }

  /// Subscribe to real-time notifications for current user
  void subscribeToNotifications(Function(Map<String, dynamic>) onNotification) {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return;

    _notificationSubscription = _client
        .channel('notifications_$currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUserId,
          ),
          callback: (payload) {
            final newNotification = payload.newRecord;
            onNotification(newNotification);

            // Show local notification
            _platform.showNotification(
              id: newNotification['id'].hashCode,
              title: newNotification['title'] ?? 'Nueva Notificación',
              body: newNotification['body'] ?? '',
              payload: newNotification['id'],
            );
          },
        )
        .subscribe();
  }

  /// Unsubscribe from notifications
  void unsubscribe() {
    _notificationSubscription?.unsubscribe();
    _notificationSubscription = null;
  }

  /// Get all notifications for current user
  Future<List<Map<String, dynamic>>> getNotifications({
    String? filterType,
    bool? unreadOnly,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('Usuario no autenticado');

      var query = _client
          .from('notifications')
          .select()
          .eq('user_id', currentUserId);

      if (filterType != null && filterType != 'all') {
        query = query.eq('type', filterType);
      }

      if (unreadOnly == true) {
        query = query.eq('is_read', false);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener notificaciones: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final result = await _client.rpc('get_unread_notification_count');
      return result as int;
    } catch (e) {
      return 0;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client.rpc(
        'mark_notification_read',
        params: {'notification_id': notificationId},
      );
    } catch (e) {
      throw Exception('Error al marcar notificación como leída: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) return;

      await _client
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', currentUserId)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Error al marcar todas como leídas: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _client.from('notifications').delete().eq('id', notificationId);
    } catch (e) {
      throw Exception('Error al eliminar notificación: $e');
    }
  }

  /// Get notification preferences
  Future<Map<String, dynamic>?> getPreferences() async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('Usuario no autenticado');

      final response = await _client
          .from('notification_preferences')
          .select()
          .eq('user_id', currentUserId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Error al obtener preferencias: $e');
    }
  }

  /// Update notification preferences
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('Usuario no autenticado');

      await _client
          .from('notification_preferences')
          .update(preferences)
          .eq('user_id', currentUserId);
    } catch (e) {
      throw Exception('Error al actualizar preferencias: $e');
    }
  }

  /// Create a notification for a rental reminder (24h before)
  Future<void> createRentalReminder({
    required String rentalId,
    required String vehicleName,
    required bool isReturn,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) return;

      final title = isReturn ? 'Recordatorio de Devolución' : 'Recordatorio de Entrega';
      final body = isReturn 
          ? 'Tu renta del $vehicleName termina en 24 horas. Por favor prepárate para la entrega.'
          : 'Tu aventura con el $vehicleName comienza en 24 horas. ¡Estamos listos!';

      await _client.from('notifications').insert({
        'user_id': currentUserId,
        'type': 'rental_update',
        'priority': 'high',
        'title': title,
        'body': body,
        'data': {'rental_id': rentalId, 'is_return': isReturn},
      });
    } catch (e) {
      throw Exception('Error al crear recordatorio: $e');
    }
  }

  /// Create a notification for a traffic fine
  Future<void> createFineAlert({
    required String vehicleName,
    required double amount,
    required String reason,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) return;

      await _client.from('notifications').insert({
        'user_id': currentUserId,
        'type': 'alert',
        'priority': 'critical',
        'title': 'Nueva Multa Registrada',
        'body': 'Se ha reportado una multa por \$$amount para el $vehicleName ($reason).',
        'data': {'amount': amount, 'reason': reason},
      });
    } catch (e) {
      throw Exception('Error al crear alerta de multa: $e');
    }
  }

  /// Create a notification for document verification status
  Future<void> createVerificationUpdate(String status) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) return;

      final isApproved = status.toLowerCase() == 'approved';
      final title = isApproved ? 'Documentos Verificados' : 'Revisión de Documentos';
      final body = isApproved 
          ? '¡Felicidades! Tus documentos han sido aprobados. Ya puedes rentar autos.'
          : 'Tus documentos requieren attention. Por favor revisa tu perfil.';

      await _client.from('notifications').insert({
        'user_id': currentUserId,
        'type': 'verification_update',
        'priority': 'medium',
        'title': title,
        'body': body,
      });
    } catch (e) {
      throw Exception('Error al crear actualización de verificación: $e');
    }
  }

  /// Create a notification for deposit return
  Future<void> createDepositReturnConfirmation(double amount) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) return;

      await _client.from('notifications').insert({
        'user_id': currentUserId,
        'type': 'payment_update',
        'priority': 'medium',
        'title': 'Depósito Devuelto',
        'body': 'Tu depósito de \$$amount ha sido liberado correctamente.',
        'data': {'amount': amount},
      });
    } catch (e) {
      throw Exception('Error al crear confirmación de depósito: $e');
    }
  }

  /// Create a test notification (for testing purposes)
  Future<void> createTestNotification() async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('Usuario no autenticado');

      await _client.from('notifications').insert({
        'user_id': currentUserId,
        'type': 'promotion',
        'priority': 'low',
        'title': 'Notificación de Prueba',
        'body': 'Esta es una notificación de prueba del sistema.',
        'data': {'test': true},
      });
    } catch (e) {
      throw Exception('Error al crear notificación de prueba: $e');
    }
  }
}
