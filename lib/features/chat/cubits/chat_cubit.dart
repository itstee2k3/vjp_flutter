import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/message.dart';
import '../../../services/api/chat_api_service.dart';
import 'package:signalr_netcore/signalr_client.dart';

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

  ChatCubit(this._chatService, this.receiverId) : super(ChatState()) {
    print('ChatCubit initialized for user: $receiverId');
    
    // Kiểm tra kết nối SignalR
    if (_chatService.hubConnection.state != HubConnectionState.Connected) {
      _chatService.connect();
    }
    
    // Lắng nghe tin nhắn mới từ SignalR
    _messageSubscription = _chatService.messageStream.listen((message) {
      if (message.senderId == receiverId || message.receiverId == receiverId) {
        _handleNewMessage(message);
      }
    });
    
    // Chỉ load tin nhắn ban đầu một lần
    loadMessages();
  }

  void _handleNewMessage(Message message) {
    final processedMessage = Message(
      id: message.id,
      senderId: message.senderId,
      receiverId: message.receiverId,
      content: message.content,
      sentAt: message.sentAt,
      isRead: message.isRead,
    );

    // Tạo danh sách tin nhắn mới để trigger rebuild
    final updatedMessages = List<Message>.from(state.messages);
    
    // Kiểm tra tin nhắn đã tồn tại chưa
    final existingIndex = updatedMessages.indexWhere((m) => 
      m.id == processedMessage.id || 
      (m.content == processedMessage.content && 
       m.senderId == processedMessage.senderId &&
       m.sentAt.difference(processedMessage.sentAt).inSeconds.abs() < 2)
    );

    if (existingIndex != -1) {
      updatedMessages[existingIndex] = processedMessage;
    } else {
      updatedMessages.add(processedMessage);
    }

    // Sắp xếp và emit state mới
    updatedMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    emit(state.copyWith(messages: updatedMessages));

    // Thêm print để debug
    print('New message handled: ${processedMessage.content}');
    print('Total messages: ${updatedMessages.length}');
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
    emit(ChatState());
    loadMessages();
  }
} 