import 'package:equatable/equatable.dart';
import '../../../../data/models/group_chat.dart'; // Assuming you have this model

enum GroupInfoStatus { initial, loading, success, failure, uploadingAvatar }

class GroupInfoState extends Equatable {
  final GroupInfoStatus status;
  final GroupChat? group; // Model containing group info (name, avatar, members...)
  final String? errorMessage;
  final String? newAvatarUrl; // Temporarily store new avatar URL after successful upload

  const GroupInfoState({
    this.status = GroupInfoStatus.initial,
    this.group,
    this.errorMessage,
    this.newAvatarUrl,
  });

  GroupInfoState copyWith({
    GroupInfoStatus? status,
    GroupChat? group,
    String? errorMessage,
    String? newAvatarUrl,
    bool clearError = false, // Flag to clear error message
    bool clearNewAvatar = false, // Flag to clear new avatar URL after use
  }) {
    return GroupInfoState(
      status: status ?? this.status,
      group: group ?? this.group,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      newAvatarUrl: clearNewAvatar ? null : newAvatarUrl ?? this.newAvatarUrl,
    );
  }

  @override
  List<Object?> get props => [status, group, errorMessage, newAvatarUrl];
} 