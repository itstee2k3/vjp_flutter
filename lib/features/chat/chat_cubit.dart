import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../data/model/message.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  late IO.Socket _socket;

  ChatCubit(String username) : super(const ChatState()) {
    _connectSocket(username);
  }

  void _connectSocket(String username) {
    _socket = IO.io(
      Platform.isIOS ? 'http://127.0.0.1:3000' : 'http://10.0.2.2:3000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'username': username})
          .build(),
    );

    _socket.onConnect((_) {
      print('Socket connected');
    });

    _socket.onDisconnect((_) {
      print('Socket disconnected');
    });

    _socket.on('message', (data) {
      print('Received message: $data');
      final message = Message.fromJson(data);
      addNewMessage(message);
    });

    _socket.connect();
  }

  void sendMessage(String text, String username) {
    if (text.trim().isEmpty) return;
    _socket.emit('message', {'message': text, 'sender': username});
  }

  void addNewMessage(Message message) {
    emit(state.copyWith(messages: List.from(state.messages)..add(message)));
  }

  @override
  Future<void> close() {
    _socket.disconnect();
    return super.close();
  }
}
