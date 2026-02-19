import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class MessageBubbleWidget extends StatelessWidget {
  final Map<String, dynamic> message;

  const MessageBubbleWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isMe = message['sender_id'] == currentUserId;
    final timestamp = DateTime.parse(message['created_at'] as String);
    final timeString = DateFormat('HH:mm').format(timestamp);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.person,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(width: 2.w),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: isMe
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16.0),
                  topRight: const Radius.circular(16.0),
                  bottomLeft: Radius.circular(isMe ? 16.0 : 4.0),
                  bottomRight: Radius.circular(isMe ? 4.0 : 16.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['content'] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isMe ? Colors.white : theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeString,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.7)
                              : theme.colorScheme.onSurfaceVariant,
                          fontSize: 10.sp,
                        ),
                      ),
                      if (isMe) ...[
                        SizedBox(width: 1.w),
                        Icon(
                          message['status'] == 'read'
                              ? Icons.done_all
                              : Icons.done,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            SizedBox(width: 2.w),
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.person,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
