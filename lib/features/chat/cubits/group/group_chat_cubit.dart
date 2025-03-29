import 'dart:async';
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
      emit(state.copyWith(isLoading: true));
      final messages = await _apiService.getGroupMessages(groupId);
      
      // Add processed message IDs
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
        error: e.toString(),
        isLoading: false,
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
    try {
      emit(state.copyWith(isSending: true));
      
      // Add temporary message
      final tempMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch,
        senderId: _apiService.currentUserId!,
        groupId: groupId.toString(),
        content: content,
        sentAt: DateTime.now(),
        isRead: false,
      );
      
      final updatedMessages = List<Message>.from(state.messages)..add(tempMessage);
      emit(state.copyWith(
        messages: updatedMessages,
        isSending: true,
      ));

      // Send message
      await _apiService.sendGroupMessage(
        groupId: groupId,
        content: content,
      );

      emit(state.copyWith(isSending: false));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isSending: false,
      ));
    }
  }

  Future<void> sendImageMessage(String content, String imageUrl) async {
    try {
      emit(state.copyWith(isSending: true));
      
      // Add temporary message
      final tempMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch,
        senderId: _apiService.currentUserId!,
        groupId: groupId.toString(),
        content: content,
        sentAt: DateTime.now(),
        isRead: false,
        type: MessageType.image,
        imageUrl: imageUrl,
      );
      
      final updatedMessages = List<Message>.from(state.messages)..add(tempMessage);
      emit(state.copyWith(
        messages: updatedMessages,
        isSending: true,
      ));

      // Send message
      await _apiService.sendGroupMessage(
        groupId: groupId,
        content: content,
        imageUrl: imageUrl,
        type: 'image',
      );

      emit(state.copyWith(isSending: false));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isSending: false,
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
