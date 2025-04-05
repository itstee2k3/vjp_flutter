import '../../../../data/models/message.dart';

class PersonalChatState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;
  final bool isSending;
  final Map<String, bool> typingStatus;
  final int currentPage;
  final bool hasMoreMessages;
  final bool isLoadingMore;

  PersonalChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.isSending = false,
    this.typingStatus = const {},
    this.currentPage = 1,
    this.hasMoreMessages = true,
    this.isLoadingMore = false,
  });

  PersonalChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
    bool? isSending,
    Map<String, bool>? typingStatus,
    int? currentPage,
    bool? hasMoreMessages,
    bool? isLoadingMore,
  }) {
    return PersonalChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSending: isSending ?? this.isSending,
      typingStatus: typingStatus ?? this.typingStatus,
      currentPage: currentPage ?? this.currentPage,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
