import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/message.dart';
import '../../../../services/api/group_chat_api_service.dart';
import 'group_chat_state.dart';

class GroupChatCubit extends Cubit<GroupChatState> {
  final GroupChatApiService _apiService;
  final int groupId;
  StreamSubscription? _messageSubscription;
  final Set<String> _processedMessageIds = {};

  GroupChatCubit({
    required GroupChatApiService apiService,
    required this.groupId,
  }) : _apiService = apiService,
       super(GroupChatState(currentUserId: apiService.currentUserId)) {
    loadMessages();
    _setupMessageStream();
  }

  GroupChatApiService get apiService => _apiService;

  Future<void> loadMessages() async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      
      print('Loading group messages for groupId: $groupId');
      final result = await _apiService.getGroupMessages(groupId, page: 1);
      
      final messages = result['messages'] as List<Message>;
      final hasMore = result['hasMore'] as bool;
      
      // Add processed message IDs
      for (var message in messages) {
        final messageId = '${message.id}-${message.senderId}-${message.content}-${message.sentAt.millisecondsSinceEpoch}';
        _processedMessageIds.add(messageId);
      }
      
      // Sort messages by time (oldest first for proper display)
      messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      
      print('Loaded ${messages.length} group messages');
      print('Has more messages: $hasMore');
      
      emit(state.copyWith(
        messages: messages,
        isLoading: false,
        error: null,
        currentPage: 1,
        hasMoreMessages: hasMore,
      ));
    } catch (e) {
      print('Error loading group messages: $e');
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  Future<void> loadMoreMessages() async {
    if (!state.hasMoreMessages || state.isLoadingMore) return;

    try {
      print('Loading more group messages, current page: ${state.currentPage}');
      emit(state.copyWith(isLoadingMore: true, error: null));

      final nextPage = state.currentPage + 1;
      print('Fetching group messages for page: $nextPage');
      
      final result = await _apiService.getGroupMessages(
        groupId, 
        page: nextPage
      );
      
      final newMessages = result['messages'] as List<Message>;
      final hasMore = result['hasMore'] as bool;
      
      print('Fetched ${newMessages.length} older group messages');

      if (newMessages.isEmpty) {
        print('No more group messages to load');
        emit(state.copyWith(
          isLoadingMore: false,
          hasMoreMessages: false,
        ));
        return;
      }

      // Add processed message IDs
      for (var message in newMessages) {
        final messageId = '${message.id}-${message.senderId}-${message.content}-${message.sentAt.millisecondsSinceEpoch}';
        _processedMessageIds.add(messageId);
      }

      // Sort new messages by time (oldest first)
      newMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      
      // Combine old messages with current messages
      final updatedMessages = [...newMessages, ...state.messages];
      
      print('Updated group message list now has ${updatedMessages.length} messages');
      print('Has more group messages: $hasMore');

      emit(state.copyWith(
        messages: updatedMessages,
        isLoadingMore: false,
        error: null,
        currentPage: nextPage,
        hasMoreMessages: hasMore,
      ));
    } catch (e) {
      print('Error loading more group messages: $e');
      emit(state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      ));
    }
  }

  void _setupMessageStream() {
    _messageSubscription = _apiService.onMessageReceived.listen((message) {
      if (message.groupId != null && int.parse(message.groupId!) == groupId) {
        final messageId = '${message.id}-${message.senderId}-${message.content}-${message.sentAt.millisecondsSinceEpoch}';
        
        if (!_processedMessageIds.contains(messageId)) {
          _processedMessageIds.add(messageId);
          final updatedMessages = List<Message>.from(state.messages)..add(message);
          emit(state.copyWith(messages: updatedMessages));
        }
      }
    });
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    
    try {
      emit(state.copyWith(isSending: true, error: null));
      
      // Create a temporary message ID for optimistic UI update
      final tempId = DateTime.now().millisecondsSinceEpoch;
      
      // Add temporary message to the UI immediately
      final tempMessage = Message(
        id: tempId,
        senderId: _apiService.currentUserId!,
        groupId: groupId.toString(),
        content: content,
        sentAt: DateTime.now(),
        isRead: false,
      );
      
      // Track the temp message ID to avoid duplicates
      final tempMessageId = '${tempMessage.id}-${tempMessage.senderId}-${tempMessage.content}-${tempMessage.sentAt.millisecondsSinceEpoch}';
      _processedMessageIds.add(tempMessageId);
      
      final updatedMessages = List<Message>.from(state.messages)..add(tempMessage);
      emit(state.copyWith(
        messages: updatedMessages,
        isSending: true,
        error: null,
      ));

      // Send message to server
      await _apiService.sendGroupMessage(
        groupId: groupId,
        content: content,
      );

      emit(state.copyWith(isSending: false, error: null));
      print('Message sent successfully: $content');
    } catch (e) {
      print('Error sending message: $e');
      
      // Mark the last message as error
      final messages = List<Message>.from(state.messages);
      if (messages.isNotEmpty) {
        final lastMessage = messages.last;
        if (lastMessage.senderId == _apiService.currentUserId && !lastMessage.isRead) {
          // Replace the optimistic message with an error message
          messages.removeLast();
          
          final errorMessage = Message(
            id: DateTime.now().millisecondsSinceEpoch + 1, // Ensure unique ID
            senderId: _apiService.currentUserId!,
            groupId: groupId.toString(),
            content: '[Lỗi: Không thể gửi tin nhắn]',
            sentAt: DateTime.now(),
            isRead: false,
          );
          
          messages.add(errorMessage);
        }
      }
      
      emit(state.copyWith(
        messages: messages,
        isSending: false,
        error: 'Không thể gửi tin nhắn: ${e.toString()}',
      ));
    }
  }

  Future<void> sendImageMessage(String content, File imageFile) async {
    try {
      emit(state.copyWith(isSending: true, error: null));
      
      // Add temporary message
      final tempId = DateTime.now().millisecondsSinceEpoch;
      final tempMessage = Message(
        id: tempId,
        senderId: _apiService.currentUserId!,
        groupId: groupId.toString(),
        content: content.isEmpty ? '[Hình ảnh]' : content,
        sentAt: DateTime.now(),
        isRead: false,
        type: MessageType.image,
        // Use a placeholder for now
        imageUrl: 'pending_upload',
      );
      
      // Track the temp message
      final tempMessageId = '${tempMessage.id}-${tempMessage.senderId}-${tempMessage.content}-${tempMessage.sentAt.millisecondsSinceEpoch}';
      _processedMessageIds.add(tempMessageId);
      
      final updatedMessages = List<Message>.from(state.messages)..add(tempMessage);
      emit(state.copyWith(
        messages: updatedMessages,
        isSending: true,
        error: null,
      ));

      print('Sending image for group: $groupId');
      
      // Try to use the API if it exists, otherwise send as base64
      try {
        // First try to use the dedicated image upload API
        final imageUrl = await _apiService.uploadGroupImage(
          groupId, 
          imageFile,
          caption: content.isEmpty ? '[Hình ảnh]' : content
        );
        
        // Send a message with the image URL
        await _apiService.sendGroupMessage(
          groupId: groupId,
          content: content.isEmpty ? '[Hình ảnh]' : content,
          imageUrl: imageUrl,
          type: 'image',
        );
      } catch (uploadError) {
        print('Dedicated upload API failed, falling back to base64: $uploadError');
        // If the upload API fails, fallback to base64
        await _apiService.sendGroupImageAsBase64(
          groupId,
          imageFile,
          caption: content.isEmpty ? '[Hình ảnh]' : content,
        );
      }

      emit(state.copyWith(isSending: false, error: null));
      print('Image message sent successfully');
    } catch (e) {
      print('Error sending image message: $e');
      
      // Mark the last message as error
      final messages = List<Message>.from(state.messages);
      if (messages.isNotEmpty) {
        final lastMessage = messages.last;
        if (lastMessage.senderId == _apiService.currentUserId && 
            lastMessage.type == MessageType.image && 
            lastMessage.imageUrl == 'pending_upload') {
          // Replace the optimistic message with an error message
          messages.removeLast();
          
          final errorMessage = Message(
            id: DateTime.now().millisecondsSinceEpoch + 1, // Ensure unique ID
            senderId: _apiService.currentUserId!,
            groupId: groupId.toString(),
            content: '[Lỗi: Không thể gửi hình ảnh]',
            sentAt: DateTime.now(),
            isRead: false,
          );
          
          messages.add(errorMessage);
        }
      }
      
      emit(state.copyWith(
        messages: messages,
        isSending: false,
        error: 'Không thể gửi hình ảnh: ${e.toString()}',
      ));
    }
  }

  void startTyping() {
    emit(state.copyWith(isTyping: true));
  }

  void stopTyping() {
    emit(state.copyWith(isTyping: false));
  }

  void resetAndReloadMessages() {
    _processedMessageIds.clear();
    emit(state.copyWith(messages: []));
    loadMessages();
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _processedMessageIds.clear();
    return super.close();
  }
}
