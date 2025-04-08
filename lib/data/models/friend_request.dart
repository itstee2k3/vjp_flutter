class FriendRequest {
  final int friendshipId;
  final String requesterId;
  final String requesterFullName;
  final String? requesterAvatarUrl; // Thêm avatar
  final DateTime requestedAt;

  FriendRequest({
    required this.friendshipId,
    required this.requesterId,
    required this.requesterFullName,
    this.requesterAvatarUrl,
    required this.requestedAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    int parsedFriendshipId = 0; // Giá trị mặc định
    if (json['friendshipId'] is int) {
      parsedFriendshipId = json['friendshipId'];
    } else if (json['friendshipId'] is String) {
      parsedFriendshipId = int.tryParse(json['friendshipId'] ?? '') ?? 0;
    } else if (json['friendshipId'] != null){
       print("Warning: Unexpected type for friendshipId: ${json['friendshipId']?.runtimeType}, value: ${json['friendshipId']}");
    }

    String parsedRequesterId = json['requesterId']?.toString() ?? '';
    String parsedRequesterFullName = json['requesterFullName']?.toString() ?? 'N/A';
    String? parsedRequesterAvatarUrl = json['requesterAvatarUrl']?.toString();

    DateTime parsedRequestedAt = DateTime.now(); // Giá trị mặc định
    if (json['requestedAt'] is String) {
      try {
        parsedRequestedAt = DateTime.parse(json['requestedAt']);
      } catch (e) {
        print('Error parsing requestedAt: ${json['requestedAt']} - $e');
      }
    } else if (json['requestedAt'] != null) {
       print("Warning: Unexpected type for requestedAt: ${json['requestedAt']?.runtimeType}, value: ${json['requestedAt']}");
    }

    return FriendRequest(
      friendshipId: parsedFriendshipId,
      requesterId: parsedRequesterId,
      requesterFullName: parsedRequesterFullName,
      requesterAvatarUrl: parsedRequesterAvatarUrl,
      requestedAt: parsedRequestedAt,
    );
  }
}