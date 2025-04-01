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
      
      final messagesFromServer = result['messages'] as List<Message>;
      final hasMore = result['hasMore'] as bool;
      
      // Lọc bỏ tin nhắn trùng lặp
      final uniqueMessages = _removeDuplicateMessages(messagesFromServer);
      
      // Add processed message IDs
      for (var message in uniqueMessages) {
        final isImageMessage = message.type == MessageType.image || message.imageUrl != null;
        
        String messageId;
        if (isImageMessage) {
          final shortenedUrl = message.imageUrl != null && message.imageUrl!.length > 20
              ? message.imageUrl!.substring(0, 20) 
              : message.imageUrl ?? '';
          messageId = '${message.id}-${message.senderId}-image-$shortenedUrl';
        } else {
          messageId = '${message.id}-${message.senderId}-${message.content}-${message.sentAt.millisecondsSinceEpoch}';
        }
        
        _processedMessageIds.add(messageId);
      }
      
      // Sort messages by time (oldest first for proper display)
      uniqueMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      
      print('Loaded ${messagesFromServer.length} group messages, filtered to ${uniqueMessages.length} unique messages');
      print('Has more messages: $hasMore');
      
      emit(state.copyWith(
        messages: uniqueMessages,
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
      
      final messagesFromServer = result['messages'] as List<Message>;
      final hasMore = result['hasMore'] as bool;
      
      print('Fetched ${messagesFromServer.length} older group messages');

      if (messagesFromServer.isEmpty) {
        print('No more group messages to load');
        emit(state.copyWith(
          isLoadingMore: false,
          hasMoreMessages: false,
        ));
        return;
      }

      // Lọc bỏ tin nhắn trùng lặp và đã tồn tại trong state
      final filteredMessages = _filterNewUniqueMessages(messagesFromServer);

      // Add processed message IDs
      for (var message in filteredMessages) {
        final isImageMessage = message.type == MessageType.image || message.imageUrl != null;
        
        String messageId;
        if (isImageMessage) {
          final shortenedUrl = message.imageUrl != null && message.imageUrl!.length > 20
              ? message.imageUrl!.substring(0, 20) 
              : message.imageUrl ?? '';
          messageId = '${message.id}-${message.senderId}-image-$shortenedUrl';
        } else {
          messageId = '${message.id}-${message.senderId}-${message.content}-${message.sentAt.millisecondsSinceEpoch}';
        }
        
        _processedMessageIds.add(messageId);
      }

      // Sort new messages by time (oldest first)
      filteredMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      
      // Combine old messages with current messages
      final updatedMessages = [...filteredMessages, ...state.messages];
      
      print('Loaded ${messagesFromServer.length} messages, filtered to ${filteredMessages.length} unique messages');
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
      // Check for group message: groupId should match our current groupId
      if (message.groupId != null) {
        // Convert the groupId to int for comparison since our current groupId is int
        int? messageGroupId;
        
        if (message.groupId is int) {
          messageGroupId = message.groupId as int;
        } else if (message.groupId is String) {
          messageGroupId = int.tryParse(message.groupId as String);
        }
        
        // Compare the parsed groupId with our current groupId
        if (messageGroupId == groupId) {
          final isImageMessage = message.type == MessageType.image || message.imageUrl != null;
          
          // Tạo hai loại messageId để kiểm tra trùng lặp
          // 1. ID thông thường với tất cả thông tin
          String messageId;
          if (isImageMessage) {
            // Tạo ID đặc biệt cho tin nhắn hình ảnh
            final shortenedUrl = message.imageUrl != null && message.imageUrl!.length > 20
                ? message.imageUrl!.substring(0, 20)
                : message.imageUrl ?? '';
            messageId = '${message.id}-${message.senderId}-image-$shortenedUrl';
          } else {
            messageId = '${message.id}-${message.senderId}-${message.content}-${message.sentAt.millisecondsSinceEpoch}';
          }
          
          // 2. ID rút gọn chỉ với nội dung và thời gian gần đây, cho tin nhắn người dùng vừa gửi
          final shortMessageId = isImageMessage
              ? '${message.senderId}-image-${message.content}'
              : '${message.senderId}-${message.content}';
              
          final isRecentMessage = DateTime.now().difference(message.sentAt).inSeconds < 5; // Tin nhắn trong vòng 5 giây

          print('Received group message: $messageId, isImage: $isImageMessage');
          
          // Đây là tin nhắn của người dùng hiện tại và gửi gần đây
          final isSenderCurrentUser = message.senderId == _apiService.currentUserId;
          
          // Kiểm tra đặc biệt cho tin nhắn hình ảnh
          if (isImageMessage) {
            // Nếu là tin nhắn hình ảnh từ người dùng hiện tại, kiểm tra xem đã có tin ảnh tạm thời chưa
            final hasPendingImage = isSenderCurrentUser && 
                state.messages.any((m) => 
                  m.senderId == message.senderId && 
                  m.type == MessageType.image && 
                  (m.imageUrl == 'pending_upload' || m.imageUrl == null));
                
            if (hasPendingImage) {
              print('Replacing pending image with actual image from server');
              
              // Thay thế tin nhắn ảnh tạm thời bằng tin nhắn từ server
              final updatedMessages = state.messages.map((m) {
                if (m.senderId == message.senderId && 
                    m.type == MessageType.image && 
                    (m.imageUrl == 'pending_upload' || m.imageUrl == null)) {
                  // Đánh dấu ID mới để tránh xử lý lại
                  _processedMessageIds.add(messageId);
                  return message;
                }
                return m;
              }).toList();
              
              emit(state.copyWith(messages: updatedMessages));
              return;
            }
          }
          
          if (!_processedMessageIds.contains(messageId)) {
            // Kiểm tra thêm cho trường hợp tin nhắn của người dùng hiện tại vừa gửi
            final isDuplicateRecentMessage = isSenderCurrentUser && isRecentMessage &&
                state.messages.any((m) {
                  if (isImageMessage) {
                    // Với hình ảnh, so sánh kiểu tin nhắn
                    return m.senderId == message.senderId && 
                           m.type == MessageType.image &&
                           m.sentAt.difference(message.sentAt).inSeconds.abs() < 10;
                  } else {
                    // Với văn bản, so sánh nội dung
                    return m.senderId == message.senderId && 
                           m.content == message.content &&
                           m.sentAt.difference(message.sentAt).inSeconds.abs() < 5;
                  }
                });
            
            if (isDuplicateRecentMessage) {
              print('Detected duplicate recent message by current user, ignoring');
              return;
            }
            
            print('Adding new message to group chat UI: $messageId');
            _processedMessageIds.add(messageId);
            
            // Thêm shortMessageId vào set nếu là tin nhắn của người dùng hiện tại
            if (isSenderCurrentUser) {
              _processedMessageIds.add(shortMessageId);
            }
            
            final updatedMessages = List<Message>.from(state.messages)..add(message);
            // Sort messages by time
            updatedMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
            emit(state.copyWith(messages: updatedMessages));
          } else {
            print('Duplicate group message detected, ignoring: $messageId');
          }
        } else {
          print('Message not for this group. Message groupId: $messageGroupId, current groupId: $groupId');
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

  Future<void> sendImageMessage(File imageFile, {String caption = ''}) async {
    try {
      emit(state.copyWith(isSending: true, error: null));
      
      // Tạo một ID duy nhất dựa trên thời gian và nội dung ảnh
      final now = DateTime.now();
      final imageFileSize = await imageFile.length();
      final imageFileName = imageFile.path.split('/').last;
      final uniqueImageId = '$imageFileName-$imageFileSize-${now.millisecondsSinceEpoch}';
      
      // Kiểm tra xem ảnh này đã được gửi gần đây chưa
      final hasSentSimilarImage = state.messages.any((m) => 
        m.type == MessageType.image && 
        m.senderId == _apiService.currentUserId &&
        now.difference(m.sentAt).inSeconds < 5); // Kiểm tra 5 giây gần đây
      
      if (hasSentSimilarImage) {
        print('Preventing duplicate image send: Similar image was sent in the last 5 seconds.');
        emit(state.copyWith(
          isSending: false,
          error: 'Đang xử lý ảnh trước, vui lòng đợi...'
        ));
        return;
      }
      
      // Add temporary message
      final tempId = DateTime.now().millisecondsSinceEpoch;
      final tempMessage = Message(
        id: tempId,
        senderId: _apiService.currentUserId!,
        groupId: groupId.toString(), // Convert to String for Message model
        content: caption.isEmpty ? '[Hình ảnh]' : caption,
        sentAt: now,
        isRead: false,
        type: MessageType.image,
        // Use a placeholder for now
        imageUrl: 'pending_upload',
      );
      
      print('Created temporary image message with groupId (string): ${tempMessage.groupId}');
      
      // Track the temp message with multiple ID formats 
      // ID dạng đầy đủ với chi tiết tin nhắn
      final tempMessageId = '${tempMessage.id}-${tempMessage.senderId}-image-pending_upload';
      _processedMessageIds.add(tempMessageId);
      
      // ID dạng ngắn với nội dung
      final shortMessageId = '${tempMessage.senderId}-${tempMessage.content}-image';
      _processedMessageIds.add(shortMessageId);
      
      // Thêm ID dựa trên độ nhận diện duy nhất của ảnh này
      final uniqueImageSignature = '${_apiService.currentUserId}-image-$uniqueImageId';
      _processedMessageIds.add(uniqueImageSignature);
      
      // Thêm ID dựa trên thời gian để tránh trùng lặp trong khoảng thời gian ngắn
      // Thêm ID trong khoảng từ hiện tại đến 3 giây sau để ngăn chặn các tin nhắn trùng lặp từ server
      for (int i = -1; i <= 3; i++) {
        final timeBasedId = '${tempMessage.senderId}-image-${now.add(Duration(seconds: i)).millisecondsSinceEpoch ~/ 1000}';
        _processedMessageIds.add(timeBasedId);
      }
      
      final updatedMessages = List<Message>.from(state.messages)..add(tempMessage);
      emit(state.copyWith(
        messages: updatedMessages,
        isSending: true,
        error: null,
      ));

      print('Sending image for group: $groupId (int)');
      
      String? imageUrl;
      bool useFallback = false;
      
      // Try to use the API if it exists, otherwise send as base64
      try {
        // First try to use the dedicated image upload API
        imageUrl = await _apiService.uploadGroupImage(
          groupId, // Pass as int to API 
          imageFile,
          caption: caption.isEmpty ? '[Hình ảnh]' : caption
        );
        
        // Kiểm tra kết quả đặc biệt báo hiệu cần fallback
        if (imageUrl == 'fallback_to_base64') {
          print('Server indicated to use base64 fallback');
          useFallback = true;
        } else {
          print('Image uploaded successfully, URL: $imageUrl');
          
          // Đã tải lên thành công, nên cập nhật UI và không cần gửi lại tin nhắn qua API
          // Chúng ta sẽ nhận được tin nhắn thông qua SignalR
          
          // Cập nhật tin nhắn tạm thời với URL ảnh thật
          final updatedMessages = state.messages.map((m) {
            if (m.id == tempId && m.senderId == _apiService.currentUserId && m.imageUrl == 'pending_upload') {
              return Message(
                id: m.id,
                senderId: m.senderId,
                groupId: m.groupId,
                content: m.content,
                sentAt: m.sentAt,
                isRead: m.isRead,
                type: MessageType.image,
                imageUrl: imageUrl,
              );
            }
            return m;
          }).toList();
          
          emit(state.copyWith(
            messages: updatedMessages,
            isSending: false,
            error: null,
          ));
        }
      } catch (uploadError) {
        print('Dedicated upload API failed, falling back to base64: $uploadError');
        useFallback = true;
      }
      
      // Sử dụng fallback nếu cần
      if (useFallback) {
        try {
          print('Using base64 fallback method');
          // If the upload API fails, fallback to base64
          await _apiService.sendGroupImageAsBase64(
            groupId, // Pass as int to API
            imageFile,
            caption: caption.isEmpty ? '[Hình ảnh]' : caption,
          );
          
          print('Base64 image sent successfully');
          
          // Tin nhắn sẽ được cập nhật tự động thông qua SignalR
          // Chúng ta giữ nguyên tin nhắn tạm thời, tin nhắn thật sẽ thay thế nó
        } catch (base64Error) {
          print('Base64 fallback also failed: $base64Error');
          throw base64Error; // Rethrow để xử lý ở catch bên ngoài
        }
      }

      print('Image message sent successfully to group: $groupId');
      emit(state.copyWith(isSending: false, error: null));
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
            groupId: groupId.toString(), // Convert to String for Message model
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

  // Phương thức loại bỏ tin nhắn trùng lặp
  List<Message> _removeDuplicateMessages(List<Message> messages) {
    final uniqueMessages = <Message>[];
    final processedIds = <String>{};
    final processedImageSenderTime = <String>{};
    final processedImageContent = <String>{};
    
    // Đầu tiên sắp xếp tin nhắn theo thời gian để đảm bảo xử lý theo thứ tự
    messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));

    for (var message in messages) {
      final isImageMessage = message.type == MessageType.image || message.imageUrl != null;
      
      // Tạo một ID duy nhất dựa trên loại tin nhắn
      String uniqueId;
      
      if (isImageMessage) {
        // ID duy nhất cho tin nhắn
        final serverMessageId = '${message.id}-${message.senderId}';
        
        // Kiểm tra tin nhắn đã tồn tại chưa
        if (processedIds.contains(serverMessageId)) {
          print('Filtering out duplicate image message ID: $serverMessageId');
          continue;
        }
        
        // Với ảnh, kết hợp senderId và thời gian với độ chính xác cao hơn
        // Thời gian chính xác đến 1 giây thay vì 5 giây
        final timeKey1s = message.sentAt.millisecondsSinceEpoch ~/ 1000;
        final timeBasedId1s = '${message.senderId}-image-$timeKey1s';
        
        // Tạo ID với độ chính xác 5 giây cho khả năng tương thích ngược
        final timeKey5s = message.sentAt.millisecondsSinceEpoch ~/ 5000;
        uniqueId = '${message.senderId}-image-$timeKey5s';
        
        // Kiểm tra xem có phải ảnh trùng lặp không, với độ chính xác 1 giây
        if (processedImageSenderTime.contains(timeBasedId1s)) {
          print('Filtering out duplicate image message with same sender and time (1s): ${message.id}');
          continue;
        }
        
        // Thêm cả ID 1 giây và 5 giây vào danh sách đã xử lý
        processedIds.add(serverMessageId);
        processedImageSenderTime.add(timeBasedId1s);
        processedImageSenderTime.add(uniqueId);
        
        // Thêm kiểm tra trùng lặp nội dung ảnh
        if (message.imageUrl != null) {
          // Rút gọn URL ảnh để lấy phần quan trọng
          String shortenedImageUrl = message.imageUrl!;
          // Lấy phần cuối cùng của URL (tên file)
          if (shortenedImageUrl.contains('/')) {
            shortenedImageUrl = shortenedImageUrl.split('/').last;
          }
          
          if (processedImageContent.contains(shortenedImageUrl)) {
            print('Filtering out duplicate image with same URL: $shortenedImageUrl');
            continue;
          }
          
          processedImageContent.add(shortenedImageUrl);
        }
      } else {
        // Với tin nhắn văn bản, sử dụng ID, senderId và nội dung
        uniqueId = '${message.id}-${message.senderId}-${message.content}';
        
        if (processedIds.contains(uniqueId)) {
          print('Filtering out duplicate text message: $uniqueId');
          continue;
        }
        
        processedIds.add(uniqueId);
      }
      
      uniqueMessages.add(message);
    }
    
    print('Filtered ${messages.length} messages to ${uniqueMessages.length} unique messages');
    return uniqueMessages;
  }

  // Phương thức lọc tin nhắn mới và duy nhất
  List<Message> _filterNewUniqueMessages(List<Message> newMessages) {
    final filteredMessages = <Message>[];
    final processedIds = <String>{};
    final processedImageSenderTime = <String>{};
    final processedImageContent = <String>{};
    
    // Tạo các tập ID cho tin nhắn hiện tại
    final existingImageSenderTimes = <String>{};
    final existingImageUrls = <String>{};
    final existingMessageIds = <String>{};
    
    // Đầu tiên sắp xếp tin nhắn theo thời gian để đảm bảo xử lý theo thứ tự
    newMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    
    for (var message in state.messages) {
      final isImageMessage = message.type == MessageType.image || message.imageUrl != null;
      
      if (isImageMessage) {
        // Thêm ID dựa trên thời gian với độ chính xác 1 giây
        final timeKey1s = message.sentAt.millisecondsSinceEpoch ~/ 1000;
        existingImageSenderTimes.add('${message.senderId}-image-$timeKey1s');
        
        // Thêm ID dựa trên thời gian với độ chính xác 5 giây
        final timeKey5s = message.sentAt.millisecondsSinceEpoch ~/ 5000;
        existingImageSenderTimes.add('${message.senderId}-image-$timeKey5s');
        
        // Lưu URL ảnh để kiểm tra trùng lặp
        if (message.imageUrl != null) {
          String shortenedImageUrl = message.imageUrl!;
          if (shortenedImageUrl.contains('/')) {
            shortenedImageUrl = shortenedImageUrl.split('/').last;
          }
          existingImageUrls.add(shortenedImageUrl);
        }
      } else {
        existingMessageIds.add('${message.id}-${message.senderId}-${message.content}');
      }
    }

    for (var message in newMessages) {
      final isImageMessage = message.type == MessageType.image || message.imageUrl != null;
      
      // Tạo một ID duy nhất dựa trên loại tin nhắn
      String uniqueId;
      
      if (isImageMessage) {
        // ID duy nhất cho tin nhắn
        final serverMessageId = '${message.id}-${message.senderId}';
        
        // Kiểm tra tin nhắn đã tồn tại trong danh sách đang xử lý
        if (processedIds.contains(serverMessageId)) {
          print('Filtering out duplicate image message ID within new messages: $serverMessageId');
          continue;
        }
        
        // Với ảnh, tạo ID thời gian với độ chính xác 1 giây
        final timeKey1s = message.sentAt.millisecondsSinceEpoch ~/ 1000;
        final timeBasedId1s = '${message.senderId}-image-$timeKey1s';
        
        // Tạo ID với độ chính xác 5 giây
        final timeKey5s = message.sentAt.millisecondsSinceEpoch ~/ 5000;
        uniqueId = '${message.senderId}-image-$timeKey5s';
        
        // Kiểm tra xem ảnh đã tồn tại trong state hiện tại chưa (dùng cả 2 cấp độ chính xác)
        if (existingImageSenderTimes.contains(timeBasedId1s) || 
            existingImageSenderTimes.contains(uniqueId)) {
          print('Skipping image message already in current state based on time: ${message.id}');
          continue;
        }
        
        // Kiểm tra xem có phải ảnh trùng lặp trong tin nhắn mới không
        if (processedImageSenderTime.contains(timeBasedId1s)) {
          print('Filtering out duplicate image in new messages based on time (1s): ${message.id}');
          continue;
        }
        
        // Thêm cả ID 1 giây và 5 giây vào danh sách đã xử lý
        processedIds.add(serverMessageId);
        processedImageSenderTime.add(timeBasedId1s);
        processedImageSenderTime.add(uniqueId);
        
        // Thêm kiểm tra trùng lặp nội dung ảnh
        if (message.imageUrl != null) {
          String shortenedImageUrl = message.imageUrl!;
          if (shortenedImageUrl.contains('/')) {
            shortenedImageUrl = shortenedImageUrl.split('/').last;
          }
          
          // Kiểm tra URL đã tồn tại trong state hiện tại chưa
          if (existingImageUrls.contains(shortenedImageUrl)) {
            print('Skipping image message with URL already in current state: $shortenedImageUrl');
            continue;
          }
          
          // Kiểm tra URL đã tồn tại trong danh sách mới chưa
          if (processedImageContent.contains(shortenedImageUrl)) {
            print('Filtering out duplicate image with same URL in new messages: $shortenedImageUrl');
            continue;
          }
          
          processedImageContent.add(shortenedImageUrl);
        }
      } else {
        // Với tin nhắn văn bản, sử dụng ID, senderId và nội dung
        uniqueId = '${message.id}-${message.senderId}-${message.content}';
        
        // Kiểm tra xem tin nhắn đã tồn tại trong state hiện tại chưa
        if (existingMessageIds.contains(uniqueId)) {
          print('Skipping text message already in current state: ${message.id}');
          continue;
        }
        
        if (processedIds.contains(uniqueId)) {
          print('Filtering out duplicate text message in new messages: ${message.id}');
          continue;
        }
        
        processedIds.add(uniqueId);
      }
      
      filteredMessages.add(message);
    }
    
    print('Filtered ${newMessages.length} new messages to ${filteredMessages.length} unique messages');
    return filteredMessages;
  }
}
