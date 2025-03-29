import '../../../../data/models/group_chat.dart';

class GroupChatListState {
  final List<GroupChat> groups;
  final bool isLoading;
  final String? error;

  GroupChatListState({
    this.groups = const [],
    this.isLoading = false,
    this.error,
  });

  factory GroupChatListState.initial() {
    return GroupChatListState();
  }

  GroupChatListState copyWith({
    List<GroupChat>? groups,
    bool? isLoading,
    String? error,
  }) {
    return GroupChatListState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
} 