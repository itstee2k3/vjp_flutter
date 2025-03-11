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
  Timer? _syncTimer;

  ChatCubit(this._chatService, this.receiverId) : super(ChatState()) {
    print('ChatCubit initialized for user: $receiverId');
    print('Current user ID: ${_chatService.currentUserId}');
    
    // Kiểm tra kết nối SignalR
    if (_chatService.hubConnection.state != HubConnectionState.Connected) {
      print('SignalR not connected in ChatCubit, connecting...');
      _chatService.connect();
    }
    
    // Lắng nghe tin nhắn mới từ SignalR
    _messageSubscription = _chatService.messageStream.listen((message) {
      if (message.senderId == receiverId || message.receiverId == receiverId) {
        print('=== Processing Realtime Message ===');
        print('Message time before: ${message.sentAt}');
        
        // Tạo bản sao của tin nhắn với thời gian UTC
        final processedMessage = Message(
          id: message.id,
          senderId: message.senderId,
          receiverId: message.receiverId,
          content: message.content,
          sentAt: message.sentAt, // Giữ nguyên thời gian
          isRead: message.isRead,
        );
        
        print('Message time after: ${processedMessage.sentAt}');
        
        // Kiểm tra xem tin nhắn đã tồn tại chưa
        final existingIndex = state.messages.indexWhere((m) => 
          m.id == processedMessage.id || 
          (m.content == processedMessage.content && 
           m.senderId == processedMessage.senderId &&
           m.sentAt.difference(processedMessage.sentAt).inSeconds.abs() < 2)
        );
        
        final updatedMessages = List<Message>.from(state.messages);
        
        if (existingIndex != -1) {
          // Cập nhật tin nhắn hiện có
          print('Updating existing message');
          updatedMessages[existingIndex] = processedMessage;
        } else {
          // Thêm tin nhắn mới
          print('Adding new message');
          updatedMessages.add(processedMessage);
        }
        
        // Sắp xếp lại tin nhắn
        updatedMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
        
        emit(state.copyWith(messages: updatedMessages));
        print('=== End Processing ===');
      }
    });
    
    // Tải tin nhắn ban đầu
    loadMessages();
    
    // Thêm đồng bộ định kỳ
    _startPeriodicSync();
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      print('Performing periodic sync');
      syncMessages();
    });
  }

  Future<void> loadMessages({int page = 1}) async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      
      final messages = await _chatService.getChatHistory(receiverId, page: page);
      
      // Thêm tất cả tin nhắn đã tải vào danh sách đã xử lý
      for (var message in messages) {
        String messageUniqueId = '${message.id ?? ''}|${message.senderId}|${message.content}|${message.sentAt.toIso8601String()}';
        _processedMessageIds.add(messageUniqueId);
      }
      
      // Sắp xếp tin nhắn theo thời gian tăng dần (cũ nhất lên đầu)
      messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      
      if (page == 1) {
        emit(state.copyWith(
          messages: messages,
          isLoading: false,
        ));
      } else {
        // Nối tin nhắn mới vào danh sách hiện tại
        final updatedMessages = List<Message>.from(state.messages)..addAll(messages);
        // Sắp xếp lại toàn bộ danh sách
        updatedMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
        emit(state.copyWith(
          messages: updatedMessages,
          isLoading: false,
        ));
      }
    } catch (e) {
      print('Error loading messages: $e');
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    
    try {
      // Tạo tin nhắn tạm thời với thời gian local
      final tempMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch,
        senderId: _chatService.currentUserId!,
        receiverId: receiverId,
        content: content,
        // Chuyển thời gian local sang UTC để đồng nhất với server
        sentAt: DateTime.now().toUtc(),
        isRead: false,
      );
      
      // Thêm tin nhắn tạm vào UI
      final updatedMessages = List<Message>.from(state.messages)..add(tempMessage);
      updatedMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      emit(state.copyWith(
        messages: updatedMessages,
        isSending: true,
      ));
      
      // Gửi tin nhắn và đợi response từ server
      await _chatService.sendMessage(receiverId, content);
      
      // Sau khi gửi thành công, sync lại tin nhắn để lấy thời gian chính xác từ server
      await syncMessages();
      
      emit(state.copyWith(isSending: false));
    } catch (e) {
      print('Error sending message: $e');
      emit(state.copyWith(
        isSending: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> syncMessages() async {
    try {
      print('Syncing messages...');
      final messages = await _chatService.getChatHistory(receiverId, page: 1);
      
      // Sắp xếp tin nhắn theo thời gian tăng dần
      messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      
      // Tìm tin nhắn mới
      final existingIds = state.messages
          .where((m) => m.id != null && m.id! < 1000000000000) // Chỉ xét các tin nhắn không phải tạm thời
          .map((m) => m.id)
          .toSet();
      
      final newMessages = messages.where((m) => m.id != null && !existingIds.contains(m.id)).toList();
      
      if (newMessages.isNotEmpty) {
        print('Found ${newMessages.length} new messages during sync');
        
        // Thêm tất cả tin nhắn mới vào danh sách đã xử lý
        for (var message in newMessages) {
          String messageUniqueId = '${message.id ?? ''}|${message.senderId}|${message.content}|${message.sentAt.toIso8601String()}';
          _processedMessageIds.add(messageUniqueId);
        }
        
        final updatedMessages = List<Message>.from(state.messages);
        
        // Thay thế các tin nhắn tạm thời bằng tin nhắn thật
        for (int i = updatedMessages.length - 1; i >= 0; i--) {
          final tempMessage = updatedMessages[i];
          
          if (tempMessage.id != null && tempMessage.id! > 1000000000000) {
            // Tìm tin nhắn thật tương ứng
            final matchingMessages = newMessages.where(
              (m) => m.content == tempMessage.content && m.senderId == tempMessage.senderId
            ).toList();
            
            if (matchingMessages.isNotEmpty) {
              print('Replacing temporary message with real message during sync');
              updatedMessages[i] = matchingMessages.first;
              // Xóa tin nhắn đã khớp khỏi danh sách tin nhắn mới để tránh thêm lại
              newMessages.remove(matchingMessages.first);
            }
          }
        }
        
        // Thêm các tin nhắn mới còn lại
        updatedMessages.addAll(newMessages);
        
        // Sắp xếp lại và cập nhật state
        updatedMessages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
        emit(state.copyWith(messages: updatedMessages));
      } else {
        print('No new messages found during sync');
      }
    } catch (e) {
      print('Error syncing messages: $e');
    }
  }

  @override
  Future<void> close() {
    _messageSubscription.cancel();
    _syncTimer?.cancel();
    _processedMessageIds.clear();
    return super.close();
  }

  ChatApiService get chatService => _chatService;

  void resetAndReloadMessages() {
    emit(ChatState());
    loadMessages();
  }
} 