class Message {
  final int? id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime sentAt;
  final bool isRead;

  Message({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.sentAt,
    this.isRead = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      content: json['content'],
      sentAt: DateTime.parse(json['sentAt']),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'receiverId': receiverId,
    'content': content,
    'sentAt': sentAt.toIso8601String(),
    'isRead': isRead,
  };
} 