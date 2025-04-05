import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    final timeFormatter = DateFormat('HH:mm');
    final formattedTime = timeFormatter.format(time);

    final dateFormatter = DateFormat('dd/MM');
    final formattedDate = dateFormatter.format(time);

    final fullTimestamp = '$formattedTime $formattedDate';

    return Text(
      fullTimestamp,
      style: TextStyle(
        fontSize: 12,
        color: isMe
            ? (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54)
            : Colors.grey[600],
      ),
    );
  }
}