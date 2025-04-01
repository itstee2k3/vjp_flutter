enum MessageType {
  text,
  image,
  file,
  audio,
  video,
  // Có thể thêm các loại khác trong tương lai: file, audio, video, etc.
}

class Message {
  final int id;
  final String senderId;
  final String? receiverId; // For 1v1 chat
  final dynamic groupId;    // For group chat
  final String content;
  final DateTime sentAt;
  final bool isRead;
  final MessageType type;
  final String? imageUrl;  // For image messages
  final String? fileUrl;   // For other file types
  final String? fileType;
  final Map<String, DateTime>? readBy;

  Message({
    required this.id,
    required this.senderId,
    this.receiverId,
    this.groupId,
    required this.content,
    required this.sentAt,
    this.isRead = false,
    this.type = MessageType.text,
    this.imageUrl,
    this.fileUrl,
    this.fileType,
    this.readBy,
  });

  Message copyWith({
    int? id,
    String? senderId,
    String? receiverId,
    dynamic groupId,
    String? content,
    DateTime? sentAt,
    bool? isRead,
    MessageType? type,
    String? imageUrl,
    String? fileUrl,
    String? fileType,
    Map<String, DateTime>? readBy,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      groupId: groupId ?? this.groupId,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      readBy: readBy ?? this.readBy,
    );
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    // Process the groupId which might be int from server but string in app
    dynamic processedGroupId;
    if (json.containsKey('groupId')) {
      processedGroupId = json['groupId']; // Keep original type (int or String)
    }

    // Xử lý trường id
    int messageId = 0;
    if (json.containsKey('id')) {
      messageId = json['id'] is String ? int.parse(json['id']) : json['id'];
    } else if (json.containsKey('Id')) {
      messageId = json['Id'] is String ? int.parse(json['Id']) : json['Id'];
    }

    // Xử lý trường sentAt
    DateTime messageSentAt = DateTime.now();
    if (json.containsKey('sentAt')) {
      if (json['sentAt'] is String) {
        try {
          messageSentAt = DateTime.parse(json['sentAt']).toLocal();
        } catch (e) {
          print('Error parsing sentAt: ${json['sentAt']}');
        }
      }
    } else if (json.containsKey('SentAt')) {
      if (json['SentAt'] is String) {
        try {
          messageSentAt = DateTime.parse(json['SentAt']).toLocal();
        } catch (e) {
          print('Error parsing SentAt: ${json['SentAt']}');
        }
      }
    }

    // Xử lý các trường khác
    String senderId = json['senderId'] ?? json['SenderId'] ?? '';
    String? receiverId = json['receiverId'] ?? json['ReceiverId'];
    String content = json['content'] ?? json['Content'] ?? '';
    bool isRead = json['isRead'] ?? json['IsRead'] ?? false;
    
    // Handle image URL
    String? imageUrl = json['imageUrl'] ?? json['ImageUrl'];
    
    // Handle file URL (for backward compatibility)
    String? fileUrl = json['fileUrl'] ?? json['FileUrl'];
    String? fileType = json['fileType'] ?? json['FileType'] ?? json['type'] ?? json['Type'] ?? 'text';

    // Xử lý loại tin nhắn
    MessageType type = MessageType.text;
    if (imageUrl != null) {
      type = MessageType.image;
    } else if (fileType != null) {
      switch (fileType.toLowerCase()) {
        case 'image':
          type = MessageType.image;
          break;
        case 'file':
          type = MessageType.file;
          break;
        case 'audio':
          type = MessageType.audio;
          break;
        case 'video':
          type = MessageType.video;
          break;
      }
    }

    // Xử lý trạng thái đã đọc
    Map<String, DateTime>? readBy;
    if (json.containsKey('readBy')) {
      readBy = Map<String, DateTime>.from(
        (json['readBy'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, DateTime.parse(value as String)),
        ),
      );
    }

    return Message(
      id: messageId,
      senderId: senderId,
      receiverId: receiverId,
      groupId: processedGroupId,
      content: content,
      sentAt: messageSentAt,
      isRead: isRead,
      type: type,
      imageUrl: imageUrl,
      fileUrl: fileUrl,
      fileType: fileType,
      readBy: readBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'groupId': groupId,
      'content': content,
      'sentAt': sentAt.toIso8601String(),
      'isRead': isRead,
      'type': type.toString().split('.').last,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'readBy': readBy?.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
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
          groupId == other.groupId &&
          content == other.content &&
          sentAt == other.sentAt &&
          isRead == other.isRead &&
          type == other.type &&
          imageUrl == other.imageUrl &&
          fileUrl == other.fileUrl &&
          fileType == other.fileType &&
          readBy == other.readBy;

  @override
  int get hashCode =>
      id.hashCode ^
      senderId.hashCode ^
      receiverId.hashCode ^
      groupId.hashCode ^
      content.hashCode ^
      sentAt.hashCode ^
      isRead.hashCode ^
      type.hashCode ^
      imageUrl.hashCode ^
      fileUrl.hashCode ^
      fileType.hashCode ^
      readBy.hashCode;

  bool get isValidImageUrl => 
      imageUrl != null && 
      (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'));

  bool get isValidFileUrl => 
      fileUrl != null && 
      (fileUrl!.startsWith('http://') || fileUrl!.startsWith('https://'));

  String? get mediaUrl => type == MessageType.image ? imageUrl : fileUrl;

  bool get isSending => content == '[Đang gửi...]';

  bool get isError => content.startsWith('[Lỗi:');

  bool get isGroupMessage => groupId != null;
} 