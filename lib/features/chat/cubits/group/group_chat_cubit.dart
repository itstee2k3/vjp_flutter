import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../data/models/message.dart';
import '../../../../services/api/group_chat_api_service.dart';
import 'group_chat_state.dart';


class GroupChatCubit extends Cubit<GroupChatState> {
  final GroupChatApiService _apiService;
  final int groupId;
  StreamSubscription? _messageSubscription;

  GroupChatCubit({
    required GroupChatApiService apiService,
    required this.groupId,
  }) : _apiService = apiService,
       super(GroupChatState(currentUserId: apiService.currentUserId)) {
    _loadMessages();
    _setupMessageStream();
  }

  Future<void> _loadMessages() async {
    try {
      emit(state.copyWith(isLoading: true));
      final messages = await _apiService.getGroupMessages(groupId);
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
    _apiService.onMessageReceived.listen((message) {
      if (message.groupId != null && int.parse(message.groupId!) == groupId) {
        final updatedMessages = List<Message>.from(state.messages)..add(message);
        emit(state.copyWith(messages: updatedMessages));
      }
    });
  }

  Future<void> sendMessage(String content) async {
    try {
      await _apiService.sendGroupMessage(
        groupId: groupId,
        content: content,
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> sendImageMessage(String content, String imageUrl) async {
    try {
      await _apiService.sendGroupMessage(
        groupId: groupId,
        content: content,
        imageUrl: imageUrl,
        type: 'image',
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void startTyping() {
    emit(state.copyWith(isTyping: true));
  }

  void stopTyping() {
    emit(state.copyWith(isTyping: false));
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    return super.close();
  }
} 
