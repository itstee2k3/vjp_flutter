import 'package:equatable/equatable.dart';
import '../../../../data/models/message.dart'; // Assuming Message model is here

enum ChatMediaStatus { initial, loading, success, failure }

class ChatMediaState extends Equatable {
  final ChatMediaStatus status;
  final List<Message> imageMessages; // Renamed for clarity
  final String? errorMessage;
  final bool hasMore;
  final bool isLoadingMore;
  final int currentPage; // Keep track of pagination

  const ChatMediaState({
    this.status = ChatMediaStatus.initial,
    this.imageMessages = const [],
    this.errorMessage,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.currentPage = 1,
  });

  ChatMediaState copyWith({
    ChatMediaStatus? status,
    List<Message>? imageMessages,
    String? errorMessage,
    bool? hasMore,
    bool? isLoadingMore,
    int? currentPage,
    bool clearError = false,
  }) {
    return ChatMediaState(
      status: status ?? this.status,
      imageMessages: imageMessages ?? this.imageMessages,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  List<String> get recentImageUrls => imageMessages
      .map((msg) => msg.imageUrl) // Extract imageUrl
      .where((url) => url != null && url.isNotEmpty) // Filter out null/empty
      .cast<String>() // Cast to String
      .toList();

  @override
  List<Object?> get props => [
        status,
        imageMessages, // Use renamed list
        errorMessage,
        hasMore,
        isLoadingMore,
        currentPage, // Add pagination state
      ];
} 