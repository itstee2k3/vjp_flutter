// import 'package:flutter/material.dart';
// import '../../../../data/models/group_chat.dart';
// import '../../../../core/widgets/group_avatar.dart';
// import '../../../../core/widgets/user_avatar.dart';
// import '../../../../data/models/user.dart';
//
// class GroupDetailsScreen extends StatelessWidget {
//   final GroupChat group;
//
//   const GroupDetailsScreen({
//     Key? key,
//     required this.group,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Group Details'),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             // Group info section
//             Container(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   GroupAvatar(
//                     avatarUrl: group.avatarUrl,
//                     name: group.name,
//                     radius: 50,
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     group.name,
//                     style: const TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   if (group.description != null && group.description!.isNotEmpty) ...[
//                     const SizedBox(height: 8),
//                     Text(
//                       group.description!,
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(color: Colors.grey),
//                     ),
//                   ],
//                   const SizedBox(height: 8),
//                   Text(
//                     'Created on ${_formatDate(group.createdAt)}',
//                     style: const TextStyle(color: Colors.grey),
//                   ),
//                 ],
//               ),
//             ),
//
//             // Members section
//             const Divider(),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Members (${group.memberCount ?? group.members.length})',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.add),
//                     onPressed: () {
//                       // Add member functionality
//                     },
//                   ),
//                 ],
//               ),
//             ),
//
//             // Member list
//             if (group.members.isNotEmpty)
//               ...group.members.map((user) => _buildMemberTile(context, user))
//             else
//               const Center(
//                 child: Padding(
//                   padding: EdgeInsets.all(16.0),
//                   child: Text('No members information available'),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMemberTile(BuildContext context, User user) {
//     return ListTile(
//       leading: UserAvatar(
//         avatarUrl: user.avatarUrl,
//         name: user.fullName,
//       ),
//       title: Text(user.fullName),
//       subtitle: Text(user.email),
//       trailing: Icon(
//         user.id == group.createdBy
//             ? Icons.star
//             : (group.isAdmin == true ? Icons.admin_panel_settings : null),
//         color: user.id == group.createdBy ? Colors.amber : Colors.blue,
//       ),
//     );
//   }
//
//   String _formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year}';
//   }
// }