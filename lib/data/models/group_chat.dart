import 'package:flutter_socket_io/data/models/message.dart';
import 'package:flutter_socket_io/data/models/user.dart';

class GroupChat {
  final int id;
  final String name;
  final String? avatarUrl;
  final String? description;
  final List<String> memberIds;
  final List<User> members;
  final int? memberCount;
  final bool? isAdmin;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final Message? lastMessage;
  final Map<String, DateTime>? lastReadBy;

  GroupChat({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.description,
    this.memberIds = const [],
    this.members = const [],
    this.memberCount,
    this.isAdmin,
    this.createdBy,
    required this.createdAt,
    this.lastMessageAt,
    this.lastMessage,
    this.lastReadBy,
  });

  factory GroupChat.fromJson(Map<String, dynamic> json) {
    // Handle case where API might use different key casing
    int? extractId() {
      final id = json['id'] ?? json['Id'];
      if (id is int) return id;
      if (id is String) return int.tryParse(id);
      return null;
    }

    String? extractString(List<String> keys) {
      for (var key in keys) {
        if (json.containsKey(key) && json[key] != null) {
          return json[key].toString();
        }
      }
      return null;
    }

    DateTime? extractDateTime(List<String> keys) {
      for (var key in keys) {
        if (json.containsKey(key) && json[key] != null) {
          if (json[key] is String) {
            try {
              return DateTime.parse(json[key]);
            } catch (e) {
              print('Error parsing date for key $key: ${json[key]}');
            }
          }
        }
      }
      return null;
    }

    // Extract fields with appropriate fallbacks
    final id = extractId() ?? 0;
    final name = extractString(['name', 'Name']) ?? 'Unknown';
    final avatarUrl = extractString(['avatar', 'Avatar']);
    final description = extractString(['description', 'Description']);
    final memberCount = json['memberCount'] ?? json['MemberCount'];
    final isAdmin = json['isAdmin'] ?? json['IsAdmin'];
    final createdBy = extractString(['createdBy', 'CreatedBy']);
    final createdAt = extractDateTime(['createdAt', 'CreatedAt']) ?? DateTime.now();

    // Handle optional lists
    List<String> memberIds = [];
    if (json.containsKey('memberIds') && json['memberIds'] is List) {
      memberIds = List<String>.from(json['memberIds']);
    }

    List<User> members = [];
    if (json.containsKey('members') && json['members'] is List) {
      members = (json['members'] as List)
          .map((memberJson) => User.fromJson(memberJson as Map<String, dynamic>))
          .toList();
    }

    // Parse optional fields
    final lastMessageAt = extractDateTime(['lastMessageAt', 'LastMessageAt']);
    
    Message? lastMessage;
    if (json.containsKey('lastMessage') && json['lastMessage'] != null) {
      try {
        lastMessage = Message.fromJson(json['lastMessage'] as Map<String, dynamic>);
      } catch (e) {
        print('Error parsing lastMessage: $e');
      }
    }

    Map<String, DateTime>? lastReadBy;
    if (json.containsKey('lastReadBy') && json['lastReadBy'] is Map) {
      try {
        lastReadBy = Map<String, DateTime>.from(
          (json['lastReadBy'] as Map).map(
            (key, value) => MapEntry(key.toString(), 
                value is String ? DateTime.parse(value) : DateTime.now()),
          ),
        );
      } catch (e) {
        print('Error parsing lastReadBy: $e');
      }
    }

    return GroupChat(
      id: id,
      name: name,
      avatarUrl: avatarUrl,
      description: description,
      memberIds: memberIds,
      members: members,
      memberCount: memberCount is int ? memberCount : null,
      isAdmin: isAdmin is bool ? isAdmin : null,
      createdBy: createdBy,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt,
      lastMessage: lastMessage,
      lastReadBy: lastReadBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatarUrl,
      'description': description,
      'memberIds': memberIds,
      'members': members.map((member) => member.toJson()).toList(),
      'memberCount': memberCount,
      'isAdmin': isAdmin,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'lastMessage': lastMessage?.toJson(),
      'lastReadBy': lastReadBy?.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
    };
  }

  GroupChat copyWith({
    int? id,
    String? name,
    String? avatar,
    String? description,
    List<String>? memberIds,
    List<User>? members,
    int? memberCount,
    bool? isAdmin,
    String? createdBy,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    Message? lastMessage,
    Map<String, DateTime>? lastReadBy,
  }) {
    return GroupChat(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatar ?? this.avatarUrl,
      description: description ?? this.description,
      memberIds: memberIds ?? this.memberIds,
      members: members ?? this.members,
      memberCount: memberCount ?? this.memberCount,
      isAdmin: isAdmin ?? this.isAdmin,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastReadBy: lastReadBy ?? this.lastReadBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupChat &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          avatarUrl == other.avatarUrl &&
          createdAt == other.createdAt &&
          memberIds == other.memberIds &&
          createdBy == other.createdBy &&
          lastMessageAt == other.lastMessageAt &&
          lastMessage == other.lastMessage &&
          lastReadBy == other.lastReadBy;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      avatarUrl.hashCode ^
      createdAt.hashCode ^
      memberIds.hashCode ^
      createdBy.hashCode ^
      lastMessageAt.hashCode ^
      lastMessage.hashCode ^
      lastReadBy.hashCode;
} 