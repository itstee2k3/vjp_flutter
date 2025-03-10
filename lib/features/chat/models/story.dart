class Story {
  final String username;
  final String avatarUrl;
  final String lastMessage;
  final String timeAgo;
  final bool hasUnread;

  Story({
    required this.username,
    required this.avatarUrl,
    required this.lastMessage,
    required this.timeAgo,
    this.hasUnread = false,
  });
} 