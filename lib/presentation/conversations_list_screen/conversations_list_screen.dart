import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../services/messaging_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';

class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  final MessagingService _messagingService = MessagingService.instance;
  final _client = SupabaseService.instance.client;
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final conversations = await _messagingService.getConversations();
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar conversaciones: $e')),
        );
      }
    }
  }

  void _openConversation(Map<String, dynamic> conversation) {
    final currentUserId = _client.auth.currentUser?.id;
    final isClient = conversation['client_id'] == currentUserId;
    final otherUser = isClient
        ? conversation['driver']
        : conversation['client'];
    final otherUserId = isClient
        ? conversation['driver_id']
        : conversation['client_id'];

    Navigator.pushNamed(
      context,
      '/messaging-screen',
      arguments: {'userId': otherUserId, 'user': otherUser},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Mensajes'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'No hay conversaciones',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadConversations,
              child: ListView.separated(
                padding: EdgeInsets.all(2.w),
                itemCount: _conversations.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
                itemBuilder: (context, index) {
                  final conversation = _conversations[index];
                  final currentUserId = _client.auth.currentUser?.id;
                  final isClient = conversation['client_id'] == currentUserId;
                  final otherUser = isClient
                      ? conversation['driver']
                      : conversation['client'];
                  final lastMessageTime = DateTime.parse(
                    conversation['last_message_at'] as String,
                  );
                  final timeString = DateFormat(
                    'dd/MM/yy HH:mm',
                  ).format(lastMessageTime);

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 28,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      otherUser['full_name'] as String,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      otherUser['role'] == 'driver' ? 'Conductor' : 'Cliente',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: Text(
                      timeString,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: () => _openConversation(conversation),
                  );
                },
              ),
            ),
    );
  }
}
