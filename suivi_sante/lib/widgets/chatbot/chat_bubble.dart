// lib/widgets/chatbot/chat_bubble.dart

import 'package:flutter/material.dart';
import 'package:suivi_sante_pro/models/chatbot/message.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isPreviousSameUser;

  const ChatBubble({
    super.key,
    required this.message,
    this.isPreviousSameUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = message.type == MessageType.user;

    final bubbleColor = isUser
        ? (isDark ? const Color(0xFF8B83FF) : const Color(0xFF6C63FF))
        : (isDark ? const Color(0xFF2A2A3E) : Colors.white);

    final textColor = isUser
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF1A1A2E));

    final maxWidth = MediaQuery.of(context).size.width * 0.75;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          top: isPreviousSameUser ? 2 : 8,
          bottom: 2,
          left: isUser ? 48 : 12,
          right: isUser ? 12 : 48,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14.5,
                  height: 1.4,
                ),
              ),
            ),
            if (!isPreviousSameUser)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                child: Text(
                  '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? Colors.grey.shade500
                        : Colors.grey.shade500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}