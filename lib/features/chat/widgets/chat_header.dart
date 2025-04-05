import 'package:flutter/material.dart';

class ChatHeader extends StatelessWidget {
  final String title;
  final String? avatarUrl;
  final VoidCallback? onInfoPressed;
  final VoidCallback onRefreshPressed;
  final bool isGroup;

  const ChatHeader({
    Key? key,
    required this.title,
    this.avatarUrl,
    this.onInfoPressed,
    required this.onRefreshPressed,
    this.isGroup = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          CircleAvatar(
            backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                ? NetworkImage(avatarUrl!)
                : AssetImage(
                    isGroup
                        ? "assets/avatar_default/avatar_group_default.png"
                        : "assets/avatar_default/avatar_default.png"
                  ) as ImageProvider,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // IconButton(
        //   icon: const Icon(Icons.refresh),
        //   onPressed: onRefreshPressed,
        // ),
        if (onInfoPressed != null)
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: onInfoPressed,
          ),
      ],
    );
  }
}