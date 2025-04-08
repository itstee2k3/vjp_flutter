import 'enums/friendship_status.dart';

class User {
  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeen;
  final FriendshipStatus friendshipStatus; // Thêm trường này
  final bool? isRequestSentByCurrentUser; // Thêm trường này

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeen,
    this.friendshipStatus = FriendshipStatus.none, // Giá trị mặc định
    this.isRequestSentByCurrentUser, // Thêm vào constructor
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Parse isRequestSentByCurrentUser trước vì có thể cần dùng để parse status
    bool? parseIsSent(dynamic isSentValue) {
        if (isSentValue == null) return null;
        if (isSentValue is bool) return isSentValue;
        if (isSentValue is String) {
            if (isSentValue.toLowerCase() == 'true') return true;
            if (isSentValue.toLowerCase() == 'false') return false;
        }
        print("Warning: Unexpected type or value for isRequestSentByCurrentUser: $isSentValue");
        return null;
    }
    final isSentByCurrentUser = parseIsSent(json['isRequestSentByCurrentUser']);

    // Sửa lại logic parse FriendshipStatus
    FriendshipStatus parseStatus(dynamic statusValue, bool? isSentFlag) {
      if (statusValue == null) return FriendshipStatus.none;
      if (statusValue is int) {
        switch (statusValue) {
          case 0: // Pending từ API
            // Dùng cờ isSentFlag để phân biệt
            return isSentFlag == true ? FriendshipStatus.pendingSent : FriendshipStatus.pendingReceived;
          case 1: // Accepted từ API
            return FriendshipStatus.accepted; // Map đúng sang enum Flutter
          case 2: // Rejected từ API
            return FriendshipStatus.rejected; // Map đúng sang enum Flutter
          case 3: // Blocked từ API
            return FriendshipStatus.blocked; // Map đúng sang enum Flutter
          default:
            print("Warning: Unknown integer value for friendshipStatus: $statusValue");
            return FriendshipStatus.none;
        }
      }
      // Xử lý trường hợp API trả về string (dự phòng)
      if (statusValue is String) {
           print("Warning: friendshipStatus received as String: $statusValue. Attempting to parse.");
           // Thử parse string nếu cần, ví dụ:
           // if (statusValue.toLowerCase() == 'accepted') return FriendshipStatus.accepted;
           // ... thêm các trường hợp khác ...
      }

      print("Warning: Unexpected type for friendshipStatus: ${statusValue?.runtimeType}, value: $statusValue");
      return FriendshipStatus.none;
    }
    final parsedStatus = parseStatus(json['friendshipStatus'], isSentByCurrentUser);

    return User(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'N/A',
      email: json['email']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null ? DateTime.tryParse(json['lastSeen'].toString()) : null,
      friendshipStatus: parsedStatus,
      isRequestSentByCurrentUser: isSentByCurrentUser,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'email': email,
    };
  }

  User copyWith({
    String? id,
    String? fullName,
    String? email,
    String? avatarUrl,
    bool? isOnline,
    DateTime? lastSeen,
    FriendshipStatus? friendshipStatus,
    bool? isRequestSentByCurrentUser,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      friendshipStatus: friendshipStatus ?? this.friendshipStatus,
      isRequestSentByCurrentUser: isRequestSentByCurrentUser ?? this.isRequestSentByCurrentUser,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
} 