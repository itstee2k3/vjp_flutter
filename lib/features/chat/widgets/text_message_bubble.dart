import 'package:flutter/material.dart';
import '../../../data/models/message.dart';
import '../../../core/config/api_config.dart';
import 'message_list.dart';
import 'message_time.dart';

class TextMessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final BubblePosition bubblePosition;
  final bool showSenderInfo;
  final Map<String, dynamic>? senderInfo; // Thông tin người gửi (fullName, avatarUrl)

  const TextMessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.bubblePosition,
    this.showSenderInfo = false, // Mặc định không hiển thị thông tin người gửi
    this.senderInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Radius messageRadius = Radius.circular(16);
    const Radius sharpRadius = Radius.circular(4);

    BorderRadius borderRadius;
    switch (bubblePosition) {
      case BubblePosition.single:
        borderRadius = BorderRadius.all(messageRadius);
        break;
      case BubblePosition.first:
        borderRadius = isMe
            ? const BorderRadius.only(
                topLeft: messageRadius,
                topRight: messageRadius,
                bottomLeft: messageRadius,
                bottomRight: sharpRadius,
              )
            : const BorderRadius.only(
                topLeft: messageRadius,
                topRight: messageRadius,
                bottomLeft: sharpRadius,
                bottomRight: messageRadius,
              );
        break;
      case BubblePosition.middle:
        borderRadius = isMe
            ? const BorderRadius.only(
                topLeft: messageRadius,
                topRight: sharpRadius,
                bottomLeft: messageRadius,
                bottomRight: sharpRadius,
              )
            : const BorderRadius.only(
                topLeft: sharpRadius,
                topRight: messageRadius,
                bottomLeft: sharpRadius,
                bottomRight: messageRadius,
              );
        break;
      case BubblePosition.last:
        borderRadius = isMe
            ? const BorderRadius.only(
                topLeft: messageRadius,
                topRight: sharpRadius,
                bottomLeft: messageRadius,
                bottomRight: messageRadius,
              )
            : const BorderRadius.only(
                topLeft: sharpRadius,
                topRight: messageRadius,
                bottomLeft: messageRadius,
                bottomRight: messageRadius,
              );
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Hiển thị tên người gửi ở chat nhóm khi showSenderInfo = true
            if (showSenderInfo && senderInfo != null && (bubblePosition == BubblePosition.first || bubblePosition == BubblePosition.single))
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (senderInfo!['avatarUrl'] != null)
                      CircleAvatar(
                        radius: 10,
                        backgroundImage: NetworkImage(senderInfo!['avatarUrl']),
                      )
                    else
                      CircleAvatar(
                        radius: 10,
                        backgroundImage: AssetImage("assets/avatar_default/avatar_default.png") as ImageProvider,
                      ),
                    const SizedBox(width: 4),
                    Text(
                      senderInfo!['fullName'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            // Tin nhắn chính
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.grey[200],
                borderRadius: borderRadius,
              ),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}