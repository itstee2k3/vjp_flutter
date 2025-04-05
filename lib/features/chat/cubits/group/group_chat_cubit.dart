import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/models/message.dart';
import '../../../../data/models/user.dart';
import '../../../../services/api/group_chat_api_service.dart';
import 'group_chat_state.dart';

class GroupChatCubit extends Cubit<GroupChatState> {
  final GroupChatApiService _apiService;
  final int groupId;
  StreamSubscription? _messageSubscription;
  final Set<String> _processedMessageIds = {};
  File? _lastImageFile; // Thêm biến này để lưu file ảnh cuối cùng
  
  // Map lưu cache thông tin người dùng
  final Map<String, Map<String, dynamic>> _userInfoCache = {};

  GroupChatCubit({
    required GroupChatApiService apiService,
    required this.groupId,
  }) : _apiService = apiService,
       super(GroupChatState(currentUserId: apiService.currentUserId)) {
    loadMessages();
    _setupMessageStream();
    _loadGroupMembers();
  }

  GroupChatApiService get apiService => _apiService;
  
  // Phương thức tải thông tin thành viên nhóm
  Future<void> _loadGroupMembers() async {
    try {
      // Tải danh sách thành viên nhóm
      final members = await _apiService.getGroupMembers(groupId);
      
      // Lưu thông tin người dùng vào cache
      for (var member in members) {
        if (member.containsKey('id') && member.containsKey('fullName')) {
          final userId = member['id'].toString();
          _userInfoCache[userId] = {
            'fullName': member['fullName'],
            'avatarUrl': member['avatarUrl'],
          };
        }
      }
    } catch (e) {
      print('Error loading group members: $e');
    }
  }
  
  // Phương thức lấy thông tin người dùng từ ID
  Map<String, dynamic>? getUserInfo(String userId) {
    return _userInfoCache[userId];
  }

  Future<void> loadMessages() async {
    try {
      emit(state.copyWith(isLoading: true, error: null));

      final messagesFromServer = await _apiService.getGroupMessages(groupId, page: 1);

      // Sort messages by time (oldest first) so newest messages appear at the bottom
      messagesFromServer.sort((a, b) => a.sentAt.compareTo(b.sentAt));

      // Add processed message IDs for deduplication
      for (var message in messagesFromServer) {
        final messageId = '${message.id}-${message.senderId}-${message.content}-${message.sentAt.millisecondsSinceEpoch}';
        _processedMessageIds.add(messageId);
      }


      print('Loaded ${messagesFromServer.length} group messages');
      print('Has more messages: ${messagesFromServer.length >= 20}');

      emit(state.copyWith(
        messages: messagesFromServer,
        isLoading: false,
        error: null,
        currentPage: 1,
        hasMoreMessages: messagesFromServer.length >= 20,
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
      
      final messagesFromServer = await _apiService.getGroupMessages(
        groupId, 
        page: nextPage
      );
      
      print('Fetched ${messagesFromServer.length} older group messages');

      if (messagesFromServer.isEmpty) {
        print('No more group messages to load');
        emit(state.copyWith(
          isLoadingMore: false,
          hasMoreMessages: false,
        ));
        return;
      }

      // Sort older messages by time (oldest first)
      messagesFromServer.sort((a, b) => a.sentAt.compareTo(b.sentAt));

      // Add processed message IDs for deduplication
      for (var message in messagesFromServer) {
        final messageId = '${message.id}-${message.senderId}-${message.content}-${message.sentAt.millisecondsSinceEpoch}';
        _processedMessageIds.add(messageId);
      }

      // Combine older messages with current messages - exactly like PersonalChatCubit
      final updatedMessages = [...messagesFromServer, ...state.messages];
      
      // Sort all messages by time (oldest first)
      updatedMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      
      print('Updated group message list now has ${updatedMessages.length} messages');
      
      // Check if there are more messages to load
      final hasMore = messagesFromServer.length >= 20; // Assuming 20 messages per page
      print('Has more group messages: $hasMore');

      emit(state.copyWith(
        messages: updatedMessages,
        isLoadingMore: false,
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
      if (message.groupId != null) {
        int? messageGroupId;

        if (message.groupId is int) {
          messageGroupId = message.groupId as int;
        } else if (message.groupId is String) {
          messageGroupId = int.tryParse(message.groupId as String);
        }

        if (messageGroupId == groupId) {
          // For image messages, create a specific ID that includes image URL (if available)
          String messageId;
          final isImageMessage = message.type == MessageType.image || message.imageUrl != null;

          if (isImageMessage && message.imageUrl != null) {
            final shortenedUrl = message.imageUrl!.length > 20
                ? message.imageUrl!.substring(0, 20)
                : message.imageUrl!;
            messageId = '${message.id}-${message.senderId}-image-$shortenedUrl';
          } else {
            messageId = '${message.id}-${message.senderId}-${message.content}-${message.sentAt.millisecondsSinceEpoch}';
          }

          if (!_processedMessageIds.contains(messageId)) {
            print('Adding new message to group chat UI: $messageId');
            _processedMessageIds.add(messageId);

            // Handle image message updates differently
            if (isImageMessage && message.imageUrl != null) {
              // Look for any pending image messages from the same sender
              final updatedMessages = List<Message>.from(state.messages);
              final pendingIndex = updatedMessages.indexWhere((m) =>
                m.type == MessageType.image &&
                m.senderId == message.senderId &&
                (m.imageUrl == null || m.content.contains('[Đang gửi')) &&
                (DateTime.now().difference(m.sentAt).inMinutes < 2)
              );

              if (pendingIndex >= 0) {
                // Replace the pending image message with the new one
                print('Replacing pending image at index $pendingIndex with new image message');
                updatedMessages[pendingIndex] = message;
              } else {
                // If no pending image is found, simply add the new message
                updatedMessages.add(message);
              }

              // Sort messages by time
              updatedMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
              emit(state.copyWith(messages: updatedMessages));
            } else {
              // For non-image messages, simply add to the list
              final updatedMessages = List<Message>.from(state.messages)..add(message);
              updatedMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
              emit(state.copyWith(messages: updatedMessages));
            }
          } else {
            print('Duplicate group message detected, ignoring: $messageId');
          }
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
      final now = DateTime.now();

      // Add temporary message to the UI immediately
      final tempMessage = Message(
        id: tempId,
        senderId: _apiService.currentUserId!,
        groupId: groupId.toString(), // Convert int to String for Message model
        content: content,
        sentAt: now,
        isRead: false,
      );

      print('Created temporary message with groupId (string): ${tempMessage.groupId}');

      // Track the temp message ID to avoid duplicates with multiple formats
      final tempMessageId = '${tempMessage.id}-${tempMessage.senderId}-${tempMessage.content}-${tempMessage.sentAt.millisecondsSinceEpoch}';
      _processedMessageIds.add(tempMessageId);

      // Thêm ID ngắn để tránh trùng lặp tin nhắn từ server
      final shortMessageId = '${tempMessage.senderId}-${tempMessage.content}';
      _processedMessageIds.add(shortMessageId);

      // Thêm ID dựa trên thời gian để tránh trùng lặp
      for (int i = -2; i <= 2; i++) {
        final timeBasedId = '${tempMessage.senderId}-${tempMessage.content}-${now.add(Duration(seconds: i)).millisecondsSinceEpoch}';
        _processedMessageIds.add(timeBasedId);
      }

      final updatedMessages = List<Message>.from(state.messages)..add(tempMessage);
      emit(state.copyWith(
        messages: updatedMessages,
        isSending: true,
        error: null,
      ));

      print('Sending message to group: $groupId');

      // Send message to server - use int for groupId as expected by the API
      await _apiService.sendGroupMessage(
        groupId: groupId, // Pass as int to API
        content: content,
      );

      print('Message sent successfully to group: $groupId');
      emit(state.copyWith(isSending: false, error: null));
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
            groupId: groupId.toString(), // Convert int to String for Message model
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

  Future<void> sendImageMessage() async {
    try {
      emit(state.copyWith(isSending: true, error: null));

      // Sử dụng ImagePicker để chọn ảnh
      final XFile? pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile == null) {
        emit(state.copyWith(isSending: false));
        return;
      }

      final imageFile = File(pickedFile.path);
      _lastImageFile = imageFile; // Lưu file ảnh để có thể retry sau này

      // Tạo ID duy nhất cho tin nhắn ảnh
      final now = DateTime.now();
      final tempId = now.millisecondsSinceEpoch;

      // Tạo tin nhắn tạm thời để hiển thị trước khi upload
      final tempMessage = Message(
        id: tempId,
        senderId: _apiService.currentUserId!,
        groupId: groupId.toString(),
        content: '[Đang gửi hình ảnh...]',
        sentAt: now,
        isRead: false,
        type: MessageType.image,
      );

      // Thêm ID tin nhắn tạm thời để tránh trùng lặp
      final tempMessageId = '${tempMessage.id}-${tempMessage.senderId}-image-pending';
      _processedMessageIds.add(tempMessageId);

      // Thêm tin nhắn tạm thời vào UI
      final updatedMessages = List<Message>.from(state.messages)..add(tempMessage);
      updatedMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      emit(state.copyWith(
        messages: updatedMessages,
        isSending: true,
      ));

      // Gửi ảnh lên server
      try {
        // Thử dùng API upload ảnh chuyên dụng trước
        await _apiService.uploadGroupImage(
          groupId,
          imageFile,
          caption: '[Hình ảnh]',
        );
        // Tin nhắn thực sẽ được cập nhật thông qua stream
      } catch (uploadError) {
        print('Upload API failed, falling back to base64: $uploadError');
        // Nếu API upload thất bại, dùng phương pháp base64
        await _apiService.sendGroupImageAsBase64(
          groupId,
          imageFile,
          caption: '[Hình ảnh]',
        );
      }

      emit(state.copyWith(isSending: false));
    } catch (e) {
      print('Error sending image message: $e');

      // Xử lý lỗi - cập nhật tin nhắn tạm thời thành tin nhắn lỗi
      final messages = List<Message>.from(state.messages);
      if (messages.isNotEmpty) {
        final lastMessage = messages.last;
        if (lastMessage.senderId == _apiService.currentUserId &&
            lastMessage.type == MessageType.image &&
            lastMessage.content == '[Đang gửi hình ảnh...]') {

          messages.removeLast();
          messages.add(Message(
            id: DateTime.now().millisecondsSinceEpoch + 1,
            senderId: _apiService.currentUserId!,
            groupId: groupId.toString(),
            content: '[Lỗi: Không thể gửi hình ảnh]',
            sentAt: DateTime.now(),
            isRead: false,
          ));
        }
      }

      emit(state.copyWith(
        messages: messages,
        isSending: false,
        error: 'Không thể gửi hình ảnh: ${e.toString()}',
      ));
    }
  }

  Future<void> retryImage() async {
    if (_lastImageFile == null) {
      emit(state.copyWith(error: 'Không có hình ảnh để gửi lại'));
      return;
    }

    try {
      emit(state.copyWith(isSending: true, error: null));

      // Tạo ID mới cho lần gửi lại
      final now = DateTime.now();
      final tempId = now.millisecondsSinceEpoch;

      // Tạo tin nhắn tạm thời
      final tempMessage = Message(
        id: tempId,
        senderId: _apiService.currentUserId!,
        groupId: groupId.toString(),
        content: '[Đang gửi lại hình ảnh...]',
        sentAt: now,
        isRead: false,
        type: MessageType.image,
      );

      // Thêm ID tin nhắn tạm thời
      final tempMessageId = '${tempMessage.id}-${tempMessage.senderId}-image-retry';
      _processedMessageIds.add(tempMessageId);

      // Cập nhật UI
      final updatedMessages = List<Message>.from(state.messages)..add(tempMessage);
      emit(state.copyWith(
        messages: updatedMessages,
        isSending: true,
      ));

      // Thử gửi lại ảnh
      String? imageUrl;
      try {
        imageUrl = await _apiService.uploadGroupImage(
          groupId,
          _lastImageFile!,
          caption: '[Hình ảnh]',
        );
      } catch (uploadError) {
        print('Upload API failed, falling back to base64: $uploadError');
        await _apiService.sendGroupImageAsBase64(
          groupId,
          _lastImageFile!,
          caption: '[Hình ảnh]',
        );
      }

      emit(state.copyWith(isSending: false));
    } catch (e) {
      print('Error retrying image: $e');

      // Xử lý lỗi khi gửi lại
      final messages = List<Message>.from(state.messages);
      if (messages.isNotEmpty) {
        final lastMessage = messages.last;
        if (lastMessage.senderId == _apiService.currentUserId &&
            lastMessage.type == MessageType.image &&
            lastMessage.content == '[Đang gửi lại hình ảnh...]') {

          messages.removeLast();
          messages.add(Message(
            id: DateTime.now().millisecondsSinceEpoch + 1,
            senderId: _apiService.currentUserId!,
            groupId: groupId.toString(),
            content: '[Lỗi: Gửi lại hình ảnh thất bại]',
            sentAt: DateTime.now(),
            isRead: false,
          ));
        }
      }

      emit(state.copyWith(
        messages: messages,
        isSending: false,
        error: 'Gửi lại hình ảnh thất bại: ${e.toString()}',
      ));
    }
  }

  void resetAndReloadMessages() {
    _processedMessageIds.clear();
    emit(GroupChatState());
    loadMessages();
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _processedMessageIds.clear();
    return super.close();
  }
} 
