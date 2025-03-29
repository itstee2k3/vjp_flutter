import 'package:flutter/material.dart';

class MessageTime extends StatelessWidget {
  final DateTime time;
  final bool isMe;

  const MessageTime({
    Key? key,
    required this.time,
    required this.isMe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final formattedTime = '$hour:$minute';

    return Text(
      formattedTime,
      style: TextStyle(
        fontSize: 12,
        color: isMe ? Colors.white70 : Colors.black54,
      ),
    );
  }
}