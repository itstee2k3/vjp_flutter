import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/models/message.dart';
import '../../../../data/models/user.dart';
import '../../../../services/api/group_chat_api_service.dart';
import 'group_chat_state.dart';

const int _pageSize = 20; // Use a consistent name

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

      // final messagesFromServer = await _apiService.getGroupMessages(groupId, page: 1, pageSize: _groupPageSize + 1); // Lấy pageSize + 1 tin nhắn
      final historyResponse = await _apiService.getGroupMessages(groupId, page: 1, pageSize: _pageSize);
      final List<Message> messagesFromServer = historyResponse['messages'] ?? [];
      final bool hasMore = historyResponse['hasMore'] ?? false;

      // Sort messages by time (oldest first) so newest messages appear at the bottom - Handled in service
      // messagesFromServer.sort((a, b) => a.sentAt.compareTo(b.sentAt));

      // Add processed message IDs for deduplication
      for (var message in messagesFromServer) {
        final messageId = '${message.id}-${message.senderId}-${message.content}-${message.sentAt.millisecondsSinceEpoch}';
        _processedMessageIds.add(messageId);
      }

      // final hasMore = messagesFromServer.length > _groupPageSize; // Kiểm tra nếu số lượng tin nhắn lấy về > pageSize - Provided by API

      // print('Loaded ${messagesFromServer.length} group messages (requested ${_groupPageSize + 1})');
      print('Loaded ${messagesFromServer.length} group messages');
      print('Has more messages: $hasMore');

      emit(state.copyWith(
        // messages: messagesFromServer.take(_groupPageSize).toList(), // Chỉ lấy pageSize tin nhắn đầu tiên - API returns correct size
        messages: messagesFromServer,
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
      
      // final messagesFromServer = await _apiService.getGroupMessages(
      //   groupId, 
      //   page: nextPage,
      //   pageSize: _groupPageSize + 1 // Lấy pageSize + 1 tin nhắn
      // );
      final historyResponse = await _apiService.getGroupMessages(groupId, page: nextPage, pageSize: _pageSize);
      final List<Message> messagesFromServer = historyResponse['messages'] ?? [];
      final bool hasMore = historyResponse['hasMore'] ?? false;
      
      // print('Fetched ${messagesFromServer.length} older group messages (requested ${_groupPageSize + 1})');
      print('Fetched ${messagesFromServer.length} older group messages');

      // if (messagesFromServer.isEmpty) {
      if (messagesFromServer.isEmpty && !hasMore) { // Only stop if API confirms no more messages
        print('No more group messages to load');
        emit(state.copyWith(
          isLoadingMore: false,
          hasMoreMessages: false,
        ));
        return;
      }
      
      if (messagesFromServer.isEmpty && hasMore) {
         print('API returned empty group list but hasMore is true. Maybe a temporary issue? Stopping load more for now.');
         emit(state.copyWith(
           isLoadingMore: false, 
           hasMoreMessages: true, // Keep possibility to load more
         ));
         return;
      }

      // Sort older messages by time (oldest first) - Handled in service
      // messagesFromServer.sort((a, b) => a.sentAt.compareTo(b.sentAt));

      // Add processed message IDs for deduplication
      for (var message in messagesFromServer) {
        final messageId = '${message.id}-${message.senderId}-${message.content}-${message.sentAt.millisecondsSinceEpoch}';
        _processedMessageIds.add(messageId);
      }

      // Check if there are more messages to load - Provided by API
      // final hasMore = messagesFromServer.length > _groupPageSize; // Kiểm tra nếu số lượng tin nhắn lấy về > pageSize
      print('Has more group messages: $hasMore');

      // Only take pageSize new messages to display - API returns correct size
      // final messagesToDisplay = messagesFromServer.take(_groupPageSize).toList();

      // Combine older messages with current messages - exactly like PersonalChatCubit
      // final updatedMessages = [...messagesToDisplay, ...state.messages];
      final updatedMessages = [...messagesFromServer, ...state.messages];
      
      // Sort all messages by time (oldest first)
      updatedMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      
      print('Updated group message list now has ${updatedMessages.length} messages');
      

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

          // --- Start: Simplified Echo Check --- 
          bool isSenderMessageEcho = false;
          if (message.senderId == _apiService.currentUserId) {
              // Check primary message ID from SignalR first
              if (_processedMessageIds.contains(messageId)) {
                  print('Echo detected by primary ID: $messageId');
                  isSenderMessageEcho = true;
              }
              // Check if the final ID matches any known placeholder ID (less reliable but a fallback)
              // This requires placeholder IDs to be added to _processedMessageIds when created
              // final placeholderIdCheck = '${message.id}-image-placeholder'; // Assuming placeholder has final ID?
              // if (!isSenderMessageEcho && _processedMessageIds.contains(placeholderIdCheck)) {
              //    print('Echo possibly detected by matching placeholder ID');
              //    isSenderMessageEcho = true;
              // }
          }
          // --- End: Simplified Echo Check ---

          // Check if it's NOT a known duplicate AND if it's not an echo from the sender
          if (!_processedMessageIds.contains(messageId) && !isSenderMessageEcho) {
            print('Adding/Updating message in group chat UI (ID: ${message.id}): $messageId');
            _processedMessageIds.add(messageId); // Add the primary ID from SignalR
            
            // // REMOVE adding other potential IDs here 
            // final shortId = '${message.senderId}-${message.content}';
            // _processedMessageIds.add(shortId);
            //  for (int i = -2; i <= 2; i++) {
            //    final timeBasedId = '${message.senderId}-${message.content}-${message.sentAt.add(Duration(seconds: i)).millisecondsSinceEpoch}';
            //    _processedMessageIds.add(timeBasedId);
            //  }

            // --- Start Refactoring Add/Update Logic --- 
            final updatedMessages = List<Message>.from(state.messages);
            bool listWasModified = false; // Flag to track if we need to emit

            if (isImageMessage && message.imageUrl != null) {
                // Look for the *last* pending image message from the *same sender*
                final pendingIndex = updatedMessages.lastIndexWhere((m) =>
                    m.type == MessageType.image &&
                    m.senderId == message.senderId &&
                    (m.imageUrl == null || m.content.contains('[Đang gửi'))
                );

                if (pendingIndex >= 0) {
                    print('Replacing last pending image from sender ${message.senderId} at index $pendingIndex with final message ID ${message.id}');
                    updatedMessages[pendingIndex] = message; // Replace placeholder with final message
                    listWasModified = true;
                } else {
                    print('No pending image placeholder found for sender ${message.senderId}. Checking for duplicates before adding message ID ${message.id}.');
                    // Check if a complete duplicate already exists before adding
                    final hasCompleteDuplicate = updatedMessages.any((m) =>
                        m.id == message.id &&
                        m.senderId == message.senderId &&
                        m.imageUrl == message.imageUrl); // Check URL too

                    if (!hasCompleteDuplicate) {
                        print('Adding final image message ID ${message.id} as no placeholder or duplicate was found.');
                        updatedMessages.add(message);
                        listWasModified = true;
                    } else {
                        print('Skipping adding complete duplicate image message (ID ${message.id}) received via SignalR');
                    }
                }
            } else if (!isImageMessage) { // Handle non-image messages (text)
                 // Check if a complete duplicate already exists before adding
                 final hasCompleteDuplicate = updatedMessages.any((m) => m.id == message.id && m.senderId == message.senderId); // Check ID and sender
                 if (!hasCompleteDuplicate) {
                    print('Adding text message ID ${message.id}');
                    updatedMessages.add(message);
                    listWasModified = true;
                 } else {
                    print('Skipping adding complete duplicate text message (ID ${message.id}) received via SignalR');
                 }
            }
            // Note: Logic for temporary image messages received via SignalR might be needed
            // if the server sends them, but currently assumed only complete messages come back.

            if (listWasModified) {
                // Sort messages by time only if modified
                updatedMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
                emit(state.copyWith(messages: updatedMessages));
            }
            // --- End Refactoring Add/Update Logic ---
            
          } else {
             if (isSenderMessageEcho) {
                 print('Duplicate group message from self detected (echo), ignoring: $messageId');
             } else {
                 print('Duplicate group message detected (already processed), ignoring: $messageId');
             }
          }
        }
      }
    });
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    try {
      emit(state.copyWith(isSending: true, error: null));

      print('Sending message to group: $groupId');

      // Send message to server - use int for groupId as expected by the API
      // We still call the API, but UI update will rely on SignalR message
      await _apiService.sendGroupMessage(
        groupId: groupId, // Pass as int to API
        content: content,
      );

      print('Message sent successfully to group: $groupId (API call finished)');
      // Don't emit isSending:false immediately, wait for SignalR or handle differently if needed
      // emit(state.copyWith(isSending: false, error: null)); 
      // Consider setting isSending back to false after a short delay or based on SignalR confirmation 
      // for better UX, but for fixing duplication, rely on SignalR message add.
      // For now, let's just ensure isSending becomes false eventually.
      // A simple approach is to set it false after the API call, but acknowledge UI update is separate.
      emit(state.copyWith(isSending: false, error: null));

    } catch (e) {
      print('Error sending message: $e');

      // --- Adjust Error Handling START ---
      // Since we removed optimistic UI, there's no temp message to replace with error.
      // Just show a general error.
      // final messages = List<Message>.from(state.messages);
      // if (messages.isNotEmpty) {
      //   final lastMessage = messages.last;
      //   if (lastMessage.senderId == _apiService.currentUserId && !lastMessage.isRead) {
      //     // Replace the optimistic message with an error message
      //     messages.removeLast();

      //     final errorMessage = Message(
      //       id: DateTime.now().millisecondsSinceEpoch + 1, // Ensure unique ID
      //       senderId: _apiService.currentUserId!,
      //       groupId: groupId.toString(), // Convert int to String for Message model
      //       content: '[Lỗi: Không thể gửi tin nhắn]',
      //       sentAt: DateTime.now(),
      //       isRead: false,
      //     );

      //     messages.add(errorMessage);
      //   }
      // }

      emit(state.copyWith(
        // messages: messages, // Don't modify messages list here
        isSending: false,
        error: 'Không thể gửi tin nhắn: ${e.toString()}',
      ));
      // --- Adjust Error Handling END ---
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
