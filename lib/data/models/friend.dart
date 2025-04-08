class Friend {
  final int friendshipId;
  final String friendId;
  final String friendFullName;
  final String? friendAvatarUrl; // Thêm avatar
  final bool? isOnline; // Thêm trạng thái online

  Friend({
    required this.friendshipId,
    required this.friendId,
    required this.friendFullName,
    this.friendAvatarUrl,
    this.isOnline,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      friendshipId: json['friendshipId'],
      friendId: json['friendId'],
      friendFullName: json['friendFullName'] ?? 'N/A',
      friendAvatarUrl: json['friendAvatarUrl'], // Parse avatar
      isOnline: json['isOnline'], // Parse trạng thái online
    );
  }
}