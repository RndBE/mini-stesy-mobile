import 'package:flutter/material.dart';
import '../models/chatbot_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatbotMessage message;

  const ChatBubble({super.key, required this.message});

  bool get _isUser => message.role == 'user';

  @override
  Widget build(BuildContext context) {
    const botColor = Color(0xFF2B3377);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            _isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar bot
          if (!_isUser) ...[
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: botColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: botColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _isUser ? botColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(_isUser ? 18 : 4),
                  bottomRight: Radius.circular(_isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isUser
                        ? botColor.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: _isUser
                    ? null
                    : Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: SelectableText(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: _isUser ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ),
          ),

          if (_isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
