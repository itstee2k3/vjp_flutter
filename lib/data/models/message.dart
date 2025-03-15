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
    // Xử lý trường id - có thể là int hoặc không tồn tại
    int messageId = 0;
    if (json.containsKey('id')) {
      if (json['id'] is int) {
        messageId = json['id'];
      } else if (json['id'] is String) {
        try {
          messageId = int.parse(json['id']);
        } catch (e) {
          print('Error parsing id: ${json['id']}');
        }
      }
    } else if (json.containsKey('Id')) {
      // Trường hợp API trả về với chữ cái đầu viết hoa
      if (json['Id'] is int) {
        messageId = json['Id'];
      } else if (json['Id'] is String) {
        try {
          messageId = int.parse(json['Id']);
        } catch (e) {
          print('Error parsing Id: ${json['Id']}');
        }
      }
    }

    // Xử lý trường sentAt - có thể là String hoặc không tồn tại
    DateTime messageSentAt = DateTime.now();
    if (json.containsKey('sentAt')) {
      if (json['sentAt'] is String) {
        try {
          // Chuyển đổi thời gian từ UTC sang giờ địa phương
          messageSentAt = DateTime.parse(json['sentAt']).toLocal();
          print('Parsed sentAt: ${json['sentAt']} to local: $messageSentAt');
        } catch (e) {
          print('Error parsing sentAt: ${json['sentAt']}');
        }
      }
    } else if (json.containsKey('SentAt')) {
      // Trường hợp API trả về với chữ cái đầu viết hoa
      if (json['SentAt'] is String) {
        try {
          // Chuyển đổi thời gian từ UTC sang giờ địa phương
          messageSentAt = DateTime.parse(json['SentAt']).toLocal();
          print('Parsed SentAt: ${json['SentAt']} to local: $messageSentAt');
        } catch (e) {
          print('Error parsing SentAt: ${json['SentAt']}');
        }
      }
    }

    // Xử lý các trường khác - có thể viết thường hoặc viết hoa
    String senderId = json['senderId'] ?? json['SenderId'] ?? '';
    String receiverId = json['receiverId'] ?? json['ReceiverId'] ?? '';
    String content = json['content'] ?? json['Content'] ?? '';
    bool isRead = json['isRead'] ?? json['IsRead'] ?? false;

    return Message(
      id: messageId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      sentAt: messageSentAt,
      isRead: isRead,
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