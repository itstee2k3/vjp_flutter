import 'package:equatable/equatable.dart';
import '../../data/model/message.dart';

class ChatState extends Equatable {
  final List<Message> messages;

  const ChatState({this.messages = const []});

  ChatState copyWith({List<Message>? messages}) {
    return ChatState(messages: messages ?? this.messages);
  }

  @override
  List<Object?> get props => [messages];
}
