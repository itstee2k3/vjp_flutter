import 'package:equatable/equatable.dart';

import '../../../../data/models/group_chat.dart';

class GroupChatListState extends Equatable {
  final List<GroupChat> groups;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  const GroupChatListState({
    required this.groups,
    required this.isLoading,
    this.error,
    required this.isInitialized,
  });

  factory GroupChatListState.initial() {
    return const GroupChatListState(
      groups: [],
      isLoading: false,
      error: null,
      isInitialized: false,
    );
  }

  GroupChatListState copyWith({
    List<GroupChat>? groups,
    bool? isLoading,
    String? error,
    bool? isInitialized,
  }) {
    return GroupChatListState(
      groups: groups ?? this.groups,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  List<Object?> get props => [groups, isLoading, error, isInitialized];
} 