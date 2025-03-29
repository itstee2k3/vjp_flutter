import '../../../../data/models/message.dart';

class PersonalChatState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;
  final bool isSending;
  final Map<String, bool> typingStatus;

  PersonalChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.isSending = false,
    this.typingStatus = const {},
  });

  PersonalChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
    bool? isSending,
    Map<String, bool>? typingStatus,
  }) {
    return PersonalChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSending: isSending ?? this.isSending,
      typingStatus: typingStatus ?? this.typingStatus,
    );
  }
}
