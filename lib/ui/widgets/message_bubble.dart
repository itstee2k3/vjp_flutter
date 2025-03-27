// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
//
// import '../../data/models/message.dart';
//
// class MessageBubble extends StatelessWidget {
//   final Message message;
//   final bool isMe;
//
//   const MessageBubble({
//     Key? key,
//     required this.message,
//     required this.isMe,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       // ... mã hiện tại ...
//       child: Column(
//         // ... mã hiện tại ...
//         children: [
//           // ... mã hiện tại ...
//           Text(
//             message.content,
//             // ... mã hiện tại ...
//           ),
//           Text(
//             _formatTime(message.sentAt),
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _formatTime(DateTime time) {
//     // Đảm bảo thời gian là giờ địa phương
//     final localTime = time.toLocal();
//
//     // Kiểm tra xem thời gian có phải là ngày hôm nay không
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final messageDay = DateTime(localTime.year, localTime.month, localTime.day);
//
//     if (messageDay == today) {
//       // Nếu là ngày hôm nay, chỉ hiển thị giờ:phút
//       return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
//     } else {
//       // Nếu không phải ngày hôm nay, hiển thị ngày/tháng giờ:phút
//       return '${localTime.day.toString().padLeft(2, '0')}/${localTime.month.toString().padLeft(2, '0')} ${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
//     }
//   }
// }