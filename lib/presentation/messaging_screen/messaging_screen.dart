import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/messaging_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/message_bubble_widget.dart';
import './widgets/message_input_widget.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final MessagingService _messagingService = MessagingService.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _otherUser;
  String? _otherUserId;
  String? _driverPhoneNumber;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  @override
  void dispose() {
    _messagingService.unsubscribeFromMessages();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args == null) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _otherUserId = args['userId'] as String?;
      _otherUser = args['user'] as Map<String, dynamic>?;
    });

    if (_otherUserId == null) {
      Navigator.pop(context);
      return;
    }

    await _loadMessages();
    _subscribeToMessages();

    // Get driver phone number if other user is a driver
    if (_otherUser?['role'] == 'driver') {
      final phone = await _messagingService.getDriverPhoneNumber(_otherUserId!);
      setState(() => _driverPhoneNumber = phone);
    }
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _messagingService.getMessages(_otherUserId!);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      _scrollToBottom();
      await _messagingService.markMessagesAsRead(_otherUserId!);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar mensajes: $e')));
      }
    }
  }

  void _subscribeToMessages() {
    _messagingService.subscribeToMessages(_otherUserId!, (newMessage) {
      setState(() {
        _messages.add(newMessage);
      });
      _scrollToBottom();
      _messagingService.markMessagesAsRead(_otherUserId!);
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final message = await _messagingService.sendMessage(
        receiverId: _otherUserId!,
        content: content,
      );

      if (message != null) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al enviar mensaje: $e')));
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _handleCallDriver() async {
    if (_driverPhoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Número de teléfono no disponible')),
      );
      return;
    }

    final uri = Uri.parse('tel:$_driverPhoneNumber');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se puede realizar la llamada')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al llamar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: _otherUser?['full_name'] ?? 'Chat',
        actions: [
          if (_driverPhoneNumber != null)
            IconButton(
              icon: const Icon(Icons.phone),
              onPressed: _handleCallDriver,
              tooltip: 'Llamar',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? Center(
                    child: Text(
                      'No hay mensajes aún\nEnvía el primer mensaje',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(2.w),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return MessageBubbleWidget(message: _messages[index]);
                    },
                  ),
          ),
          MessageInputWidget(
            controller: _messageController,
            onSend: _sendMessage,
            isSending: _isSending,
          ),
        ],
      ),
    );
  }
}
