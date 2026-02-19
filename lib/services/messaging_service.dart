import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class MessagingService {
  static MessagingService? _instance;
  static MessagingService get instance => _instance ??= MessagingService._();

  MessagingService._();

  final SupabaseClient _client = SupabaseService.instance.client;
  RealtimeChannel? _messageSubscription;

  /// Send a message from sender to receiver
  Future<Map<String, dynamic>?> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    try {
      final senderId = _client.auth.currentUser?.id;
      if (senderId == null) throw Exception('Usuario no autenticado');

      final response = await _client
          .from('messages')
          .insert({
            'sender_id': senderId,
            'receiver_id': receiverId,
            'content': content,
            'status': 'sent',
          })
          .select()
          .single();

      // Update conversation last_message_at
      await _updateConversation(senderId, receiverId);

      return response;
    } catch (e) {
      throw Exception('Error al enviar mensaje: $e');
    }
  }

  /// Get messages between current user and another user
  Future<List<Map<String, dynamic>>> getMessages(String otherUserId) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('Usuario no autenticado');

      final response = await _client
          .from('messages')
          .select(
            '*, sender:sender_id(full_name, avatar_url), receiver:receiver_id(full_name, avatar_url)',
          )
          .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .or('sender_id.eq.$otherUserId,receiver_id.eq.$otherUserId')
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener mensajes: $e');
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String senderId) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) return;

      await _client
          .from('messages')
          .update({
            'status': 'read',
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('sender_id', senderId)
          .eq('receiver_id', currentUserId)
          .neq('status', 'read');
    } catch (e) {
      // Silent fail
    }
  }

  /// Get all conversations for current user
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('Usuario no autenticado');

      final response = await _client
          .from('conversations')
          .select(
            '*, client:client_id(full_name, avatar_url, role), driver:driver_id(full_name, avatar_url, role)',
          )
          .or('client_id.eq.$currentUserId,driver_id.eq.$currentUserId')
          .order('last_message_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error al obtener conversaciones: $e');
    }
  }

  /// Subscribe to real-time messages for a specific conversation
  void subscribeToMessages(
    String otherUserId,
    Function(Map<String, dynamic>) onMessage,
  ) {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return;

    _messageSubscription = _client
        .channel('messages_$currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: currentUserId,
          ),
          callback: (payload) {
            final newMessage = payload.newRecord;
            if (newMessage['sender_id'] == otherUserId) {
              onMessage(newMessage);
            }
          },
        )
        .subscribe();
  }

  /// Unsubscribe from real-time messages
  void unsubscribeFromMessages() {
    _messageSubscription?.unsubscribe();
    _messageSubscription = null;
  }

  /// Get driver phone number from database
  Future<String?> getDriverPhoneNumber(String driverId) async {
    try {
      final response = await _client
          .from('driver_contacts')
          .select('phone_number')
          .eq('driver_id', driverId)
          .eq('is_active', true)
          .maybeSingle();

      return response?['phone_number'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Update conversation last_message_at timestamp
  Future<void> _updateConversation(String userId1, String userId2) async {
    try {
      // Try to update existing conversation
      final existing = await _client
          .from('conversations')
          .select('id')
          .or('client_id.eq.$userId1,driver_id.eq.$userId1')
          .or('client_id.eq.$userId2,driver_id.eq.$userId2')
          .maybeSingle();

      if (existing != null) {
        await _client
            .from('conversations')
            .update({'last_message_at': DateTime.now().toIso8601String()})
            .eq('id', existing['id']);
      } else {
        // Create new conversation
        await _client.from('conversations').insert({
          'client_id': userId1,
          'driver_id': userId2,
          'last_message_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      // Silent fail
    }
  }
}
