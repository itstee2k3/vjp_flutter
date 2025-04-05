import 'package:equatable/equatable.dart';
import '../../../../data/models/message.dart';

class GroupChatState extends Equatable {
  final List<Message> messages;
  final bool isLoading;
  final String? error;
  final bool isTyping;
  final String? currentUserId;
  final bool isSending;
  final int currentPage;
  final bool hasMoreMessages;
  final bool isLoadingMore;

  GroupChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.isTyping = false,
    this.currentUserId,
    this.isSending = false,
    this.currentPage = 1,
    this.hasMoreMessages = true,
    this.isLoadingMore = false,
  });

  GroupChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
    bool? isTyping,
    String? currentUserId,
    bool? isSending,
    int? currentPage,
    bool? hasMoreMessages,
    bool? isLoadingMore,
  }) {
    return GroupChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isTyping: isTyping ?? this.isTyping,
      currentUserId: currentUserId ?? this.currentUserId,
      isSending: isSending ?? this.isSending,
      currentPage: currentPage ?? this.currentPage,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
    messages, 
    isLoading, 
    error, 
    isTyping, 
    currentUserId, 
    isSending,
    currentPage,
    hasMoreMessages,
    isLoadingMore,
  ];
}