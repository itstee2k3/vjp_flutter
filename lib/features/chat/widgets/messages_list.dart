import 'package:flutter/material.dart';
import '../../../data/models/story.dart';

class MessagesList extends StatelessWidget {
  final List<Story> stories;
  final Function(Story) onMessageTap;

  const MessagesList({
    Key? key,
    required this.stories,
    required this.onMessageTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: stories.length,
      itemBuilder: (context, index) {
        final story = stories[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(story.avatarUrl),
          ),
          title: Text(
            story.username,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            story.lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[600]),
          ),
          trailing: SizedBox(
            height: 40,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  story.timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (story.hasUnread)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
          onTap: () => onMessageTap(story),
        );
      },
    );
  }
} 