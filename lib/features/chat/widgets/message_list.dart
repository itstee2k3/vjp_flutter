import 'package:flutter/material.dart';
import '../../../data/models/message.dart';
import 'image_message_bubble.dart';
import 'text_message_bubble.dart';

class MessageList extends StatelessWidget {
  final List<Message> messages;
  final String currentUserId;
  final ScrollController scrollController;
  final VoidCallback? onRetryImage;

  const MessageList({
    Key? key,
    required this.messages,
    required this.currentUserId,
    required this.scrollController,
    this.onRetryImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == currentUserId;

        if (message.type == MessageType.image) {
          return ImageMessageBubble(
            message: message,
            isMe: isMe,
            onRetry: onRetryImage,
          );
        }

        return TextMessageBubble(
          message: message,
          isMe: isMe,
        );
      },
    );
  }
}