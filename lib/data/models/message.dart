class Message {
  final int id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime sentAt;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.sentAt,
    required this.isRead,
  });

  Message copyWith({
    int? id,
    String? senderId,
    String? receiverId, 
    String? content,
    DateTime? sentAt,
    bool? isRead,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime;
    if (json['sentAt'] is String) {
      final sentAtStr = json['sentAt'] as String;
      if (sentAtStr.contains('+')) {
        final parts = sentAtStr.split('+');
        final timeStr = parts[0];
        parsedTime = DateTime.parse(timeStr);
      } else {
        parsedTime = DateTime.parse(sentAtStr);
      }
    } else {
      parsedTime = DateTime.now();
    }

    return Message(
      id: json['id'] ?? 0,
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      content: json['content'] ?? '',
      sentAt: parsedTime,
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'sentAt': sentAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is Message &&
    runtimeType == other.runtimeType &&
    id == other.id &&
    senderId == other.senderId &&
    receiverId == other.receiverId &&
    content == other.content &&
    sentAt == other.sentAt &&
    isRead == other.isRead;

  @override
  int get hashCode =>
    id.hashCode ^
    senderId.hashCode ^
    receiverId.hashCode ^
    content.hashCode ^
    sentAt.hashCode ^
    isRead.hashCode;
} 