import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/api/chat_api_service.dart';
import '../../../../services/api/group_chat_api_service.dart';
import '../../screens/shared/chat_info_screen.dart';
import 'chat_media_state.dart';
import '../../../../data/models/message.dart';

const int _mediaPageSize = 30; // Fetch more items per page for media screen

class ChatMediaCubit extends Cubit<ChatMediaState> {
  final ChatApiService? _chatApiService;
  final GroupChatApiService? _groupChatApiService;
  final String chatIdString;
  final ChatType chatType;

  ChatMediaCubit({
    required this.chatIdString,
    required this.chatType,
    ChatApiService? chatApiService,
    GroupChatApiService? groupChatApiService,
  })  : _chatApiService = chatApiService,
        _groupChatApiService = groupChatApiService,
        assert(chatType == ChatType.personal ? chatApiService != null : true,
              'ChatApiService must be provided for personal chats'),
        assert(chatType == ChatType.group ? groupChatApiService != null : true,
              'GroupChatApiService must be provided for group chats'),
        super(const ChatMediaState()) {
    loadInitialMedia();
  }

  Future<void> loadInitialMedia() async {
    if (state.status == ChatMediaStatus.loading) return;
    emit(state.copyWith(status: ChatMediaStatus.loading));
    print("🖼️ Fetching initial media page for $chatType ($chatIdString)");
    await _fetchMediaPage(1);
  }

  Future<void> loadMoreMedia() async {
     if (state.isLoadingMore || !state.hasMore) return;
     emit(state.copyWith(isLoadingMore: true));
     final nextPage = state.currentPage + 1;
     print("🖼️ Fetching media page $nextPage for $chatType ($chatIdString)");
     await _fetchMediaPage(nextPage);
  }

  Future<void> _fetchMediaPage(int page) async {
    try {
      List<Message> fetchedMessages = [];
      bool fetchedHasMore = true;

      if (chatType == ChatType.personal) {
        final response = await _chatApiService!.getChatHistory(chatIdString, page: page, pageSize: _mediaPageSize);
        fetchedMessages = response['messages'] as List<Message>? ?? [];
        fetchedHasMore = response['hasMore'] as bool? ?? false;
      } else { // Group
        final response = await _groupChatApiService!.getGroupMessages(int.parse(chatIdString), page: page, pageSize: _mediaPageSize);
        fetchedMessages = response['messages'] as List<Message>? ?? [];
        fetchedHasMore = response['hasMore'] as bool? ?? false;
      }
      print("🖼️ Fetched ${fetchedMessages.length} raw messages for page $page. HasMore: $fetchedHasMore");

      // Log details of each fetched message BEFORE filtering
      for (var msg in fetchedMessages) {
        print("  - Raw Msg ID: ${msg.id}, Type: ${msg.type}, URL: ${msg.imageUrl}");
      }

      // Filter for image messages
      final imageMessages = fetchedMessages
          .where((msg) => msg.type == MessageType.image && msg.imageUrl != null && msg.imageUrl!.isNotEmpty)
          .toList();
      print("🖼️ Found ${imageMessages.length} image messages on page $page.");
      
      // Append new images to existing ones
      final updatedImageList = page == 1 
          ? imageMessages // First page, replace state
          : [...state.imageMessages, ...imageMessages]; // Subsequent pages, append

      // Sort the combined list? Optional, depends on desired UI order (e.g., newest first)
      // updatedImageList.sort((a, b) => b.sentAt.compareTo(a.sentAt));

      print("🖼️ Emitting state - Page: $page, Total Images: ${updatedImageList.length}, Has More: $fetchedHasMore");

      emit(state.copyWith(
        // Always emit success if the fetch itself didn't throw an error
        status: ChatMediaStatus.success,
        imageMessages: updatedImageList,
        hasMore: fetchedHasMore,
        isLoadingMore: false,
        currentPage: page,
        clearError: true, // Clear any previous error on success
      ));
    } catch (e) {
      print("❌ Error fetching media page $page: $e");
      emit(state.copyWith(
        // Keep existing images on error, just update status
        status: ChatMediaStatus.failure,
        errorMessage: e.toString(),
        isLoadingMore: false,
        // Keep hasMore as true maybe? Or set based on error?
      ));
    }
  }
} 