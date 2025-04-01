import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_socket_io/features/chat/cubits/personal/personal_chat_state.dart';
import '../../../../data/models/message.dart';
import '../../../../services/api/chat_api_service.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class PersonalChatCubit extends Cubit<PersonalChatState> {
  final ChatApiService _chatService;
  final String receiverId;
  late StreamSubscription _messageSubscription;
  final Set<String> _processedMessageIds = {};
  File? _lastImageFile;

  PersonalChatCubit(this._chatService, this.receiverId) : super(PersonalChatState()) {
    print('ChatCubit initialized for user: $receiverId');

    // Kiểm tra kết nối SignalR
    if (_chatService.hubConnection.state != HubConnectionState.Connected) {
      print("⚠️ SignalR chưa kết nối. Đang kết nối lại...");

      _chatService.connect();
    }


    print("✅ SignalR trạng thái: ${_chatService.hubConnection.state}");

    // Lắng nghe tin nhắn mới từ SignalR
    _messageSubscription = _chatService.messageStream.listen((message) {
      final currentUserId = _chatService.currentUserId;

      // Chỉ xử lý tin nhắn liên quan đến cuộc trò chuyện hiện tại
      if (currentUserId != null &&
          ((message.senderId == currentUserId && message.receiverId == receiverId) ||
           (message.receiverId == currentUserId && message.senderId == receiverId))) {

        // Tạo ID duy nhất cho tin nhắn để tránh trùng lặp
        final messageId = '${message.id}-${message.senderId}-${message.content}-${message.sentAt.millisecondsSinceEpoch}';

        // Kiểm tra xem tin nhắn đã được xử lý chưa
        if (!_processedMessageIds.contains(messageId)) {
          _processedMessageIds.add(messageId);
          _handleNewMessage(message);
          print('Processed new message: $messageId');
        } else {
          print('Skipped duplicate message: $messageId');
        }
      }
    });

    // Chỉ load tin nhắn ban đầu một lần
    loadMessages();
  }

  void _handleNewMessage(Message message) {
    // Đảm bảo tin nhắn được xử lý đúng cách
    print('Handling new message: ${message.id}, type: ${message.type}, imageUrl: ${message.imageUrl}');

    // Kiểm tra nếu đây là tin nhắn hình ảnh mới (có imageUrl)
    final isFreshImageMessage = message.type == MessageType.image && 
                              message.imageUrl != null && 
                              !message.content.contains('[Đang gửi');
    
    // Tạo danh sách tin nhắn mới để trigger rebuild
    final updatedMessages = List<Message>.from(state.messages);

    // Kiểm tra tin nhắn đã tồn tại chưa - cập nhật cách kiểm tra cho tin nhắn hình ảnh
    int existingIndex = -1;
    
    if (message.type == MessageType.image) {
      // Với tin nhắn hình ảnh từ server (có URL), tìm tất cả tin nhắn ảnh tạm thời để cập nhật
      if (isFreshImageMessage) {
        // Tìm tin nhắn tạm thời "Đang gửi" để thay thế
        existingIndex = updatedMessages.indexWhere((m) =>
          m.type == MessageType.image && 
          m.senderId == message.senderId &&
          m.content.contains('[Đang gửi') && 
          m.imageUrl == null // tin nhắn tạm thời chưa có URL
        );
        
        // Nếu đã có một tin nhắn hoàn chỉnh giống hệt (có cùng URL), bỏ qua
        final hasDuplicateComplete = updatedMessages.any((m) => 
          m.type == MessageType.image && 
          m.imageUrl == message.imageUrl &&
          m.senderId == message.senderId &&
          !m.content.contains('[Đang gửi')
        );
        
        if (hasDuplicateComplete) {
          print('Skipping duplicate complete image message with same URL');
          if (existingIndex >= 0) {
            // Nếu có tin nhắn tạm thời, xóa nó khỏi danh sách
            updatedMessages.removeAt(existingIndex);
            emit(state.copyWith(messages: updatedMessages));
          }
          return;
        }
      } else {
        // Với tin nhắn ảnh tạm thời, kiểm tra đã có chưa
        existingIndex = updatedMessages.indexWhere((m) =>
          m.type == MessageType.image && 
          m.senderId == message.senderId &&
          m.content.contains('[Đang gửi') && 
          m.imageUrl == null
        );
      }
    } else {
      // Với các tin nhắn khác, tìm theo ID hoặc nội dung + thời gian
      existingIndex = updatedMessages.indexWhere((m) =>
        m.id == message.id ||
        (m.senderId == message.senderId &&
         m.receiverId == message.receiverId &&
         m.content == message.content &&
         m.sentAt.difference(message.sentAt).inSeconds.abs() < 5)
      );
    }

    if (existingIndex >= 0) {
      // Cập nhật tin nhắn tạm thời thành tin nhắn thật với URL
      print('Updating existing message at index $existingIndex');
      final existingMessage = updatedMessages[existingIndex];
      print('Old message: ${existingMessage.id}, content: ${existingMessage.content}, imageUrl: ${existingMessage.imageUrl}');
      print('New message: ${message.id}, content: ${message.content}, imageUrl: ${message.imageUrl}');
      
      // Nếu tin nhắn cũ là tạm thời và tin nhắn mới có URL, cập nhật
      if (existingMessage.content.contains('[Đang gửi') && message.imageUrl != null) {
        updatedMessages[existingIndex] = message;
      }
      // Hoặc nếu trùng ID nhưng tin nhắn mới có dữ liệu đầy đủ hơn
      else if (existingMessage.id == message.id && message.imageUrl != null && existingMessage.imageUrl == null) {
        updatedMessages[existingIndex] = message;
      }
    } else {
      // Luôn thêm tin nhắn hình ảnh mới có URL nếu không tìm thấy tin nhắn tương ứng để cập nhật
      if (isFreshImageMessage) {
        // Kiểm tra xem đã có tin nhắn hoàn chỉnh với cùng URL chưa
        final hasDuplicateUrl = updatedMessages.any((m) => 
          m.type == MessageType.image && 
          m.imageUrl == message.imageUrl &&
          m.senderId == message.senderId
        );
        
        if (!hasDuplicateUrl) {
          print('Adding new image message with URL: ${message.imageUrl}');
          updatedMessages.add(message);
        } else {
          print('Skipping duplicate image message with URL: ${message.imageUrl}');
        }
      } 
      // Thêm các tin nhắn khác (không phải ảnh)
      else if (message.type != MessageType.image) {
        print('Adding new non-image message: ${message.id}, type: ${message.type}');
        updatedMessages.add(message);
      }
      // Đối với tin nhắn tạm thời khác, chỉ thêm nếu không có tin nhắn tương tự
      else {
        // Kiểm tra xem đã có tin nhắn tạm thời tương tự chưa
        final hasSimilarTempMessage = updatedMessages.any((m) => 
          m.type == MessageType.image && 
          m.senderId == message.senderId &&
          m.content.contains('[Đang gửi') && 
          m.imageUrl == null);
          
        if (!hasSimilarTempMessage) {
          print('Adding new temporary image message');
          updatedMessages.add(message);
        } else {
          print('Skipping duplicate temporary image message');
        }
      }
    }

    // Sắp xếp tin nhắn theo thời gian
    updatedMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));

    // Gọi phương thức loại bỏ tin nhắn ảnh trùng lặp
    final deduplicatedMessages = _deduplicateImageMessages(updatedMessages);

    // Cập nhật state để trigger rebuild
    emit(state.copyWith(messages: deduplicatedMessages));
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    try {
      emit(state.copyWith(isSending: true));

      // Thêm tin nhắn tạm thời vào danh sách
      final tempMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch,
        senderId: _chatService.currentUserId!,
        receiverId: receiverId,
        content: content,
        sentAt: DateTime.now(),
        isRead: false,
      );

      final updatedMessages = List<Message>.from(state.messages)..add(tempMessage);
      emit(state.copyWith(
        messages: updatedMessages,
        isSending: true,
      ));

      // Gửi tin nhắn
      await _chatService.sendMessage(receiverId, content);

      emit(state.copyWith(isSending: false));
    } catch (e) {
      emit(state.copyWith(isSending: false, error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _messageSubscription.cancel();
    _processedMessageIds.clear();
    return super.close();
  }

  ChatApiService get chatService => _chatService;

  Future<void> loadMessages() async {
    try {
      emit(state.copyWith(isLoading: true, error: null));

      final messages = await _chatService.getChatHistory(receiverId, page: 1);

      // Sắp xếp tin nhắn theo thời gian tăng dần
      messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));

      // Thêm tất cả ID tin nhắn vào danh sách đã xử lý
      for (var message in messages) {
        final messageId = '${message.id}-${message.senderId}-${message.content}-${message.sentAt.millisecondsSinceEpoch}';
        _processedMessageIds.add(messageId);
      }

      // Kiểm tra xem còn tin nhắn để load thêm không
      final hasMore = messages.length >= 20; // Giả sử mỗi trang có 20 tin nhắn

      emit(state.copyWith(
        messages: messages,
        isLoading: false,
        currentPage: 1,
        hasMoreMessages: hasMore,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> loadMoreMessages() async {
    if (!state.hasMoreMessages || state.isLoadingMore) return;

    try {
      print('Loading more messages, current page: ${state.currentPage}');
      emit(state.copyWith(isLoadingMore: true, error: null));

      final nextPage = state.currentPage + 1;
      print('Fetching messages for page: $nextPage');
      final newMessages = await _chatService.getChatHistory(receiverId, page: nextPage);
      print('Fetched ${newMessages.length} older messages');

      if (newMessages.isEmpty) {
        print('No more messages to load');
        emit(state.copyWith(
          isLoadingMore: false,
          hasMoreMessages: false,
        ));
        return;
      }

      // Sắp xếp tin nhắn mới theo thời gian
      newMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));

      // Thêm ID tin nhắn mới vào danh sách đã xử lý
      for (var message in newMessages) {
        final messageId = '${message.id}-${message.senderId}-${message.content}-${message.sentAt.millisecondsSinceEpoch}';
        _processedMessageIds.add(messageId);
      }

      // Kết hợp tin nhắn cũ vào đầu danh sách hiện tại
      final updatedMessages = [...newMessages, ...state.messages];
      
      // Sắp xếp lại toàn bộ danh sách tin nhắn theo thời gian
      updatedMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      
      print('Updated message list now has ${updatedMessages.length} messages');
      
      // Kiểm tra xem còn tin nhắn để load thêm không
      final hasMore = newMessages.length >= 20; // Giả sử mỗi trang có 20 tin nhắn
      print('Has more messages: $hasMore');

      emit(state.copyWith(
        messages: updatedMessages,
        isLoadingMore: false,
        currentPage: nextPage,
        hasMoreMessages: hasMore,
      ));
    } catch (e) {
      print('Error loading more messages: $e');
      emit(state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      ));
    }
  }

  void resetAndReloadMessages() {
    _processedMessageIds.clear();
    emit(PersonalChatState());
    loadMessages();
  }

  // Phương thức mới để loại bỏ các tin nhắn ảnh trùng lặp
  List<Message> _deduplicateImageMessages(List<Message> messages) {
    // Sắp xếp tin nhắn theo thời gian trước
    final sortedMessages = List<Message>.from(messages)
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));

    final result = <Message>[];
    final processedImageIds = <String>{};

    // Xử lý từng tin nhắn theo thứ tự thời gian
    for (final message in sortedMessages) {
      // Tạo ID duy nhất cho tin nhắn ảnh dựa trên URL và ID tin nhắn
      final messageUniqueKey = message.type == MessageType.image
          ? '${message.id}_${message.imageUrl ?? "null"}'
          : message.id.toString();

      // Nếu là tin nhắn ảnh có URL đã xử lý, bỏ qua
      if (message.type == MessageType.image &&
          message.imageUrl != null &&
          processedImageIds.contains(messageUniqueKey)) {
        print('Skipping duplicate image message: $messageUniqueKey');
        continue;
      }

      // Đánh dấu đã xử lý và thêm vào kết quả
      if (message.type == MessageType.image && message.imageUrl != null) {
        processedImageIds.add(messageUniqueKey);
      }

      result.add(message);
    }

    // Sắp xếp lại kết quả theo thời gian để đảm bảo thứ tự đúng
    result.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return result;
  }

  Future<void> sendImage() async {
    try {
      print('Attempting to pick image using Image Picker directly');
      emit(state.copyWith(isSending: true));

      final XFile? pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      print('Image Picker result: ${pickedFile?.path}');

      if (pickedFile == null) {
        print('No image selected');
        emit(state.copyWith(isSending: false));
        return;
      }

      final file = File(pickedFile.path);
      _lastImageFile = file;

      // Tạo ID ngẫu nhiên cho mỗi lần gửi ảnh để đảm bảo mỗi lần gửi đều là duy nhất
      final sendId = DateTime.now().millisecondsSinceEpoch.toString() + '_' + 
                     DateTime.now().microsecondsSinceEpoch.toString();
      
      print('Selected file: ${file.path}, size: ${await file.length()} bytes');
      print('Generated unique send ID: $sendId');

      // Tạo tin nhắn tạm thời cho phiên gửi ảnh này
      final tempMessage = Message(
        id: int.parse(sendId.substring(0, 10)), // Đảm bảo ID không trùng lặp
        senderId: _chatService.currentUserId!,
        receiverId: receiverId,
        content: '[Đang gửi hình ảnh...]',
        sentAt: DateTime.now(),
        isRead: false,
        type: MessageType.image,
      );
      
      // Thêm tin nhắn tạm thời vào danh sách
      final updatedMessages = List<Message>.from(state.messages)..add(tempMessage);
      emit(state.copyWith(messages: updatedMessages, isSending: true));
      
      try {
        // Gửi ảnh không đợi bất kỳ delay nào
        await _chatService.sendImageMessage(receiverId, file);
        
        // Sau khi gửi xong, chỉ cập nhật trạng thái gửi
        emit(state.copyWith(isSending: false));
      } catch (e) {
        print('Error sending image: $e');
        
        // Khi có lỗi, cập nhật tin nhắn tạm thời thành tin nhắn lỗi
        final errorMessageIndex = updatedMessages.indexWhere(
          (m) => m.id == tempMessage.id
        );
        
        if (errorMessageIndex >= 0) {
          // Cập nhật tin nhắn lỗi
          updatedMessages[errorMessageIndex] = Message(
            id: tempMessage.id,
            senderId: _chatService.currentUserId!,
            receiverId: receiverId,
            content: '[Lỗi: không thể gửi hình ảnh]',
            sentAt: DateTime.now(),
            isRead: false,
            type: MessageType.text,
          );
        }
        
        emit(state.copyWith(
          messages: updatedMessages,
          isSending: false, 
          error: 'Lỗi khi gửi ảnh: $e'
        ));
      }
    } catch (e) {
      print('Error picking image: $e');
      emit(state.copyWith(isSending: false, error: 'Lỗi khi chọn ảnh: $e'));
    }
  }

  Future<void> retryImage() async {
    if (_lastImageFile == null) {
      emit(state.copyWith(error: 'Không có hình ảnh để thử lại'));
      return;
    }

    try {
      emit(state.copyWith(isSending: true));
      await _chatService.sendImageMessage(receiverId, _lastImageFile!);
      emit(state.copyWith(isSending: false));
    } catch (e) {
      print('Error retrying image: $e');
      emit(state.copyWith(isSending: false, error: 'Lỗi khi gửi lại ảnh: $e'));
    }
  }


  Future<void> sendImageFromSource(ImageSource source) async {
    try {
      print('Attempting to pick image from source: $source');

      final XFile? pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 70,
      );

      print('Picked file: ${pickedFile?.path}');

      if (pickedFile == null) {
        print('No image selected');
        return;
      }

      emit(state.copyWith(isSending: true));

      final imageFile = File(pickedFile.path);
      await _chatService.sendImageMessage(receiverId, imageFile);

      emit(state.copyWith(isSending: false));
    } catch (e) {
      print('Error picking image: $e');
      emit(state.copyWith(isSending: false, error: 'Lỗi khi chọn ảnh: $e'));
    }
  }

  void sendTypingStatus(String userId, bool isTyping) {
    try {
      final updatedTypingStatus = Map<String, bool>.from(state.typingStatus);
      updatedTypingStatus[userId] = isTyping;
      emit(state.copyWith(typingStatus: updatedTypingStatus));
    } catch (e) {
      print('Error sending typing status: $e');
    }
  }
} 