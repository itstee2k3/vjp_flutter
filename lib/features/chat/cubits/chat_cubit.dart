import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/message.dart';
import '../../../services/api/chat_api_service.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

// States
class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final String? error;
  final bool isSending;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.isSending = false,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
    bool? isSending,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSending: isSending ?? this.isSending,
    );
  }
}

class ChatCubit extends Cubit<ChatState> {
  final ChatApiService _chatService;
  final String receiverId;
  late StreamSubscription _messageSubscription;
  final Set<String> _processedMessageIds = {};
  File? _lastImageFile;

  ChatCubit(this._chatService, this.receiverId) : super(ChatState()) {
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
    print('Handling new message: ${message.id}, type: ${message.type}');
    
    // Tạo danh sách tin nhắn mới để trigger rebuild
    final updatedMessages = List<Message>.from(state.messages);
    
    // Kiểm tra tin nhắn đã tồn tại chưa
    final existingIndex = updatedMessages.indexWhere((m) => 
      m.id == message.id || 
      (m.senderId == message.senderId && 
       m.receiverId == message.receiverId &&
       ((m.type == MessageType.image && message.type == MessageType.image) ||
        (m.content == message.content && 
         m.sentAt.difference(message.sentAt).inSeconds.abs() < 5)))
    );
    
    if (existingIndex >= 0) {
      // Cập nhật tin nhắn hiện có
      print('Updating existing message at index $existingIndex');
      updatedMessages[existingIndex] = message;
    } else {
      // Thêm tin nhắn mới
      print('Adding new message');
      updatedMessages.add(message);
    }
    
    // Sắp xếp tin nhắn theo thời gian
    updatedMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    
    // Cập nhật state để trigger rebuild
    emit(state.copyWith(messages: updatedMessages));
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
      
      emit(state.copyWith(
        messages: messages,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  void resetAndReloadMessages() {
    _processedMessageIds.clear();
    emit(ChatState());
    loadMessages();
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
      
      print('Selected file: ${file.path}, size: ${await file.length()} bytes');
      
      try {
        await _chatService.sendImageMessage(receiverId, file);
        emit(state.copyWith(isSending: false));
      } catch (e) {
        print('Error sending image: $e');
        emit(state.copyWith(isSending: false, error: 'Lỗi khi gửi ảnh: $e'));
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

  // Phương thức hiển thị dialog chọn nguồn hình ảnh
  Future<ImageSource?> _showImageSourceDialog() async {
    // Phương thức này cần được triển khai để hiển thị dialog chọn nguồn hình ảnh
    // Nhưng hiện tại nó đang trả về null, nên cần cập nhật
    
    // Bạn có thể sử dụng BuildContext để hiển thị dialog, nhưng điều này không khả thi trong Cubit
    // Thay vào đó, bạn có thể sử dụng một callback hoặc một stream để thông báo cho UI hiển thị dialog
    
    // Tạm thời, bạn có thể hardcode một giá trị để test:
    return ImageSource.gallery;
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
} 