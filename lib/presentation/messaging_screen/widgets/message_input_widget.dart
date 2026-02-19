import 'package:flutter/material.dart';

class MessageInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;

  const MessageInputWidget({
    super.key,
    required this.controller,
    required this.onSend,
    required this.isSending,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2 * 8.0, vertical: 1 * 8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje...',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4 * 8.0,
                    vertical: 1.5 * 8.0,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                enabled: !isSending,
              ),
            ),
            SizedBox(width: 2 * 8.0),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.send),
                color: Colors.white,
                onPressed: isSending ? null : onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
