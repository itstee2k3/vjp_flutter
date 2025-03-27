import '../../../../data/models/message.dart';

class PersonalChatState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;
  final bool isSending;

  PersonalChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.isSending = false,
  });

  PersonalChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
    bool? isSending,
  }) {
    return PersonalChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSending: isSending ?? this.isSending,
    );
  }
}
