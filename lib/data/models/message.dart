enum MessageType {
  text,
  image,
  // Có thể thêm các loại khác trong tương lai: file, audio, video, etc.
}

class Message {
  final int id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime sentAt;
  final bool isRead;
  final MessageType type;
  final String? imageUrl; // URL của hình ảnh nếu là tin nhắn hình ảnh

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.sentAt,
    required this.isRead,
    this.type = MessageType.text,
    this.imageUrl,
  });

  Message copyWith({
    int? id,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? sentAt,
    bool? isRead,
    MessageType? type,
    String? imageUrl,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
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
    
    // Xử lý loại tin nhắn và URL hình ảnh
    MessageType type = MessageType.text;
    String? imageUrl;
    
    if (json.containsKey('type') || json.containsKey('Type')) {
      String typeStr = (json['type'] ?? json['Type'] ?? 'text').toString().toLowerCase();
      if (typeStr == 'image') {
        type = MessageType.image;
        imageUrl = json['imageUrl'] ?? json['ImageUrl'];
      }
    } else if (json.containsKey('imageUrl') && json['imageUrl'] != null) {
      type = MessageType.image;
      imageUrl = json['imageUrl'];
    } else if (json.containsKey('ImageUrl') && json['ImageUrl'] != null) {
      type = MessageType.image;
      imageUrl = json['ImageUrl'];
    }

    return Message(
      id: messageId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      sentAt: messageSentAt,
      isRead: isRead,
      type: type,
      imageUrl: imageUrl,
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
      'type': type.toString().split('.').last,
      if (imageUrl != null) 'imageUrl': imageUrl,
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
          isRead == other.isRead &&
          type == other.type &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode =>
      id.hashCode ^
      senderId.hashCode ^
      receiverId.hashCode ^
      content.hashCode ^
      sentAt.hashCode ^
      isRead.hashCode ^
      type.hashCode ^
      (imageUrl?.hashCode ?? 0);

  // Thêm phương thức để kiểm tra xem imageUrl có phải là URL hợp lệ không
  bool get isValidImageUrl => 
      imageUrl != null && 
      (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'));

  // Thêm phương thức để kiểm tra xem tin nhắn có đang trong trạng thái gửi không
  bool get isSending => content == '[Đang gửi hình ảnh...]';

  // Thêm phương thức để kiểm tra xem tin nhắn có bị lỗi không
  bool get isError => content.startsWith('[Lỗi:');
} 