

import '../../../../data/models/message.dart';

class GroupChatState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;
  final bool isTyping;
  final String? currentUserId;

  GroupChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.isTyping = false,
    this.currentUserId,
  });

  GroupChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
    bool? isTyping,
    String? currentUserId,
  }) {
    return GroupChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isTyping: isTyping ?? this.isTyping,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }
} 