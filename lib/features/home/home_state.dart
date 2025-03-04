import 'package:equatable/equatable.dart';
import '../../data/model/message.dart';

class HomeState extends Equatable {
  final List<Message> messages;

  const HomeState({this.messages = const []});

  HomeState copyWith({List<Message>? messages}) {
    return HomeState(messages: messages ?? this.messages);
  }

  @override
  List<Object?> get props => [messages];
}
