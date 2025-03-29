import 'package:equatable/equatable.dart';
import '../../../../data/models/message.dart';

class GroupChatState extends Equatable {
  final List<Message> messages;
  final bool isLoading;
  final String? error;
  final bool isTyping;
  final String? currentUserId;
  final bool isSending;

  GroupChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.isTyping = false,
    this.currentUserId,
    this.isSending = false,
  });

  GroupChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
    bool? isTyping,
    String? currentUserId,
    bool? isSending,
  }) {
    return GroupChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isTyping: isTyping ?? this.isTyping,
      currentUserId: currentUserId ?? this.currentUserId,
      isSending: isSending ?? this.isSending,
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, error, isTyping, currentUserId, isSending];
}